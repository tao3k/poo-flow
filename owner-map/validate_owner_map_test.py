#!/usr/bin/env python3

from __future__ import annotations

import copy
import unittest
from pathlib import Path

from validate_owner_map import (
    OwnerMapValidationError,
    artifact_digest,
    load_document,
    validate_document,
    validate_schema_document,
    validate_validation_receipt,
    validate_validation_receipt_schema_document,
)

REPO_ROOT = Path(__file__).resolve().parents[1]
ARTIFACT = REPO_ROOT / "owner-map/module-system-owner-map-v1.json"
SCHEMA = REPO_ROOT / "owner-map/module-system-owner-map-v1.schema.json"
RECEIPT = REPO_ROOT / "owner-map/module-system-owner-map-validation-receipt-v2.json"
RECEIPT_SCHEMA = REPO_ROOT / "owner-map/module-system-owner-map-validation-receipt-v2.schema.json"


class OwnerMapContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.document = load_document(ARTIFACT)

    def assert_rejected(self, document: dict) -> None:
        with self.assertRaises(OwnerMapValidationError):
            validate_document(document, REPO_ROOT)

    def test_current_contract_is_closed(self) -> None:
        receipt = validate_document(self.document, REPO_ROOT)
        self.assertEqual(receipt.rowCount, 8)
        self.assertEqual(receipt.checkedOwnerCount, 16)

    def test_missing_owner_row_fails_closed(self) -> None:
        document = copy.deepcopy(self.document)
        document["rows"].pop()
        self.assert_rejected(document)

    def test_stale_selector_fails_closed(self) -> None:
        document = copy.deepcopy(self.document)
        document["rows"][0]["sourceOwner"]["selector"] += "-stale"
        self.assert_rejected(document)

    def test_stale_content_digest_fails_closed(self) -> None:
        document = copy.deepcopy(self.document)
        document["rows"][0]["sourceOwner"]["contentSha256"] = "0" * 64
        self.assert_rejected(document)

    def test_wrong_build_label_fails_closed(self) -> None:
        document = copy.deepcopy(self.document)
        document["rows"][0]["buildTarget"] = "//scheme:compile"
        self.assert_rejected(document)

    def test_child_source_owner_fails_closed(self) -> None:
        document = copy.deepcopy(self.document)
        document["rows"][0]["sourceOwner"]["path"] = "packages/wendao-episteme/build.ss"
        self.assert_rejected(document)

    def test_child_lifecycle_evidence_fails_closed(self) -> None:
        document = copy.deepcopy(self.document)
        document["rows"][0]["evidenceReceipt"]["childTest"] = "packages/wendao-episteme:test"
        self.assert_rejected(document)

    def test_schema_version_drift_fails_closed(self) -> None:
        document = copy.deepcopy(self.document)
        document["schemaVersion"] = 2
        self.assert_rejected(document)

    def test_deterministic_replay(self) -> None:
        self.assertEqual(artifact_digest(self.document), artifact_digest(load_document(ARTIFACT)))

    def test_schema_document_matches_validator_contract(self) -> None:
        validate_schema_document(load_document(SCHEMA))

    def test_validation_receipt_is_portable_and_content_bound(self) -> None:
        validate_validation_receipt(load_document(RECEIPT), self.document)

    def test_absolute_host_paths_fail_closed(self) -> None:
        for pointer in ("outputBase", "artifactPath"):
            with self.subTest(pointer=pointer):
                receipt = copy.deepcopy(load_document(RECEIPT))
                if pointer == "outputBase":
                    receipt["projectAggregateObservation"][pointer] = "/private/tmp/build"
                else:
                    receipt["aspRuntimeArtifact"][pointer] = "/home/user/runtime/asp"
                with self.assertRaises(OwnerMapValidationError):
                    validate_validation_receipt(receipt, self.document)

    def test_validation_receipt_artifact_digest_drift_fails_closed(self) -> None:
        receipt = copy.deepcopy(load_document(RECEIPT))
        receipt["artifact"]["sha256"] = "0" * 64
        with self.assertRaises(OwnerMapValidationError):
            validate_validation_receipt(receipt, self.document)

    def test_validation_receipt_schema_matches_validator_contract(self) -> None:
        validate_validation_receipt_schema_document(load_document(RECEIPT_SCHEMA))


if __name__ == "__main__":
    unittest.main()
