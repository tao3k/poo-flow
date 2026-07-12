"""Build the out-of-line CFFI extension and bundle the qualified C runtime."""

from __future__ import annotations

from pathlib import Path
import platform
import shutil
import subprocess

from setuptools import setup
from setuptools.command.build_py import build_py

ROOT = Path(__file__).resolve().parents[2]
RUNTIME_C = ROOT / "bindings" / "runtime-c"


class BuildPyWithRuntime(build_py):
    def run(self) -> None:
        subprocess.run(["make", "-C", str(RUNTIME_C), "all"], check=True)
        super().run()
        extension = {"Darwin": "dylib", "Windows": "dll"}.get(
            platform.system(), "so"
        )
        source = RUNTIME_C / "build" / f"libpoo_flow_runtime_v0.{extension}"
        target = Path(self.build_lib) / "poo_flow_runtime" / "_native" / "lib"
        target.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target / source.name)


setup(
    cffi_modules=["src/poo_flow_runtime/_native/_build.py:ffibuilder"],
    cmdclass={"build_py": BuildPyWithRuntime},
)
