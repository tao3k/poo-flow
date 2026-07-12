CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -Werror -pedantic
CPPFLAGS ?= -Iinclude
BUILD_DIR ?= build
PREFIX ?= /usr/local
DESTDIR ?=
UNAME_S := $(shell uname -s)
SHARED_EXT := $(if $(filter Darwin,$(UNAME_S)),dylib,so)
SHARED_FLAG := $(if $(filter Darwin,$(UNAME_S)),-dynamiclib,-shared)
REPO_PARENT := $(abspath ../../..)
GERBIL_ENV := env -u CPATH -u SDKROOT -u C_INCLUDE_PATH -u LIBRARY_PATH GERBIL_LOADPATH=$(REPO_PARENT)
RUNTIME_C_INCLUDE := $(abspath include)
RUNTIME_C_STATIC := $(abspath $(BUILD_DIR)/libpoo_flow_runtime_v0.a)
RUNTIME_C_LIBRARY := $(abspath $(BUILD_DIR))
PROJECT_GERBIL_PATH := $(abspath ../../.gerbil)

.PHONY: all generate check-generated test sanitize asan leak install-consumer benchmark gerbil-benchmark install clean

generate:
	cd ../.. && $(GERBIL_ENV) gxi bindings/runtime-c/tools/generate-runtime-v0-contract.ss

check-generated:
	cd ../.. && $(GERBIL_ENV) gxi bindings/runtime-c/tools/generate-runtime-v0-contract.ss --check

all: $(BUILD_DIR)/libpoo_flow_runtime_v0.a $(BUILD_DIR)/libpoo_flow_runtime_v0.$(SHARED_EXT)

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/runtime_v0.o: src/runtime_v0.c include/poo_flow/runtime_v0.h | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -fPIC -c $< -o $@

$(BUILD_DIR)/libpoo_flow_runtime_v0.a: $(BUILD_DIR)/runtime_v0.o
	ar rcs $@ $<

$(BUILD_DIR)/libpoo_flow_runtime_v0.$(SHARED_EXT): $(BUILD_DIR)/runtime_v0.o
	$(CC) $(SHARED_FLAG) $< -o $@

$(BUILD_DIR)/runtime_v0_harness: src/runtime_v0.c tests/runtime_v0_harness.c include/poo_flow/runtime_v0.h | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) src/runtime_v0.c tests/runtime_v0_harness.c -o $@

$(BUILD_DIR)/runtime_v0_batch_harness: src/runtime_v0.c src/runtime_v0_internal.h tests/runtime_v0_batch_harness.c include/poo_flow/runtime_v0.h | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) src/runtime_v0.c tests/runtime_v0_batch_harness.c -o $@

$(BUILD_DIR)/runtime_v0_vector_harness: tests/runtime_v0_vector_harness.c include/poo_flow/runtime_v0.h | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) tests/runtime_v0_vector_harness.c -o $@

test: check-generated $(BUILD_DIR)/runtime_v0_harness $(BUILD_DIR)/runtime_v0_batch_harness $(BUILD_DIR)/runtime_v0_vector_harness
	./$(BUILD_DIR)/runtime_v0_harness
	./$(BUILD_DIR)/runtime_v0_batch_harness
	./$(BUILD_DIR)/runtime_v0_vector_harness tests/vectors/runtime_v0_event_1.txt

sanitize: | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -fsanitize=undefined -fno-omit-frame-pointer src/runtime_v0.c tests/runtime_v0_harness.c -o $(BUILD_DIR)/runtime_v0_harness_ubsan
	./$(BUILD_DIR)/runtime_v0_harness_ubsan
	$(CC) $(CPPFLAGS) $(CFLAGS) -fsanitize=undefined -fno-omit-frame-pointer src/runtime_v0.c tests/runtime_v0_batch_harness.c -o $(BUILD_DIR)/runtime_v0_batch_harness_ubsan
	./$(BUILD_DIR)/runtime_v0_batch_harness_ubsan

asan: | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -fsanitize=address -fno-omit-frame-pointer src/runtime_v0.c tests/runtime_v0_harness.c -o $(BUILD_DIR)/runtime_v0_harness_asan
	./$(BUILD_DIR)/runtime_v0_harness_asan
	$(CC) $(CPPFLAGS) $(CFLAGS) -fsanitize=address -fno-omit-frame-pointer src/runtime_v0.c tests/runtime_v0_batch_harness.c -o $(BUILD_DIR)/runtime_v0_batch_harness_asan
	./$(BUILD_DIR)/runtime_v0_batch_harness_asan

leak: test
	@if [ "$(UNAME_S)" = Darwin ]; then \
	  leaks -atExit -- ./$(BUILD_DIR)/runtime_v0_harness; \
	  leaks -atExit -- ./$(BUILD_DIR)/runtime_v0_batch_harness; \
	elif command -v valgrind >/dev/null 2>&1; then \
	  valgrind --error-exitcode=1 --leak-check=full ./$(BUILD_DIR)/runtime_v0_harness; \
	  valgrind --error-exitcode=1 --leak-check=full ./$(BUILD_DIR)/runtime_v0_batch_harness; \
	else \
	  echo "no supported leak checker available" >&2; exit 77; \
	fi

install-consumer: all
	rm -rf $(BUILD_DIR)/install-root
	$(MAKE) install DESTDIR=$(abspath $(BUILD_DIR)/install-root) PREFIX=/usr
	$(CC) $(CFLAGS) -I$(abspath $(BUILD_DIR)/install-root/usr/include) tests/runtime_v0_installed_consumer.c $(abspath $(BUILD_DIR)/install-root/usr/lib/libpoo_flow_runtime_v0.a) -o $(BUILD_DIR)/runtime_v0_installed_consumer
	./$(BUILD_DIR)/runtime_v0_installed_consumer

$(BUILD_DIR)/runtime_v0_batch_benchmark: src/runtime_v0.c src/runtime_v0_internal.h benchmarks/runtime_v0_batch_benchmark.c include/poo_flow/runtime_v0.h | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -O3 src/runtime_v0.c benchmarks/runtime_v0_batch_benchmark.c -o $@

benchmark: check-generated $(BUILD_DIR)/runtime_v0_batch_benchmark
	./$(BUILD_DIR)/runtime_v0_batch_benchmark 20

gerbil-benchmark: all benchmarks/runtime-v0-gerbil-ffi-benchmark.ss
	cd ../.. && $(GERBIL_ENV) gxc -O -d .gerbil/lib -cc-options "-I$(RUNTIME_C_INCLUDE)" -ld-options "-L$(RUNTIME_C_LIBRARY) -lpoo_flow_runtime_v0" bindings/runtime-c/benchmarks/runtime-v0-gerbil-ffi-benchmark.ss
	cd ../.. && env -u CPATH -u SDKROOT -u C_INCLUDE_PATH -u LIBRARY_PATH DYLD_LIBRARY_PATH=$(RUNTIME_C_LIBRARY) GERBIL_PATH=$(PROJECT_GERBIL_PATH) gxi -e '(begin (import :poo-flow/bindings/runtime-c/benchmarks/runtime-v0-gerbil-ffi-benchmark) (main))'

install: all
	install -d $(DESTDIR)$(PREFIX)/include/poo_flow $(DESTDIR)$(PREFIX)/lib
	install -m 0644 include/poo_flow/runtime_v0.h $(DESTDIR)$(PREFIX)/include/poo_flow/runtime_v0.h
	install -m 0644 include/poo_flow/runtime_v0_contract.h $(DESTDIR)$(PREFIX)/include/poo_flow/runtime_v0_contract.h
	install -m 0644 $(BUILD_DIR)/libpoo_flow_runtime_v0.a $(DESTDIR)$(PREFIX)/lib/libpoo_flow_runtime_v0.a
	install -m 0755 $(BUILD_DIR)/libpoo_flow_runtime_v0.$(SHARED_EXT) $(DESTDIR)$(PREFIX)/lib/libpoo_flow_runtime_v0.$(SHARED_EXT)

clean:
	rm -rf $(BUILD_DIR)
