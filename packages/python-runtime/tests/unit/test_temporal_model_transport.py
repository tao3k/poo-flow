# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Negative controls for the private real-model transport; no model service needed."""
from pathlib import Path
import sys
import time
import pytest
sys.path.insert(0, str(Path(__file__).resolve().parents[4] / 'scripts/temporal'))
from model_study_transport import CodexInference, ModelTransportError, strict_json


def executable(tmp_path, body):
    path = tmp_path / 'fake-server'
    path.write_text('#!' + sys.executable + '\n' + body)
    path.chmod(0o700)
    return str(path)


def test_stderr_diagnostics_do_not_reset_progress_deadline(tmp_path):
    program = executable(tmp_path, "import sys,time\nwhile True:\n sys.stderr.write('diagnostic\\n');sys.stderr.flush();time.sleep(0.03)\n")
    started = time.monotonic()
    with pytest.raises(ModelTransportError, match='progress deadline'):
        CodexInference(tmp_path/'receipt',model='gpt-6-sol',effort='medium',executable=program)
    assert time.monotonic()-started < 8
    assert (tmp_path/'receipt/server.stderr').stat().st_size > 0


def test_model_tool_request_is_rejected(tmp_path):
    program = executable(tmp_path, '''import json,sys
for line in sys.stdin:
 m=json.loads(line)
 if m.get('method')=='initialize':
  print(json.dumps({'id':m['id'],'result':{}}),flush=True)
 elif m.get('method')=='thread/start':
  print(json.dumps({'id':99,'method':'item/commandExecution/requestApproval','params':{}}),flush=True)
''')
    c = CodexInference(tmp_path/'receipt',model='gpt-6-sol',effort='medium',executable=program)
    try:
        with pytest.raises(ModelTransportError,match='tool/approval'):
            c.infer('irrelevant',{'type':'object'})
    finally:
        c.close()


def test_ambiguous_json_keys_are_rejected():
    with pytest.raises(ValueError,match='duplicate JSON key'):
        strict_json('{"classification":"unknown","classification":"necessary"}')
