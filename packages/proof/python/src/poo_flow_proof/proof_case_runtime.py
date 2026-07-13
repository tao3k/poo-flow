"""Native proof-case validation through the stable C ABI.

The Python validator and CFFI adapter intentionally consume the same generated
native vector.  This keeps Python useful as a production runtime while making
cross-runtime conformance byte-for-byte testable without a JSON boundary.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import IntEnum
from os import PathLike
from struct import unpack_from

from cffi import FFI

from poo_flow_proof.generated.proof_case_vector import (
    ABI_VERSION,
    CASE_KINDS,
    DURABILITY_PROFILES,
    FIELD_OFFSETS,
    MEDIATION_OUTCOMES,
    REQUIRED_OBLIGATION_MASK,
    SCHEMA_FINGERPRINT_HEX,
    VECTOR_ALIGNMENT,
    VECTOR_SIZE,
)


class ProofStatus(IntEnum):
    OK = 0
    INVALID_ARGUMENT = 1
    BUFFER_TOO_SMALL = 2
    STALE_HANDLE = 3
    SCHEMA_MISMATCH = 4
    MALFORMED_EVIDENCE = 5
    UNSUPPORTED_OBLIGATION = 6


class ProofCaseError(ValueError):
    def __init__(self, status: ProofStatus, message: str) -> None:
        super().__init__(message)
        self.status = status


@dataclass(frozen=True)
class ProofCaseLayout:
    required_size: int
    alignment: int
    abi_version: int
    schema_fingerprint: bytes


def _u32(vector: bytes, field: str) -> int:
    return unpack_from("<I", vector, FIELD_OFFSETS[field])[0]


def _u64(vector: bytes, field: str) -> int:
    return unpack_from("<Q", vector, FIELD_OFFSETS[field])[0]


def validate_proof_case_vector(vector: bytes) -> ProofStatus:
    """Mirror the C boundary checks using generated native-layout constants."""
    if len(vector) != VECTOR_SIZE:
        return ProofStatus.MALFORMED_EVIDENCE
    if _u32(vector, "abi_version") != ABI_VERSION:
        return ProofStatus.SCHEMA_MISMATCH
    fingerprint = vector[
        FIELD_OFFSETS["schema_fingerprint"] : FIELD_OFFSETS["schema_fingerprint"] + 32
    ]
    if fingerprint != bytes.fromhex(SCHEMA_FINGERPRINT_HEX):
        return ProofStatus.SCHEMA_MISMATCH

    required = _u64(vector, "required_obligation_mask")
    present = _u64(vector, "present_obligation_mask")
    if (required | present) & ~REQUIRED_OBLIGATION_MASK:
        return ProofStatus.UNSUPPORTED_OBLIGATION
    if present & ~required:
        return ProofStatus.MALFORMED_EVIDENCE

    if _u32(vector, "case_kind") not in CASE_KINDS.values():
        return ProofStatus.MALFORMED_EVIDENCE
    if _u32(vector, "obligation_count") > 8:
        return ProofStatus.MALFORMED_EVIDENCE
    if _u32(vector, "mediation_outcome") not in MEDIATION_OUTCOMES.values():
        return ProofStatus.MALFORMED_EVIDENCE
    if _u32(vector, "durability_profile") not in DURABILITY_PROFILES.values():
        return ProofStatus.MALFORMED_EVIDENCE
    if any(vector[FIELD_OFFSETS["reserved"] :]):
        return ProofStatus.MALFORMED_EVIDENCE
    return ProofStatus.OK


_CDEF = """
typedef uint32_t poo_flow_proof_status;
typedef struct { const unsigned char *data; size_t size; uint64_t generation; }
  poo_flow_proof_case_handle;
typedef struct {
  size_t required_size;
  size_t alignment;
  uint32_t abi_version;
  unsigned char schema_fingerprint[32];
} poo_flow_proof_case_layout;
poo_flow_proof_status poo_flow_proof_case_init(
  const void *, size_t, poo_flow_proof_case_handle *);
poo_flow_proof_status poo_flow_proof_case_release(poo_flow_proof_case_handle *);
poo_flow_proof_status poo_flow_proof_case_measure(
  const poo_flow_proof_case_handle *, poo_flow_proof_case_layout *);
poo_flow_proof_status poo_flow_proof_case_write(
  const poo_flow_proof_case_handle *, void *, size_t, size_t *);
const char *poo_flow_proof_status_name(poo_flow_proof_status);
"""


class NativeProofCaseRuntime:
    """Zero-copy input adapter over ``poo_flow_proof_case_v1``."""

    def __init__(self, library: str | PathLike[str]) -> None:
        self.ffi = FFI()
        self.ffi.cdef(_CDEF)
        self.lib = self.ffi.dlopen(str(library))

    def _raise(self, raw_status: int) -> None:
        status = ProofStatus(raw_status)
        name = self.ffi.string(self.lib.poo_flow_proof_status_name(raw_status)).decode()
        raise ProofCaseError(status, name)

    def validate_and_copy(self, vector: bytes) -> tuple[ProofCaseLayout, bytes]:
        backing = self.ffi.from_buffer("const unsigned char[]", vector)
        handle = self.ffi.new("poo_flow_proof_case_handle *")
        status = self.lib.poo_flow_proof_case_init(backing, len(vector), handle)
        if status != ProofStatus.OK:
            self._raise(status)
        try:
            raw_layout = self.ffi.new("poo_flow_proof_case_layout *")
            status = self.lib.poo_flow_proof_case_measure(handle, raw_layout)
            if status != ProofStatus.OK:
                self._raise(status)
            layout = ProofCaseLayout(
                required_size=raw_layout.required_size,
                alignment=raw_layout.alignment,
                abi_version=raw_layout.abi_version,
                schema_fingerprint=bytes(self.ffi.buffer(raw_layout.schema_fingerprint, 32)),
            )
            output = self.ffi.new("unsigned char[]", layout.required_size)
            written = self.ffi.new("size_t *")
            status = self.lib.poo_flow_proof_case_write(
                handle, output, layout.required_size, written
            )
            if status != ProofStatus.OK:
                self._raise(status)
            if written[0] != layout.required_size:
                raise RuntimeError("C ABI returned an inconsistent proof-case length")
            return layout, bytes(self.ffi.buffer(output, written[0]))
        finally:
            status = self.lib.poo_flow_proof_case_release(handle)
            if status != ProofStatus.OK:
                self._raise(status)


def assert_native_differential(
    runtime: NativeProofCaseRuntime, vector: bytes
) -> ProofCaseLayout:
    python_status = validate_proof_case_vector(vector)
    try:
        layout, copied = runtime.validate_and_copy(vector)
    except ProofCaseError as error:
        if error.status != python_status:
            raise AssertionError(
                f"Python/C proof status mismatch: {python_status.name} != {error.status.name}"
            ) from error
        raise
    if python_status != ProofStatus.OK:
        raise AssertionError(f"C accepted vector rejected by Python: {python_status.name}")
    if copied != vector:
        raise AssertionError("C ABI proof-case round trip changed native bytes")
    if layout != ProofCaseLayout(
        VECTOR_SIZE, VECTOR_ALIGNMENT, ABI_VERSION, bytes.fromhex(SCHEMA_FINGERPRINT_HEX)
    ):
        raise AssertionError("C ABI layout differs from generated Python contract")
    return layout
