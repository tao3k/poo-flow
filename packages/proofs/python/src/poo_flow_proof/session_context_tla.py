"""Qualify POO Flow Session and WorkTree scope models with TLC mutants."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import selectors
import signal
import subprocess
import sys
import tempfile
import time


ROOT = Path(__file__).resolve().parents[5]
MODELS = ROOT / "packages/proofs/tla/session-context"
CASES = {
    "ContextSession": [
        ("none", None),
        ("ignoreCAS", "NoDoubleCommit"),
        ("ignoreAuth", "NoUnauthorizedCommit"),
        ("ignoreCut", "NoMixedCut"),
        ("resurrect", "NoClosedResume"),
    ],
    "WorktreeContext": [
        ("none", None),
        ("ignoreScope", "NoForeignRead"),
        ("ignoreReadAuth", "NoUnauthorizedRead"),
        ("ignoreSourceCut", "NoStaleSourceImport"),
        ("ignoreTargetCut", "NoStaleTargetImport"),
        ("ignoreCAS", "NoDoubleImport"),
        ("ignoreApplicable", "NoInapplicableImport"),
    ],
}


def qualify(command: list[str], cwd: Path, log: Path) -> tuple[int, bytes]:
    """Preserve real TLC output; stop after five silent seconds or 45 seconds."""
    child = subprocess.Popen(
        command,
        cwd=cwd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        start_new_session=True,
        bufsize=0,
    )
    assert child.stdout is not None
    started = last_output = time.monotonic()
    output = bytearray()
    pending = bytearray()
    visible = (
        b"TLC2 Version", b"Parsing file", b"Starting...",
        b"Finished computing initial states", b"Model checking completed",
        b"Error: Invariant", b"Finished in",
    )
    try:
        with selectors.DefaultSelector() as selector, log.open("wb") as stream:
            selector.register(child.stdout, selectors.EVENT_READ)
            while selector.get_map() or child.poll() is None:
                for key, _ in selector.select(timeout=0.1):
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        continue
                    last_output = time.monotonic()
                    stream.write(chunk)
                    stream.flush()
                    output.extend(chunk)
                    pending.extend(chunk)
                    while b"\n" in pending:
                        line, _, remainder = pending.partition(b"\n")
                        pending = bytearray(remainder)
                        if line.startswith(visible) or b" states generated, " in line:
                            sys.stdout.buffer.write(line + b"\n")
                            sys.stdout.buffer.flush()
                now = time.monotonic()
                if now - last_output > 5 or now - started > 45:
                    print("TLC-FAIL: five seconds without output or 45s batch limit", flush=True)
                    os.killpg(child.pid, signal.SIGTERM)
                    return 124, bytes(output)
        return child.wait(), bytes(output)
    finally:
        if child.poll() is None:
            os.killpg(child.pid, signal.SIGTERM)
            try:
                child.wait(timeout=1)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait()
        child.stdout.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--tlc", default="tlc")
    args = parser.parse_args()
    receipt = args.receipt.resolve()
    receipt.parent.mkdir(parents=True, exist_ok=True)
    results = []

    with tempfile.TemporaryDirectory(prefix="poo-session-tla-", dir=receipt.parent) as temporary:
        work = Path(temporary)
        for name, cases in CASES.items():
            model = MODELS / f"{name}.tla"
            (work / model.name).write_bytes(model.read_bytes())
            template = (MODELS / f"{name}.cfg").read_text()
            for mutation, invariant in cases:
                config = template.replace('Bug = "none"', f'Bug = "{mutation}"')
                if mutation != "none" and config == template:
                    parser.error(f"{name}: mutation replacement failed")
                config_name = f"{name}-{mutation}.cfg"
                (work / config_name).write_text(config)
                log = receipt.parent / f"{name}-{mutation}.log"
                print(f"SESSION-TLA: {name} {mutation}", flush=True)
                status, output = qualify(
                    [
                        args.tlc, "-deadlock", "-workers", "2", "-seed", "1", "-fp", "0",
                        "-metadir", str(work / f"states-{name}-{mutation}"),
                        "-config", config_name, model.name,
                    ],
                    work,
                    log,
                )
                content = output.decode(errors="replace")
                counts = re.search(r"([\d,]+) states generated, ([\d,]+) distinct states", content)
                if counts is None:
                    print(f"SESSION-TLA-FAIL: no state count for {name} {mutation}", flush=True)
                    return 1
                if invariant is None:
                    accepted = (
                        status == 0
                        and "TLC2 Version 2.19" in content
                        and "Model checking completed. No error has been found." in content
                        and "0 states left on queue" in content
                    )
                else:
                    accepted = status == 12 and f"Invariant {invariant} is violated." in content
                if not accepted:
                    print(f"SESSION-TLA-FAIL: {name} {mutation} exit {status}", flush=True)
                    return 1
                results.append({
                    "model": name,
                    "mutation": mutation,
                    "expected_invariant": invariant,
                    "exit": status,
                    "distinct": int(counts[2].replace(",", "")),
                    "config_sha256": hashlib.sha256(config.encode()).hexdigest(),
                    "log": str(log),
                    "log_sha256": hashlib.sha256(output).hexdigest(),
                })

    receipt.write_text(json.dumps({
        "schema": "poo-flow.session-context-tla.v1",
        "model_sha256": {
            name: hashlib.sha256((MODELS / f"{name}.tla").read_bytes()).hexdigest()
            for name in CASES
        },
        "cases": results,
    }, indent=2) + "\n")
    print(f"SESSION-TLA-OK: {len(results)} normal and mutant cases", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
