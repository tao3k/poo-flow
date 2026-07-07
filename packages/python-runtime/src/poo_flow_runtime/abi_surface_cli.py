"""Command-line ABI surface manifest carrier and validator."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from .abi_surface import (
    RuntimeAbiSurfaceError,
    coerce_runtime_abi_surface_manifest,
    runtime_abi_surface_self_test_receipt,
    runtime_abi_surface_validation_receipt,
    runtime_abi_surface_manifest_bytes,
    runtime_abi_surface_manifest_string,
)


def _read_payload(source: str) -> bytes:
    if source == "-":
        return sys.stdin.buffer.read()
    return Path(source).read_bytes()


def _validation_receipt(status: str, detail: str) -> str:
    return runtime_abi_surface_validation_receipt(status, detail).string()


def _parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Emit or validate the POO Flow Python runtime ABI surface.",
    )
    action = parser.add_mutually_exclusive_group()
    action.add_argument(
        "--validate",
        metavar="PATH",
        help="Validate an ABI surface manifest from PATH, or '-' for stdin.",
    )
    action.add_argument(
        "--self-test",
        action="store_true",
        help="Validate the generated ABI surface manifest and emit a receipt.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    if args.self_test:
        return _self_test()
    if args.validate is None:
        sys.stdout.write(runtime_abi_surface_manifest_string())
        return 0
    try:
        payload = _read_payload(args.validate)
    except OSError as exc:
        sys.stdout.write(_validation_receipt("fail", str(exc)))
        return 1
    return _validate(payload)


def _self_test() -> int:
    receipt = runtime_abi_surface_self_test_receipt()
    sys.stdout.write(receipt.string())
    return 0 if receipt.status == "ok" else 1


def _validate(payload: bytes) -> int:
    try:
        manifest = coerce_runtime_abi_surface_manifest(payload)
    except RuntimeAbiSurfaceError as exc:
        sys.stdout.write(_validation_receipt("fail", str(exc)))
        return 1
    sys.stdout.write(_validation_receipt("ok", manifest.schema))
    return 0


def script_main() -> None:
    raise SystemExit(main())


if __name__ == "__main__":
    script_main()
