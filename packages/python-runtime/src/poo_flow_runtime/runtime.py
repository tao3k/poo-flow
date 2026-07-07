from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Mapping


class RuntimeGraphRuntimeError(RuntimeError):
    pass


@dataclass(frozen=True)
class RuntimeGraphRuntime:
    thread_id: str | None = None
    store: Any = None
    checkpointer: Any = None
    metadata: Mapping[str, Any] = field(default_factory=dict)

    def emit_custom(self, value: Any) -> Any:
        sink = self.metadata.get("_poo_flow_runtime_custom_stream")
        if sink is None:
            return value
        if hasattr(sink, "append"):
            sink.append(value)
            return value
        if callable(sink):
            sink(value)
            return value
        raise RuntimeGraphRuntimeError(
            "runtime custom stream sink is not appendable or callable"
        )

    def require_thread_id(self) -> str:
        if self.thread_id is None:
            raise RuntimeGraphRuntimeError("runtime graph thread_id is not configured")
        return self.thread_id

    def require_store(self) -> Any:
        if self.store is None:
            raise RuntimeGraphRuntimeError("runtime graph store is not configured")
        return self.store

    def require_checkpointer(self) -> Any:
        if self.checkpointer is None:
            raise RuntimeGraphRuntimeError("runtime graph checkpointer is not configured")
        return self.checkpointer
