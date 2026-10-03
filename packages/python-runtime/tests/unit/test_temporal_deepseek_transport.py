# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time
import pytest
sys.path.insert(0,str(Path(__file__).resolve().parents[4]/'scripts/temporal'))
from model_study_deepseek import configuration, worker, DeepSeekInference
from model_study_transport import ModelTransportError


def env_file(tmp_path):
    p=tmp_path/'test.env'
    p.write_text('DEEPSEEK_API_KEY="private-test-key"\nANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic\nANTHROPIC_MODEL=deepseek-v4-flash\nCLAUDE_CODE_EFFORT_LEVEL=max\n')
    return p


def fixture_client(monkeypatch,events):
    import httpx
    class Response:
        status_code=200
        def __enter__(self):return self
        def __exit__(self,*args):pass
        def iter_lines(self):
            for event in events:yield 'data: '+json.dumps(event)
    class Client:
        def __init__(self,*args,**kwargs):pass
        def __enter__(self):return self
        def __exit__(self,*args):pass
        def stream(self,*args,**kwargs):return Response()
    monkeypatch.setattr(httpx,'Client',Client)


def test_real_content_parser_redacts_thinking_and_credentials(tmp_path,monkeypatch,capsys):
    fixture_client(monkeypatch,[
        dict(type='message_start',message=dict(model='deepseek-v4-flash',usage={'input_tokens':10})),
        dict(type='ping'),
        dict(type='content_block_delta',delta=dict(type='thinking_delta',thinking='private reasoning')),
        dict(type='content_block_delta',delta=dict(type='text_delta',text='{"answer":true}')),
        dict(type='message_delta',delta=dict(stop_reason='end_turn'),usage={'output_tokens':20}),
        dict(type='message_stop')])
    worker(dict(env_file=str(env_file(tmp_path)),prompt='return JSON',schema={'type':'object'}))
    captured=capsys.readouterr().out
    assert 'private-test-key' not in captured and 'private reasoning' not in captured
    events=[json.loads(line) for line in captured.splitlines()]
    thinking=next(e for e in events if e.get('channel')=='thinking_delta')
    assert thinking['digest']=='sha256:'+hashlib.sha256(b'private reasoning').hexdigest()
    assert events[-1]['event']=='completed' and events[-1]['usage']['output_tokens']==20


def test_model_tool_block_is_rejected(tmp_path,monkeypatch):
    fixture_client(monkeypatch,[dict(type='content_block_start',content_block=dict(type='tool_use'))])
    with pytest.raises(ModelTransportError,match='tool/content'):
        worker(dict(env_file=str(env_file(tmp_path)),prompt='return JSON',schema={}))


def test_noncontent_events_cannot_extend_five_second_deadline(tmp_path,monkeypatch):
    original=subprocess.Popen
    program="import sys,json,time\nsys.stdin.readline()\nwhile True:\n print(json.dumps({'event':'configuration'}),flush=True);time.sleep(0.03)\n"
    def spawn(command,**kwargs):return original([sys.executable,'-u','-c',program],**kwargs)
    monkeypatch.setattr(subprocess,'Popen',spawn)
    c=DeepSeekInference(tmp_path/'receipt',env_file=env_file(tmp_path));started=time.monotonic()
    with pytest.raises(ModelTransportError,match='await-first-content'):
        c.infer('return JSON',{'type':'object'})
    assert time.monotonic()-started < 7


def test_configured_model_and_effort_are_preserved(tmp_path):
    _,meta=configuration(env_file(tmp_path))
    assert meta['model']=='deepseek-v4-flash' and meta['reasoningEffort']=='max'


def test_numeric_false_cannot_pass_boolean_rubric():
    from model_study import validate_answer
    answer=dict(classification='possible',precedence_proves_causation=False,model_can_authorize=0,
        fair_infinite_progress=False,operation='none',source='',reason='bounded',api_symbols=[],
        axes=dict(source_generation='',valid_time='',knowledge_time='',causal_cut=''))
    with pytest.raises(ValueError,match='boolean type'):
        validate_answer(answer)


def test_placeholder_constants_are_rejected_before_native_process(tmp_path,monkeypatch):
    from poo_flow_runtime.temporal_evaluator import NativeTemporalEvaluator
    source=b'---- MODULE TemporalComposition ----\nCONSTANT ModelIdentity\n====\n'
    evaluator=NativeTemporalEvaluator(tmp_path,source,'sha256:'+hashlib.sha256(source).hexdigest(),
        evaluator_key=b'x'*32,gerbil_environment={})
    def must_not_spawn(*args,**kwargs):raise AssertionError('invalid literals spawned native evaluator')
    monkeypatch.setattr(subprocess,'Popen',must_not_spawn)
    with pytest.raises(ValueError,match='literal profile missing bindings'):
        evaluator.assess(subject='s',scope='s',cut='c',projection='p',policy='p',generation='g',query='q',target='t')
