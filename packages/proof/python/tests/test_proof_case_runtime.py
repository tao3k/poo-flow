from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path
from struct import pack_into

import pytest

from poo_flow_proof.generated.proof_case_vector import FIELD_OFFSETS, VECTOR_SIZE
from poo_flow_proof.proof_case_emit import generated_artifacts
from poo_flow_proof.proof_case_manifest import load_proof_case_schema
from poo_flow_proof.proof_case_runtime import (
    NativeProofCaseRuntime,
    ProofCaseError,
    ProofStatus,
    VectorDivergence,
    assert_native_differential,
    first_vector_divergence,
    proof_case_vector_digest,
    validate_proof_case_vector,
)


REPO_ROOT = Path(__file__).parents[4]
PROOF_ROOT = Path(__file__).parents[2]


@pytest.fixture(scope="session")
def native_runtime(tmp_path_factory: pytest.TempPathFactory) -> NativeProofCaseRuntime:
    output = tmp_path_factory.mktemp("runtime-c") / (
        "libpoo_flow_proof.dylib" if sys.platform == "darwin" else "libpoo_flow_proof.so"
    )
    link_mode = "-dynamiclib" if sys.platform == "darwin" else "-shared"
    subprocess.run(
        [
            "cc",
            "-std=c11",
            "-O2",
            "-fPIC",
            link_mode,
            "-I",
            str(REPO_ROOT / "bindings/runtime-c/include"),
            str(REPO_ROOT / "bindings/runtime-c/src/proof_case_v1.c"),
            "-o",
            str(output),
        ],
        check=True,
    )
    return NativeProofCaseRuntime(output)


def positive_vector() -> bytes:
    schema = load_proof_case_schema(PROOF_ROOT / "proof-case-vector-v1.toml")
    return bytes.fromhex(
        generated_artifacts(schema)[Path("vectors/proof_case_vector_v1_positive.hex")]
    )


def scheme_vector() -> tuple[bytes, bytes]:
    env = os.environ.copy()
    env["GERBIL_LOADPATH"] = str(REPO_ROOT)
    command_line_sdk = Path("/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk")
    homebrew = Path("/opt/homebrew/bin")
    if sys.platform == "darwin" and command_line_sdk.is_dir() and homebrew.is_dir():
        env["SDKROOT"] = str(command_line_sdk)
        env["PATH"] = ":".join(
            [str(homebrew), "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        )
    completed = subprocess.run(
        ["gxpkg", "env", "gxi", "tools/emit-proof-case-vector.ss"],
        cwd=REPO_ROOT,
        env=env,
        check=True,
        capture_output=True,
        text=True,
    )
    receipt = dict(line.split("=", 1) for line in completed.stdout.splitlines())
    return bytes.fromhex(receipt["vector"]), bytes.fromhex(receipt["digest"])


def test_native_cffi_round_trip_matches_python_contract(
    native_runtime: NativeProofCaseRuntime,
) -> None:
    vector = positive_vector()
    layout = assert_native_differential(native_runtime, vector)

    assert layout.required_size == VECTOR_SIZE
    assert validate_proof_case_vector(vector) is ProofStatus.OK


def test_scheme_c_python_and_lean_fixture_share_one_vector(
    native_runtime: NativeProofCaseRuntime,
) -> None:
    generated = positive_vector()
    scheme, scheme_digest = scheme_vector()

    assert first_vector_divergence(
        generated,
        scheme,
        expected_owner="manifest/lean",
        actual_owner="scheme",
    ) is None
    assert proof_case_vector_digest(scheme) == scheme_digest
    assert_native_differential(native_runtime, scheme)


def test_differential_reports_first_owner_and_field() -> None:
    generated = positive_vector()
    mutated = bytearray(generated)
    mutated[FIELD_OFFSETS["effect_digest"]] ^= 1

    assert first_vector_divergence(
        generated,
        bytes(mutated),
        expected_owner="manifest/lean",
        actual_owner="scheme",
    ) == VectorDivergence(
        "manifest/lean", "scheme", "effect_digest", FIELD_OFFSETS["effect_digest"]
    )


@pytest.mark.parametrize(
    ("field", "value", "expected"),
    [
        ("abi_version", 2, ProofStatus.SCHEMA_MISMATCH),
        ("required_obligation_mask", 0x100, ProofStatus.UNSUPPORTED_OBLIGATION),
        ("mediation_outcome", 99, ProofStatus.MALFORMED_EVIDENCE),
    ],
)
def test_python_and_c_reject_mutations_with_same_status(
    native_runtime: NativeProofCaseRuntime,
    field: str,
    value: int,
    expected: ProofStatus,
) -> None:
    vector = bytearray(positive_vector())
    format_ = "<Q" if field == "required_obligation_mask" else "<I"
    pack_into(format_, vector, FIELD_OFFSETS[field], value)

    assert validate_proof_case_vector(bytes(vector)) is expected
    with pytest.raises(ProofCaseError) as caught:
        assert_native_differential(native_runtime, bytes(vector))
    assert caught.value.status is expected


def test_python_and_c_reject_truncated_vector(
    native_runtime: NativeProofCaseRuntime,
) -> None:
    vector = positive_vector()[:-1]

    assert validate_proof_case_vector(vector) is ProofStatus.MALFORMED_EVIDENCE
    with pytest.raises(ProofCaseError) as caught:
        assert_native_differential(native_runtime, vector)
    assert caught.value.status is ProofStatus.MALFORMED_EVIDENCE
