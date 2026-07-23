"""Shared construction of Gerbil process environments."""

from __future__ import annotations

import os
from collections.abc import Mapping, Sequence
from pathlib import Path


def build_gerbil_environment(
    *,
    gerbil_path: Path,
    dependency_root: Path,
    project_dependency_roots: Sequence[Path],
    gxi: Path | None = None,
    inherited: Mapping[str, str] | None = None,
) -> dict[str, str]:
    """Return the canonical environment for one compiled Gerbil project."""
    environment = dict(os.environ if inherited is None else inherited)
    loadpath = (
        gerbil_path / "lib",
        *(root / ".gerbil" / "lib" for root in project_dependency_roots),
        dependency_root,
    )
    environment["GERBIL_PATH"] = str(gerbil_path)
    environment["GERBIL_LOADPATH"] = os.pathsep.join(map(str, loadpath))
    if gxi is not None:
        environment["PATH"] = os.pathsep.join(
            (str(gxi.parent), environment.get("PATH", ""))
        )
    return environment


__all__ = ["build_gerbil_environment"]
