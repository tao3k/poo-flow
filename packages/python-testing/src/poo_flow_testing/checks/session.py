# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Finite TLC cases for Session lifecycle and WorkTree shared Context."""

from __future__ import annotations

import hashlib
import os
from pathlib import Path
import re
import selectors
import signal
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass

from ..model import CaseContext, CaseEvidence

IDLE_LIMIT_SECONDS = 5
CASE_LIMIT_SECONDS = 45
STATE_COUNT = re.compile(rb"([\d,]+) states generated, ([\d,]+) distinct states")
CASES = (
    ("ContextSession", "none", None),
    ("ContextSession", "ignoreCAS", "NoDoubleCommit"),
    ("ContextSession", "ignoreAuth", "NoUnauthorizedCommit"),
    ("ContextSession", "ignoreCut", "NoMixedCut"),
    ("ContextSession", "resurrect", "NoClosedResume"),
    ("WorktreeContext", "none", None),
    ("WorktreeContext", "ignoreScope", "NoForeignRead"),
    ("WorktreeContext", "ignoreReadAuth", "NoUnauthorizedRead"),
    ("WorktreeContext", "ignoreSourceCut", "NoStaleSourceImport"),
    ("WorktreeContext", "ignoreTargetCut", "NoStaleTargetImport"),
    ("WorktreeContext", "ignoreCAS", "NoDoubleImport"),
    ("WorktreeContext", "ignoreApplicable", "NoInapplicableImport"),
)


@dataclass(frozen=True)
class TlaCase:
    model: str
    mutation: str
    expected_invariant: str | None


def _terminate(child: subprocess.Popen[bytes]) -> None:
    if child.poll() is not None:
        return
    try:
        os.killpg(child.pid, signal.SIGTERM)
    except ProcessLookupError:
        return
    try:
        child.wait(timeout=1)
    except subprocess.TimeoutExpired:
        os.killpg(child.pid, signal.SIGKILL)
        child.wait()


def _run_tlc(command: list[str], cwd: Path) -> tuple[int, bytes, int]:
    """Collect actual TLC bytes, with a strict idle and per-case deadline."""
    child = subprocess.Popen(
        command, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        start_new_session=True, bufsize=0,
    )
    assert child.stdout is not None
    started = last_output = time.monotonic()
    output = bytearray()
    pending = bytearray()
    visible = (b"TLC2 Version", b"Parsing file", b"Starting...",
               b"Finished computing initial states", b"Model checking completed",
               b"Error: Invariant", b"Finished in")
    try:
        with selectors.DefaultSelector() as selector:
            selector.register(child.stdout, selectors.EVENT_READ)
            while selector.get_map() or child.poll() is None:
                for key, _ in selector.select(timeout=0.1):
                    chunk = os.read(key.fileobj.fileno(), 65536)
                    if not chunk:
                        selector.unregister(key.fileobj)
                        continue
                    last_output = time.monotonic()
                    output.extend(chunk)
                    pending.extend(chunk)
                    while b"\n" in pending:
                        line, _, remainder = pending.partition(b"\n")
                        pending = bytearray(remainder)
                        visible_line = (any(token in line for token in visible)
                                        or b" states generated, " in line)
                        if visible_line:
                            sys.stdout.buffer.write(line + b"\n")
                            sys.stdout.buffer.flush()
                now = time.monotonic()
                if now - last_output > IDLE_LIMIT_SECONDS:
                    raise TimeoutError("process produced no bytes for five seconds")
                if now - started > CASE_LIMIT_SECONDS:
                    raise TimeoutError("TLC exceeded the 45-second case limit")
        return child.wait(), bytes(output), round((time.monotonic() - started) * 1000)
    finally:
        _terminate(child)
        child.stdout.close()


def check_tla(context: CaseContext, case: TlaCase) -> CaseEvidence:
    models = context.repository_root / "packages/proofs/tla/session-context"
    model = models / f"{case.model}.tla"
    model_bytes = model.read_bytes()
    template = (models / f"{case.model}.cfg").read_text()
    config = template.replace('Bug = "none"', f'Bug = "{case.mutation}"')
    if case.mutation != "none" and config == template:
        raise AssertionError("TLC mutant was not installed in the configuration")
    with tempfile.TemporaryDirectory(prefix="poo-session-tla-") as directory:
        work = Path(directory)
        (work / model.name).write_bytes(model_bytes)
        config_name = f"{case.model}-{case.mutation}.cfg"
        (work / config_name).write_text(config)
        sys.stdout.buffer.write(f"TLC {case.model} {case.mutation}\n".encode())
        sys.stdout.buffer.flush()
        status, output, duration_ms = _run_tlc(
            ["tlc", "-deadlock", "-workers", "2", "-seed", "1", "-fp", "0",
             "-metadir", str(work / "states"), "-config", config_name, model.name],
            work,
        )
    counts = STATE_COUNT.search(output)
    if counts is None:
        raise AssertionError(
            f"{case.model}/{case.mutation}: TLC omitted state counts; exit={status}; "
            + output.decode(errors="replace")[-1200:])
    if case.expected_invariant is None:
        accepted = (status == 0 and b"TLC2 Version 2.19" in output
                    and b"Model checking completed. No error has been found." in output
                    and b"0 states left on queue" in output)
    else:
        accepted = (status == 12
                    and f"Invariant {case.expected_invariant} is violated.".encode() in output)
    if not accepted:
        raise AssertionError(
            f"{case.model}/{case.mutation}: unexpected TLC exit/invariant; exit={status}; "
            + output.decode(errors="replace")[-1200:])
    return CaseEvidence({
        "model": case.model,
        "model_sha256": hashlib.sha256(model_bytes).hexdigest(),
        "mutation": case.mutation,
        "expected_invariant": case.expected_invariant,
        "config_sha256": hashlib.sha256(config.encode()).hexdigest(),
        "exit": status,
        "generated_states": int(counts[1].replace(b",", b"")),
        "distinct_states": int(counts[2].replace(b",", b"")),
        "duration_ms": duration_ms,
        "idle_limit_seconds": IDLE_LIMIT_SECONDS,
        "case_limit_seconds": CASE_LIMIT_SECONDS,
        "stdout_sha256": hashlib.sha256(output).hexdigest(),
    })


def check_tla_model(context: CaseContext, model: str) -> CaseEvidence:
    """Orchestrate one native TLA model and its declared guard mutations."""
    runs = [dict(check_tla(context, TlaCase(*entry)).details)
            for entry in CASES if entry[0] == model]
    if not runs:
        raise ValueError("unknown Session TLA model: " + model)
    return CaseEvidence({"model": model, "runs": runs})
