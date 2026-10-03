# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
#
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

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
    env.setdefault("GERBIL_LOADPATH", str(repo_root / ".gerbil" / "lib"))
    from poo_flow_runtime._scheme_load_runner import scheme_string

    preload = repo_root / "packages/python-runtime/src/poo_flow_runtime/projections/runtime-preload.ss"
    modules = ("policy", "policy-manifest", "store", "store-backend", "runtime-manifest")
    progress = "(load " + scheme_string(str(preload)) + ") (parameterize ((current-output-port (current-error-port))) " + " ".join(
        '(runtime-preload-module! "poo-flow/modules/memory-core/durable/' + module + '")' for module in modules
    ) + ' (runtime-preload-module! "poo-flow/scripts/temporal/exit-child-process"))'
    result = subprocess.run(
        [
            "gxi",
            "-e",
            progress,
            "-e",
            (
                "(begin "
                "(import :poo-flow/scripts/temporal/exit-child-process "
                ":poo-flow/modules/memory-core/durable/policy "
                ":poo-flow/modules/memory-core/durable/policy-manifest "
                ":poo-flow/modules/memory-core/durable/store "
                ":poo-flow/modules/memory-core/durable/store-backend "
                ":poo-flow/modules/memory-core/durable/runtime-manifest) "
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
                "poo-flow-durable-runtime-store-backend/default)) "
                "(temporal-child-process-exit! 0))"
            ),
        ],
        cwd=repo_root,
        env=env,
        check=True,
        stdout=subprocess.PIPE,
        stderr=None if env.get("POO_FLOW_SCHEME_LOAD_PROGRESS") == "1" else subprocess.PIPE,
        timeout=90,
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
