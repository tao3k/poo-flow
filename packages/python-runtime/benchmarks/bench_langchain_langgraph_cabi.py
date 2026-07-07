#!/usr/bin/env python3
"""Benchmark native LangChain/LangGraph flows against POO Flow runtime surfaces.

The benchmark intentionally avoids real LLM/network calls. It measures framework
orchestration, graph execution, runtime handoff, and C ABI materialization costs
for deterministic agent-flow shapes.
"""

from __future__ import annotations

import argparse
import gc
import json
import operator
import platform
import statistics
import sys
import time
import traceback
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Annotated, Any, TypedDict


Subject = Callable[[int], Any]


@dataclass(frozen=True)
class BenchmarkCase:
    name: str
    family: str
    description: str
    features: tuple[str, ...]
    make_subject: Callable[[], Subject]
    max_iterations: int | None = None


@dataclass(frozen=True)
class BenchmarkResult:
    name: str
    family: str
    description: str
    features: tuple[str, ...]
    iterations: int
    warmup: int
    mean_us: float
    p50_us: float
    p95_us: float
    min_us: float
    max_us: float
    ops_per_second: float
    checksum: int


@dataclass(frozen=True)
class BenchmarkFailure:
    name: str
    family: str
    description: str
    features: tuple[str, ...]
    phase: str
    error_type: str
    error: str


@dataclass(frozen=True)
class GateCheck:
    name: str
    family: str
    description: str
    features: tuple[str, ...]
    status: str
    receipt: str = ""
    error_type: str = ""
    error: str = ""


@dataclass(frozen=True)
class Report:
    generated_at: str
    command: str
    python: str
    platform: str
    iterations: int
    warmup: int
    gc_enabled_during_measurement: bool
    case_caps_enabled: bool
    results: tuple[BenchmarkResult, ...] = field(default_factory=tuple)
    failures: tuple[BenchmarkFailure, ...] = field(default_factory=tuple)
    gates: tuple[GateCheck, ...] = field(default_factory=tuple)


class AgentRouterState(TypedDict, total=False):
    session_id: str
    question: str
    intent: str
    documents: list[str]
    tool_result: str
    answer: str
    trace: list[str]


class HandoffState(TypedDict, total=False):
    tasks: list[str]
    messages: Annotated[list[str], operator.add]
    task: str
    final: str


class ApprovalState(TypedDict, total=False):
    approved: bool
    draft: str
    final: str


class LongGraphState(TypedDict, total=False):
    value: int
    trace: Annotated[list[str], operator.add]


def _linear_node_names(count: int = 32) -> tuple[str, ...]:
    return tuple(f"step_{index:02d}" for index in range(count))


def _agent_input(iteration: int) -> dict[str, str]:
    mode = iteration % 3
    if mode == 0:
        question = "Need docs for durable checkpoint policy and proof receipt."
    elif mode == 1:
        question = "Ask tool permission scope before running sandbox command."
    else:
        question = "Escalate a risky patch to a reviewer for approval."
    return {"session_id": f"session-{iteration % 64}", "question": question}


def _classify(question: str) -> str:
    lower = question.lower()
    if "docs" in lower or "checkpoint" in lower or "proof" in lower:
        return "rag"
    if "tool" in lower or "sandbox" in lower or "permission" in lower:
        return "tool"
    return "handoff"


def _checksum(value: Any) -> int:
    if value is None:
        return 0
    if isinstance(value, Mapping):
        total = 17
        for key in sorted(value.keys(), key=str):
            total = (total * 131 + len(str(key)) + _checksum(value[key])) % 1_000_003
        return total
    if isinstance(value, (list, tuple)):
        total = 19
        for item in value:
            total = (total * 131 + _checksum(item)) % 1_000_003
        return total
    return len(str(value)) % 1_000_003


def _percentile(sorted_values: Sequence[float], percentile: float) -> float:
    if not sorted_values:
        return 0.0
    if len(sorted_values) == 1:
        return sorted_values[0]
    rank = (len(sorted_values) - 1) * percentile
    lower = int(rank)
    upper = min(lower + 1, len(sorted_values) - 1)
    weight = rank - lower
    return sorted_values[lower] * (1.0 - weight) + sorted_values[upper] * weight


def _run_case(
    case: BenchmarkCase,
    *,
    iterations: int,
    warmup: int,
    keep_gc: bool,
) -> BenchmarkResult | BenchmarkFailure:
    try:
        subject = case.make_subject()
    except Exception as exc:
        return _failure(case, "setup", exc)

    try:
        for index in range(warmup):
            subject(index)
    except Exception as exc:
        return _failure(case, "warmup", exc)

    durations_us: list[float] = []
    checksum = 0
    was_gc_enabled = gc.isenabled()
    if not keep_gc:
        gc.disable()
    try:
        for index in range(iterations):
            started = time.perf_counter_ns()
            value = subject(index)
            ended = time.perf_counter_ns()
            durations_us.append((ended - started) / 1000.0)
            checksum = (checksum + _checksum(value)) % 1_000_003
    except Exception as exc:
        return _failure(case, "measure", exc)
    finally:
        if was_gc_enabled and not keep_gc:
            gc.enable()

    ordered = sorted(durations_us)
    mean_us = statistics.fmean(durations_us) if durations_us else 0.0
    return BenchmarkResult(
        name=case.name,
        family=case.family,
        description=case.description,
        features=case.features,
        iterations=iterations,
        warmup=warmup,
        mean_us=mean_us,
        p50_us=_percentile(ordered, 0.50),
        p95_us=_percentile(ordered, 0.95),
        min_us=min(durations_us) if durations_us else 0.0,
        max_us=max(durations_us) if durations_us else 0.0,
        ops_per_second=(1_000_000.0 / mean_us) if mean_us else 0.0,
        checksum=checksum,
    )


def _failure(case: BenchmarkCase, phase: str, exc: Exception) -> BenchmarkFailure:
    return BenchmarkFailure(
        name=case.name,
        family=case.family,
        description=case.description,
        features=case.features,
        phase=phase,
        error_type=type(exc).__name__,
        error=str(exc),
    )


def make_langchain_linear_agent() -> Subject:
    from langchain_core.output_parsers import JsonOutputParser
    from langchain_core.prompts import ChatPromptTemplate
    from langchain_core.runnables import RunnableLambda

    prompt = ChatPromptTemplate.from_messages(
        [
            (
                "system",
                "You are a deterministic policy model for agent flow routing.",
            ),
            ("human", "session={session_id}\nquestion={question}"),
        ]
    )
    parser = JsonOutputParser()

    def policy_model(prompt_value: Any) -> str:
        text = prompt_value.to_string()
        intent = _classify(text)
        payload = {
            "intent": intent,
            "next": "retrieve" if intent == "rag" else "tool" if intent == "tool" else "review",
            "confidence": 0.91,
        }
        return json.dumps(payload, separators=(",", ":"))

    def attach_observation(parsed: Mapping[str, Any]) -> dict[str, Any]:
        intent = str(parsed["intent"])
        return {
            "intent": intent,
            "observation": f"{intent}-observation",
            "answer": f"final:{parsed['next']}:{intent}",
        }

    chain = prompt | RunnableLambda(policy_model) | parser | RunnableLambda(attach_observation)

    def subject(iteration: int) -> Any:
        return chain.invoke(_agent_input(iteration))

    return subject


def make_langchain_branch_agent() -> Subject:
    from langchain_core.runnables import RunnableBranch, RunnableLambda

    def classify(payload: Mapping[str, str]) -> dict[str, Any]:
        intent = _classify(payload["question"])
        return {"intent": intent, "session_id": payload["session_id"], "question": payload["question"]}

    def rag_branch(state: Mapping[str, Any]) -> dict[str, Any]:
        return {
            "intent": state["intent"],
            "documents": ["policy-proof.org", "checkpoint-contract.org"],
            "answer": "rag:proof-docs",
        }

    def tool_branch(state: Mapping[str, Any]) -> dict[str, Any]:
        return {
            "intent": state["intent"],
            "tool_result": "sandbox-scope:read-only",
            "answer": "tool:permission-reviewed",
        }

    def handoff_branch(state: Mapping[str, Any]) -> dict[str, Any]:
        return {
            "intent": state["intent"],
            "reviewer": "human-review",
            "answer": "handoff:approval-required",
        }

    branch = RunnableBranch(
        (lambda state: state["intent"] == "rag", RunnableLambda(rag_branch)),
        (lambda state: state["intent"] == "tool", RunnableLambda(tool_branch)),
        RunnableLambda(handoff_branch),
    )
    chain = RunnableLambda(classify) | branch

    def subject(iteration: int) -> Any:
        return chain.invoke(_agent_input(iteration))

    return subject


def make_langgraph_router_agent() -> Subject:
    from langgraph.graph import END, START, StateGraph

    def classify(state: AgentRouterState) -> AgentRouterState:
        trace = [*state.get("trace", ()), "classify"]
        return {"intent": _classify(state["question"]), "trace": trace}

    def route(state: AgentRouterState) -> str:
        return state["intent"]

    def retrieve(state: AgentRouterState) -> AgentRouterState:
        trace = [*state.get("trace", ()), "retrieve"]
        return {"documents": ["policy-proof.org", "checkpoint-contract.org"], "trace": trace}

    def tool(state: AgentRouterState) -> AgentRouterState:
        trace = [*state.get("trace", ()), "tool"]
        return {"tool_result": "sandbox-scope:read-only", "trace": trace}

    def handoff(state: AgentRouterState) -> AgentRouterState:
        trace = [*state.get("trace", ()), "handoff"]
        return {"tool_result": "reviewer:human-review", "trace": trace}

    def finalize(state: AgentRouterState) -> AgentRouterState:
        trace = [*state.get("trace", ()), "finalize"]
        if state.get("documents"):
            answer = "rag:proof-docs"
        elif state.get("intent") == "tool":
            answer = "tool:permission-reviewed"
        else:
            answer = "handoff:approval-required"
        return {"answer": answer, "trace": trace}

    graph = StateGraph(AgentRouterState)
    graph.add_node("classify", classify)
    graph.add_node("retrieve", retrieve)
    graph.add_node("tool", tool)
    graph.add_node("handoff", handoff)
    graph.add_node("finalize", finalize)
    graph.add_edge(START, "classify")
    graph.add_conditional_edges(
        "classify",
        route,
        {"rag": "retrieve", "tool": "tool", "handoff": "handoff"},
    )
    graph.add_edge("retrieve", "finalize")
    graph.add_edge("tool", "finalize")
    graph.add_edge("handoff", "finalize")
    graph.add_edge("finalize", END)
    app = graph.compile()

    def subject(iteration: int) -> Any:
        return app.invoke({**_agent_input(iteration), "trace": []})

    return subject


def make_langgraph_handoff_reducer() -> Subject:
    from langgraph.graph import END, START, StateGraph
    from langgraph.types import Send

    def supervisor(state: HandoffState) -> HandoffState:
        return {
            "tasks": ["retrieve-context", "review-policy", "check-sandbox"],
            "messages": ["supervisor:assigned"],
        }

    def dispatch(state: HandoffState):
        return [
            Send("worker", {"task": task, "messages": []})
            for task in state["tasks"]
        ]

    def worker(state: HandoffState) -> HandoffState:
        return {"messages": [f"worker:{state['task']}"]}

    def join(state: HandoffState) -> HandoffState:
        return {"final": "|".join(state["messages"])}

    graph = StateGraph(HandoffState)
    graph.add_node("supervisor", supervisor)
    graph.add_node("worker", worker)
    graph.add_node("join", join)
    graph.add_edge(START, "supervisor")
    graph.add_conditional_edges("supervisor", dispatch, ["worker"])
    graph.add_edge("worker", "join")
    graph.add_edge("join", END)
    app = graph.compile()

    def subject(iteration: int) -> Any:
        return app.invoke({"tasks": [], "messages": [], "final": ""})

    return subject


def make_langgraph_interrupt_resume() -> Subject:
    from langgraph.checkpoint.memory import InMemorySaver
    from langgraph.graph import END, START, StateGraph
    from langgraph.types import Command, interrupt

    def draft(state: ApprovalState) -> ApprovalState:
        return {"draft": "ship-policy-change"}

    def approve(state: ApprovalState) -> ApprovalState:
        decision = interrupt({"draft": state["draft"], "kind": "approval"})
        return {"approved": bool(decision.get("approved"))}

    def finalize(state: ApprovalState) -> ApprovalState:
        return {"final": "released" if state.get("approved") else "blocked"}

    graph = StateGraph(ApprovalState)
    graph.add_node("draft", draft)
    graph.add_node("approve", approve)
    graph.add_node("finalize", finalize)
    graph.add_edge(START, "draft")
    graph.add_edge("draft", "approve")
    graph.add_edge("approve", "finalize")
    graph.add_edge("finalize", END)
    app = graph.compile(checkpointer=InMemorySaver())

    def subject(iteration: int) -> Any:
        config = {"configurable": {"thread_id": f"approval-{iteration}"}}
        first = app.invoke(
            {"approved": False, "draft": "", "final": ""},
            config=config,
        )
        if "__interrupt__" not in first:
            raise RuntimeError("expected LangGraph interrupt")
        return app.invoke(Command(resume={"approved": True}), config=config)

    return subject


def make_langgraph_long_graph() -> Subject:
    from langgraph.graph import END, START, StateGraph

    graph = StateGraph(LongGraphState)
    nodes = _linear_node_names()

    for name in nodes:
        def node(state: LongGraphState, node_name: str = name) -> LongGraphState:
            return {
                "value": int(state.get("value", 0)) + 1,
                "trace": [node_name],
            }

        graph.add_node(name, node)

    graph.add_edge(START, nodes[0])
    for left, right in zip(nodes, nodes[1:]):
        graph.add_edge(left, right)
    graph.add_edge(nodes[-1], END)
    app = graph.compile()

    def subject(iteration: int) -> Any:
        return app.invoke({"value": iteration, "trace": []})

    return subject


def make_langgraph_router_stream() -> Subject:
    from langgraph.graph import END, START, StateGraph

    def classify(state: AgentRouterState) -> AgentRouterState:
        return {"intent": _classify(state["question"]), "trace": ["classify"]}

    def route(state: AgentRouterState) -> str:
        return state["intent"]

    def retrieve(state: AgentRouterState) -> AgentRouterState:
        return {"documents": ["policy-proof.org"], "trace": ["retrieve"]}

    def tool(state: AgentRouterState) -> AgentRouterState:
        return {"tool_result": "sandbox-scope:read-only", "trace": ["tool"]}

    def handoff(state: AgentRouterState) -> AgentRouterState:
        return {"tool_result": "reviewer:human-review", "trace": ["handoff"]}

    def finalize(state: AgentRouterState) -> AgentRouterState:
        return {"answer": state.get("intent", "unknown"), "trace": ["finalize"]}

    graph = StateGraph(AgentRouterState)
    graph.add_node("classify", classify)
    graph.add_node("retrieve", retrieve)
    graph.add_node("tool", tool)
    graph.add_node("handoff", handoff)
    graph.add_node("finalize", finalize)
    graph.add_edge(START, "classify")
    graph.add_conditional_edges(
        "classify",
        route,
        {"rag": "retrieve", "tool": "tool", "handoff": "handoff"},
    )
    graph.add_edge("retrieve", "finalize")
    graph.add_edge("tool", "finalize")
    graph.add_edge("handoff", "finalize")
    graph.add_edge("finalize", END)
    app = graph.compile()

    def subject(iteration: int) -> Any:
        return tuple(app.stream({**_agent_input(iteration), "trace": []}, stream_mode="updates"))

    return subject


def make_poo_executor_router_agent() -> Subject:
    from poo_flow_runtime.runtime_graph import (
        END,
        START,
        RuntimeGraphConditionalEdge,
        RuntimeGraphEdge,
        RuntimeGraphExecutor,
        RuntimeGraphPlan,
    )

    def classify(state: Mapping[str, Any]) -> dict[str, Any]:
        return {
            "intent": _classify(str(state["question"])),
            "trace": [*state.get("trace", ()), "classify"],
        }

    def route(state: Mapping[str, Any]) -> str:
        return str(state["intent"])

    def retrieve(state: Mapping[str, Any]) -> dict[str, Any]:
        return {
            "documents": ["policy-proof.org", "checkpoint-contract.org"],
            "trace": [*state.get("trace", ()), "retrieve"],
        }

    def tool(state: Mapping[str, Any]) -> dict[str, Any]:
        return {
            "tool_result": "sandbox-scope:read-only",
            "trace": [*state.get("trace", ()), "tool"],
        }

    def handoff(state: Mapping[str, Any]) -> dict[str, Any]:
        return {
            "tool_result": "reviewer:human-review",
            "trace": [*state.get("trace", ()), "handoff"],
        }

    def finalize(state: Mapping[str, Any]) -> dict[str, Any]:
        if state.get("documents"):
            answer = "rag:proof-docs"
        elif state.get("intent") == "tool":
            answer = "tool:permission-reviewed"
        else:
            answer = "handoff:approval-required"
        return {"answer": answer, "trace": [*state.get("trace", ()), "finalize"]}

    plan = RuntimeGraphPlan(
        nodes=("classify", "retrieve", "tool", "handoff", "finalize"),
        edges=(
            RuntimeGraphEdge(START, "classify"),
            RuntimeGraphEdge("retrieve", "finalize"),
            RuntimeGraphEdge("tool", "finalize"),
            RuntimeGraphEdge("handoff", "finalize"),
            RuntimeGraphEdge("finalize", END),
        ),
        conditional_edges=(
            RuntimeGraphConditionalEdge(
                "classify",
                "intent-router",
                {"rag": "retrieve", "tool": "tool", "handoff": "handoff"},
            ),
        ),
        step_limit=20,
    )
    executor = RuntimeGraphExecutor(
        plan,
        {
            "classify": classify,
            "retrieve": retrieve,
            "tool": tool,
            "handoff": handoff,
            "finalize": finalize,
        },
        routers={"intent-router": route},
    )

    def subject(iteration: int) -> Any:
        state, trace = executor.invoke_with_trace({**_agent_input(iteration), "trace": []})
        return {"state": state, "trace": trace}

    return subject


def make_poo_executor_handoff_reducer() -> Subject:
    from poo_flow_runtime.runtime_graph import (
        END,
        START,
        RuntimeGraphEdge,
        RuntimeGraphExecutor,
        RuntimeGraphPlan,
        RuntimeGraphSend,
    )

    def supervisor(state: Mapping[str, Any]) -> list[Any]:
        return [
            RuntimeGraphSend("worker", {"task": task})
            for task in ("retrieve-context", "review-policy", "check-sandbox")
        ]

    def worker(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"messages": [f"worker:{state['task']}"]}

    def join(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"final": "|".join(state.get("messages", ()))}

    def append_values(left: Any, right: Any) -> list[Any]:
        return list(left or []) + list(right or [])

    plan = RuntimeGraphPlan(
        nodes=("supervisor", "worker", "join"),
        edges=(
            RuntimeGraphEdge(START, "supervisor"),
            RuntimeGraphEdge("supervisor", "worker"),
            RuntimeGraphEdge("worker", "join"),
            RuntimeGraphEdge("join", END),
        ),
        step_limit=20,
    )
    executor = RuntimeGraphExecutor(
        plan,
        {"supervisor": supervisor, "worker": worker, "join": join},
        reducers={"messages": append_values},
    )

    def subject(iteration: int) -> Any:
        state, trace = executor.invoke_with_trace({"messages": [], "final": ""})
        return {"state": state, "trace": trace}

    return subject


def make_poo_executor_interrupt_resume() -> Subject:
    from poo_flow_runtime.runtime_graph import (
        END,
        START,
        RuntimeGraphEdge,
        RuntimeGraphExecutor,
        RuntimeGraphInterrupt,
        RuntimeGraphInterrupted,
        RuntimeGraphPlan,
    )

    def draft(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"draft": "ship-policy-change"}

    def approve(state: Mapping[str, Any]) -> RuntimeGraphInterrupt:
        return RuntimeGraphInterrupt({"draft": state["draft"], "kind": "approval"})

    def finalize(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"final": "released" if state.get("approved") else "blocked"}

    plan = RuntimeGraphPlan(
        nodes=("draft", "approve", "finalize"),
        edges=(
            RuntimeGraphEdge(START, "draft"),
            RuntimeGraphEdge("draft", "approve"),
            RuntimeGraphEdge("approve", "finalize"),
            RuntimeGraphEdge("finalize", END),
        ),
        step_limit=20,
    )
    executor = RuntimeGraphExecutor(
        plan,
        {"draft": draft, "approve": approve, "finalize": finalize},
    )

    def subject(iteration: int) -> Any:
        try:
            executor.invoke_with_trace({"approved": False, "draft": "", "final": ""})
        except RuntimeGraphInterrupted as interrupted:
            state, trace, events = executor.resume_interrupted(
                interrupted,
                {"approved": True},
            )
            return {"state": state, "trace": trace, "events": tuple(e.kind for e in events)}
        raise RuntimeError("expected POO executor interrupt")

    return subject


def make_poo_executor_long_graph() -> Subject:
    from poo_flow_runtime.runtime_graph import (
        END,
        START,
        RuntimeGraphEdge,
        RuntimeGraphExecutor,
        RuntimeGraphPlan,
    )

    nodes = _linear_node_names()
    actions = {
        node: (lambda state, node_name=node: {"value": int(state.get("value", 0)) + 1})
        for node in nodes
    }
    edges = [RuntimeGraphEdge(START, nodes[0])]
    edges.extend(RuntimeGraphEdge(left, right) for left, right in zip(nodes, nodes[1:]))
    edges.append(RuntimeGraphEdge(nodes[-1], END))
    executor = RuntimeGraphExecutor(
        RuntimeGraphPlan(nodes=nodes, edges=tuple(edges), step_limit=64),
        actions,
    )

    def subject(iteration: int) -> Any:
        state, trace = executor.invoke_with_trace({"value": iteration})
        return {"state": state, "trace": trace}

    return subject


def make_poo_executor_router_stream_events() -> Subject:
    from poo_flow_runtime.runtime_graph import (
        END,
        START,
        RuntimeGraphConditionalEdge,
        RuntimeGraphEdge,
        RuntimeGraphExecutor,
        RuntimeGraphPlan,
    )

    def classify(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"intent": _classify(str(state["question"]))}

    def route(state: Mapping[str, Any]) -> str:
        return str(state["intent"])

    def retrieve(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"answer": "rag:proof-docs"}

    def tool(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"answer": "tool:permission-reviewed"}

    def handoff(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"answer": "handoff:approval-required"}

    plan = RuntimeGraphPlan(
        nodes=("classify", "retrieve", "tool", "handoff"),
        edges=(
            RuntimeGraphEdge(START, "classify"),
            RuntimeGraphEdge("retrieve", END),
            RuntimeGraphEdge("tool", END),
            RuntimeGraphEdge("handoff", END),
        ),
        conditional_edges=(
            RuntimeGraphConditionalEdge(
                "classify",
                "intent-router",
                {"rag": "retrieve", "tool": "tool", "handoff": "handoff"},
            ),
        ),
        step_limit=20,
    )
    executor = RuntimeGraphExecutor(
        plan,
        {
            "classify": classify,
            "retrieve": retrieve,
            "tool": tool,
            "handoff": handoff,
        },
        routers={"intent-router": route},
    )

    def subject(iteration: int) -> Any:
        return tuple(
            (event.kind, event.node)
            for event in executor.stream_events(_agent_input(iteration))
        )

    return subject


def make_poo_cabi_describe_linear() -> Subject:
    from poo_flow_runtime import PooFlowRuntimeBinding

    binding = PooFlowRuntimeBinding.from_probe()

    def subject(iteration: int) -> Any:
        graph_plan = binding.graph_plan()
        try:
            graph_plan.set_step_limit(20)
            for node in ("classify", "retrieve", "finalize"):
                graph_plan.add_node(node)
                graph_plan.set_node_action(node, node)
            graph_plan.add_edge("__start__", "classify")
            graph_plan.add_edge("classify", "retrieve")
            graph_plan.add_edge("retrieve", "finalize")
            graph_plan.add_edge("finalize", "__end__")
            return graph_plan.describe()
        finally:
            graph_plan.close()

    return subject


def make_poo_cabi_describe_long_graph() -> Subject:
    from poo_flow_runtime import PooFlowRuntimeBinding

    binding = PooFlowRuntimeBinding.from_probe()
    nodes = _linear_node_names()

    def subject(iteration: int) -> Any:
        graph_plan = binding.graph_plan()
        try:
            graph_plan.set_step_limit(64)
            for node in nodes:
                graph_plan.add_node(node)
                graph_plan.set_node_action(node, node)
            graph_plan.add_edge("__start__", nodes[0])
            for left, right in zip(nodes, nodes[1:]):
                graph_plan.add_edge(left, right)
            graph_plan.add_edge(nodes[-1], "__end__")
            return graph_plan.describe()
        finally:
            graph_plan.close()

    return subject


def make_poo_cabi_program_long_graph() -> Subject:
    from poo_flow_runtime import RuntimeGraphProgram, RuntimeGraphRegistries
    from poo_flow_runtime.runtime_graph import END, START, RuntimeGraphEdge, RuntimeGraphPlan

    nodes = _linear_node_names()
    actions = {
        node: (lambda state, node_name=node: {"value": int(state.get("value", 0)) + 1})
        for node in nodes
    }
    edges = [RuntimeGraphEdge(START, nodes[0])]
    edges.extend(RuntimeGraphEdge(left, right) for left, right in zip(nodes, nodes[1:]))
    edges.append(RuntimeGraphEdge(nodes[-1], END))
    program = RuntimeGraphProgram(
        plan=RuntimeGraphPlan(nodes=nodes, edges=tuple(edges), step_limit=64),
        registries=RuntimeGraphRegistries(actions=actions),
    )

    def subject(iteration: int) -> Any:
        return program.invoke({"value": iteration})

    return subject


def make_poo_cabi_program_router() -> Subject:
    from poo_flow_runtime import RuntimeGraphProgram, RuntimeGraphRegistries
    from poo_flow_runtime.materialization import RuntimeGraphBindings
    from poo_flow_runtime.runtime_graph import (
        END,
        START,
        RuntimeGraphConditionalEdge,
        RuntimeGraphEdge,
        RuntimeGraphPlan,
    )

    def classify(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"intent": _classify(str(state["question"]))}

    def route(state: Mapping[str, Any]) -> str:
        return str(state["intent"])

    def retrieve(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"answer": "rag:proof-docs"}

    def tool(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"answer": "tool:permission-reviewed"}

    def handoff(state: Mapping[str, Any]) -> dict[str, Any]:
        return {"answer": "handoff:approval-required"}

    plan = RuntimeGraphPlan(
        nodes=("classify", "retrieve", "tool", "handoff"),
        edges=(
            RuntimeGraphEdge(START, "classify"),
            RuntimeGraphEdge("retrieve", END),
            RuntimeGraphEdge("tool", END),
            RuntimeGraphEdge("handoff", END),
        ),
        conditional_edges=(
            RuntimeGraphConditionalEdge(
                "classify",
                "intent-router",
                {"rag": "retrieve", "tool": "tool", "handoff": "handoff"},
            ),
        ),
        step_limit=20,
    )
    program = RuntimeGraphProgram(
        plan=plan,
        graph_bindings=RuntimeGraphBindings(
            node_actions={node: node for node in plan.nodes},
        ),
        registries=RuntimeGraphRegistries(
            actions={
                "classify": classify,
                "retrieve": retrieve,
                "tool": tool,
                "handoff": handoff,
            },
            routers={"intent-router": route},
        ),
    )

    def subject(iteration: int) -> Any:
        return program.invoke(_agent_input(iteration))

    return subject


def _cabi_gate(
    name: str,
    description: str,
    features: tuple[str, ...],
    build: Callable[[Any], None],
) -> GateCheck:
    from poo_flow_runtime import PooFlowRuntimeBinding

    binding = PooFlowRuntimeBinding.from_probe()
    graph_plan = binding.graph_plan()
    try:
        graph_plan.set_step_limit(20)
        build(graph_plan)
        receipt = graph_plan.describe().decode("utf-8", errors="replace").strip()
        try:
            graph_plan.validate()
        except Exception as exc:
            return GateCheck(
                name=name,
                family="poo-flow-cabi-gate",
                description=description,
                features=features,
                status="failed",
                receipt=receipt,
                error_type=type(exc).__name__,
                error=str(exc),
            )
        return GateCheck(
            name=name,
            family="poo-flow-cabi-gate",
            description=description,
            features=features,
            status="passed",
            receipt=receipt,
        )
    except Exception as exc:
        return GateCheck(
            name=name,
            family="poo-flow-cabi-gate",
            description=description,
            features=features,
            status="setup-failed",
            error_type=type(exc).__name__,
            error=str(exc),
        )
    finally:
        graph_plan.close()


def cabi_gates() -> tuple[GateCheck, ...]:
    def linear(graph_plan: Any) -> None:
        for node in ("classify", "retrieve", "finalize"):
            graph_plan.add_node(node)
            graph_plan.set_node_action(node, node)
        graph_plan.add_edge("__start__", "classify")
        graph_plan.add_edge("classify", "retrieve")
        graph_plan.add_edge("retrieve", "finalize")
        graph_plan.add_edge("finalize", "__end__")

    def conditional(graph_plan: Any) -> None:
        for node in ("classify", "retrieve", "tool", "handoff"):
            graph_plan.add_node(node)
            graph_plan.set_node_action(node, node)
        graph_plan.add_edge("__start__", "classify")
        for route, target in (("rag", "retrieve"), ("tool", "tool"), ("handoff", "handoff")):
            graph_plan.add_conditional_route(
                source="classify",
                router="intent-router",
                route_key=route,
                target=target,
            )
            graph_plan.add_edge(target, "__end__")

    def reducer(graph_plan: Any) -> None:
        for node in ("supervisor", "worker", "join"):
            graph_plan.add_node(node)
            graph_plan.set_node_action(node, node)
        graph_plan.set_state_reducer("messages", "messages-append")
        graph_plan.add_edge("__start__", "supervisor")
        graph_plan.add_edge("supervisor", "worker")
        graph_plan.add_edge("worker", "join")
        graph_plan.add_edge("join", "__end__")

    def long_graph(graph_plan: Any) -> None:
        nodes = _linear_node_names()
        for node in nodes:
            graph_plan.add_node(node)
            graph_plan.set_node_action(node, node)
        graph_plan.add_edge("__start__", nodes[0])
        for left, right in zip(nodes, nodes[1:]):
            graph_plan.add_edge(left, right)
        graph_plan.add_edge(nodes[-1], "__end__")

    return (
        _cabi_gate(
            "poo-flow-cabi-linear-validate",
            "C ABI validate gate for a linear agent graph.",
            ("c-abi", "validate", "linear-graph"),
            linear,
        ),
        _cabi_gate(
            "poo-flow-cabi-conditional-validate",
            "C ABI validate gate for conditional policy routing.",
            ("c-abi", "validate", "conditional-edge", "policy-router"),
            conditional,
        ),
        _cabi_gate(
            "poo-flow-cabi-reducer-validate",
            "C ABI validate gate for reducer-backed handoff state.",
            ("c-abi", "validate", "reducer", "handoff"),
            reducer,
        ),
        _cabi_gate(
            "poo-flow-cabi-long-graph-validate",
            "C ABI validate gate for a 32-node long graph.",
            ("c-abi", "validate", "long-graph", "scale"),
            long_graph,
        ),
    )


def benchmark_cases() -> tuple[BenchmarkCase, ...]:
    return (
        BenchmarkCase(
            "langchain-linear-agent-native",
            "langchain-native",
            "Prompt -> deterministic policy model -> JSON parser -> observation attachment.",
            ("prompt-template", "output-parser", "runnable-sequence", "agent-policy"),
            make_langchain_linear_agent,
            max_iterations=1000,
        ),
        BenchmarkCase(
            "langchain-branch-tool-native",
            "langchain-native",
            "Classifier -> RunnableBranch for RAG/tool/handoff routing.",
            ("runnable-branch", "policy-router", "tool-selection", "handoff-route"),
            make_langchain_branch_agent,
            max_iterations=1000,
        ),
        BenchmarkCase(
            "langgraph-router-agent-native",
            "langgraph-native",
            "StateGraph with conditional edges for RAG/tool/handoff routes.",
            ("state-graph", "conditional-edge", "policy-router", "agent-state"),
            make_langgraph_router_agent,
            max_iterations=200,
        ),
        BenchmarkCase(
            "langgraph-handoff-reducer-native",
            "langgraph-native",
            "StateGraph dynamic Send fanout plus reducer aggregation.",
            ("state-graph", "send", "multi-agent-handoff", "reducer"),
            make_langgraph_handoff_reducer,
            max_iterations=200,
        ),
        BenchmarkCase(
            "langgraph-interrupt-resume-native",
            "langgraph-native",
            "StateGraph interrupt/resume through an in-memory checkpointer.",
            ("interrupt", "resume", "checkpoint", "human-in-loop"),
            make_langgraph_interrupt_resume,
            max_iterations=100,
        ),
        BenchmarkCase(
            "langgraph-long-graph-native",
            "langgraph-native",
            "StateGraph 32-node linear graph for long-chain orchestration cost.",
            ("state-graph", "long-graph", "scale", "linear-graph"),
            make_langgraph_long_graph,
            max_iterations=100,
        ),
        BenchmarkCase(
            "langgraph-router-stream-native",
            "langgraph-native",
            "StateGraph conditional router consumed through stream updates.",
            ("state-graph", "stream", "events", "conditional-edge"),
            make_langgraph_router_stream,
            max_iterations=200,
        ),
        BenchmarkCase(
            "poo-flow-executor-router-agent",
            "poo-flow-executor",
            "POO runtime graph executor with conditional policy routing, without C ABI validation.",
            ("runtime-graph", "conditional-edge", "policy-router", "executor-only"),
            make_poo_executor_router_agent,
        ),
        BenchmarkCase(
            "poo-flow-executor-handoff-reducer",
            "poo-flow-executor",
            "POO runtime graph executor with RuntimeGraphSend fanout and reducer aggregation.",
            ("runtime-graph", "send", "multi-agent-handoff", "reducer", "executor-only"),
            make_poo_executor_handoff_reducer,
        ),
        BenchmarkCase(
            "poo-flow-executor-interrupt-resume",
            "poo-flow-executor",
            "POO runtime graph executor interrupt/resume flow, without C ABI validation.",
            ("runtime-graph", "interrupt", "resume", "human-in-loop", "executor-only"),
            make_poo_executor_interrupt_resume,
        ),
        BenchmarkCase(
            "poo-flow-executor-long-graph",
            "poo-flow-executor",
            "POO runtime graph executor over a 32-node long graph.",
            ("runtime-graph", "long-graph", "scale", "executor-only"),
            make_poo_executor_long_graph,
        ),
        BenchmarkCase(
            "poo-flow-executor-router-stream-events",
            "poo-flow-executor",
            "POO runtime graph executor conditional router consumed through event stream.",
            ("runtime-graph", "stream", "events", "conditional-edge", "executor-only"),
            make_poo_executor_router_stream_events,
        ),
        BenchmarkCase(
            "poo-flow-cabi-describe-linear",
            "poo-flow-cabi",
            "C ABI graph handle materialization and receipt describe, with explicit close.",
            ("c-abi", "receipt", "materialization", "linear-graph"),
            make_poo_cabi_describe_linear,
        ),
        BenchmarkCase(
            "poo-flow-cabi-describe-long-graph",
            "poo-flow-cabi",
            "C ABI 32-node graph handle materialization and receipt describe.",
            ("c-abi", "receipt", "materialization", "long-graph", "scale"),
            make_poo_cabi_describe_long_graph,
            max_iterations=500,
        ),
        BenchmarkCase(
            "poo-flow-cabi-program-router",
            "poo-flow-cabi",
            "RuntimeGraphProgram invoke path with C ABI validation enabled.",
            ("c-abi", "validate", "runtime-graph-program", "policy-router"),
            make_poo_cabi_program_router,
        ),
        BenchmarkCase(
            "poo-flow-cabi-program-long-graph",
            "poo-flow-cabi",
            "RuntimeGraphProgram invoke path for a C ABI-validated 32-node graph.",
            ("c-abi", "validate", "runtime-graph-program", "long-graph", "scale"),
            make_poo_cabi_program_long_graph,
            max_iterations=200,
        ),
    )


def run_report(args: argparse.Namespace) -> Report:
    results: list[BenchmarkResult] = []
    failures: list[BenchmarkFailure] = []
    for case in benchmark_cases():
        iterations = args.iterations
        if case.max_iterations is not None and not args.no_case_caps:
            iterations = min(iterations, case.max_iterations)
        warmup = min(args.warmup, max(1, iterations // 10))
        if args.progress:
            print(
                f"[benchmark] {case.name} iterations={iterations} warmup={warmup}",
                file=sys.stderr,
                flush=True,
            )
        result = _run_case(
            case,
            iterations=iterations,
            warmup=warmup,
            keep_gc=args.keep_gc,
        )
        if isinstance(result, BenchmarkFailure):
            failures.append(result)
        else:
            results.append(result)

    gates = cabi_gates()
    return Report(
        generated_at=datetime.now(timezone.utc).isoformat(),
        command=" ".join(sys.argv),
        python=sys.version.replace("\n", " "),
        platform=platform.platform(),
        iterations=args.iterations,
        warmup=args.warmup,
        gc_enabled_during_measurement=args.keep_gc,
        case_caps_enabled=not args.no_case_caps,
        results=tuple(results),
        failures=tuple(failures),
        gates=gates,
    )


def _json_default(value: Any) -> Any:
    if hasattr(value, "__dataclass_fields__"):
        return {
            key: _json_default(getattr(value, key))
            for key in value.__dataclass_fields__.keys()
        }
    if isinstance(value, tuple):
        return list(value)
    return value


def render_json(report: Report) -> str:
    return json.dumps(_json_default(report), indent=2, sort_keys=True)


def _org_escape(value: Any) -> str:
    return str(value).replace("|", "\\vert{}").replace("\n", " ")


def _features(features: Sequence[str]) -> str:
    return ", ".join(features)


def render_org(report: Report) -> str:
    lines: list[str] = []
    lines.append("#+title: LangChain/LangGraph C ABI Benchmark Report")
    lines.append("#+startup: overview")
    lines.append("")
    lines.append("* Scope")
    lines.append("This benchmark compares native LangChain/LangGraph orchestration with the POO Flow runtime surfaces used to hand graph receipts to a runtime language.")
    lines.append("")
    lines.append("It does not measure real LLM latency, network tools, or durable storage IO. The deterministic actions model the control-plane cost of AI Agent Flow shapes: policy routing, graph edges, dynamic handoff, reducers, checkpoint interrupt/resume, long graph scale, stream/event consumption, receipt materialization, and C ABI validation gates.")
    lines.append("")
    lines.append("* Local Clone Inputs")
    lines.append("- LangChain: =../../.data/langchain/libs/core=")
    lines.append("- LangGraph: =../../.data/langgraph/libs/langgraph=")
    lines.append("- POO Flow runtime: current =packages/python-runtime= workspace")
    lines.append("")
    lines.append("* Command")
    lines.append("#+begin_src sh")
    lines.append("uv run \\")
    lines.append("  --with-editable ../../.data/langgraph/libs/langgraph \\")
    lines.append("  --with-editable ../../.data/langchain/libs/core \\")
    lines.append("  python benchmarks/bench_langchain_langgraph_cabi.py \\")
    lines.append("  --iterations 2000 \\")
    lines.append("  --warmup 200 \\")
    lines.append("  --progress \\")
    lines.append("  --format org \\")
    lines.append("  --report-org benchmarks/README.org")
    lines.append("#+end_src")
    lines.append("")
    lines.append("* Run Metadata")
    lines.append(f"- Generated at: ={report.generated_at}=")
    lines.append(f"- Command: ={_org_escape(report.command)}=")
    lines.append(f"- Python: ={_org_escape(report.python)}=")
    lines.append(f"- Platform: ={_org_escape(report.platform)}=")
    lines.append(f"- Iterations: ={report.iterations}=")
    lines.append(f"- Warmup: ={report.warmup}=")
    lines.append(f"- Per-case caps: ={str(report.case_caps_enabled).lower()}=")
    lines.append(f"- GC during measurement: ={str(report.gc_enabled_during_measurement).lower()}=")
    lines.append("")
    lines.append("* Benchmark Results")
    lines.append("| name | family | features | mean us | p50 us | p95 us | min us | max us | ops/s | checksum |")
    lines.append("|-")
    for result in sorted(report.results, key=lambda item: (item.family, item.name)):
        lines.append(
            "| {name} | {family} | {features} | {mean:.3f} | {p50:.3f} | {p95:.3f} | {min:.3f} | {max:.3f} | {ops:.2f} | {checksum} |".format(
                name=_org_escape(result.name),
                family=_org_escape(result.family),
                features=_org_escape(_features(result.features)),
                mean=result.mean_us,
                p50=result.p50_us,
                p95=result.p95_us,
                min=result.min_us,
                max=result.max_us,
                ops=result.ops_per_second,
                checksum=result.checksum,
            )
        )
    if not report.results:
        lines.append("| none | none | none | 0 | 0 | 0 | 0 | 0 | 0 | 0 |")
    lines.append("")
    lines.append("* C ABI Gates")
    lines.append("| name | status | features | error | receipt summary |")
    lines.append("|-")
    for gate in report.gates:
        receipt_summary = " ".join(
            item
            for item in gate.receipt.splitlines()
            if item.startswith(("kind=", "nodes=", "edges=", "conditional-routes=", "state-reducers=", "plan-digest="))
        )
        error = f"{gate.error_type}: {gate.error}" if gate.error else ""
        lines.append(
            "| {name} | {status} | {features} | {error} | {receipt} |".format(
                name=_org_escape(gate.name),
                status=_org_escape(gate.status),
                features=_org_escape(_features(gate.features)),
                error=_org_escape(error),
                receipt=_org_escape(receipt_summary),
            )
        )
    lines.append("")
    lines.append("* Failures")
    lines.append("| name | family | phase | features | error |")
    lines.append("|-")
    for failure in report.failures:
        lines.append(
            "| {name} | {family} | {phase} | {features} | {error_type}: {error} |".format(
                name=_org_escape(failure.name),
                family=_org_escape(failure.family),
                phase=_org_escape(failure.phase),
                features=_org_escape(_features(failure.features)),
                error_type=_org_escape(failure.error_type),
                error=_org_escape(failure.error),
            )
        )
    if not report.failures:
        lines.append("| none | none | none | none | none |")
    lines.append("")
    lines.append("* Interpretation")
    lines.append("- LangChain cases cover runnable composition, prompt/parser cost, branch routing, and tool/handoff selection.")
    lines.append("- LangGraph cases cover the production graph controls we need to compare against: conditional edges, dynamic Send fanout, reducer aggregation, checkpoint-backed interrupt/resume.")
    lines.append("- Long graph cases use a fixed 32-node linear graph to expose scale cost without introducing LLM or IO latency.")
    lines.append("- Stream cases consume framework/runtime stream outputs so the benchmark is not limited to invoke-only happy paths.")
    lines.append("- POO executor cases measure the current Python graph semantics without crossing the C ABI validation gate.")
    lines.append("- POO C ABI receipt cases measure graph handle materialization and receipt creation with explicit handle close, so the benchmark does not hide handle lifetime leaks.")
    lines.append("- POO C ABI validation failures are reported as gates and failures instead of being converted into fake performance numbers.")
    lines.append("")
    lines.append("* Current Gaps Exposed")
    if any(gate.status != "passed" for gate in report.gates):
        lines.append("- C ABI graph =describe= can produce receipts, but =validate= currently rejects basic linear/conditional/reducer graph shapes. This blocks honest RuntimeGraphProgram CABI-vs-native execution benchmarks until the ABI validator is aligned with runtime graph semantics.")
    if any(failure.family == "poo-flow-cabi" for failure in report.failures):
        lines.append("- RuntimeGraphProgram CABI execution is not counted when setup/warmup/measurement fails; the failure table is the source of truth for that gap.")
    lines.append("- The next benchmark expansion should add durable checkpoint persistence, larger graph-size sweeps, generated Scheme receipt -> Lean fact alignment, and a stable JSON artifact for CI trend comparison.")
    lines.append("")
    return "\n".join(lines)


def render_text(report: Report) -> str:
    lines = [
        f"generated_at={report.generated_at}",
        f"iterations={report.iterations} warmup={report.warmup} keep_gc={report.gc_enabled_during_measurement}",
        "",
        "BENCHMARKS",
    ]
    for result in sorted(report.results, key=lambda item: (item.family, item.name)):
        lines.append(
            f"{result.name}: mean={result.mean_us:.3f}us p50={result.p50_us:.3f}us "
            f"p95={result.p95_us:.3f}us ops/s={result.ops_per_second:.2f} features={','.join(result.features)}"
        )
    lines.append("")
    lines.append("CABI GATES")
    for gate in report.gates:
        suffix = f" {gate.error_type}: {gate.error}" if gate.error else ""
        lines.append(f"{gate.name}: {gate.status}{suffix}")
    if report.failures:
        lines.append("")
        lines.append("FAILURES")
        for failure in report.failures:
            lines.append(
                f"{failure.name}: phase={failure.phase} {failure.error_type}: {failure.error}"
            )
    return "\n".join(lines)


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iterations", type=int, default=2000)
    parser.add_argument("--warmup", type=int, default=200)
    parser.add_argument(
        "--no-case-caps",
        action="store_true",
        help="Use the global iteration count for every case, including slow scale/checkpoint cases.",
    )
    parser.add_argument(
        "--progress",
        action="store_true",
        help="Print per-case progress to stderr while the suite runs.",
    )
    parser.add_argument(
        "--format",
        choices=("text", "json", "org"),
        default="text",
        help="Output format for stdout.",
    )
    parser.add_argument(
        "--report-org",
        type=Path,
        help="Write a full Org benchmark report to this path.",
    )
    parser.add_argument(
        "--keep-gc",
        action="store_true",
        help="Leave Python GC enabled during the measured section.",
    )
    parser.add_argument(
        "--fail-on-gap",
        action="store_true",
        help="Exit non-zero when benchmark failures or C ABI gate failures are present.",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    report = run_report(args)

    if args.report_org:
        args.report_org.parent.mkdir(parents=True, exist_ok=True)
        args.report_org.write_text(render_org(report) + "\n", encoding="utf-8")

    if args.format == "json":
        print(render_json(report))
    elif args.format == "org":
        print(render_org(report))
    else:
        print(render_text(report))

    has_gap = bool(report.failures) or any(gate.status != "passed" for gate in report.gates)
    return 1 if args.fail_on_gap and has_gap else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise
    except Exception:
        traceback.print_exc()
        raise SystemExit(1)
