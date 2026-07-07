from __future__ import annotations

import os
import shutil
import subprocess
from functools import lru_cache
from pathlib import Path

import pytest


_SCHEME_PAYLOAD_SEPARATOR = b"\n--poo-flow-runtime-envelope--\n"


@lru_cache(maxsize=1)
def _scheme_generated_durable_payloads() -> tuple[bytes, bytes]:
    if shutil.which("gxi") is None:
        pytest.skip("Gerbil gxi is not available")
    repo_root = Path(__file__).resolve().parents[4]
    if not (repo_root / ".gerbil" / "lib").exists():
        pytest.skip("package-local Gerbil build output is not available")

    env = os.environ.copy()
    env["GERBIL_LOADPATH"] = ".gerbil/lib"
    result = subprocess.run(
        [
            "gxi",
            "-e",
            (
                "(begin "
                "(import :poo-flow/src/module-system/durable-policy "
                ":poo-flow/src/module-system/durable-policy-manifest "
                ":poo-flow/src/module-system/durable-runtime-store "
                ":poo-flow/src/module-system/durable-runtime-store-backend "
                ":poo-flow/src/module-system/durable-runtime-manifest) "
                "(define policy "
                "(poo-flow-durable-policy "
                "(quote durable/python-runtime-envelope) "
                "(quote shared))) "
                "(display "
                "(poo-flow-durable-policy-runtime-manifest-string policy)) "
                "(display \"\\n--poo-flow-runtime-envelope--\\n\") "
                "(display "
                "(poo-flow-durable-runtime-manifest-string "
                "policy "
                "poo-flow-durable-runtime-store-contract/default "
                "poo-flow-durable-runtime-store-backend/default)))"
            ),
        ],
        cwd=repo_root,
        env=env,
        check=True,
        capture_output=True,
    )
    policy_manifest, runtime_envelope = result.stdout.split(
        _SCHEME_PAYLOAD_SEPARATOR,
        1,
    )
    return policy_manifest, runtime_envelope


def scheme_durable_policy_manifest_bytes() -> bytes:
    return _scheme_generated_durable_payloads()[0]


def scheme_durable_runtime_envelope_bytes() -> bytes:
    return _scheme_generated_durable_payloads()[1]
