#!/usr/bin/env python3
"""Fail-closed validator for the RFC45 module-system owner map v1."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any
from urllib.parse import quote

SCHEMA_ID = "poo-flow.module-system-owner-map"
SCHEMA_VERSION = 1
ARTIFACT_ID = "poo-flow.module-system-owner-map.v1"
ARTIFACT_PATH = "owner-map/module-system-owner-map-v1.json"
VALIDATION_RECEIPT_SCHEMA_ID = "poo-flow.module-system-owner-map-validation-receipt"
VALIDATION_RECEIPT_SCHEMA_VERSION = 2
VALIDATION_RECEIPT_PATH = "owner-map/module-system-owner-map-validation-receipt-v2.json"
REQUIRED_ROW_IDS = (
    "rfc45-01-mix-module-expansion",
    "rfc45-02-g0-decision",
    "rfc45-03-runtime-context-recovery",
    "rfc45-04-observability-snapshot",
    "rfc45-05-lineage-cycle",
    "rfc45-06-gerbil-poo-consumption",
    "rfc45-07-public-composition",
    "rfc45-08-parent-qualification",
)
ALLOWED_BUILD_TARGETS = {
    "//owner-map:rfc45_01_mix_sources",
    "//owner-map:rfc45_02_sources",
    "//owner-map:rfc45_03_sources",
    "//owner-map:rfc45_04_sources",
    "//owner-map:rfc45_05_sources",
    "//owner-map:rfc45_06_sources",
    "//owner-map:rfc45_07_composition_sources",
    "//owner-map:module_system_sources",
}
HEX_64 = re.compile(r"^[0-9a-f]{64}$")


class OwnerMapValidationError(ValueError):
    pass


@dataclass(frozen=True)
class ValidationReceipt:
    schemaId: str
    schemaVersion: int
    artifactId: str
    artifactPath: str
    artifactSha256: str
    rowCount: int
    checkedOwnerCount: int
    descendantBoundary: str
    gitlinkChecked: bool


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise OwnerMapValidationError(message)


def load_document(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    _require(isinstance(value, dict), f"{path}: document must be an object")
    return value


def canonical_bytes(document: dict[str, Any]) -> bytes:
    return (json.dumps(document, sort_keys=True, separators=(",", ":")) + "\n").encode()


def artifact_digest(document: dict[str, Any]) -> str:
    return hashlib.sha256(canonical_bytes(document)).hexdigest()


def file_digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def expected_selector(owner: dict[str, Any]) -> str:
    symbol = quote(owner["symbol"], safe="-._~")
    return f"gerbil-scheme://{owner['path']}#item/{owner['kind']}/{symbol}"


def _validate_owner(owner: Any, role: str, repo_root: Path) -> None:
    _require(isinstance(owner, dict), f"{role}: owner must be an object")
    required = {"path", "symbol", "kind", "selector", "contentSha256"}
    _require(set(owner) == required, f"{role}: owner fields drift")
    path = owner["path"]
    _require(isinstance(path, str) and path.endswith(".ss"), f"{role}: invalid Gerbil owner path")
    _require(not path.startswith("packages/"), f"{role}: descendant checkout cannot own parent lifecycle")
    source_path = repo_root / path
    _require(source_path.is_file(), f"{role}: missing owner {path}")
    symbol = owner["symbol"]
    _require(isinstance(symbol, str) and symbol, f"{role}: missing owner symbol")
    _require(symbol in source_path.read_text(encoding="utf-8"), f"{role}: stale owner symbol {symbol}")
    _require(owner["kind"] in {"function", "macro"}, f"{role}: invalid parser kind")
    _require(owner["selector"] == expected_selector(owner), f"{role}: stale parser selector")
    _require(bool(HEX_64.fullmatch(owner["contentSha256"])), f"{role}: invalid content digest")
    _require(file_digest(source_path) == owner["contentSha256"], f"{role}: stale owner content digest")


def _validate_row(row: Any, expected_id: str, repo_root: Path) -> None:
    _require(isinstance(row, dict), f"{expected_id}: row must be an object")
    required = {
        "rowId", "rfc", "implementationState", "sourceOwner", "testOwner",
        "buildTarget", "evidenceReceipt",
    }
    _require(set(row) == required, f"{expected_id}: row fields drift")
    _require(row["rowId"] == expected_id, f"{expected_id}: row identity drift")
    _require(row["rfc"] == expected_id[3:8], f"{expected_id}: RFC identity drift")
    _require(row["implementationState"] == "implemented", f"{expected_id}: implementation not closed")
    _validate_owner(row["sourceOwner"], f"{expected_id}.sourceOwner", repo_root)
    _validate_owner(row["testOwner"], f"{expected_id}.testOwner", repo_root)
    _require(row["buildTarget"] in ALLOWED_BUILD_TARGETS, f"{expected_id}: unqualified build target")
    evidence = row["evidenceReceipt"]
    _require(isinstance(evidence, dict), f"{expected_id}: evidence receipt must be an object")
    _require(
        {"sourceTarget", "testTarget", "validationTarget"} <= set(evidence),
        f"{expected_id}: incomplete evidence receipt",
    )
    _require(evidence["sourceTarget"] == row["buildTarget"], f"{expected_id}: source target drift")
    _require(evidence["testTarget"] == "//owner-map:scheme_owner_map_test", f"{expected_id}: test target drift")
    _require(evidence["validationTarget"] == "//owner-map:contract_validation_test", f"{expected_id}: validation target drift")
    _require(
        "packages/wendao-episteme" not in json.dumps(evidence, sort_keys=True),
        f"{expected_id}: child lifecycle dependency",
    )


def validate_schema_document(schema: dict[str, Any]) -> None:
    _require(schema.get("$id") == SCHEMA_ID, "schema identity drift")
    properties = schema.get("properties", {})
    _require(properties.get("schemaId", {}).get("const") == SCHEMA_ID, "schemaId contract drift")
    _require(properties.get("schemaVersion", {}).get("const") == SCHEMA_VERSION, "schemaVersion contract drift")
    row_properties = properties.get("rows", {}).get("items", {}).get("properties", {})
    owner = schema.get("$defs", {}).get("owner", {})
    required_owner = {"path", "symbol", "kind", "selector", "contentSha256"}
    _require(set(owner.get("required", [])) == required_owner, "schema owner contract drift")
    _require(row_properties.get("implementationState", {}).get("const") == "implemented", "schema state drift")


def _reject_absolute_paths(value: Any, pointer: str = "") -> None:
    if isinstance(value, dict):
        for key, item in value.items():
            _reject_absolute_paths(item, f"{pointer}/{key}")
        return
    if isinstance(value, list):
        for index, item in enumerate(value):
            _reject_absolute_paths(item, f"{pointer}/{index}")
        return
    if not isinstance(value, str):
        return
    is_repository_label = value.startswith("//") and ":" in value
    is_absolute = not is_repository_label and (
        value.startswith(("/", "~/", "\\\\"))
        or bool(re.match(r"^[A-Za-z]:[\\\\/]", value))
    )
    _require(not is_absolute, f"validation receipt contains host path at {pointer}")


def validate_validation_receipt_schema_document(schema: dict[str, Any]) -> None:
    _require(schema.get("$id") == VALIDATION_RECEIPT_SCHEMA_ID, "receipt schema identity drift")
    properties = schema.get("properties", {})
    _require(
        properties.get("schemaVersion", {}).get("const") == VALIDATION_RECEIPT_SCHEMA_VERSION,
        "receipt schemaVersion contract drift",
    )
    _require(
        properties.get("aspRuntimeArtifact", {}).get("required")
        == ["commandRole", "installScope", "artifactIdentity"],
        "receipt runtime identity contract drift",
    )


def validate_validation_receipt(receipt: dict[str, Any], document: dict[str, Any]) -> None:
    _reject_absolute_paths(receipt)
    _require(
        set(receipt) == {
            "schemaId",
            "schemaVersion",
            "receiptPath",
            "artifact",
            "focusedGates",
            "projectAggregateObservation",
            "aspRuntimeArtifact",
        },
        "validation receipt top-level contract drift",
    )
    _require(receipt["schemaId"] == VALIDATION_RECEIPT_SCHEMA_ID, "validation receipt schemaId drift")
    _require(
        receipt["schemaVersion"] == VALIDATION_RECEIPT_SCHEMA_VERSION,
        "validation receipt schemaVersion drift",
    )
    _require(receipt["receiptPath"] == VALIDATION_RECEIPT_PATH, "validation receipt path drift")
    artifact = receipt["artifact"]
    _require(artifact["path"] == ARTIFACT_PATH, "validation receipt artifact path drift")
    _require(artifact["sha256"] == artifact_digest(document), "validation receipt artifact digest drift")
    _require(artifact["rowCount"] == len(document["rows"]), "validation receipt row count drift")
    _require(artifact["checkedOwnerCount"] == len(document["rows"]) * 2, "validation receipt owner count drift")
    _require(receipt["focusedGates"]["affectedAggregate"]["status"] == "passed", "affected aggregate not closed")
    observation = receipt["projectAggregateObservation"]
    _require(observation["authoritativeForOwnerMapClosure"] is False, "project aggregate authority drift")
    _require("outputBase" not in observation, "host output base cannot enter a versioned receipt")
    _require(
        receipt["aspRuntimeArtifact"]
        == {
            "commandRole": "asp",
            "installScope": "ASP_STATE_HOME/runtime",
            "artifactIdentity": "blake3-256:5809daeb043f1fd5bdbe776b3dfb58112cb9775115916c87a8ea525a4d6185b8",
        },
        "ASP runtime content identity drift",
    )


def validate_gitlink(document: dict[str, Any], repo_root: Path) -> None:
    boundary = document["descendantBoundary"]
    result = subprocess.run(
        ["git", "ls-files", "-s", "--", boundary["path"]],
        cwd=repo_root,
        check=True,
        capture_output=True,
        text=True,
    )
    expected = f"160000 {boundary['pin']} 0\t{boundary['path']}"
    _require(result.stdout.strip() == expected, "descendant gitlink identity drift")


def validate_document(
    document: dict[str, Any], repo_root: Path, *, check_gitlink: bool = False
) -> ValidationReceipt:
    required = {"schemaId", "schemaVersion", "artifactId", "artifactPath", "rows", "descendantBoundary"}
    _require(set(document) == required, "top-level contract drift")
    _require(document["schemaId"] == SCHEMA_ID, "schemaId drift")
    _require(document["schemaVersion"] == SCHEMA_VERSION, "schemaVersion drift")
    _require(document["artifactId"] == ARTIFACT_ID, "artifactId drift")
    _require(document["artifactPath"] == ARTIFACT_PATH, "artifactPath drift")
    rows = document["rows"]
    _require(isinstance(rows, list), "rows must be an array")
    _require(tuple(row.get("rowId") for row in rows) == REQUIRED_ROW_IDS, "row closure drift")
    for row, row_id in zip(rows, REQUIRED_ROW_IDS, strict=True):
        _validate_row(row, row_id, repo_root)
    boundary = document["descendantBoundary"]
    expected_boundary = {
        "path": "packages/wendao-episteme",
        "relationship": "pinned-provenance-only",
        "pin": "9566d310a2813e81068326e7d17a30d330de393f",
        "url": "https://github.com/tao3k/wendao-episteme.git",
        "forbiddenLifecycle": ["build", "test", "release", "source-scan"],
    }
    _require(boundary == expected_boundary, "descendant boundary drift")
    if check_gitlink:
        validate_gitlink(document, repo_root)
    return ValidationReceipt(
        schemaId=SCHEMA_ID,
        schemaVersion=SCHEMA_VERSION,
        artifactId=ARTIFACT_ID,
        artifactPath=ARTIFACT_PATH,
        artifactSha256=artifact_digest(document),
        rowCount=len(rows),
        checkedOwnerCount=len(rows) * 2,
        descendantBoundary=boundary["relationship"],
        gitlinkChecked=check_gitlink,
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--schema", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--receipt-schema", type=Path, required=True)
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--check-gitlink", action="store_true")
    args = parser.parse_args()
    document = load_document(args.artifact)
    validate_schema_document(load_document(args.schema))
    receipt_document = load_document(args.receipt)
    validate_validation_receipt_schema_document(load_document(args.receipt_schema))
    validate_validation_receipt(receipt_document, document)
    receipt = validate_document(document, args.repo_root.resolve(), check_gitlink=args.check_gitlink)
    print(json.dumps(asdict(receipt), sort_keys=True))


if __name__ == "__main__":
    main()
