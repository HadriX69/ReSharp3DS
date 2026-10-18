#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------
ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM")
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/3ds_rules

#---------------------------------------------------------------------------------
# ReSharp3DS general Makefile
#
# Default:
#   make
#
# Dev:
#   make BUILD_TYPE=dev
#
# Release:
#   make BUILD_TYPE=release
#
# Clean:
#   make clean
#   make distclean
#---------------------------------------------------------------------------------
TARGET      := ReSharp3DS

# BUILD_TYPE:
#   dev     = local debug
#   beta    = frequent distribution / public beta
#   release = clean build for stable release
BUILD_TYPE ?= release

BUILD       := build-$(BUILD_TYPE)
SOURCES     := source source/clr
DATA        := data
INCLUDES    := include source/clr
GRAPHICS    := gfx
GFXBUILD    := $(BUILD)

# If you have a RomFS, uncomment:
# ROMFS := romfs

# Optional SMDH metadata
APP_TITLE       ?= ReSharp3DS
APP_DESCRIPTION	:=	ReSharp3DS: C-Sharp runtime for Nintendo 3DS  # for Nintendo 3DS
APP_AUTHOR      ?= Saiitanaa
APP_DESC_INT	:=	-gl "ReSharp3DS: C-Sharp Laufzeitumgebung für Nintendo 3DS" \
					-pl "ReSharp3DS: Ambiente de execução C-Sharp para Nintendo 3DS" \
					-il "ReSharp3DS: runtime C-Sharp per Nintendo 3DS" \
					-fl "ReSharp3DS : environnement d'exécution C-Sharp pour Nintendo 3DS" \
					-jl "ReSharp3DS: ニンテンドー3DS向けC-Sharpランタイム" \
					-rl "ReSharp3DS: среда выполнения C-Sharp для Nintendo 3DS" \
					-sl "ReSharp3DS: Entorno de ejecución de C-Sharp para Nintendo 3DS" \
					-scl "ReSharp3DS：面向任天堂 3DS 的 C-Sharp 运行时"

#---------------------------------------------------------------------------------
# General options
#---------------------------------------------------------------------------------
ENABLE_RTTI ?= 1
CXXSTD      ?= gnu++11

# By default:
# - dev     : permissive enabled for difficult porting
# - beta    : permissive disabled to avoid hidden errors
# - release : permissive disabled
PERMISSIVE ?= 0

#---------------------------------------------------------------------------------
# 3DS CPU / ABI
#---------------------------------------------------------------------------------
ARCH := -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft

#---------------------------------------------------------------------------------
# Build flags
#---------------------------------------------------------------------------------
COMMON_FLAGS := -Wall -mword-relocations -ffunction-sections $(ARCH)

ifeq ($(BUILD_TYPE),dev)
	COMMON_FLAGS += -g3 -O0 -DDEBUG=1 -DRESHARP3DS_DEV=1
	PERMISSIVE := 1
else ifeq ($(BUILD_TYPE),beta)
	COMMON_FLAGS += -g -O2 -DDEBUG=1 -DRESHARP3DS_BETA=1
else ifeq ($(BUILD_TYPE),release)
	COMMON_FLAGS += -g -O2 -DNDEBUG -DRESHARP3DS_RELEASE=1
else
	$(error Invalid BUILD_TYPE. Use dev, beta, or release)
endif

#---------------------------------------------------------------------------------
# C flags
#---------------------------------------------------------------------------------
CFLAGS := $(COMMON_FLAGS)
CFLAGS += $(INCLUDE) -D__3DS__

#---------------------------------------------------------------------------------
# C++ flags
#---------------------------------------------------------------------------------
CXXFLAGS := $(COMMON_FLAGS)
CXXFLAGS += $(INCLUDE) -D__3DS__
CXXFLAGS += -std=$(CXXSTD)
CXXFLAGS += -fno-exceptions

ifeq ($(ENABLE_RTTI),1)
	CXXFLAGS += -frtti
else
	CXXFLAGS += -fno-rtti
endif

ifeq ($(PERMISSIVE),1)
	CXXFLAGS += -fpermissive
endif

#---------------------------------------------------------------------------------
# Assembler / linker
#---------------------------------------------------------------------------------
ASFLAGS := -g $(ARCH)

LDFLAGS := -specs=3dsx.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

# citro2d depends on citro3d/libctru, so keep this order.
LIBS := -lcitro2d -lcitro3d -lctru -lm

LIBDIRS := $(CTRULIB)

#---------------------------------------------------------------------------------
# Nothing below normally needs editing
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT := $(CURDIR)/$(TARGET)
export TOPDIR := $(CURDIR)

export VPATH := $(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
				$(foreach dir,$(GRAPHICS),$(CURDIR)/$(dir)) \
				$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR := $(CURDIR)/$(BUILD)

CFILES      := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES    := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES      := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
PICAFILES   := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.v.pica)))
SHLISTFILES := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.shlist)))
GFXFILES    := $(foreach dir,$(GRAPHICS),$(notdir $(wildcard $(dir)/*.t3s)))
BINFILES    := $(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

ifeq ($(strip $(CPPFILES)),)
	export LD := $(CC)
else
	export LD := $(CXX)
endif

ifeq ($(GFXBUILD),$(BUILD))
	export T3XFILES := $(GFXFILES:.t3s=.t3x)
else
	export ROMFS_T3XFILES := $(patsubst %.t3s,$(GFXBUILD)/%.t3x,$(GFXFILES))
	export T3XHFILES     := $(patsubst %.t3s,$(BUILD)/%.h,$(GFXFILES))
endif

export OFILES_SOURCES := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export OFILES_BIN := $(addsuffix .o,$(BINFILES)) \
					 $(PICAFILES:.v.pica=.shbin.o) \
					 $(SHLISTFILES:.shlist=.shbin.o) \
					 $(addsuffix .o,$(T3XFILES))

export OFILES := $(OFILES_BIN) $(OFILES_SOURCES)

export HFILES := $(PICAFILES:.v.pica=_shbin.h) \
				 $(SHLISTFILES:.shlist=_shbin.h) \
				 $(addsuffix .h,$(subst .,_,$(BINFILES))) \
				 $(GFXFILES:.t3s=.h)

export INCLUDE := $(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
				  $(foreach dir,$(LIBDIRS),-I$(dir)/include) \
				  -I$(CURDIR)/$(BUILD)

export LIBPATHS := $(foreach dir,$(LIBDIRS),-L$(dir)/lib)

export _3DSXDEPS := $(if $(NO_SMDH),,$(OUTPUT).smdh)

ifeq ($(strip $(ICON)),)
	icons := $(wildcard *.png)
	ifneq (,$(findstring $(TARGET).png,$(icons)))
		export APP_ICON := $(TOPDIR)/$(TARGET).png
	else
		ifneq (,$(findstring icon.png,$(icons)))
			export APP_ICON := $(TOPDIR)/icon.png
		endif
	endif
else
	export APP_ICON := $(TOPDIR)/$(ICON)
endif

ifeq ($(strip $(NO_SMDH)),)
	export _3DSXFLAGS += --smdh=$(CURDIR)/$(TARGET).smdh
endif

ifneq ($(ROMFS),)
	export _3DSXFLAGS += --romfs=$(CURDIR)/$(ROMFS)
endif

.PHONY: all clean distclean info

all: info $(BUILD) $(GFXBUILD) $(DEPSDIR) $(ROMFS_T3XFILES) $(T3XHFILES)
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

info:
	@echo "Building $(TARGET)"
	@echo "BUILD_TYPE=$(BUILD_TYPE)"
	@echo "BUILD=$(BUILD)"
	@echo "PERMISSIVE=$(PERMISSIVE)"
	@echo "ENABLE_RTTI=$(ENABLE_RTTI)"

$(BUILD):
	@mkdir -p $@

ifneq ($(GFXBUILD),$(BUILD))
$(GFXBUILD):
	@mkdir -p $@
endif

ifneq ($(DEPSDIR),$(BUILD))
$(DEPSDIR):
	@mkdir -p $@
endif

clean:
	@echo clean $(BUILD_TYPE) ...
	@rm -fr build build-dev build-beta build-release
	@rm -f $(TARGET).3dsx $(TARGET).smdh $(TARGET).elf $(TARGET).map

distclean:
	@echo distclean ...
	@rm -fr build build-dev build-beta build-release
	@rm -f $(TARGET).3dsx $(TARGET).smdh $(TARGET).elf $(TARGET).map

$(GFXBUILD)/%.t3x $(BUILD)/%.h : %.t3s
	@echo $(notdir $<)
	@tex3ds -i $< -H $(BUILD)/$*.h -d $(DEPSDIR)/$*.d -o $(GFXBUILD)/$*.t3x

else

$(OUTPUT).3dsx : $(OUTPUT).elf $(_3DSXDEPS)

$(OFILES_SOURCES) : $(HFILES)

$(OUTPUT).elf : $(OFILES)

%.bin.o %_bin.h : %.bin
	@echo $(notdir $<)
	@$(bin2o)

.PRECIOUS : %.t3x %.shbin

%.t3x.o %_t3x.h : %.t3x
	$(SILENTMSG) $(notdir $<)
	$(bin2o)

%.shbin.o %_shbin.h : %.shbin
	$(SILENTMSG) $(notdir $<)
	$(bin2o)

-include $(DEPSDIR)/*.d

endif