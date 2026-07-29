from __future__ import annotations

import argparse
import asyncio
import json
from importlib.metadata import version
from pathlib import Path
from typing import Any


def independent_source(source: str) -> str:
    """Project-local imports are checked by Lean; AXLE checks declarations independently."""
    body = [
        line
        for line in source.splitlines()
        if line != "import Mathlib" and not line.startswith("import PooFlowProof.")
    ]
    return "import Mathlib\n" + "\n".join(body) + "\n"


def message_payload(messages: object) -> dict[str, list[Any]]:
    return {
        "errors": list(getattr(messages, "errors", [])),
        "warnings": list(getattr(messages, "warnings", [])),
        "infos": list(getattr(messages, "infos", [])),
    }


async def verify_one(
    client: Any,
    path: Path,
    environment: str,
    preserve_imports: bool,
) -> dict[str, Any]:
    original = path.read_text()
    content = original if preserve_imports else independent_source(original)
    statement = await client.theorem2sorry(
        content,
        environment,
        ignore_imports=not preserve_imports,
        timeout_seconds=120,
    )
    statement_messages = {
        "lean": message_payload(statement.lean_messages),
        "tool": message_payload(statement.tool_messages),
    }
    if statement_messages["lean"]["errors"] or statement_messages["tool"]["errors"]:
        return {
            "path": str(path),
            "mode": "preserved-imports" if preserve_imports else "independent",
            "theorem2sorry": {
                "request": statement.info,
                "messages": statement_messages,
            },
            "verify": None,
        }

    verified = await client.verify_proof(
        statement.content,
        content,
        environment,
        ignore_imports=not preserve_imports,
        timeout_seconds=120,
    )
    return {
        "path": str(path),
        "mode": "preserved-imports" if preserve_imports else "independent",
        "theorem2sorry": {
            "request": statement.info,
            "messages": statement_messages,
        },
        "verify": {
            "okay": verified.okay,
            "failed_declarations": verified.failed_declarations,
            "lean_messages": message_payload(verified.lean_messages),
            "tool_messages": message_payload(verified.tool_messages),
            "timings": verified.timings,
            "request": verified.info,
        },
    }


def receipt_succeeded(receipt: dict[str, Any]) -> bool:
    verification = receipt["verify"]
    return verification is not None and bool(verification["okay"])


async def run(args: argparse.Namespace) -> int:
    from axle import AxleClient

    async with AxleClient(max_concurrency=len(args.paths)) as client:
        receipts = await asyncio.gather(
            *(
                verify_one(client, path, args.environment, args.preserve_imports)
                for path in args.paths
            )
        )
    output = {
        "axle_sdk": {
            "distribution": "axiom-axle",
            "version": version("axiom-axle"),
        },
        "environment": args.environment,
        "mode": "preserved-imports" if args.preserve_imports else "independent",
        "receipts": receipts,
    }
    print(json.dumps(output, indent=2, default=str))
    return 0 if all(receipt_succeeded(receipt) for receipt in receipts) else 1


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Verify Lean declarations through the UV-managed AXLE client."
    )
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--environment", default="lean-4.31.0")
    parser.add_argument("--preserve-imports", action="store_true")
    raise SystemExit(asyncio.run(run(parser.parse_args())))


if __name__ == "__main__":
    main()
