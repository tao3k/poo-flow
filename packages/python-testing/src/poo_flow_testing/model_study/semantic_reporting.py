# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Flush actual native and provider progress through the study CLI reporting surface."""
import sys


def report_progress(message: str, *, end: str = '\n') -> None:
    """Publish an actual progress event; callers own what counts as progress."""
    sys.stdout.write(message + end)
    sys.stdout.flush()
