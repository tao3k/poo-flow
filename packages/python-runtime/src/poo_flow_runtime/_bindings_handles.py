"""Owned context and graph-plan handles for the runtime C ABI."""

from __future__ import annotations

import ctypes

from ._bindings_model import PooFlowBytes, payload_array, string_arg


class PooFlowContext:
    def __init__(self, binding, ctx: int) -> None:
        self._binding = binding
        self._ctx = ctx

    def __enter__(self) -> "PooFlowContext":
        return self

    def __exit__(self, exc_type: object, exc: object, tb: object) -> None:
        self.close()

    def close(self) -> None:
        if self._ctx:
            self._binding._runtime.poo_flow_context_free(self._ctx)
            self._ctx = 0

    def validate_manifest(self, manifest: bytes) -> bytes:
        payload = payload_array(manifest)
        out = PooFlowBytes()
        status = self._binding._runtime.poo_flow_validate_manifest(
            self._ctx, payload, len(manifest), ctypes.byref(out)
        )
        self._binding._raise_unless_ok(status)
        return self._binding._take_bytes(out)

    def plan_runtime_handoff(self, request: bytes) -> bytes:
        payload = payload_array(request)
        out = PooFlowBytes()
        status = self._binding._runtime.poo_flow_plan_runtime_handoff(
            self._ctx, payload, len(request), ctypes.byref(out)
        )
        self._binding._raise_unless_ok(status)
        return self._binding._take_bytes(out)

    def plan_runtime_graph_handoff(self, graph_plan: "PooFlowGraphPlan", request: bytes) -> bytes:
        payload = payload_array(request)
        out = PooFlowBytes()
        status = self._binding._runtime.poo_flow_plan_runtime_graph_handoff(
            self._ctx, graph_plan._plan, payload, len(request), ctypes.byref(out)
        )
        self._binding._raise_unless_ok(status)
        return self._binding._take_bytes(out)


class PooFlowGraphPlan:
    def __init__(self, binding, plan: int) -> None:
        self._binding = binding
        self._plan = plan

    def __enter__(self) -> "PooFlowGraphPlan":
        return self

    def __exit__(self, exc_type: object, exc: object, tb: object) -> None:
        self.close()

    def close(self) -> None:
        if self._plan:
            self._binding._runtime.poo_flow_graph_plan_free(self._plan)
            self._plan = 0

    def set_step_limit(self, step_limit: int) -> None:
        status = self._binding._runtime.poo_flow_graph_plan_set_step_limit(
            self._plan, step_limit
        )
        self._binding._raise_unless_ok(status)

    def add_node(self, node: str) -> None:
        self._call_string("poo_flow_graph_plan_add_node", node)

    def set_node_action(self, node: str, action: str) -> None:
        self._call_string("poo_flow_graph_plan_set_node_action", node, action)

    def set_state_reducer(self, state_key: str, reducer: str) -> None:
        self._call_string("poo_flow_graph_plan_set_state_reducer", state_key, reducer)

    def add_edge(self, source: str, target: str) -> None:
        self._call_string("poo_flow_graph_plan_add_edge", source, target)

    def add_conditional_route(
        self, *, source: str, router: str, route_key: str, target: str
    ) -> None:
        self._call_string(
            "poo_flow_graph_plan_add_conditional_route",
            source,
            router,
            route_key,
            target,
        )

    def describe(self) -> bytes:
        return self._take_output("poo_flow_graph_plan_describe")

    def validate(self) -> bytes:
        return self._take_output("poo_flow_graph_plan_validate")

    def _call_string(self, name: str, *args: str) -> None:
        status = getattr(self._binding._runtime, name)(
            self._plan, *(string_arg(arg) for arg in args)
        )
        self._binding._raise_unless_ok(status)

    def _take_output(self, name: str) -> bytes:
        out = PooFlowBytes()
        status = getattr(self._binding._runtime, name)(self._plan, ctypes.byref(out))
        self._binding._raise_unless_ok(status)
        return self._binding._take_bytes(out)
