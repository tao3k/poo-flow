"""ctypes runtime binding object for the runtime C ABI."""

from __future__ import annotations

import ctypes
import pathlib
from typing import Self

from ._bindings_build import compile_probe, default_package_root, default_workspace_root
from ._bindings_handles import PooFlowContext, PooFlowGraphPlan
from ._bindings_model import PooFlowBytes, PooFlowRuntimeError, Status


class PooFlowRuntimeBinding:
    def __init__(self, library_path: pathlib.Path) -> None:
        self.library_path = library_path
        self._runtime = ctypes.CDLL(str(library_path))
        self._configure_runtime()

    @classmethod
    def from_probe(
        cls,
        *,
        package_root: pathlib.Path | None = None,
        workspace_root: pathlib.Path | None = None,
        force_rebuild: bool = False,
    ) -> Self:
        package = package_root or default_package_root()
        workspace = workspace_root or default_workspace_root()
        return cls(compile_probe(package, workspace, force_rebuild=force_rebuild))

    def context(self) -> PooFlowContext:
        ctx = self._runtime.poo_flow_context_new()
        if not ctx:
            raise PooFlowRuntimeError(Status.INTERNAL_ERROR, self.status_name(Status.INTERNAL_ERROR))
        return PooFlowContext(self, ctx)

    def graph_plan(self) -> PooFlowGraphPlan:
        plan = self._runtime.poo_flow_graph_plan_new()
        if not plan:
            raise PooFlowRuntimeError(Status.INTERNAL_ERROR, self.status_name(Status.INTERNAL_ERROR))
        return PooFlowGraphPlan(self, plan)

    def status_name(self, status: int) -> str:
        return self._runtime.poo_flow_status_name(int(status)).decode("utf-8")

    def _raise_unless_ok(self, status: int) -> None:
        if status != Status.OK:
            raise PooFlowRuntimeError(status, self.status_name(status))

    def _take_bytes(self, value: PooFlowBytes) -> bytes:
        try:
            if not value.ptr or value.len == 0:
                return b""
            return ctypes.string_at(value.ptr, value.len)
        finally:
            self._runtime.poo_flow_bytes_free(value)

    def _configure_runtime(self) -> None:
        self._configure_context_api()
        self._configure_manifest_api()
        self._configure_graph_plan_api()
        self._configure_bytes_api()
        self._configure_status_api()

    def _configure_context_api(self) -> None:
        self._runtime.poo_flow_context_new.argtypes = []
        self._runtime.poo_flow_context_new.restype = ctypes.c_void_p
        self._runtime.poo_flow_context_free.argtypes = [ctypes.c_void_p]
        self._runtime.poo_flow_context_free.restype = None

    def _configure_manifest_api(self) -> None:
        byte_ptr = ctypes.POINTER(ctypes.c_uint8)
        bytes_out = ctypes.POINTER(PooFlowBytes)
        self._runtime.poo_flow_validate_manifest.argtypes = [
            ctypes.c_void_p,
            byte_ptr,
            ctypes.c_size_t,
            bytes_out,
        ]
        self._runtime.poo_flow_validate_manifest.restype = ctypes.c_int
        self._runtime.poo_flow_plan_runtime_handoff.argtypes = [
            ctypes.c_void_p,
            byte_ptr,
            ctypes.c_size_t,
            bytes_out,
        ]
        self._runtime.poo_flow_plan_runtime_handoff.restype = ctypes.c_int
        self._runtime.poo_flow_plan_runtime_graph_handoff.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            byte_ptr,
            ctypes.c_size_t,
            bytes_out,
        ]
        self._runtime.poo_flow_plan_runtime_graph_handoff.restype = ctypes.c_int

    def _configure_graph_plan_api(self) -> None:
        bytes_out = ctypes.POINTER(PooFlowBytes)
        self._runtime.poo_flow_graph_plan_new.argtypes = []
        self._runtime.poo_flow_graph_plan_new.restype = ctypes.c_void_p
        self._runtime.poo_flow_graph_plan_free.argtypes = [ctypes.c_void_p]
        self._runtime.poo_flow_graph_plan_free.restype = None
        self._runtime.poo_flow_graph_plan_set_step_limit.argtypes = [
            ctypes.c_void_p,
            ctypes.c_size_t,
        ]
        self._runtime.poo_flow_graph_plan_set_step_limit.restype = ctypes.c_int
        for name, args in _GRAPH_STRING_APIS.items():
            getattr(self._runtime, name).argtypes = [ctypes.c_void_p, *args]
            getattr(self._runtime, name).restype = ctypes.c_int
        self._runtime.poo_flow_graph_plan_describe.argtypes = [ctypes.c_void_p, bytes_out]
        self._runtime.poo_flow_graph_plan_describe.restype = ctypes.c_int
        self._runtime.poo_flow_graph_plan_validate.argtypes = [ctypes.c_void_p, bytes_out]
        self._runtime.poo_flow_graph_plan_validate.restype = ctypes.c_int

    def _configure_bytes_api(self) -> None:
        self._runtime.poo_flow_bytes_free.argtypes = [PooFlowBytes]
        self._runtime.poo_flow_bytes_free.restype = None

    def _configure_status_api(self) -> None:
        self._runtime.poo_flow_status_name.argtypes = [ctypes.c_int]
        self._runtime.poo_flow_status_name.restype = ctypes.c_char_p


_GRAPH_STRING_APIS = {
    "poo_flow_graph_plan_add_node": [ctypes.c_char_p],
    "poo_flow_graph_plan_set_node_action": [ctypes.c_char_p, ctypes.c_char_p],
    "poo_flow_graph_plan_set_state_reducer": [ctypes.c_char_p, ctypes.c_char_p],
    "poo_flow_graph_plan_add_edge": [ctypes.c_char_p, ctypes.c_char_p],
    "poo_flow_graph_plan_add_conditional_route": [
        ctypes.c_char_p,
        ctypes.c_char_p,
        ctypes.c_char_p,
        ctypes.c_char_p,
    ],
}
