#!/usr/bin/env python3

from __future__ import annotations

import copy
import unittest

from shared_gerbil_capability_test import (
    ReceiptValidationError,
    validate_project,
    validate_toolchain,
)


class SharedGerbilCapabilityUnitTest(unittest.TestCase):
    def setUp(self) -> None:
        self.toolchain = {
            "schema": "gerbil-bazel.prebuilt-toolchain-receipt.v1",
            "dependencyPolicy": "project-package-manifest",
            "dependencyState": {"gerbil-poo": "ready"},
            "dependencyRoots": ["external/gerbil-poo"],
        }
        self.project = {
            "schema": "gerbil-bazel.project-receipt.v1",
            "status": "ok",
            "resourceGuard": {
                "outcome": "completed",
                "peakRssBytes": 64 * 1024 * 1024,
                "maxRssBytes": 12 * 1024 * 1024 * 1024,
                "effectiveBuildCoreCount": 4,
                "memoryPerCoreBytes": 2 * 1024 * 1024 * 1024,
            },
            "dependencySourceResolutions": [
                {
                    "outcome": "resolved",
                    "expectedRevision": "abc123",
                    "observedRevision": "abc123",
                }
            ],
        }

    def test_valid_receipts_are_admitted(self) -> None:
        validate_toolchain(self.toolchain)
        validate_project(self.project)

    def test_missing_prebuilt_roots_fail_closed(self) -> None:
        receipt = copy.deepcopy(self.toolchain)
        receipt["dependencyRoots"] = []
        with self.assertRaises(ReceiptValidationError):
            validate_toolchain(receipt)

    def test_dependency_revision_drift_fails_closed(self) -> None:
        receipt = copy.deepcopy(self.project)
        receipt["dependencySourceResolutions"][0]["observedRevision"] = "def456"
        with self.assertRaises(ReceiptValidationError):
            validate_project(receipt)

    def test_adaptive_peak_rss_boundary_fails_closed(self) -> None:
        receipt = copy.deepcopy(self.project)
        receipt["resourceGuard"]["peakRssBytes"] = 8 * 1024 * 1024 * 1024
        with self.assertRaises(ReceiptValidationError):
            validate_project(receipt)

    def test_peak_rss_budget_scales_with_effective_build_cores(self) -> None:
        receipt = copy.deepcopy(self.project)
        receipt["resourceGuard"]["peakRssBytes"] = 3 * 1024 * 1024 * 1024
        receipt["resourceGuard"]["effectiveBuildCoreCount"] = 2
        validate_project(receipt)
        receipt["resourceGuard"]["effectiveBuildCoreCount"] = 1
        with self.assertRaises(ReceiptValidationError):
            validate_project(receipt)


if __name__ == "__main__":
    unittest.main()
