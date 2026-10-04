# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Bind read-only model tool calls to caller-owned tasks before invoking Scheme."""
from __future__ import annotations
import json
from typing import Any, Mapping

from .semantic_runtime import SemanticRuntime, SemanticRuntimeError, _unique_json_pairs


def temporal_tool_definition() -> dict[str, Any]:
    """Describe the read-only Temporal operation; Runtime owns argument validation."""
    return {'type': 'function', 'name': 'poo_flow_temporal_solve',
            'description': 'Evaluate the supplied caller task through the Temporal Library.',
            'parameters': {'type': 'object', 'required': ['task'],
                           'additionalProperties': False,
                           'properties': {'task': {'type': 'object'}}}}


def _bound_task(task: Mapping[str, Any], call: Mapping[str, Any]) -> dict[str, Any]:
    if (call.get('type') != 'function_call' or call.get('name') != 'poo_flow_temporal_solve'
            or not isinstance(call.get('call_id'), str) or not 0 < len(call['call_id']) <= 128):
        raise SemanticRuntimeError('invalid Temporal tool identity', status=3)
    raw = call.get('arguments')
    if not isinstance(raw, str) or len(raw.encode()) > 1048576:
        raise SemanticRuntimeError('invalid Temporal tool argument size', status=3)
    try:
        arguments = json.loads(raw, object_pairs_hook=_unique_json_pairs)
        if not isinstance(arguments, dict) or set(arguments) != {'task'}:
            raise ValueError('tool requires exactly one task')
        expected = json.dumps(dict(task), sort_keys=True, separators=(',', ':'), allow_nan=False)
        actual = json.dumps(arguments['task'], sort_keys=True, separators=(',', ':'), allow_nan=False)
        if expected != actual:
            raise ValueError('model task differs from the caller current task')
        return json.loads(expected)
    except (ValueError, TypeError) as error:
        raise SemanticRuntimeError('Temporal tool task binding rejected', status=3) from error


def invoke_temporal_tool(runtime: SemanticRuntime, task: Mapping[str, Any],
                         call: Mapping[str, Any]) -> dict[str, Any]:
    """Execute one bound read-only call; model parameters cannot replace source data."""
    result = runtime.call('temporal.solve', _bound_task(task, call))
    return {'schema': 'poo-flow.semantic-tool-result', 'callId': call['call_id'],
            'artifactDigest': runtime.artifact_digest, 'result': result}


async def ainvoke_temporal_tool(runtime: SemanticRuntime, task: Mapping[str, Any],
                               call: Mapping[str, Any]) -> dict[str, Any]:
    """Execute the same bound operation using the Runtime owner thread asynchronously."""
    result = await runtime.acall('temporal.solve', _bound_task(task, call))
    return {'schema': 'poo-flow.semantic-tool-result', 'callId': call['call_id'],
            'artifactDigest': runtime.artifact_digest, 'result': result}
