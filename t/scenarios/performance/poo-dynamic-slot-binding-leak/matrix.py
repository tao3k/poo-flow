#!/usr/bin/env python3
"""Bounded diagnostic matrix for the Gerbil POO dynamic slot leak.

This runner is intentionally opt-in. Use --list to inspect the matrix and
--run to execute each case in a child process with resource limits.
"""

from __future__ import annotations

import argparse
import json
import os
import resource
import signal
import subprocess
import sys
import time
from dataclasses import dataclass


MB = 1024 * 1024


@dataclass(frozen=True)
class Case:
    name: str
    expression: str
    expect: str


CASES = [
    Case(
        "literal-slot",
        """
(begin
  (import (only-in :clan/poo/object .o .ref))
  (def obj
    (.o (kind (quote poo-performance-prototype-composition-cache))
        (family (quote poo-performance-prototype-composition-cache-family))
        (descriptor-count 12)
        (key-span 4)
        (first-value 4)
        (last-value 15)
        (descriptor-checksum 0)))
  (write (.ref obj (quote descriptor-count)))
  (newline)
  (exit 0))
""",
        "pass",
    ),
    Case(
        "dynamic-same-name",
        """
(begin
  (import (only-in :clan/poo/object .o .ref))
  (def descriptor-count 12)
  (def key-span 4)
  (def last-value (+ key-span (- descriptor-count 1)))
  (def obj
    (.o (kind (quote poo-performance-prototype-composition-cache))
        (family (quote poo-performance-prototype-composition-cache-family))
        (descriptor-count descriptor-count)
        (key-span key-span)
        (first-value key-span)
        (last-value last-value)
        (descriptor-checksum 0)))
  (write (.ref obj (quote family)))
  (newline)
  (write (.ref obj (quote descriptor-count)))
  (newline)
  (exit 0))
""",
        "leak-or-timeout",
    ),
    Case(
        "dynamic-renamed",
        """
(begin
  (import (only-in :clan/poo/object .o .ref))
  (def count-value 12)
  (def span-value 4)
  (def last-scalar (+ span-value (- count-value 1)))
  (def obj
    (.o (kind (quote poo-performance-prototype-composition-cache))
        (family (quote poo-performance-prototype-composition-cache-family))
        (descriptor-count count-value)
        (key-span span-value)
        (first-value span-value)
        (last-value last-scalar)
        (descriptor-checksum 0)))
  (write (.ref obj (quote descriptor-count)))
  (newline)
  (exit 0))
""",
        "classify",
    ),
    Case(
        "dynamic-family-only",
        """
(begin
  (import (only-in :clan/poo/object .o .ref))
  (def descriptor-count 12)
  (def key-span 4)
  (def obj
    (.o (kind (quote poo-performance-prototype-composition-cache))
        (family (quote poo-performance-prototype-composition-cache-family))
        (descriptor-count descriptor-count)
        (key-span key-span)))
  (write (.ref obj (quote family)))
  (newline)
  (exit 0))
""",
        "classify",
    ),
    Case(
        "alist-control",
        """
(begin
  (def obj
    (quote ((family . poo-performance-prototype-composition-cache-family)
            (descriptor-count . 12))))
  (write (cdr (assoc (quote descriptor-count) obj)))
  (newline)
  (exit 0))
""",
        "pass",
    ),
]


def limit_child(memory_mb: int, cpu_seconds: int) -> None:
    os.setsid()
    soft_memory = memory_mb * MB
    for limit_name in ("RLIMIT_AS", "RLIMIT_DATA"):
        limit = getattr(resource, limit_name, None)
        if limit is not None:
            try:
                resource.setrlimit(limit, (soft_memory, soft_memory))
            except (OSError, ValueError):
                pass
    try:
        resource.setrlimit(resource.RLIMIT_CPU, (cpu_seconds, cpu_seconds + 1))
    except (OSError, ValueError):
        pass


def run_case(case: Case, timeout: float, memory_mb: int, cpu_seconds: int) -> dict:
    start = time.monotonic()
    command = ["gxpkg", "env", "gxi", "-e", case.expression]
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        preexec_fn=lambda: limit_child(memory_mb, cpu_seconds),
    )
    timed_out = False
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        stdout, stderr = process.communicate()
    elapsed_ms = round((time.monotonic() - start) * 1000, 3)
    return {
        "name": case.name,
        "expect": case.expect,
        "status": "timeout" if timed_out else "exit",
        "returncode": process.returncode,
        "elapsedMs": elapsed_ms,
        "stdout": stdout.strip(),
        "stderrTail": stderr.strip()[-600:],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--run", action="store_true")
    parser.add_argument("--case", choices=[case.name for case in CASES])
    parser.add_argument("--timeout", type=float, default=3.0)
    parser.add_argument("--memory-mb", type=int, default=256)
    parser.add_argument("--cpu-seconds", type=int, default=2)
    args = parser.parse_args()

    if args.list or not args.run:
        for case in CASES:
            print(json.dumps({"name": case.name, "expect": case.expect}))
        return 0

    failed = False
    selected_cases = [case for case in CASES if args.case in (None, case.name)]
    for case in selected_cases:
        result = run_case(case, args.timeout, args.memory_mb, args.cpu_seconds)
        print(json.dumps(result, sort_keys=True))
        if case.expect == "pass" and result["returncode"] != 0:
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
