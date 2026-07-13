"""Build the out-of-line CFFI extension and bundle the qualified C runtime."""

from __future__ import annotations

import os
from pathlib import Path
import platform
import shutil

from setuptools import setup
from setuptools.command.build_py import build_py

RUNTIME_LIBRARY_ENV = "POO_FLOW_RUNTIME_V0_LIBRARY"


def _runtime_library() -> Path:
    configured = os.environ.get(RUNTIME_LIBRARY_ENV)
    if not configured:
        raise RuntimeError(
            f"{RUNTIME_LIBRARY_ENV} must name the Bazel-built runtime-v0 "
            "shared library"
        )
    library = Path(configured).expanduser().resolve()
    if not library.is_file():
        raise RuntimeError(f"Bazel runtime-v0 shared library is absent: {library}")
    return library


class BuildPyWithRuntime(build_py):
    def run(self) -> None:
        super().run()
        extension = {"Darwin": "dylib", "Windows": "dll"}.get(
            platform.system(), "so"
        )
        source = _runtime_library()
        target = Path(self.build_lib) / "poo_flow_runtime" / "_native" / "lib"
        target.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target / f"libpoo_flow_runtime_v0.{extension}")


setup(
    cffi_modules=["src/poo_flow_runtime/_native/_build.py:ffibuilder"],
    cmdclass={"build_py": BuildPyWithRuntime},
)
