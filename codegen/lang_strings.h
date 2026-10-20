#pragma once
#include <3ds.h>

#define NUM_LANGUAGES 2

typedef enum {
    LANG_EN = 0,
    LANG_FR = 1,
} AppLanguage;

typedef struct {
    const char* str_mscorlib_restoring;
    const char* str_mscorlib_failed_restore;
    const char* str_mscorlib_restored;
    const char* str_file_open_failed;
    const char* str_mscorlib_not_found;
    const char* str_apps_not_found;
    const char* str_ok;
    const char* str_missing;
    const char* str_no_pe_folders_found;
    const char* str_no_pe_folders_found_advice;
    const char* str_refresh;
    const char* str_project_support;
    const char* str_check;
    const char* str_folder_found;
    const char* str_mscorlib_found;
    const char* str_browser_item_count;
} Strings;

extern const Strings STRINGS[NUM_LANGUAGES];
