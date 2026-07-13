from __future__ import annotations

import argparse
from importlib.metadata import version
from pathlib import Path

import poo_flow_proof
from poo_flow_proof.proof_case_runtime import (
    NativeProofCaseRuntime,
    assert_native_differential,
    proof_case_vector_digest,
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", type=Path, required=True)
    parser.add_argument("--vector", type=Path, required=True)
    parser.add_argument("--forbid-root", type=Path, required=True)
    args = parser.parse_args()

    package_path = Path(poo_flow_proof.__file__).resolve()
    try:
        package_path.relative_to(args.forbid_root.resolve())
    except ValueError:
        pass
    else:
        raise RuntimeError(f"consumer imported checkout source: {package_path}")

    vector = bytes.fromhex(args.vector.read_text(encoding="ascii"))
    runtime = NativeProofCaseRuntime(args.library)
    layout = assert_native_differential(runtime, vector)
    digest = proof_case_vector_digest(vector).hex()
    print(
        "installed-wheel-consumer: "
        f"version={version('poo-flow-proof')} "
        f"size={layout.required_size} digest={digest} "
        f"package={package_path}"
    )


if __name__ == "__main__":
    main()
