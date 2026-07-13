from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).parents[4]
PACKAGE_ROOT = Path(__file__).parents[1]
VECTOR = REPO_ROOT / "packages/proof/vectors/proof_case_vector_v1_positive.hex"
CONSUMER = Path(__file__).with_name("installed_wheel_consumer.py")


def test_installed_wheel_consumes_public_c_abi(tmp_path: Path) -> None:
    if sys.platform == "win32":
        pytest.skip("runtime-C installed wheel gate currently targets POSIX hosts")
    dist = tmp_path / "dist"
    subprocess.run(
        ["uv", "build", "--wheel", "--out-dir", str(dist)],
        cwd=PACKAGE_ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    wheel = next(dist.glob("poo_flow_proof-*.whl"))

    environment = tmp_path / "venv"
    subprocess.run(
        ["uv", "venv", "--python", sys.executable, str(environment)],
        check=True,
        capture_output=True,
        text=True,
    )
    python = environment / ("Scripts/python.exe" if os.name == "nt" else "bin/python")
    subprocess.run(
        ["uv", "pip", "install", "--python", str(python), str(wheel)],
        check=True,
        capture_output=True,
        text=True,
    )

    library = tmp_path / (
        "poo_flow_proof.dll"
        if sys.platform == "win32"
        else "libpoo_flow_proof.dylib"
        if sys.platform == "darwin"
        else "libpoo_flow_proof.so"
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
            str(library),
        ],
        check=True,
    )

    consumer_env = os.environ.copy()
    consumer_env.pop("PYTHONPATH", None)
    completed = subprocess.run(
        [
            str(python),
            str(CONSUMER),
            "--library",
            str(library),
            "--vector",
            str(VECTOR),
            "--forbid-root",
            str(REPO_ROOT),
        ],
        cwd=tmp_path,
        env=consumer_env,
        check=True,
        capture_output=True,
        text=True,
    )

    assert "installed-wheel-consumer: version=0.1.0 size=424" in completed.stdout
    assert "digest=970eaffbfaae38970e2107b89fa11258c6211a5c293a1e400a464527b7a0e44a" in (
        completed.stdout
    )
    assert "site-packages" in completed.stdout
