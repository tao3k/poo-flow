from __future__ import annotations

from pathlib import Path

from cffi import FFI

ffibuilder = FFI()
ffibuilder.cdef(
    """
    typedef struct {
      uint32_t status;
      uint16_t abi_major;
      uint16_t abi_minor;
      uint64_t capabilities;
      uint64_t max_payload_bytes;
      char error[160];
    } poo_flow_python_runtime_v0_health;

    typedef struct poo_flow_python_runtime_v0_context
        poo_flow_python_runtime_v0_context;

    typedef struct {
      uint16_t layout_version;
      uint16_t event_kind;
      uint32_t flags;
      uint64_t sequence;
      uint64_t event_identity_high;
      uint64_t event_identity_low;
      uint64_t correlation_identity_high;
      uint64_t correlation_identity_low;
      uint64_t authorization_identity_high;
      uint64_t authorization_identity_low;
      uint64_t payload_offset;
      uint64_t payload_length;
      uint64_t deadline_mono_ns;
      uint32_t required_evidence_bits;
      uint32_t reserved0;
    } poo_flow_python_runtime_v0_event;

    typedef struct {
      uint32_t status;
      uint64_t published_count;
      uint64_t produced_count;
      uint64_t accepted_count;
      uint64_t rejected_count;
      uint64_t accepted_watermark;
    } poo_flow_python_runtime_v0_batch_result;

    int poo_flow_python_runtime_v0_probe(
        const char *library_path,
        const uint8_t *bundle_schema,
        size_t bundle_schema_length,
        const uint8_t *runtime_identity,
        size_t runtime_identity_length,
        poo_flow_python_runtime_v0_health *health);

    poo_flow_python_runtime_v0_context *poo_flow_python_runtime_v0_open(
        const char *library_path,
        const uint8_t *bundle_schema,
        size_t bundle_schema_length,
        const uint8_t *runtime_identity,
        size_t runtime_identity_length,
        uint32_t digest_algorithm,
        const uint8_t *bundle_digest,
        size_t bundle_digest_length,
        uint64_t bundle_epoch,
        const uint8_t *canonical_packet,
        size_t canonical_packet_length,
        poo_flow_python_runtime_v0_health *health);

    uint32_t poo_flow_python_runtime_v0_close(
        poo_flow_python_runtime_v0_context *context);

    uint32_t poo_flow_python_runtime_v0_arena_register(
        poo_flow_python_runtime_v0_context *context,
        uint8_t *memory,
        uint64_t capacity,
        uint32_t alignment,
        uint64_t generation);

    uint32_t poo_flow_python_runtime_v0_arena_release(
        poo_flow_python_runtime_v0_context *context);

    uint32_t poo_flow_python_runtime_v0_arena_recycle(
        poo_flow_python_runtime_v0_context *context,
        uint64_t expected_generation,
        uint64_t next_generation);

    uint32_t poo_flow_python_runtime_v0_roundtrip(
        poo_flow_python_runtime_v0_context *context,
        poo_flow_python_runtime_v0_event *events,
        uint64_t event_count,
        uint32_t *item_statuses,
        uint64_t item_status_capacity,
        uint8_t *accepted_bitmap,
        uint64_t accepted_bitmap_bytes,
        poo_flow_python_runtime_v0_batch_result *result);
    """
)

native_dir = Path(__file__).resolve().parent
runtime_c = native_dir.parents[4] / "bindings" / "runtime-c"
ffibuilder.set_source(
    "poo_flow_runtime._native._runtime_v0_cffi",
    '#include "runtime_v0_shim.c"',
    include_dirs=[str(native_dir), str(runtime_c / "include")],
)

if __name__ == "__main__":
    ffibuilder.compile(
        tmpdir=str(native_dir / "_build_temp"),
        target=str(native_dir / "_runtime_v0_cffi.abi3.so"),
        verbose=True,
    )
