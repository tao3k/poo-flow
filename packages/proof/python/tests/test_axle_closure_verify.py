from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

import pytest

from poo_flow_proof import axle_closure_verify, axle_verify
from poo_flow_proof.lean_declaration_closure import (
    LeanDeclarationClosure,
    LeanOwnerSource,
)


def closure() -> LeanDeclarationClosure:
    return LeanDeclarationClosure.from_mapping(
        {
            "base_imports": ["Init"],
            "declarations": [
                {
                    "kind": "theorem",
                    "local_dependencies": [],
                    "name": "Example.safe",
                    "owner_module": "Example.Root",
                    "source_range": {
                        "start_line": 1,
                        "start_column": 0,
                        "start_char_utf16": 0,
                        "end_line": 1,
                        "end_column": 42,
                        "end_char_utf16": 42,
                    },
                }
            ],
            "lean_version": "4.31.0",
            "owner_modules": ["Example.Root"],
            "root_declarations": ["Example.safe"],
            "root_module": "Example.Root",
            "schema_id": "poo-flow.lean-declaration-closure.v1",
        }
    )


def namespace(
    tmp_path: Path,
    *,
    environment: str = "lean-4.31.0",
    paths: list[Path] | None = None,
    closure_output: Path | None = None,
) -> argparse.Namespace:
    return argparse.Namespace(
        base_imports=[],
        closure_output=closure_output,
        environment=environment,
        lean_root=tmp_path,
        paths=[] if paths is None else paths,
        preserve_imports=False,
        root_declarations=["Example.safe"],
        root_module="Example.Root",
    )


def install_preflight_fakes(
    monkeypatch: pytest.MonkeyPatch,
    source: LeanOwnerSource,
) -> None:
    monkeypatch.setattr(
        axle_closure_verify,
        "export_declaration_closure",
        lambda **_: closure(),
    )
    monkeypatch.setattr(
        axle_closure_verify,
        "resolve_owner_sources",
        lambda **_: (source,),
    )


def test_closure_mode_builds_exact_bundle_through_existing_cli(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    capsys: pytest.CaptureFixture[str],
) -> None:
    source_path = tmp_path / "Example" / "Root.lean"
    source_path.parent.mkdir()
    source_path.write_text("theorem Example.safe : True := by trivial\n")
    (tmp_path / "lake-manifest.json").write_text(
        '{"name":"poo-flow-proof","packages":[]}\n'
    )
    source = LeanOwnerSource(
        module="Example.Root",
        path=source_path,
        owner_path="Example/Root.lean",
        source_digest="sha256:" + "a" * 64,
    )
    install_preflight_fakes(monkeypatch, source)
    assert axle_closure_verify.run(namespace(tmp_path)) == 0

    receipts = [
        json.loads(line) for line in capsys.readouterr().out.splitlines()
    ]
    assert receipts[0]["schema_id"] == "poo-flow.axle-closure-preflight.v1"
    assert receipts[0]["root_declarations"] == ["Example.safe"]
    assert (
        receipts[1]["schema_id"]
        == "poo-flow.axle-exact-declaration-closure.v1"
    )
    assert receipts[1]["verification"]["okay"] is True


def test_explicit_source_set_mismatch_fails_closed(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = LeanOwnerSource(
        module="Example.Root",
        path=tmp_path / "Example" / "Root.lean",
        owner_path="Example/Root.lean",
        source_digest="sha256:" + "a" * 64,
    )
    install_preflight_fakes(monkeypatch, source)

    with pytest.raises(
        ValueError,
        match="axle-source-set-mismatch",
    ):
        axle_closure_verify.run(
            namespace(tmp_path, paths=[tmp_path / "Other.lean"])
        )


def test_axle_environment_must_match_lean_version(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source = LeanOwnerSource(
        module="Example.Root",
        path=tmp_path / "Example" / "Root.lean",
        owner_path="Example/Root.lean",
        source_digest="sha256:" + "a" * 64,
    )
    install_preflight_fakes(monkeypatch, source)

    with pytest.raises(
        ValueError,
        match="axle-environment-toolchain-mismatch",
    ):
        axle_closure_verify.run(
            namespace(tmp_path, environment="lean-4.32.0")
        )


def test_closure_artifact_contains_independent_bundle(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    source_path = tmp_path / "Example" / "Root.lean"
    source_path.parent.mkdir()
    source_path.write_text("theorem Example.safe : True := by trivial\n")
    (tmp_path / "lake-manifest.json").write_text(
        '{"name":"poo-flow-proof","packages":[]}\n'
    )
    source = LeanOwnerSource(
        module="Example.Root",
        path=source_path,
        owner_path="Example/Root.lean",
        source_digest="sha256:" + "a" * 64,
    )
    install_preflight_fakes(monkeypatch, source)
    monkeypatch.setattr(
        axle_closure_verify.axle_verify,
        "run",
        lambda _: 0,
    )
    output = tmp_path / "closure.json"

    axle_closure_verify.run(
        namespace(tmp_path, closure_output=output)
    )

    artifact = json.loads(output.read_text())
    assert artifact["closure"]["root_module"] == "Example.Root"
    assert artifact["preflight"]["declaration_count"] == 1
    assert (
        artifact["independent_declaration_bundle"]["schema_id"]
        == "poo-flow.independent-declaration-bundle.v1"
    )
    assert artifact["independent_declaration_bundle_digest"].startswith("sha256:")


def test_existing_main_routes_closure_flags(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    received: list[argparse.Namespace] = []
    monkeypatch.setattr(
        axle_closure_verify,
        "run",
        lambda args: received.append(args) or 0,
    )
    monkeypatch.setattr(
        sys,
        "argv",
        [
            "poo-flow-axle-verify",
            "--lean-root",
            "../lean",
            "--root-module",
            "Example.Root",
            "--root-declaration",
            "Example.safe",
        ],
    )

    with pytest.raises(SystemExit) as exited:
        axle_verify.main()

    assert exited.value.code == 0
    assert received[0].root_module == "Example.Root"
    assert received[0].axle_operation_timeout_seconds == 30.0
    assert received[0].axle_base_timeout_seconds == 10.0


def test_existing_main_preserves_path_mode(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    received: list[argparse.Namespace] = []

    async def fake_run(args: argparse.Namespace) -> int:
        received.append(args)
        return 0

    monkeypatch.setattr(axle_verify, "run", fake_run)
    monkeypatch.setattr(
        sys,
        "argv",
        ["poo-flow-axle-verify", "Proof.lean"],
    )

    with pytest.raises(SystemExit) as exited:
        axle_verify.main()

    assert exited.value.code == 0
    assert received[0].paths == [Path("Proof.lean")]
