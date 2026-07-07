"""CFFI runtime ABI backend loaded from the canonical C header."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from cffi import FFI

from ._bindings_build import compile_probe, default_package_root, default_workspace_root
from ._bindings_model import PooFlowRuntimeError, Status


class PooFlowRuntimeCffiBinding:
    def __init__(self, library_path: Path, *, workspace_root: Path | None = None) -> None:
        workspace = workspace_root or default_workspace_root()
        self._ffi = FFI()
        self._ffi.cdef(_runtime_cdef(workspace))
        self._runtime = self._ffi.dlopen(str(library_path))

    @classmethod
    def from_probe(
        cls,
        *,
        package_root: Path | None = None,
        workspace_root: Path | None = None,
        force_rebuild: bool = False,
    ) -> "PooFlowRuntimeCffiBinding":
        package = package_root or default_package_root()
        workspace = workspace_root or default_workspace_root()
        return cls(
            compile_probe(package, workspace, force_rebuild=force_rebuild),
            workspace_root=workspace,
        )

    def context(self) -> "PooFlowCffiContext":
        ctx = self._runtime.poo_flow_context_new()
        if ctx == self._ffi.NULL:
            raise PooFlowRuntimeError(
                Status.INTERNAL_ERROR, self.status_name(Status.INTERNAL_ERROR)
            )
        return PooFlowCffiContext(self, ctx)

    def graph_plan(self) -> "PooFlowCffiGraphPlan":
        plan = self._runtime.poo_flow_graph_plan_new()
        if plan == self._ffi.NULL:
            raise PooFlowRuntimeError(
                Status.INTERNAL_ERROR, self.status_name(Status.INTERNAL_ERROR)
            )
        return PooFlowCffiGraphPlan(self, plan)

    def status_name(self, status: int) -> str:
        return self._ffi.string(self._runtime.poo_flow_status_name(status)).decode(
            "utf-8"
        )

    def raise_unless_ok(self, status: int) -> None:
        if status != Status.OK:
            raise PooFlowRuntimeError(status, self.status_name(status))

    def take_bytes(self, value: Any) -> bytes:
        try:
            return bytes(self._ffi.buffer(value.ptr, value.len))
        finally:
            self._runtime.poo_flow_bytes_free(value)

    def bytes_arg(self, payload: bytes) -> Any:
        return self._ffi.from_buffer(payload)

    def string_arg(self, value: str) -> Any:
        return self._ffi.new("char[]", value.encode("utf-8"))

    def bytes_out(self) -> Any:
        return self._ffi.new("poo_flow_bytes_t *")


class PooFlowCffiContext:
    def __init__(self, binding: PooFlowRuntimeCffiBinding, ctx: Any) -> None:
        self._binding = binding
        self._ctx = ctx

    def __enter__(self) -> "PooFlowCffiContext":
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self.close()

    def close(self) -> None:
        if self._ctx != self._binding._ffi.NULL:
            self._binding._runtime.poo_flow_context_free(self._ctx)
            self._ctx = self._binding._ffi.NULL

    def validate_manifest(self, manifest: bytes) -> bytes:
        return self._call_bytes("poo_flow_validate_manifest", manifest)

    def plan_runtime_handoff(self, request: bytes) -> bytes:
        return self._call_bytes("poo_flow_plan_runtime_handoff", request)

    def plan_runtime_graph_handoff(
        self, graph_plan: "PooFlowCffiGraphPlan", request: bytes
    ) -> bytes:
        payload = self._binding.bytes_arg(request)
        out = self._binding.bytes_out()
        status = self._binding._runtime.poo_flow_plan_runtime_graph_handoff(
            self._ctx, graph_plan._plan, payload, len(request), out
        )
        self._binding.raise_unless_ok(status)
        return self._binding.take_bytes(out[0])

    def _call_bytes(self, name: str, payload_bytes: bytes) -> bytes:
        payload = self._binding.bytes_arg(payload_bytes)
        out = self._binding.bytes_out()
        status = getattr(self._binding._runtime, name)(
            self._ctx, payload, len(payload_bytes), out
        )
        self._binding.raise_unless_ok(status)
        return self._binding.take_bytes(out[0])


class PooFlowCffiGraphPlan:
    def __init__(self, binding: PooFlowRuntimeCffiBinding, plan: Any) -> None:
        self._binding = binding
        self._plan = plan

    def __enter__(self) -> "PooFlowCffiGraphPlan":
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        self.close()

    def close(self) -> None:
        if self._plan != self._binding._ffi.NULL:
            self._binding._runtime.poo_flow_graph_plan_free(self._plan)
            self._plan = self._binding._ffi.NULL

    def set_step_limit(self, step_limit: int) -> None:
        status = self._binding._runtime.poo_flow_graph_plan_set_step_limit(
            self._plan, step_limit
        )
        self._binding.raise_unless_ok(status)

    def add_node(self, node: str) -> None:
        self._call_string("poo_flow_graph_plan_add_node", node)

    def set_node_action(self, node: str, action: str) -> None:
        self._call_string("poo_flow_graph_plan_set_node_action", node, action)

    def set_state_reducer(self, state_key: str, reducer: str) -> None:
        self._call_string(
            "poo_flow_graph_plan_set_state_reducer", state_key, reducer
        )

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
        c_args = [self._binding.string_arg(arg) for arg in args]
        status = getattr(self._binding._runtime, name)(self._plan, *c_args)
        self._binding.raise_unless_ok(status)

    def _take_output(self, name: str) -> bytes:
        out = self._binding.bytes_out()
        status = getattr(self._binding._runtime, name)(self._plan, out)
        self._binding.raise_unless_ok(status)
        return self._binding.take_bytes(out[0])


def _runtime_cdef(workspace_root: Path) -> str:
    header = workspace_root / "bindings" / "runtime-c" / "include" / "poo_flow_runtime_abi.h"
    return "\n".join(_cdef_lines(header.read_text()))


def _cdef_lines(header: str):
    for line in header.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or stripped == 'extern "C" {':
            continue
        if stripped == "}":
            continue
        yield line


__all__ = [
    "PooFlowCffiContext",
    "PooFlowCffiGraphPlan",
    "PooFlowRuntimeCffiBinding",
]
