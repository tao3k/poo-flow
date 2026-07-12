#!/usr/bin/env python3
"""Generate deterministic runtime v0 C constants and conformance vector."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def render_header(contract: dict[str, object]) -> str:
    capabilities = contract["capabilities"]
    assert isinstance(capabilities, dict)
    lines = [
        "#ifndef POO_FLOW_RUNTIME_V0_CONTRACT_H",
        "#define POO_FLOW_RUNTIME_V0_CONTRACT_H",
        "",
        "#include <stdint.h>",
        "",
        f"#define POO_FLOW_RUNTIME_V0_ABI_MAJOR {contract['abi_major']}u",
        f"#define POO_FLOW_RUNTIME_V0_ABI_MINOR {contract['abi_minor']}u",
        f'#define POO_FLOW_RUNTIME_V0_BUNDLE_SCHEMA "{contract["bundle_schema"]}"',
        f'#define POO_FLOW_RUNTIME_V0_CONTROL_PACKET_SCHEMA "{contract["control_packet_schema"]}"',
    ]
    for name, bit in capabilities.items():
        lines.append(
            f"#define POO_FLOW_RUNTIME_V0_CAP_{name.upper()} "
            f"(UINT64_C(1) << {bit})"
        )
    lines.extend(("", "#endif", ""))
    return "\n".join(lines)


def render_vector(contract: dict[str, object]) -> str:
    capabilities = contract["capabilities"]
    assert isinstance(capabilities, dict)
    lines = [
        "schema=poo-flow.runtime-v0.contract-vector.1",
        f"abi-major={contract['abi_major']}",
        f"abi-minor={contract['abi_minor']}",
        f"bundle-schema={contract['bundle_schema']}",
        f"control-packet-schema={contract['control_packet_schema']}",
        f"abi-v1-frozen={str(contract['abi_v1_frozen']).lower()}",
    ]
    lines.extend(f"capability-{name}={bit}" for name, bit in capabilities.items())
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    contract = json.loads((root / "schema/runtime_v0_contract.json").read_text())
    outputs = {
        root / "include/poo_flow/runtime_v0_contract.h": render_header(contract),
        root / "tests/vectors/runtime_v0_contract.txt": render_vector(contract),
    }
    mismatches = []
    for path, content in outputs.items():
        if args.check:
            if not path.exists() or path.read_text() != content:
                mismatches.append(str(path.relative_to(root)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
    if mismatches:
        raise SystemExit("stale generated runtime v0 artifacts: " + ", ".join(mismatches))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
