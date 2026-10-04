# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Read project runtime source dependencies enumerated by the AOT compiler."""
from pathlib import Path


def project_sources(root: Path, ascent: Path, manifest: dict) -> dict[str, str]:
    """Supply actual project implementations, retaining platform imports as imports."""
    paths = {'poo-flow/src/ffi/semantic': root / 'src/ffi/semantic.ss'}
    for entry in manifest['modules']:
        name = entry['module']
        if name.startswith('gerbil-ascent/'):
            paths[name] = ascent / (name.removeprefix('gerbil-ascent/') + '.ss')
        elif name.startswith('poo-flow/'):
            paths[name] = root / (name.removeprefix('poo-flow/') + '.ss')
        elif name.startswith('core/'):
            paths[name] = root / (name + '.ss')
    # This imported facade has no runtime body and is absent from the native linker list.
    paths['gerbil-ascent/program/scheme-language'] = ascent / 'program/scheme-language.ss'
    return {name + '.ss': path.read_text() for name, path in paths.items()}
