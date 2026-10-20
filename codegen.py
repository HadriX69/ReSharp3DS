import os
import yaml

SRCDIR = "locale"
DESTDIR = "codegen"

basepath = os.path.dirname(os.path.realpath(__file__))
SRCDIR = basepath + "/" + SRCDIR
DESTDIR = basepath + "/" + DESTDIR

languages = ["en", "fr"]

# buttons / glyphs map
replace_map = {
    "a_button": "\ue000",
    "b_button": "\ue001",
    "x_button": "\ue002",
    "y_button": "\ue003",
    "l_button": "\ue004",
    "r_button": "\ue005",
    "d_pad": "\ue006",
    "start_button": "【start】",
    "select_button": "【select】",
    "playcoin": "\ue075",
    "analog_stick": "\ue077",
    "power_button": "\ue078",
}

def apply_replacements(text):
    """Replace the button tags with the corresponding glyphs or text"""
    for tag, replacement in replace_map.items():
        text = text.replace(f"{{{tag}}}", replacement)
    return text

# loading YAML
translations = {}
for lang in languages:
    filepath = f"{SRCDIR}/{lang}.yaml"
    if os.path.exists(filepath):
        with open(filepath, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
           
            if data:
                for key, value in data.items():
                    if isinstance(value, str):
                        data[key] = apply_replacements(value)
                translations[lang] = data

keys = list(translations["en"].keys())

# .h generation
header_content = "#pragma once\n#include <3ds.h>\n\n"
header_content += f"#define NUM_LANGUAGES {len(languages)}\n\n"
header_content += "typedef enum {\n"
header_content += "    LANG_EN = 0,\n"
header_content += "    LANG_FR = 1,\n"
header_content += "} AppLanguage;\n\n"

header_content += "typedef struct {\n"
for key in keys:
    header_content += f"    const char* {key};\n"
header_content += "} Strings;\n\n"

header_content += "extern const Strings STRINGS[NUM_LANGUAGES];\n"

os.makedirs(DESTDIR, exist_ok=True)
with open(f"{DESTDIR}/lang_strings.h", "w", encoding="utf-8") as f:
    f.write(header_content)

# .c generation
c_content = '#include "lang_strings.h"\n\n'
c_content += "const Strings STRINGS[NUM_LANGUAGES] = {\n"

for i, lang in enumerate(languages):
    c_content += f"    // {lang.upper()}\n    {{\n"
    for key in keys:
        text = translations[lang].get(key, translations["en"][key])
        
        text_escaped = text.replace('"', '\\"')
        c_content += f'        .{key} = "{text_escaped}",\n'
    c_content += "    },\n"

c_content += "};\n"

with open(f"{DESTDIR}/lang_strings.c", "w", encoding="utf-8") as f:
    f.write(c_content)

print("lang_strings.c and lang_strings.h generated successfully in codegen folder")