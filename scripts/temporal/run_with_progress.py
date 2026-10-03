#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Run a gate with a five second output deadline and a bounded total runtime."""
import argparse
import os
import selectors
import signal
import subprocess
import sys
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--timeout", type=float, default=90)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command or args.timeout <= 0:
        parser.error("a command and positive timeout are required")
    child = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             start_new_session=True)
    started = last_output = time.monotonic()
    selector = selectors.DefaultSelector()
    selector.register(child.stdout, selectors.EVENT_READ)
    try:
        while selector.get_map():
            now = time.monotonic()
            if now - started >= args.timeout or now - last_output >= 5:
                print(f"PROGRESS-GATE-FAILED: timeout or five seconds without output; child-status={child.poll()}", file=sys.stderr)
                os.killpg(child.pid, signal.SIGKILL)
                child.wait()
                return 70
            for key, _ in selector.select(min(5 - (now - last_output), args.timeout - (now - started))):
                data = os.read(key.fd, 65536)
                if not data:
                    selector.unregister(key.fileobj)
                else:
                    last_output = time.monotonic()
                    sys.stdout.buffer.write(data)
                    sys.stdout.buffer.flush()
        return child.wait(timeout=max(.01, min(5, args.timeout - (time.monotonic() - started))))
    except BaseException:
        if child.poll() is None:
            os.killpg(child.pid, signal.SIGKILL)
            child.wait()
        raise
    finally:
        selector.close()
        child.stdout.close()


if __name__ == "__main__":
    raise SystemExit(main())
