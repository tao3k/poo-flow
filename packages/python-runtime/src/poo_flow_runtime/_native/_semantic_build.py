# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Out-of-line CFFI API projection of the semantic AOT byte boundary."""
import sys
from cffi import FFI
ffibuilder = FFI()
ffibuilder.cdef('''
typedef struct { int32_t status; uint8_t *data; size_t length; } poo_flow_semantic_result;
int32_t poo_flow_python_semantic_open(const char *path);
int32_t poo_flow_python_semantic_call(const char *operation, const uint8_t *input,
                                    size_t length, poo_flow_semantic_result *result);
int32_t poo_flow_python_semantic_close(void);
void poo_flow_python_semantic_release(poo_flow_semantic_result *result);
''')
ffibuilder.set_source('poo_flow_runtime._native._semantic_cffi', r'''
#include <stdint.h>
#include <stddef.h>
#include <dlfcn.h>
#include <string.h>
#include <pthread.h>
static pthread_mutex_t shim_lock = PTHREAD_MUTEX_INITIALIZER;
typedef struct { int32_t status; uint8_t *data; size_t length; } poo_flow_semantic_result;
static void *library;
static int32_t (*open_native)(void);
static int32_t (*call_native)(const char *, const uint8_t *, size_t, poo_flow_semantic_result *);
static int32_t (*close_native)(void);
static void (*release_native)(poo_flow_semantic_result *);
int32_t poo_flow_python_semantic_open(const char *path) {
  pthread_mutex_lock(&shim_lock);
  if (library) { pthread_mutex_unlock(&shim_lock); return 1; }
  library = dlopen(path, RTLD_NOW | RTLD_LOCAL);
  if (!library) { pthread_mutex_unlock(&shim_lock); return 6; }
  void *symbol;
#define LOAD(field, name) symbol = dlsym(library, name); if (!symbol) { dlclose(library); library = NULL; pthread_mutex_unlock(&shim_lock); return 6; } memcpy(&field, &symbol, sizeof(field))
  LOAD(open_native, "poo_flow_semantic_open");
  LOAD(call_native, "poo_flow_semantic_call");
  LOAD(close_native, "poo_flow_semantic_close");
  LOAD(release_native, "poo_flow_semantic_result_release");
#undef LOAD
  int32_t status = open_native();
  pthread_mutex_unlock(&shim_lock);
  return status;
}
int32_t poo_flow_python_semantic_call(const char *operation, const uint8_t *input,
                                    size_t length, poo_flow_semantic_result *result) {
  pthread_mutex_lock(&shim_lock);
  int32_t status = library ? call_native(operation, input, length, result) : 1;
  pthread_mutex_unlock(&shim_lock);
  return status;
}
int32_t poo_flow_python_semantic_close(void) {
  pthread_mutex_lock(&shim_lock);
  int32_t status = library ? close_native() : 1;
  pthread_mutex_unlock(&shim_lock);
  return status;
}
void poo_flow_python_semantic_release(poo_flow_semantic_result *result) {
  pthread_mutex_lock(&shim_lock);
  if (library) release_native(result);
  pthread_mutex_unlock(&shim_lock);
}
''', libraries=['dl', 'pthread'] if sys.platform.startswith('linux') else [])

if __name__ == '__main__':
    ffibuilder.compile(verbose=True)
