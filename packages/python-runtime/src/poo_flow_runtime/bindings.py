"""ctypes wrapper for the upstream POO Flow runtime C ABI."""

from __future__ import annotations

import ctypes
import os
import pathlib
import platform
import subprocess
from enum import IntEnum
from typing import Self


class Status(IntEnum):
    OK = 0
    INVALID_ARGUMENT = 1
    INVALID_MANIFEST = 2
    RUNTIME_REJECTED = 3
    INVALID_GRAPH = 4
    INTERNAL_ERROR = 255


class PooFlowRuntimeError(RuntimeError):
    def __init__(self, status: int, status_name: str) -> None:
        self.status = status
        self.status_name = status_name
        super().__init__(f"POO Flow runtime ABI returned {status_name} ({status})")


class _PooFlowBytes(ctypes.Structure):
    _fields_ = [
        ("ptr", ctypes.POINTER(ctypes.c_uint8)),
        ("len", ctypes.c_size_t),
    ]


class PooFlowRuntimeBinding:
    """Load and call the runtime C ABI."""

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
    ) -> Self:
        package_root = package_root or default_package_root()
        workspace_root = workspace_root or default_workspace_root()
        library_path = compile_probe(package_root, workspace_root)
        return cls(library_path)

    def context(self) -> "PooFlowContext":
        ctx = self._runtime.poo_flow_context_new()
        if not ctx:
            raise PooFlowRuntimeError(
                Status.INTERNAL_ERROR,
                self.status_name(Status.INTERNAL_ERROR),
            )
        return PooFlowContext(self, ctx)

    def graph_plan(self) -> "PooFlowGraphPlan":
        plan = self._runtime.poo_flow_graph_plan_new()
        if not plan:
            raise PooFlowRuntimeError(
                Status.INTERNAL_ERROR,
                self.status_name(Status.INTERNAL_ERROR),
            )
        return PooFlowGraphPlan(self, plan)

    def status_name(self, status: int) -> str:
        name = self._runtime.poo_flow_status_name(int(status))
        return name.decode("ascii", "replace")

    def _raise_unless_ok(self, status: int) -> None:
        if status == Status.OK:
            return
        raise PooFlowRuntimeError(status, self.status_name(status))

    def _take_bytes(self, value: _PooFlowBytes) -> bytes:
        try:
            if not value.ptr or value.len == 0:
                return b""
            return ctypes.string_at(value.ptr, value.len)
        finally:
            self._runtime.poo_flow_bytes_free(value)

    def _configure_runtime(self) -> None:
        runtime = self._runtime

        runtime.poo_flow_context_new.argtypes = []
        runtime.poo_flow_context_new.restype = ctypes.c_void_p

        runtime.poo_flow_context_free.argtypes = [ctypes.c_void_p]
        runtime.poo_flow_context_free.restype = None

        runtime.poo_flow_validate_manifest.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_uint8),
            ctypes.c_size_t,
            ctypes.POINTER(_PooFlowBytes),
        ]
        runtime.poo_flow_validate_manifest.restype = ctypes.c_int

        runtime.poo_flow_plan_runtime_handoff.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_uint8),
            ctypes.c_size_t,
            ctypes.POINTER(_PooFlowBytes),
        ]
        runtime.poo_flow_plan_runtime_handoff.restype = ctypes.c_int

        runtime.poo_flow_graph_plan_new.argtypes = []
        runtime.poo_flow_graph_plan_new.restype = ctypes.c_void_p

        runtime.poo_flow_graph_plan_free.argtypes = [ctypes.c_void_p]
        runtime.poo_flow_graph_plan_free.restype = None

        runtime.poo_flow_graph_plan_set_step_limit.argtypes = [
            ctypes.c_void_p,
            ctypes.c_size_t,
        ]
        runtime.poo_flow_graph_plan_set_step_limit.restype = ctypes.c_int

        runtime.poo_flow_graph_plan_add_node.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
        ]
        runtime.poo_flow_graph_plan_add_node.restype = ctypes.c_int

        runtime.poo_flow_graph_plan_set_node_action.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
            ctypes.c_char_p,
        ]
        runtime.poo_flow_graph_plan_set_node_action.restype = ctypes.c_int

        runtime.poo_flow_graph_plan_set_state_reducer.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
            ctypes.c_char_p,
        ]
        runtime.poo_flow_graph_plan_set_state_reducer.restype = ctypes.c_int

        runtime.poo_flow_graph_plan_add_edge.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
            ctypes.c_char_p,
        ]
        runtime.poo_flow_graph_plan_add_edge.restype = ctypes.c_int

        runtime.poo_flow_graph_plan_add_conditional_route.argtypes = [
            ctypes.c_void_p,
            ctypes.c_char_p,
            ctypes.c_char_p,
            ctypes.c_char_p,
            ctypes.c_char_p,
        ]
        runtime.poo_flow_graph_plan_add_conditional_route.restype = ctypes.c_int

        runtime.poo_flow_graph_plan_describe.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(_PooFlowBytes),
        ]
        runtime.poo_flow_graph_plan_describe.restype = ctypes.c_int

        runtime.poo_flow_graph_plan_validate.argtypes = [
            ctypes.c_void_p,
            ctypes.POINTER(_PooFlowBytes),
        ]
        runtime.poo_flow_graph_plan_validate.restype = ctypes.c_int

        runtime.poo_flow_plan_runtime_graph_handoff.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.POINTER(ctypes.c_uint8),
            ctypes.c_size_t,
            ctypes.POINTER(_PooFlowBytes),
        ]
        runtime.poo_flow_plan_runtime_graph_handoff.restype = ctypes.c_int

        runtime.poo_flow_bytes_free.argtypes = [_PooFlowBytes]
        runtime.poo_flow_bytes_free.restype = None

        runtime.poo_flow_status_name.argtypes = [ctypes.c_int]
        runtime.poo_flow_status_name.restype = ctypes.c_char_p


class PooFlowContext:
    """Runtime context handle backed by the C ABI."""

    def __init__(self, binding: PooFlowRuntimeBinding, ctx: int) -> None:
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
        payload = _payload_array(manifest)
        receipt = _PooFlowBytes()
        status = self._binding._runtime.poo_flow_validate_manifest(
            self._ctx,
            payload,
            len(manifest),
            ctypes.byref(receipt),
        )
        self._binding._raise_unless_ok(status)
        return self._binding._take_bytes(receipt)

    def plan_runtime_handoff(self, request: bytes) -> bytes:
        payload = _payload_array(request)
        handoff = _PooFlowBytes()
        status = self._binding._runtime.poo_flow_plan_runtime_handoff(
            self._ctx,
            payload,
            len(request),
            ctypes.byref(handoff),
        )
        self._binding._raise_unless_ok(status)
        return self._binding._take_bytes(handoff)

    def plan_runtime_graph_handoff(
        self,
        graph_plan: "PooFlowGraphPlan",
        request: bytes,
    ) -> bytes:
        payload = _payload_array(request)
        handoff = _PooFlowBytes()
        status = self._binding._runtime.poo_flow_plan_runtime_graph_handoff(
            self._ctx,
            graph_plan._plan,
            payload,
            len(request),
            ctypes.byref(handoff),
        )
        self._binding._raise_unless_ok(status)
        return self._binding._take_bytes(handoff)


class PooFlowGraphPlan:
    """Opaque runtime graph plan handle backed by the C ABI."""

    def __init__(self, binding: PooFlowRuntimeBinding, plan: int) -> None:
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
            self._plan,
            step_limit,
        )
        self._binding._raise_unless_ok(status)

    def add_node(self, node: str) -> None:
        status = self._binding._runtime.poo_flow_graph_plan_add_node(
            self._plan,
            _string_arg(node),
        )
        self._binding._raise_unless_ok(status)

    def set_node_action(self, node: str, action: str) -> None:
        status = self._binding._runtime.poo_flow_graph_plan_set_node_action(
            self._plan,
            _string_arg(node),
            _string_arg(action),
        )
        self._binding._raise_unless_ok(status)

    def set_state_reducer(self, state_key: str, reducer: str) -> None:
        status = self._binding._runtime.poo_flow_graph_plan_set_state_reducer(
            self._plan,
            _string_arg(state_key),
            _string_arg(reducer),
        )
        self._binding._raise_unless_ok(status)

    def add_edge(self, source: str, target: str) -> None:
        status = self._binding._runtime.poo_flow_graph_plan_add_edge(
            self._plan,
            _string_arg(source),
            _string_arg(target),
        )
        self._binding._raise_unless_ok(status)

    def add_conditional_route(
        self,
        *,
        source: str,
        router: str,
        route_key: str,
        target: str,
    ) -> None:
        status = self._binding._runtime.poo_flow_graph_plan_add_conditional_route(
            self._plan,
            _string_arg(source),
            _string_arg(router),
            _string_arg(route_key),
            _string_arg(target),
        )
        self._binding._raise_unless_ok(status)

    def describe(self) -> bytes:
        receipt = _PooFlowBytes()
        status = self._binding._runtime.poo_flow_graph_plan_describe(
            self._plan,
            ctypes.byref(receipt),
        )
        self._binding._raise_unless_ok(status)
        return self._binding._take_bytes(receipt)

    def validate(self) -> bytes:
        receipt = _PooFlowBytes()
        status = self._binding._runtime.poo_flow_graph_plan_validate(
            self._plan,
            ctypes.byref(receipt),
        )
        self._binding._raise_unless_ok(status)
        return self._binding._take_bytes(receipt)


def default_package_root() -> pathlib.Path:
    return pathlib.Path(__file__).resolve().parents[2]


def default_workspace_root() -> pathlib.Path:
    configured = os.environ.get("POO_FLOW_WORKSPACE")
    if configured:
        return pathlib.Path(configured).resolve()

    for start in (pathlib.Path.cwd(), pathlib.Path(__file__).resolve()):
        for candidate in (start, *start.parents):
            if (candidate / "bindings" / "runtime-c").is_dir():
                return candidate

    return pathlib.Path(__file__).resolve().parents[4]


def compile_probe(package_root: pathlib.Path, workspace_root: pathlib.Path) -> pathlib.Path:
    bindings = workspace_root / "bindings" / "runtime-c"
    header = bindings / "include" / "poo_flow_runtime_abi.h"
    source = bindings / "probe" / "poo_flow_runtime_abi_probe.c"
    if not header.exists() or not source.exists():
        raise RuntimeError(f"runtime C bindings are missing under {bindings}")

    build_dir = package_root / "build" / "runtime-c-abi"
    build_dir.mkdir(parents=True, exist_ok=True)
    output = build_dir / shared_library_name()

    if platform.system() == "Windows":
        raise RuntimeError("Windows probe build is not implemented yet")

    command = [
        os.environ.get("CC", "cc"),
        "-std=c99",
        "-Wall",
        "-Wextra",
        "-Werror",
        "-fPIC",
        "-shared",
        "-I",
        str(bindings / "include"),
        str(source),
        "-o",
        str(output),
    ]
    subprocess.run(command, check=True)
    return output


def shared_library_name() -> str:
    system = platform.system()
    if system == "Darwin":
        return "libpoo_flow_runtime_abi_probe.dylib"
    if system == "Windows":
        return "poo_flow_runtime_abi_probe.dll"
    return "libpoo_flow_runtime_abi_probe.so"


def _payload_array(payload: bytes) -> ctypes.Array[ctypes.c_uint8]:
    if not isinstance(payload, bytes):
        raise TypeError("runtime ABI payloads must be bytes")
    if len(payload) == 0:
        return (ctypes.c_uint8 * 0)()
    return (ctypes.c_uint8 * len(payload)).from_buffer_copy(payload)


def _string_arg(value: str) -> bytes:
    if not isinstance(value, str):
        raise TypeError("runtime ABI string values must be str")
    return value.encode("utf-8")
