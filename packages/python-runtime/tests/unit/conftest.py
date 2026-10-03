# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

import hashlib
import os
from pathlib import Path
import pytest
from poo_flow_runtime.semantic_runtime import SemanticRuntime, SemanticRuntimeError

@pytest.fixture(scope='session')
def runtime():
    configured = os.environ.get('POO_FLOW_SEMANTIC_LIBRARY')
    if not configured:
        pytest.skip('semantic AOT artifact must be explicitly configured')
    path = Path(configured)
    with SemanticRuntime(path, expected_digest=hashlib.sha256(path.read_bytes()).hexdigest()) as value:
        yield value
    with pytest.raises(SemanticRuntimeError, match='closed'):
        value.call('descriptor', {})
    value.close()
    result = value._ffi.new('poo_flow_semantic_result *')
    assert value._lib.poo_flow_python_semantic_call(b'descriptor', b'{}', 2, result) == 1
    assert value._lib.poo_flow_python_semantic_open(str(path).encode()) == 1


