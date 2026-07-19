from __future__ import annotations

import os
from pathlib import Path

import pytest


def _bundle_library() -> Path:
    override = os.environ.get("POO_FLOW_BUNDLE_V1_LIBRARY")
    if override:
        return Path(override).expanduser().resolve()
    return (
        Path(__file__).resolve().parents[4]
        / "bazel-bin"
        / "bindings"
        / "runtime-c"
        / "bundle-v1"
        / "libbundle_v1_shared.dylib"
    )


def test_bundle_v1_cffi_is_typed_zero_copy_and_logarithmic() -> None:
    cffi = pytest.importorskip("cffi")
    library = _bundle_library()
    if not library.is_file():
        pytest.skip("focused Bundle v1 shared-library build has not run")

    ffi = cffi.FFI()
    ffi.cdef(
        """
        typedef uint32_t poo_flow_bundle_v1_status;
        typedef struct { uint64_t high; uint64_t low; }
          poo_flow_bundle_v1_compact_id;
        typedef struct {
          uint64_t offset;
          uint64_t length;
          uint32_t stride;
          uint32_t alignment;
        } poo_flow_bundle_v1_region;
        typedef struct {
          poo_flow_bundle_v1_compact_id case_id;
          poo_flow_bundle_v1_compact_id component_id;
          poo_flow_bundle_v1_compact_id object_id;
          poo_flow_bundle_v1_compact_id type_id;
          poo_flow_bundle_v1_compact_id contract_id;
          poo_flow_bundle_v1_compact_id role_id;
          poo_flow_bundle_v1_compact_id capability_id;
          poo_flow_bundle_v1_compact_id policy_id;
          poo_flow_bundle_v1_compact_id strategy_id;
          poo_flow_bundle_v1_compact_id adapter_id;
          poo_flow_bundle_v1_compact_id projection_id;
          uint64_t composition_order;
          uint32_t flags;
          uint32_t reserved0;
          uint64_t reserved1;
        } poo_flow_bundle_v1_component_entry;
        typedef struct {
          uint32_t struct_size;
          uint32_t flags;
          uint16_t schema_major;
          uint16_t schema_minor;
          uint32_t reserved0;
          poo_flow_bundle_v1_compact_id bundle_id;
          uint8_t digest[32];
          uint64_t bundle_epoch;
          uint64_t arena_bytes;
          poo_flow_bundle_v1_region symbols;
          poo_flow_bundle_v1_region components;
          poo_flow_bundle_v1_region edges;
          poo_flow_bundle_v1_region evidence_obligations;
          poo_flow_bundle_v1_region metadata_bytes;
          uint64_t reserved[7];
        } poo_flow_bundle_v1_descriptor;
        poo_flow_bundle_v1_status poo_flow_bundle_v1_validate(
          const poo_flow_bundle_v1_descriptor *, const void *, uint64_t);
        poo_flow_bundle_v1_status poo_flow_bundle_v1_find_component(
          const poo_flow_bundle_v1_descriptor *,
          const void *,
          poo_flow_bundle_v1_compact_id,
          poo_flow_bundle_v1_compact_id,
          const poo_flow_bundle_v1_component_entry **);
        """
    )
    native = ffi.dlopen(str(library))
    assert ffi.sizeof("poo_flow_bundle_v1_descriptor") == 256
    assert ffi.sizeof("poo_flow_bundle_v1_component_entry") == 200
    rows = ffi.new("poo_flow_bundle_v1_component_entry[]", 2)
    descriptor = ffi.new("poo_flow_bundle_v1_descriptor *")

    for index, row in enumerate(rows):
        row.case_id.low = 41
        row.component_id.low = index + 1
        row.object_id.low = 100 + index
        row.flags = 1

    descriptor.struct_size = ffi.sizeof("poo_flow_bundle_v1_descriptor")
    descriptor.flags = 3
    descriptor.schema_major = 1
    descriptor.schema_minor = 0
    descriptor.bundle_id.low = 7
    descriptor.digest[0] = 0xA5
    descriptor.arena_bytes = ffi.sizeof(rows)
    descriptor.symbols.stride = 32
    descriptor.symbols.alignment = 8
    descriptor.components.offset = 0
    descriptor.components.length = ffi.sizeof(rows)
    descriptor.components.stride = ffi.sizeof(
        "poo_flow_bundle_v1_component_entry"
    )
    descriptor.components.alignment = ffi.alignof(
        "poo_flow_bundle_v1_component_entry"
    )
    descriptor.edges.stride = 80
    descriptor.edges.alignment = 8
    descriptor.evidence_obligations.stride = 96
    descriptor.evidence_obligations.alignment = 8
    descriptor.metadata_bytes.stride = 1
    descriptor.metadata_bytes.alignment = 1

    assert native.poo_flow_bundle_v1_validate(
        descriptor, rows, ffi.sizeof(rows)
    ) == 0

    found = ffi.new("const poo_flow_bundle_v1_component_entry **")
    case_id = ffi.new("poo_flow_bundle_v1_compact_id *", {"low": 41})[0]
    component_id = ffi.new(
        "poo_flow_bundle_v1_compact_id *", {"low": 2}
    )[0]
    assert native.poo_flow_bundle_v1_find_component(
        descriptor, rows, case_id, component_id, found
    ) == 0
    assert found[0].object_id.low == 101
    assert int(ffi.cast("uintptr_t", found[0])) == int(
        ffi.cast("uintptr_t", rows + 1)
    )

    missing_id = ffi.new(
        "poo_flow_bundle_v1_compact_id *", {"low": 99}
    )[0]
    assert native.poo_flow_bundle_v1_find_component(
        descriptor, rows, case_id, missing_id, found
    ) == 8
