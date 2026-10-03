# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import pytest
import json
from types import SimpleNamespace
from poo_flow_testing.model_study.direct.tasks import finite_rows
from poo_flow_testing.model_study.direct.live import live
from poo_flow_testing.model_study.direct.live import _provider_response
from poo_flow_testing.model_study.direct.native import score_candidate


def test_independent_closure_oracle_handles_cycles_and_positive_length_paths():
    assert finite_rows('closure', [(1, 2), (2, 1), (2, 3)]) == [
        (1, 1), (1, 2), (1, 3), (2, 1), (2, 2), (2, 3)]
    assert finite_rows('join', [(1, 2), (2, 1), (2, 3)]) == [(1, 1), (1, 3), (2, 2)]
    assert finite_rows('closure', []) == []


def test_unapproved_new_batch_stops_before_output_or_provider_import(tmp_path):
    preview = tmp_path / 'preview'; preview.mkdir()
    (preview/'plan.json').write_text('{}')
    output = tmp_path / 'unused'
    with pytest.raises(ValueError, match='approval'):
        live(tmp_path, preview, output, None)
    assert not output.exists()


@pytest.mark.parametrize('candidate', ['#.(system "unsafe")', '('*65+')'*65])
def test_candidate_reader_extensions_stop_before_native_loading(tmp_path, candidate):
    output = tmp_path / 'guard'
    observation = score_candidate(tmp_path, tmp_path/'absent-expected',
                                  candidate, output)
    assert not observation['correct']
    assert observation['transportRejected']
    assert not (output/'native-score.log').exists()


@pytest.mark.parametrize('completed', [True, False])
def test_provider_stream_retains_raw_events_and_requires_a_terminal_record(tmp_path, completed):
    def event(kind, **fields):
        return SimpleNamespace(type=kind, **fields,
            model_dump_json=lambda: json.dumps({'type': kind, 'delta': fields.get('delta')}))
    events = [event('response.reasoning_text.delta', delta='offline fixture'),
              event('response.output_text.delta', delta='((11 13))')]
    response = SimpleNamespace(model_dump_json=lambda **options: '{"id":"offline-test"}')
    if completed:
        events.append(event('response.completed', response=response))
    client = SimpleNamespace(responses=SimpleNamespace(create=lambda **request: iter(events)))
    path = tmp_path/'response.json'
    if completed:
        raw, terminal, reasoning, elapsed = _provider_response(client, {}, path)
        assert raw == '((11 13))' and terminal is response and reasoning == 1
        assert json.loads(path.read_text())['id'] == 'offline-test'
    else:
        with pytest.raises(RuntimeError, match='terminal'):
            _provider_response(client, {}, path)
        assert not path.exists()
    archived = [json.loads(line) for line in path.with_suffix('.events.jsonl').read_text().splitlines()]
    assert archived[1]['delta'] == '((11 13))'
