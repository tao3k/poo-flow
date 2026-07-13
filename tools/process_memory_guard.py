#!/usr/bin/env python3
"""Run a command with observable RSS and elapsed-time fail-closed guards."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

RSS_LIMIT_EXIT = 70
TIMEOUT_EXIT = 71


def process_tree_rss_bytes(root_pid: int) -> int:
    completed = subprocess.run(
        ["ps", "-axo", "pid=,ppid=,rss="],
        check=True,
        capture_output=True,
        text=True,
    )
    rows: dict[int, tuple[int, int]] = {}
    for line in completed.stdout.splitlines():
        fields = line.split()
        if len(fields) == 3:
            pid, ppid, rss_kib = map(int, fields)
            rows[pid] = (ppid, rss_kib * 1024)
    descendants = {root_pid}
    changed = True
    while changed:
        changed = False
        for pid, (ppid, _rss) in rows.items():
            if ppid in descendants and pid not in descendants:
                descendants.add(pid)
                changed = True
    return sum(rows.get(pid, (0, 0))[1] for pid in descendants)


def terminate_group(process: subprocess.Popen[bytes]) -> None:
    if process.poll() is not None:
        return
    os.killpg(process.pid, signal.SIGTERM)
    try:
        process.wait(timeout=0.5)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()


def write_receipt(path: Path | None, receipt: dict[str, object]) -> None:
    payload = json.dumps(receipt, sort_keys=True, separators=(",", ":"))
    print(f"[process-memory-guard] {payload}", file=sys.stderr, flush=True)
    if path is not None:
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix(path.suffix + ".tmp")
        temporary.write_text(payload + "\n", encoding="utf-8")
        temporary.replace(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--label", required=True)
    parser.add_argument("--max-rss-mib", required=True, type=int)
    parser.add_argument("--timeout-seconds", required=True, type=float)
    parser.add_argument("--sample-ms", type=int, default=100)
    parser.add_argument("--receipt", type=Path)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command or args.max_rss_mib <= 0 or args.timeout_seconds <= 0:
        parser.error("positive limits and a command are required")

    started = time.monotonic()
    process = subprocess.Popen(command, start_new_session=True)
    peak_rss = 0
    outcome = "running"
    exit_code = 0
    limit_bytes = args.max_rss_mib * 1024 * 1024
    while process.poll() is None:
        try:
            peak_rss = max(peak_rss, process_tree_rss_bytes(process.pid))
        except subprocess.CalledProcessError:
            pass
        elapsed = time.monotonic() - started
        if peak_rss > limit_bytes:
            outcome, exit_code = "rss-limit-exceeded", RSS_LIMIT_EXIT
            terminate_group(process)
            break
        if elapsed > args.timeout_seconds:
            outcome, exit_code = "timeout", TIMEOUT_EXIT
            terminate_group(process)
            break
        time.sleep(args.sample_ms / 1000)
    if outcome == "running":
        outcome = "completed"
        exit_code = int(process.returncode or 0)
    elapsed_ms = round((time.monotonic() - started) * 1000)
    write_receipt(
        args.receipt,
        {
            "schema": "poo-flow.process-memory-guard.v1",
            "label": args.label,
            "outcome": outcome,
            "exitCode": exit_code,
            "commandExitCode": process.returncode,
            "peakRssBytes": peak_rss,
            "maxRssBytes": limit_bytes,
            "elapsedMs": elapsed_ms,
            "timeoutMs": round(args.timeout_seconds * 1000),
        },
    )
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
