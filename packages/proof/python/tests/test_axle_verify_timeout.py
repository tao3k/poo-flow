from __future__ import annotations

import asyncio
import json
import sys

import pytest

from poo_flow_proof import axle_verify


def test_cli_bounds_the_complete_axle_operation(
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
) -> None:
    async def never_returns(_args: object) -> int:
        await asyncio.sleep(60)
        return 0

    monkeypatch.setattr(axle_verify, "run", never_returns)
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "axle_verify.py",
            "--axle-operation-timeout-seconds",
            "0.01",
            "--axle-base-timeout-seconds",
            "0",
            "independent-bundle.lean",
        ],
    )

    with pytest.raises(SystemExit) as raised:
        axle_verify.main()

    assert raised.value.code == 1
    receipt = json.loads(capsys.readouterr().err)
    assert receipt == {
        "base_timeout_seconds": 0.0,
        "code": "axle-operation-deadline-exceeded",
        "operation_timeout_seconds": 0.01,
        "schema_id": "poo-flow.axle-verification.v1",
        "status": "rejected",
    }
