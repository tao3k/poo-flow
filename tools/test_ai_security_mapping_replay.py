from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from ai_security_mapping_replay import (
    ReplayValidationError,
    replay_mapping_bundle,
    sha256_file,
)


REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
BUNDLE_PATH = (
    REPOSITORY_ROOT
    / "docs/20-29-ai-security/receipts"
    / "asr-framework-mapping-005.bundle.v1.json"
)
RECEIPT_PATH = (
    REPOSITORY_ROOT
    / "docs/20-29-ai-security/receipts"
    / "asr-framework-mapping-005.receipt.v1.json"
)


class AISecurityMappingReplayTests(unittest.TestCase):
    def load_fixture(self, path: Path) -> dict:
        return json.loads(path.read_text(encoding="utf-8"))

    def write_json(self, path: Path, value: dict) -> None:
        path.write_text(
            json.dumps(value, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )

    def write_mutated_pair(
        self,
        directory: Path,
        bundle: dict,
        receipt: dict,
    ) -> tuple[Path, Path]:
        bundle_path = directory / "bundle.json"
        receipt_path = directory / "receipt.json"
        self.write_json(bundle_path, bundle)
        receipt["bundle"]["sha256"] = sha256_file(bundle_path)
        self.write_json(receipt_path, receipt)
        return bundle_path, receipt_path

    def test_exact_bundle_replays_expected_metrics(self) -> None:
        replay = replay_mapping_bundle(BUNDLE_PATH, RECEIPT_PATH)

        self.assertEqual(replay["result"], "passed")
        self.assertEqual(replay["metrics"]["claimCount"], 8)
        self.assertEqual(replay["metrics"]["proofCoverageCount"], 6)
        self.assertEqual(replay["metrics"]["unknownEscalationCount"], 2)
        self.assertEqual(replay["assurance"]["digestIntegrity"], "verified")
        self.assertEqual(
            replay["assurance"]["schemaAndSemanticReplay"],
            "verified",
        )
        self.assertEqual(
            replay["assurance"]["issuerAuthentication"],
            "not-provided",
        )
        self.assertEqual(
            replay["assurance"]["transparencyInclusion"],
            "not-provided",
        )

    def test_digest_mismatch_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            bundle_path = Path(temporary_directory) / "bundle.json"
            bundle_path.write_bytes(BUNDLE_PATH.read_bytes() + b"\n")

            with self.assertRaisesRegex(
                ReplayValidationError,
                "digest does not match",
            ):
                replay_mapping_bundle(bundle_path, RECEIPT_PATH)

    def test_authority_amplification_fails_closed(self) -> None:
        bundle = self.load_fixture(BUNDLE_PATH)
        receipt = self.load_fixture(RECEIPT_PATH)
        bundle["claims"][0]["authorityAfter"] = 4

        with tempfile.TemporaryDirectory() as temporary_directory:
            bundle_path, receipt_path = self.write_mutated_pair(
                Path(temporary_directory),
                bundle,
                receipt,
            )
            with self.assertRaisesRegex(
                ReplayValidationError,
                "amplifies authority",
            ):
                replay_mapping_bundle(bundle_path, receipt_path)

    def test_escalation_without_reason_fails_closed(self) -> None:
        bundle = self.load_fixture(BUNDLE_PATH)
        receipt = self.load_fixture(RECEIPT_PATH)
        del bundle["claims"][6]["escalationReason"]

        with tempfile.TemporaryDirectory() as temporary_directory:
            bundle_path, receipt_path = self.write_mutated_pair(
                Path(temporary_directory),
                bundle,
                receipt,
            )
            with self.assertRaisesRegex(
                ReplayValidationError,
                "escalationReason",
            ):
                replay_mapping_bundle(bundle_path, receipt_path)

    def test_spoofed_coverage_metric_fails_closed(self) -> None:
        bundle = self.load_fixture(BUNDLE_PATH)
        receipt = self.load_fixture(RECEIPT_PATH)
        bundle["expectedMetrics"]["proofCoverageCount"] = 7

        with tempfile.TemporaryDirectory() as temporary_directory:
            bundle_path, receipt_path = self.write_mutated_pair(
                Path(temporary_directory),
                bundle,
                receipt,
            )
            with self.assertRaisesRegex(
                ReplayValidationError,
                "wrong proofCoverageCount",
            ):
                replay_mapping_bundle(bundle_path, receipt_path)

    def test_pending_csa_detail_cannot_be_promoted(self) -> None:
        bundle = self.load_fixture(BUNDLE_PATH)
        receipt = self.load_fixture(RECEIPT_PATH)
        bundle["claims"][7]["mappingStatus"] = "projection"

        with tempfile.TemporaryDirectory() as temporary_directory:
            bundle_path, receipt_path = self.write_mutated_pair(
                Path(temporary_directory),
                bundle,
                receipt,
            )
            with self.assertRaisesRegex(
                ReplayValidationError,
                "must fail closed",
            ):
                replay_mapping_bundle(bundle_path, receipt_path)


if __name__ == "__main__":
    unittest.main()
