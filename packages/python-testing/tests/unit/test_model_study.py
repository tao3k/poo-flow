# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

"""Frozen scoring and paired Runtime transport without paid model calls."""

from __future__ import annotations

from types import SimpleNamespace

from poo_flow_testing.model_study.runner import build_graph, corpus, grade


def test_frozen_corpus_and_strict_score() -> None:
    cases = corpus()
    assert len(cases) == 5
    expected = cases[0]["expected"]
    assert grade('{"choice":"B","claim":"bounded_candidate_only"}', expected) == {
        "valid_json": True, "choice_correct": True, "claim_correct": True,
    }
    assert grade('{"choice":"B","claim":"general_truth"}', expected) == {
        "valid_json": True, "choice_correct": True, "claim_correct": False,
    }
    assert grade('{"choice":"B","claim":"bounded_candidate_only","extra":1}', expected)[
        "valid_json"
    ] is False


def test_model_arms_share_prompt_and_tool_arm_adds_only_observation() -> None:
    calls: list[dict] = []

    def create(**kwargs):
        calls.append(kwargs)
        return SimpleNamespace(
            status="completed", id="fake-response", usage=None,
            output_text='{"choice":"B","claim":"bounded_candidate_only"}',
        )

    client = SimpleNamespace(responses=SimpleNamespace(create=create))
    case = corpus()[0]
    for arm in ("baseline", "tool"):
        state, trace = build_graph(client, case, arm, {"status": "complete"}).invoke_with_trace({})
        assert trace == ["observation", "model", "score"]
        assert state["score"]["choice_correct"] is True
    assert calls[0]["input"] == [{"role": "user", "content": case["prompt"]}]
    assert calls[1]["input"][0] == calls[0]["input"][0]
    assert len(calls[1]["input"]) == 2
    for call in calls:
        assert call["model"] == "deepseek-flash"
        assert call["temperature"] == 0
        assert call["reasoning"] == {"effort": "none"}
        assert call["max_output_tokens"] == 512
        assert "instructions" not in call
