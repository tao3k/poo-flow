# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""CLI entrypoint for current semantic ABI model acceptance.

Model IO sees task data, actual Scheme source and an output schema. It never
sees a solved answer, semantic tutorial or a retry/repair instruction.
"""
import argparse
from pathlib import Path
import sys

from .semantic_plan import configuration, prepare
from .semantic_execution import execute


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--poo-root', type=Path, required=True)
    parser.add_argument('--ascent-root', type=Path, required=True)
    parser.add_argument('--library', type=Path, required=True)
    parser.add_argument('--env-file', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--live', action='store_true')
    args = parser.parse_args()
    config = configuration(args.env_file)
    model = config.get('DEEPSEEK_MODEL') or config.get('ANTHROPIC_MODEL')
    if not model:
        raise ValueError('the provided configuration must declare its DeepSeek model')
    prepare(args.poo_root.resolve(), args.library.resolve(), args.ascent_root.resolve(), args.output, model)
    if args.live:
        return execute(args.poo_root.resolve(), args.library.resolve(), args.output, config['DEEPSEEK_API_KEY'])
    return 0


if __name__ == '__main__':
    sys.exit(main())
