# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import asyncio
import json

import pytest

from poo_flow_testing.model_study.semantic_abi import configuration, request_for
from poo_flow_testing.model_study.semantic_cases import corpus
from poo_flow_testing.model_study.semantic_provider import ContentTimeout, consume_lines


def line(kind, **fields):
    return 'data: ' + json.dumps(dict(type=kind, **fields))


def test_metadata_and_reasoning_cannot_keep_a_content_stall_alive():
    async def lines():
        while True:
            await asyncio.sleep(0.002)
            yield line('response.reasoning_text.delta', delta='private reasoning')
    record = {}
    with pytest.raises(ContentTimeout):
        asyncio.run(consume_lines(lines(), record, idle_seconds=0.02))
    assert record['raw'] == ''
    assert record['events']
    assert 'private reasoning' not in json.dumps(record)


def test_stalled_content_after_first_delta_fails_without_repair():
    async def lines():
        yield line('response.output_text.delta', delta='{"status":')
        await asyncio.sleep(0.1)
    record = {}
    with pytest.raises(ContentTimeout):
        asyncio.run(consume_lines(lines(), record, idle_seconds=0.02))
    assert record['raw'] == '{"status":'


def test_whitespace_content_cannot_reset_the_watchdog():
    async def lines():
        while True:
            await asyncio.sleep(0.002)
            yield line('response.output_text.delta', delta=' ')
    with pytest.raises(ContentTimeout):
        asyncio.run(consume_lines(lines(), {}, idle_seconds=0.02))


def test_terminal_completion_and_genuine_content_are_both_required():
    async def lines():
        yield line('response.output_text.delta', delta='{"status":"complete","rows":[]}')
        yield line('response.completed', response={'id': 'test', 'status': 'completed'})
    record = {}
    assert asyncio.run(consume_lines(lines(), record)).startswith('{')
    assert record['responseId'] == 'test'
    assert len(record['contentGapsSeconds']) == 1


def test_incomplete_output_cannot_be_credited_as_acceptance():
    async def lines():
        yield line('response.output_text.delta', delta='{}')
        yield line('response.incomplete', response={'status': 'incomplete'})
    with pytest.raises(RuntimeError, match='complete content'):
        asyncio.run(consume_lines(lines(), {}))


def test_request_contains_only_current_task_source_and_transport_contract():
    cases = corpus()
    assert len(cases) == 12
    assert len({item['id'] for item in cases}) == 12
    for case in cases:
        request = request_for(case['request'], {'source.ss': '(def actual-source 1)'}, 'configured-model')
        assert request['model'] == 'configured-model'
        assert len(request['input']) == 1
        supplied = request['input'][0]['content']
        assert '(def actual-source 1)' in supplied
        assert '(semantic-call "temporal.solve" ' in supplied
        payload = json.dumps(case['request'], ensure_ascii=False, separators=(',', ':'))
        assert json.dumps(payload, ensure_ascii=False) in supplied
        assert 'expected' not in supplied and 'native-private' not in supplied
        assert 'instructions' not in request and 'tools' not in request
    cases[0]['request']['source']['parents'].clear()
    assert corpus()[0]['request']['source']['parents']


def test_configuration_reads_literals_without_executing_shell(tmp_path):
    path = tmp_path/'env'
    path.write_text('export DEEPSEEK_API_KEY="literal-key"\nANTHROPIC_MODEL=deepseek-v4-flash\nUNRELATED=$(touch unsafe)\n')
    assert configuration(path) == {'DEEPSEEK_API_KEY': 'literal-key', 'ANTHROPIC_MODEL': 'deepseek-v4-flash'}
