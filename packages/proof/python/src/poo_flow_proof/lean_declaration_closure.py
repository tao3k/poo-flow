from __future__ import annotations

from dataclasses import dataclass
from hashlib import sha256
import json
import os
from pathlib import Path
import subprocess
from typing import Callable, Mapping, Sequence


SCHEMA_ID = "poo-flow.lean-declaration-closure.v1"


class LeanClosureError(ValueError):
    def __init__(self, code: str, detail: str) -> None:
        super().__init__(f"{code}: {detail}")
        self.code = code
        self.detail = detail


def _require_string(value: object, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise LeanClosureError("invalid-field", field)
    return value


def _require_string_tuple(value: object, field: str) -> tuple[str, ...]:
    if not isinstance(value, list) or any(
        not isinstance(item, str) or not item for item in value
    ):
        raise LeanClosureError("invalid-field", field)
    return tuple(value)


@dataclass(frozen=True)
class LeanSourceRange:
    start_line: int
    start_column: int
    start_char_utf16: int
    end_line: int
    end_column: int
    end_char_utf16: int

    @classmethod
    def from_mapping(cls, value: object) -> LeanSourceRange:
        if not isinstance(value, Mapping):
            raise LeanClosureError(
                "invalid-source-range",
                "expected object",
            )
        fields = (
            "start_line",
            "start_column",
            "start_char_utf16",
            "end_line",
            "end_column",
            "end_char_utf16",
        )
        parsed: dict[str, int] = {}
        for field in fields:
            item = value.get(field)
            if not isinstance(item, int) or item < 0:
                raise LeanClosureError("invalid-source-range", field)
            parsed[field] = item
        if parsed["start_line"] == 0 or parsed["end_line"] == 0:
            raise LeanClosureError("invalid-source-range", "line numbers are 1-based")
        if (
            parsed["end_line"],
            parsed["end_char_utf16"],
        ) < (
            parsed["start_line"],
            parsed["start_char_utf16"],
        ):
            raise LeanClosureError("invalid-source-range", "end precedes start")
        return cls(**parsed)

    def canonical_record(self) -> dict[str, int]:
        return {
            "start_line": self.start_line,
            "start_column": self.start_column,
            "start_char_utf16": self.start_char_utf16,
            "end_line": self.end_line,
            "end_column": self.end_column,
            "end_char_utf16": self.end_char_utf16,
        }


@dataclass(frozen=True)
class LeanDeclaration:
    name: str
    kind: str
    owner_module: str
    local_dependencies: tuple[str, ...]
    source_range: LeanSourceRange | None = None

    @classmethod
    def from_mapping(cls, value: object) -> LeanDeclaration:
        if not isinstance(value, Mapping):
            raise LeanClosureError("invalid-declaration", "expected object")
        return cls(
            name=_require_string(value.get("name"), "declaration.name"),
            kind=_require_string(value.get("kind"), "declaration.kind"),
            owner_module=_require_string(
                value.get("owner_module"), "declaration.owner_module"
            ),
            local_dependencies=_require_string_tuple(
                value.get("local_dependencies"),
                "declaration.local_dependencies",
            ),
            source_range=(
                LeanSourceRange.from_mapping(source_range)
                if (source_range := value.get("source_range")) is not None
                else None
            ),
        )

    def canonical_record(self) -> dict[str, object]:
        record: dict[str, object] = {
            "kind": self.kind,
            "local_dependencies": list(self.local_dependencies),
            "name": self.name,
            "owner_module": self.owner_module,
        }
        if self.source_range is not None:
            record["source_range"] = self.source_range.canonical_record()
        return record


@dataclass(frozen=True)
class LeanDeclarationClosure:
    lean_version: str
    root_module: str
    root_declarations: tuple[str, ...]
    base_imports: tuple[str, ...]
    owner_modules: tuple[str, ...]
    declarations: tuple[LeanDeclaration, ...]
    schema_id: str = SCHEMA_ID

    def __post_init__(self) -> None:
        if self.schema_id != SCHEMA_ID:
            raise LeanClosureError("unsupported-schema", self.schema_id)
        for field, value in (
            ("lean_version", self.lean_version),
            ("root_module", self.root_module),
        ):
            _require_string(value, field)
        if not self.root_declarations:
            raise LeanClosureError("missing-root-declaration", self.root_module)
        if len(set(self.root_declarations)) != len(self.root_declarations):
            raise LeanClosureError("duplicate-root-declaration", self.root_module)
        if not self.base_imports:
            raise LeanClosureError("missing-base-import", self.root_module)
        if tuple(sorted(set(self.owner_modules))) != self.owner_modules:
            raise LeanClosureError("non-canonical-owner-modules", self.root_module)

        emitted: set[str] = set()
        owners: set[str] = set()
        for declaration in self.declarations:
            if declaration.name in emitted:
                raise LeanClosureError(
                    "duplicate-declaration",
                    declaration.name,
                )
            missing = [
                dependency
                for dependency in declaration.local_dependencies
                if dependency not in emitted
            ]
            if missing:
                raise LeanClosureError(
                    "non-topological-declaration",
                    f"{declaration.name}: {','.join(missing)}",
                )
            emitted.add(declaration.name)
            owners.add(declaration.owner_module)

        missing_roots = [
            declaration
            for declaration in self.root_declarations
            if declaration not in emitted
        ]
        if missing_roots:
            raise LeanClosureError(
                "root-outside-closure",
                ",".join(missing_roots),
            )
        if owners != set(self.owner_modules):
            raise LeanClosureError(
                "owner-module-mismatch",
                self.root_module,
            )

    @classmethod
    def from_mapping(cls, value: object) -> LeanDeclarationClosure:
        if not isinstance(value, Mapping):
            raise LeanClosureError("invalid-receipt", "expected object")
        declarations = value.get("declarations")
        if not isinstance(declarations, list):
            raise LeanClosureError("invalid-field", "declarations")
        return cls(
            schema_id=_require_string(value.get("schema_id"), "schema_id"),
            lean_version=_require_string(
                value.get("lean_version"),
                "lean_version",
            ),
            root_module=_require_string(value.get("root_module"), "root_module"),
            root_declarations=_require_string_tuple(
                value.get("root_declarations"),
                "root_declarations",
            ),
            base_imports=_require_string_tuple(
                value.get("base_imports"),
                "base_imports",
            ),
            owner_modules=_require_string_tuple(
                value.get("owner_modules"),
                "owner_modules",
            ),
            declarations=tuple(
                LeanDeclaration.from_mapping(declaration)
                for declaration in declarations
            ),
        )

    @classmethod
    def from_json(cls, source: str) -> LeanDeclarationClosure:
        try:
            value = json.loads(source)
        except json.JSONDecodeError as error:
            raise LeanClosureError("invalid-json", str(error)) from error
        return cls.from_mapping(value)

    def canonical_manifest(self) -> dict[str, object]:
        return {
            "base_imports": list(self.base_imports),
            "declarations": [
                declaration.canonical_record()
                for declaration in self.declarations
            ],
            "lean_version": self.lean_version,
            "owner_modules": list(self.owner_modules),
            "root_declarations": list(self.root_declarations),
            "root_module": self.root_module,
            "schema_id": self.schema_id,
        }

    @property
    def closure_digest(self) -> str:
        canonical = json.dumps(
            self.canonical_manifest(),
            ensure_ascii=False,
            separators=(",", ":"),
            sort_keys=True,
        ).encode()
        return f"sha256:{sha256(canonical).hexdigest()}"

    def owner_modules_in_dependency_order(self) -> tuple[str, ...]:
        declaration_owners = {
            declaration.name: declaration.owner_module
            for declaration in self.declarations
        }
        dependencies = {
            owner_module: set() for owner_module in self.owner_modules
        }
        for declaration in self.declarations:
            for dependency in declaration.local_dependencies:
                dependency_owner = declaration_owners[dependency]
                if dependency_owner != declaration.owner_module:
                    dependencies[declaration.owner_module].add(
                        dependency_owner
                    )

        result: list[str] = []
        emitted: set[str] = set()
        while len(result) < len(dependencies):
            ready = sorted(
                owner
                for owner, owner_dependencies in dependencies.items()
                if owner not in emitted
                and owner_dependencies.issubset(emitted)
            )
            if not ready:
                unresolved = sorted(set(dependencies) - emitted)
                raise LeanClosureError(
                    "owner-module-cycle",
                    ",".join(unresolved),
                )
            result.extend(ready)
            emitted.update(ready)
        return tuple(result)


@dataclass(frozen=True)
class LeanOwnerSource:
    module: str
    path: Path
    owner_path: str
    source_digest: str


Runner = Callable[..., subprocess.CompletedProcess[str]]


def export_declaration_closure(
    *,
    lean_root: Path,
    root_module: str,
    root_declarations: Sequence[str],
    base_imports: Sequence[str] = ("Init",),
    runner: Runner = subprocess.run,
) -> LeanDeclarationClosure:
    if not root_declarations:
        raise LeanClosureError("missing-root-declaration", root_module)
    exporter = Path("PooFlowProof/Export/DeclarationClosure.lean")
    build = runner(
        ["lake", "build", root_module],
        cwd=lean_root,
        capture_output=True,
        check=False,
        text=True,
    )
    if build.returncode != 0:
        raise LeanClosureError(
            "lake-build-failed",
            build.stderr.strip() or build.stdout.strip() or root_module,
        )

    command = [
        "lake",
        "env",
        "lean",
        "--run",
        str(exporter),
        "--root-module",
        root_module,
    ]
    for root_declaration in root_declarations:
        command.extend(("--root-declaration", root_declaration))
    for base_import in base_imports:
        if base_import != "Init":
            command.extend(("--base-import", base_import))
    exported = runner(
        command,
        cwd=lean_root,
        capture_output=True,
        check=False,
        text=True,
    )
    if exported.returncode != 0:
        raise LeanClosureError(
            "lean-export-failed",
            exported.stderr.strip() or exported.stdout.strip() or root_module,
        )
    closure = LeanDeclarationClosure.from_json(exported.stdout)
    if closure.root_module != root_module:
        raise LeanClosureError(
            "root-module-mismatch",
            f"{root_module} != {closure.root_module}",
        )
    if closure.root_declarations != tuple(root_declarations):
        raise LeanClosureError(
            "root-declaration-mismatch",
            root_module,
        )
    expected_base_imports = ("Init",) + tuple(
        base_import for base_import in base_imports if base_import != "Init"
    )
    if closure.base_imports != expected_base_imports:
        raise LeanClosureError(
            "base-import-mismatch",
            root_module,
        )
    return closure


def _source_roots(lean_root: Path, lean_path: str) -> tuple[Path, ...]:
    roots: list[Path] = [lean_root.resolve()]
    marker = Path(".lake/build/lib/lean")
    for raw_entry in lean_path.split(os.pathsep):
        if not raw_entry:
            continue
        entry = Path(raw_entry).resolve()
        entry_parts = entry.parts
        marker_parts = marker.parts
        if len(entry_parts) >= len(marker_parts) and tuple(
            entry_parts[-len(marker_parts) :]
        ) == marker_parts:
            roots.append(Path(*entry_parts[: -len(marker_parts)]))
    return tuple(dict.fromkeys(roots))


def resolve_owner_sources(
    *,
    closure: LeanDeclarationClosure,
    lean_root: Path,
    runner: Runner = subprocess.run,
) -> tuple[LeanOwnerSource, ...]:
    lean_path_receipt = runner(
        ["lake", "env", "printenv", "LEAN_PATH"],
        cwd=lean_root,
        capture_output=True,
        check=False,
        text=True,
    )
    if lean_path_receipt.returncode != 0:
        raise LeanClosureError(
            "lean-path-failed",
            lean_path_receipt.stderr.strip() or str(lean_root),
        )
    lean_root = lean_root.resolve()
    roots = _source_roots(lean_root, lean_path_receipt.stdout.strip())
    sources: list[LeanOwnerSource] = []
    for module in closure.owner_modules_in_dependency_order():
        relative = Path(*module.split(".")).with_suffix(".lean")
        matches = tuple(
            candidate
            for root in roots
            if (candidate := (root / relative).resolve()).is_file()
        )
        if len(matches) != 1:
            raise LeanClosureError(
                "owner-source-resolution-failed",
                f"{module}: matches={len(matches)}",
            )
        path = matches[0]
        try:
            owner_path = path.relative_to(lean_root).as_posix()
        except ValueError:
            owner_path = f"{module}:{path.as_posix()}"
        digest = f"sha256:{sha256(path.read_bytes()).hexdigest()}"
        sources.append(
            LeanOwnerSource(
                module=module,
                path=path,
                owner_path=owner_path,
                source_digest=digest,
            )
        )
    return tuple(sources)
