CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -Werror -pedantic
CPPFLAGS ?= -Iinclude
BUILD_DIR ?= build
PREFIX ?= /usr/local
DESTDIR ?=
UNAME_S := $(shell uname -s)
SHARED_EXT := $(if $(filter Darwin,$(UNAME_S)),dylib,so)
SHARED_FLAG := $(if $(filter Darwin,$(UNAME_S)),-dynamiclib,-shared)

.PHONY: all generate check-generated test sanitize install clean

generate:
	python3 tools/generate_runtime_v0_contract.py

check-generated:
	python3 tools/generate_runtime_v0_contract.py --check

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

test: check-generated $(BUILD_DIR)/runtime_v0_harness
	./$(BUILD_DIR)/runtime_v0_harness

sanitize: | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -fsanitize=undefined -fno-omit-frame-pointer src/runtime_v0.c tests/runtime_v0_harness.c -o $(BUILD_DIR)/runtime_v0_harness_ubsan
	./$(BUILD_DIR)/runtime_v0_harness_ubsan

install: all
	install -d $(DESTDIR)$(PREFIX)/include/poo_flow $(DESTDIR)$(PREFIX)/lib
	install -m 0644 include/poo_flow/runtime_v0.h $(DESTDIR)$(PREFIX)/include/poo_flow/runtime_v0.h
	install -m 0644 include/poo_flow/runtime_v0_contract.h $(DESTDIR)$(PREFIX)/include/poo_flow/runtime_v0_contract.h
	install -m 0644 $(BUILD_DIR)/libpoo_flow_runtime_v0.a $(DESTDIR)$(PREFIX)/lib/libpoo_flow_runtime_v0.a
	install -m 0755 $(BUILD_DIR)/libpoo_flow_runtime_v0.$(SHARED_EXT) $(DESTDIR)$(PREFIX)/lib/libpoo_flow_runtime_v0.$(SHARED_EXT)

clean:
	rm -rf $(BUILD_DIR)
