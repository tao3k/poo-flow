#!/usr/bin/env python3

from __future__ import annotations

import copy
import unittest
from pathlib import Path

from validate_owner_map import (
    OwnerMapValidationError,
    load_manifest,
    validate_manifest,
)

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parents[2]
MANIFEST = HERE / "ownership.bzl"


class OwnerMapTest(unittest.TestCase):
    def setUp(self) -> None:
        self.values = load_manifest(MANIFEST)

    def assert_rejected(self, values: dict) -> None:
        with self.assertRaises(OwnerMapValidationError):
            validate_manifest(values, REPO_ROOT)

    def test_current_source_owned_map_is_closed(self) -> None:
        validate_manifest(self.values, REPO_ROOT)

    def test_missing_row_fails_closed(self) -> None:
        values = copy.deepcopy(self.values)
        values["OWNER_MAP_ROWS"].pop()
        self.assert_rejected(values)

    def test_reordered_row_fails_closed(self) -> None:
        values = copy.deepcopy(self.values)
        values["OWNER_MAP_ROWS"][0:2] = reversed(values["OWNER_MAP_ROWS"][0:2])
        self.assert_rejected(values)

    def test_stale_symbol_fails_closed(self) -> None:
        values = copy.deepcopy(self.values)
        values["OWNER_MAP_ROWS"][0]["source_symbol"] = "stale-owner"
        self.assert_rejected(values)

    def test_descendant_owner_fails_closed(self) -> None:
        values = copy.deepcopy(self.values)
        values["OWNER_MAP_ROWS"][0]["source_path"] = "lambda-episteme/build.ss"
        self.assert_rejected(values)

    def test_duplicate_target_fails_closed(self) -> None:
        values = copy.deepcopy(self.values)
        values["OWNER_MAP_ROWS"][1]["target_name"] = values["OWNER_MAP_ROWS"][0][
            "target_name"
        ]
        self.assert_rejected(values)


if __name__ == "__main__":
    unittest.main()
