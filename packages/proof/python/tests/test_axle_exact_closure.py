from __future__ import annotations

import asyncio
from dataclasses import dataclass, field
from pathlib import Path
from types import SimpleNamespace

import pytest

from poo_flow_proof import axle_exact_closure
from poo_flow_proof.axle_exact_closure import (
    AxleExactClosureError,
    ExactAxleClosure,
    SourceDeclaration,
    build_exact_axle_closure,
    source_declaration_closure,
)
from poo_flow_proof.lean_declaration_closure import (
    LeanDeclarationClosure,
    LeanOwnerSource,
)


@dataclass
class FakeDocument:
    name: str
    local_type_dependencies: list[str] = field(default_factory=list)
    local_value_dependencies: list[str] = field(default_factory=list)
    local_syntactic_dependencies: list[str] = field(default_factory=list)


def documents(*values: FakeDocument) -> dict[str, FakeDocument]:
    return {value.name: value for value in values}


def test_generated_lean_constants_collapse_to_source_declaration() -> None:
    result = source_declaration_closure(
        lean_declarations=(
            "Example.Policy",
            "Example.Policy.mk",
            "Example.Policy.authority",
            "Example.admit",
        ),
        root_declarations=("Example.admit",),
        documents=documents(
            FakeDocument("Example.Policy"),
            FakeDocument(
                "Example.admit",
                local_type_dependencies=["Example.Policy"],
                local_value_dependencies=["Example.Policy.authority"],
            ),
        ),
    )

    assert result == ("Example.Policy", "Example.admit")


def test_inaccessible_generated_instance_normalizes_to_source_owner() -> None:
    assert axle_exact_closure._normalized_source_declaration_name(
        "«_Example.instDecidableEqThing»",
        {"Example.Thing": "Example.Thing"},
    ) == "Example.Thing"


def test_source_range_aliases_collapse_generated_document_cycle() -> None:
    result = source_declaration_closure(
        lean_declarations=("Example.Policy", "Example.Policy.mk"),
        root_declarations=("Example.Policy",),
        documents=documents(
            FakeDocument(
                "Example.Policy",
                local_value_dependencies=[
                    "Example.Policy.mk",
                    "Example.instReprPolicy",
                ],
                local_syntactic_dependencies=[
                    "Example.Policy.unlistedGeneratedField"
                ],
            ),
            FakeDocument(
                "Example.Policy.mk",
                local_type_dependencies=["Example.Policy"],
            ),
            FakeDocument(
                "Example.instReprPolicy",
                local_type_dependencies=["Example.Policy"],
            ),
        ),
        declaration_aliases={
            "Example.Policy": "Example.Policy",
            "Example.Policy.mk": "Example.Policy",
        },
    )

    assert result == ("Example.Policy",)


def test_axle_local_dependencies_extend_the_lean_seed_to_a_fixed_point() -> None:
    result = source_declaration_closure(
        lean_declarations=("Example.root",),
        root_declarations=("Example.root",),
        documents=documents(
            FakeDocument("Example.base"),
            FakeDocument(
                "Example.middle",
                local_syntactic_dependencies=["Example.base"],
            ),
            FakeDocument(
                "Example.root",
                local_value_dependencies=["Example.middle"],
            ),
        ),
    )

    assert result == ("Example.base", "Example.middle", "Example.root")


def test_unmapped_local_dependency_fails_closed() -> None:
    with pytest.raises(
        AxleExactClosureError,
        match="local-dependency-without-source-declaration",
    ):
        source_declaration_closure(
            lean_declarations=("Example.root",),
            root_declarations=("Example.root",),
            documents=documents(
                FakeDocument(
                    "Example.root",
                    local_value_dependencies=["Example.missing"],
                )
            ),
        )


def test_source_declaration_cycle_fails_closed() -> None:
    with pytest.raises(AxleExactClosureError, match="source-declaration-cycle"):
        source_declaration_closure(
            lean_declarations=("Example.left", "Example.right"),
            root_declarations=("Example.left",),
            documents=documents(
                FakeDocument(
                    "Example.left",
                    local_value_dependencies=["Example.right"],
                ),
                FakeDocument(
                    "Example.right",
                    local_value_dependencies=["Example.left"],
                ),
            ),
        )


def test_bundle_identity_excludes_runtime_verification_receipts() -> None:
    declaration = SourceDeclaration(
        name="Example.safe",
        kind="theorem",
        declaration="theorem safe : True := by trivial",
        local_dependencies=(),
    )
    shared = {
        "lean_closure_digest": "sha256:" + "a" * 64,
        "environment": "lean-4.31.0",
        "root_declarations": ("Example.safe",),
        "source_declarations": ("Example.safe",),
        "declarations": (declaration,),
        "canonical_source": "theorem Example.safe : True := by trivial\n",
    }

    first = ExactAxleClosure(
        **shared,
        theorem2sorry={"request": {"id": "first"}},
        verification={"okay": True, "timings": {"total": 1}},
    )
    second = ExactAxleClosure(
        **shared,
        theorem2sorry={"request": {"id": "second"}},
        verification={"okay": True, "timings": {"total": 999}},
    )

    assert first.bundle_digest == second.bundle_digest
    assert first.canonical_manifest() != second.canonical_manifest()


def test_exact_closure_parallelizes_independent_axle_phases_and_emits_receipts(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    closure = LeanDeclarationClosure.from_mapping(
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
    source_path = tmp_path / "Example" / "Root.lean"
    source_path.parent.mkdir()
    source_path.write_text("theorem Example.safe : True := by trivial\n")
    source = LeanOwnerSource(
        module="Example.Root",
        path=source_path,
        owner_path="Example/Root.lean",
        source_digest="sha256:" + "a" * 64,
    )
    document = SimpleNamespace(
        name="Example.safe",
        kind="theorem",
        declaration="theorem Example.safe : True := by trivial",
        local_type_dependencies=[],
        local_value_dependencies=[],
        local_syntactic_dependencies=[],
    )
    messages = SimpleNamespace(errors=[])
    extraction = SimpleNamespace(
        documents={"Example.safe": document},
        lean_messages=messages,
        tool_messages=messages,
    )

    class FakeAxleClient:
        def __init__(self) -> None:
            self.extract_calls = 0
            self.roundtrip_started = asyncio.Event()
            self.theorem_started = asyncio.Event()
            self.timeouts: list[float] = []

        async def extract_decls(
            self,
            _content: str,
            _environment: str,
            *,
            ignore_imports: bool,
            timeout_seconds: float,
        ) -> object:
            assert ignore_imports is False
            self.timeouts.append(timeout_seconds)
            self.extract_calls += 1
            if self.extract_calls == 1:
                return extraction
            self.roundtrip_started.set()
            await asyncio.wait_for(self.theorem_started.wait(), timeout=0.25)
            return extraction

        async def theorem2sorry(
            self,
            _content: str,
            _environment: str,
            *,
            names: list[str],
            ignore_imports: bool,
            timeout_seconds: float,
        ) -> object:
            assert names == ["Example.safe"]
            assert ignore_imports is False
            self.timeouts.append(timeout_seconds)
            self.theorem_started.set()
            await asyncio.wait_for(self.roundtrip_started.wait(), timeout=0.25)
            return SimpleNamespace(
                content="theorem Example.safe : True := by sorry",
                info={"operation": "theorem2sorry"},
                lean_messages=messages,
                tool_messages=messages,
            )

        async def verify_proof(
            self,
            _statement: str,
            _content: str,
            _environment: str,
            *,
            ignore_imports: bool,
            timeout_seconds: float,
        ) -> object:
            assert ignore_imports is False
            self.timeouts.append(timeout_seconds)
            return SimpleNamespace(
                okay=True,
                failed_declarations=[],
                lean_messages=messages,
                tool_messages=messages,
                timings={"total": 1},
                info={"operation": "verify_proof"},
            )

    fake_client = FakeAxleClient()
    receipts: list[dict[str, object]] = []
    monkeypatch.setattr(
        axle_exact_closure,
        "_compose_owner_sources",
        lambda _closure, _sources: "theorem Example.safe : True := by trivial\n",
    )
    monkeypatch.setattr(
        axle_exact_closure,
        "_compose_source_declarations",
        lambda _names, _documents, _base_imports: (
            "theorem Example.safe : True := by trivial\n"
        ),
    )

    exact = asyncio.run(
        build_exact_axle_closure(
            closure=closure,
            sources=(source,),
            environment="lean-4.31.0",
            client=fake_client,  # type: ignore[arg-type]
            operation_timeout_seconds=7,
            base_timeout_seconds=2,
            phase_observer=lambda receipt: receipts.append(dict(receipt)),
        )
    )

    assert exact.verification["okay"] is True
    assert fake_client.timeouts == [7, 7, 7, 7]
    states_by_phase = {
        phase: [
            receipt["state"]
            for receipt in receipts
            if receipt["phase"] == phase
        ]
        for phase in {
            "owner-source-extract",
            "canonical-roundtrip-extract",
            "root-theorem2sorry",
            "root-proof-verify",
        }
    }
    assert states_by_phase == {
        "owner-source-extract": ["started", "completed"],
        "canonical-roundtrip-extract": ["started", "completed"],
        "root-theorem2sorry": ["started", "completed"],
        "root-proof-verify": ["started", "completed"],
    }


def test_owner_source_envelope_uses_declared_base_imports(
    tmp_path: Path,
) -> None:
    source_path = tmp_path / "Example" / "Root.lean"
    source_path.parent.mkdir()
    source_path.write_text("theorem Example.safe : True := by trivial\n")
    closure = LeanDeclarationClosure.from_mapping(
        {
            "base_imports": ["Init", "Batteries.Data.List.Perm"],
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
    source = LeanOwnerSource(
        module="Example.Root",
        path=source_path,
        owner_path="Example/Root.lean",
        source_digest="sha256:" + "a" * 64,
    )

    envelope = axle_exact_closure._compose_owner_sources(closure, (source,))

    assert envelope.startswith(
        "import Init\nimport Batteries.Data.List.Perm\n\n"
    )
    assert "import Mathlib" not in envelope
    assert "theorem Example.safe : True := by trivial" in envelope
