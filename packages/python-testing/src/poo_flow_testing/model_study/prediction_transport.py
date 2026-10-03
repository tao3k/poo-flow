# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Extract inert predictions without semantic repair or consulting an oracle.

This transport was added after the frozen direct study began. Replays using it
are supplementary observations, never replacements for the original scores.
"""
import re
from .direct.tasks import DIRECT_DATA_ALPHABET


def prediction_from_output(output):
    if len(output.encode()) > 65536:
        return None
    text = output.strip()
    if text.startswith(('(', "'(")) and DIRECT_DATA_ALPHABET.fullmatch(text):
        depth = 0
        for index, char in enumerate(text):
            depth += (char == '(') - (char == ')')
            if depth < 0 or depth > 64:
                break
            if char == ')' and depth == 0:
                if not text[index+1:].strip() and len(text.encode()) <= 8192:
                    return text
                break
    assertions = []
    for match in re.finditer(r'\(check-equal\?\s+result\s+', text):
        depth = 0
        for index in range(match.start(), len(text)):
            depth += (text[index] == '(') - (text[index] == ')')
            if depth > 64:
                break
            if depth == 0:
                candidate = text[match.start():index+1]
                if DIRECT_DATA_ALPHABET.fullmatch(candidate):
                    assertions.append(candidate)
                break
    if not assertions:
        assertions = [value.strip() for value in
                      re.findall(r'```(?:scheme|gerbil)?\s*\n(.*?)\n```', text, re.S)
                      if value.strip() and DIRECT_DATA_ALPHABET.fullmatch(value.strip())]
    # Equal token sequences are duplicate renderings. Different predictions
    # are ambiguous; never choose the one that matches the private answer.
    unique = {tuple(re.findall(r"[A-Za-z0-9_?+\-]+|[()']", value)): value
              for value in assertions}
    if len(unique) != 1:
        return None
    candidate = next(iter(unique.values()))
    return candidate if len(candidate.encode()) <= 8192 else None
