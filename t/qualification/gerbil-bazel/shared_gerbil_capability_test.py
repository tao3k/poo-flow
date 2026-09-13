#!/usr/bin/env python3
"""Validate the shared Gerbil toolchain and package receipts as typed JSON."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any

MAX_PACKAGE_PEAK_RSS_BYTES = 5 * 1024 * 1024 * 1024
TOOLCHAIN_SCHEMAS = {
    "gerbil-bazel.local-toolchain-receipt.v1",
    "gerbil-bazel.prebuilt-toolchain-receipt.v1",
}


class ReceiptValidationError(ValueError):
    pass


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ReceiptValidationError(message)


def resolve_runfile(key: str) -> Path:
    candidate = Path(key)
    if candidate.is_absolute():
        return candidate
    runfiles_dir = os.environ.get("RUNFILES_DIR")
    if runfiles_dir:
        return Path(runfiles_dir) / key
    manifest_path = os.environ.get("RUNFILES_MANIFEST_FILE")
    if manifest_path:
        prefix = f"{key} "
        with Path(manifest_path).open(encoding="utf-8") as manifest:
            for line in manifest:
                if line.startswith(prefix):
                    return Path(line[len(prefix) :].rstrip("\n"))
        raise ReceiptValidationError(f"runfile is absent from manifest: {key}")
    raise ReceiptValidationError("Bazel runfiles environment is unavailable")


def load_receipt(key: str) -> tuple[Path, dict[str, Any]]:
    path = resolve_runfile(key)
    _require(path.is_file(), f"shared Gerbil receipt is missing: {path}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ReceiptValidationError(
            f"shared Gerbil receipt is not valid JSON: {path}"
        ) from error
    _require(
        isinstance(value, dict), f"shared Gerbil receipt must be an object: {path}"
    )
    return path, value


def validate_toolchain(receipt: dict[str, Any]) -> None:
    schema = receipt.get("schema")
    _require(
        schema in TOOLCHAIN_SCHEMAS, f"unsupported toolchain receipt schema: {schema!r}"
    )
    _require(
        receipt.get("dependencyPolicy") == "project-package-manifest",
        "toolchain dependencyPolicy must be project-package-manifest",
    )
    dependency_state = receipt.get("dependencyState")
    _require(
        isinstance(dependency_state, dict)
        and bool(dependency_state)
        and all(state in {"ready", "missing"} for state in dependency_state.values()),
        "toolchain dependencyState must be a non-empty ready/missing map",
    )
    if schema == "gerbil-bazel.prebuilt-toolchain-receipt.v1":
        roots = receipt.get("dependencyRoots")
        _require(
            isinstance(roots, list)
            and bool(roots)
            and all(isinstance(root, str) and root for root in roots),
            "prebuilt toolchain dependencyRoots must be a non-empty string list",
        )


def validate_project(receipt: dict[str, Any]) -> None:
    _require(
        receipt.get("schema") == "gerbil-bazel.project-receipt.v1",
        "project receipt schema drift",
    )
    _require(receipt.get("status") == "ok", "project receipt status is not ok")
    resource_guard = receipt.get("resourceGuard")
    _require(
        isinstance(resource_guard, dict), "project receipt resourceGuard is missing"
    )
    _require(
        resource_guard.get("outcome") == "completed",
        "project resource guard did not complete",
    )
    peak_rss = resource_guard.get("peakRssBytes")
    _require(
        isinstance(peak_rss, int)
        and not isinstance(peak_rss, bool)
        and peak_rss < MAX_PACKAGE_PEAK_RSS_BYTES,
        "project peak RSS reached the 5 GiB rejection boundary",
    )
    resolutions = receipt.get("dependencySourceResolutions")
    _require(
        isinstance(resolutions, list) and bool(resolutions),
        "project source resolutions are missing",
    )
    _require(
        all(
            isinstance(resolution, dict)
            and resolution.get("outcome") == "resolved"
            and resolution.get("observedRevision") == resolution.get("expectedRevision")
            for resolution in resolutions
        ),
        "project source resolution is incomplete or revision-drifted",
    )


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(f"usage: {argv[0]} TOOLCHAIN_RECEIPT PROJECT_RECEIPT...", file=sys.stderr)
        return 2
    try:
        _, toolchain = load_receipt(argv[1])
        validate_toolchain(toolchain)
        for key in argv[2:]:
            path, project = load_receipt(key)
            try:
                validate_project(project)
            except ReceiptValidationError as error:
                compact = json.dumps(project, sort_keys=True, separators=(",", ":"))
                raise ReceiptValidationError(
                    f"{path}: {error}; receipt={compact}"
                ) from error
    except ReceiptValidationError as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
