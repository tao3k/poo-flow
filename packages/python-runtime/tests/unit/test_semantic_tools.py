# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Exercise native read-only tool binding, stale source rejection and async parity."""
import asyncio
from copy import deepcopy
import json
import pytest
from poo_flow_runtime.semantic_tools import invoke_temporal_tool, ainvoke_temporal_tool
from poo_flow_runtime.semantic_runtime import SemanticRuntimeError
from semantic_cases import temporal_request


def _call(task):
    return {'type': 'function_call', 'name': 'poo_flow_temporal_solve',
            'call_id': 'actual-call', 'arguments': json.dumps({'task': task})}


def test_bound_tool_runs_current_native_owner_and_async(runtime):
    task = temporal_request()
    call = _call(task)
    result = invoke_temporal_tool(runtime, task, call)
    assert result['result'] == runtime.call('temporal.solve', task)
    assert result['artifactDigest'] == runtime.artifact_digest
    assert asyncio.run(ainvoke_temporal_tool(runtime, task, call)) == result
    task['source']['generation'] = task['lens']['generation'] = 2
    with pytest.raises(SemanticRuntimeError, match='binding rejected'):
        invoke_temporal_tool(runtime, task, call)


@pytest.mark.parametrize('change', ['source', 'operation', 'duplicate', 'type', 'extra'])
def test_model_cannot_replace_caller_source_or_operation(runtime, change):
    task = temporal_request()
    call = _call(task)
    if change == 'source':
        other = deepcopy(task)
        other['source']['parents'].clear()
        call = _call(other)
    elif change == 'operation':
        call['name'] = 'graph.admit'
    elif change == 'duplicate':
        call['arguments'] = '{"task":{},"task":' + json.dumps(task) + '}'
    elif change == 'type':
        other = deepcopy(task)
        other['lens']['generation'] = float(other['lens']['generation'])
        call = _call(other)
    else:
        call['arguments'] = json.dumps({'task': task, 'authority': True})
    with pytest.raises(SemanticRuntimeError):
        invoke_temporal_tool(runtime, task, call)
    assert task == temporal_request()
