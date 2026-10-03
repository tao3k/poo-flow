# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Public Python Library contract and acceptance receipt rejection controls."""
from pathlib import Path
import sys
import pytest
import poo_flow_runtime as library

REPO = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(REPO / 'scripts/temporal'))
from check_library import TESTS, test_receipt as read_test_receipt


@pytest.mark.parametrize('name,module', [
    ('Publication', 'temporal_selection'),
    ('SignedPublication', 'temporal_selection'),
    ('TemporalSelectionStore', 'temporal_selection'),
    ('NativeTemporalSelectionStore', 'native_temporal_selection'),
    ('TemporalBudgetCoordinator', 'temporal_budget'),
    ('NativeTemporalEvaluator', 'temporal_evaluator'),
])
def test_public_facade_exposes_library_contract(name, module):
    implementation = __import__('poo_flow_runtime.' + module, fromlist=[name])
    assert name in library.__all__
    assert getattr(library, name) is getattr(implementation, name)


def xml_receipt(tmp_path, control=''):
    path = tmp_path / 'tests.xml'
    path.write_text('<testsuites><testsuite>' + ''.join(
        '<testcase classname="' + Path(p).stem + '" name="contract">' +
        (control if i == 0 else '') + '</testcase>' for i, p in enumerate(TESTS)) +
        '</testsuite></testsuites>')
    return path


@pytest.mark.parametrize('control', ['<skipped/>', '<failure/>', '<error/>'])
def test_skipped_or_failed_tests_cannot_close_library(tmp_path, control):
    with pytest.raises(ValueError, match='failed, errored, skipped'):
        read_test_receipt(xml_receipt(tmp_path, control))


def test_missing_test_module_cannot_close_library(tmp_path):
    path = xml_receipt(tmp_path)
    path.write_text(path.read_text().replace(Path(TESTS[0]).stem, 'another_module'))
    with pytest.raises(ValueError, match='inventory differs'):
        read_test_receipt(path)


def test_complete_test_receipt_is_counted(tmp_path):
    assert read_test_receipt(xml_receipt(tmp_path))['passed'] == len(TESTS)
