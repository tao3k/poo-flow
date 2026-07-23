"""Explicit semantic comparison pairs; names alone never imply equivalence."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class ComparisonSpec:
    label: str
    native_case: str
    poo_flow_case: str


COMPARISONS = (
    ComparisonSpec("LangChain branch/tool route", "langchain-branch-tool-native", "poo-flow-executor-router-agent"),
    ComparisonSpec("LangGraph router", "langgraph-router-agent-native", "poo-flow-executor-router-agent"),
    ComparisonSpec("LangGraph handoff/reducer", "langgraph-handoff-reducer-native", "poo-flow-executor-handoff-reducer"),
    ComparisonSpec("LangGraph interrupt/resume", "langgraph-interrupt-resume-native", "poo-flow-executor-interrupt-resume"),
    ComparisonSpec("LangGraph long graph", "langgraph-long-graph-native", "poo-flow-executor-long-graph"),
    ComparisonSpec("LangGraph stream/events", "langgraph-router-stream-native", "poo-flow-executor-router-stream-events"),
    ComparisonSpec("CrewAI sequential crew", "crewai-sequential-crew-native", "poo-flow-executor-crewai-sequential"),
)
