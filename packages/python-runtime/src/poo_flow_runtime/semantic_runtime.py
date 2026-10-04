# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
"""Production semantic byte calls on a dedicated Scheme owner thread.

Python owns scheduling and transport. Existing Scheme modules own every result.
Cancellation discards a pure call's result; it cannot interrupt Gambit or grant IO.
"""
from __future__ import annotations
import asyncio
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
from types import MappingProxyType
import threading
from typing import Any, Mapping


def _unique_json_pairs(pairs):
    result = dict(pairs)
    if len(result) != len(pairs):
        raise ValueError('duplicate JSON object key')
    return result


class SemanticRuntimeError(RuntimeError):
    def __init__(self, message: str, *, status: int) -> None:
        super().__init__(message)
        self.status = status


class SemanticRuntime:
    @classmethod
    def bundled(cls) -> SemanticRuntime:
        """Open the optional wheel artifact using its producer digest."""
        import sys
        name = 'libpoo_flow_semantic.dylib' if sys.platform == 'darwin' else 'libpoo_flow_semantic.so'
        path = Path(__file__).parent / '_native' / 'lib' / name
        manifest = json.loads(Path(str(path) + '.json').read_text())
        if (manifest.get('schema') != 'poo-flow.semantic-aot-artifact'
                or manifest.get('version') != 1):
            raise SemanticRuntimeError('invalid semantic artifact manifest', status=6)
        return cls(path, expected_digest=manifest['artifactSha256'])

    def __init__(self, library: str | Path, *, expected_digest: str) -> None:
        path = Path(library).resolve()
        if hashlib.sha256(path.read_bytes()).hexdigest() != expected_digest:
            raise SemanticRuntimeError('semantic artifact digest mismatch', status=6)
        from ._native._semantic_cffi import ffi, lib
        self._ffi, self._lib = ffi, lib
        self.artifact_digest = expected_digest
        self._lock = threading.Lock()
        self._slots = threading.BoundedSemaphore(64)
        self._closed = False
        self._worker = ThreadPoolExecutor(max_workers=1, thread_name_prefix='poo-scheme')
        initialized = False
        try:
            status = self._worker.submit(lib.poo_flow_python_semantic_open, str(path).encode()).result()
            if status:
                raise SemanticRuntimeError('semantic AOT initialization failed', status=status)
            initialized = True
            self.descriptor = self.call('descriptor', {})
            if (self.descriptor.get('schema') != 'poo-flow.semantic-descriptor'
                    or self.descriptor.get('abiVersion') != 1):
                raise SemanticRuntimeError('semantic ABI descriptor mismatch', status=6)
        except BaseException:
            if initialized:
                self._worker.submit(lib.poo_flow_python_semantic_close).result()
            self._worker.shutdown(wait=True)
            self._closed = True
            raise

    def classify_temporal_family(self, task: Mapping[str, Any]) -> dict[str, Any]:
        """Classify the finite POO hypothesis family in the native Scheme engine."""
        return self.call('temporal.family.classify', task)

    async def aclassify_temporal_family(self, task: Mapping[str, Any]) -> dict[str, Any]:
        return await self.acall('temporal.family.classify', task)

    def observe_temporal_family(self, task: Mapping[str, Any],
                                candidate: Mapping[str, Any]) -> dict[str, Any]:
        """Replay a family result; this does not authenticate evidence or authorize IO."""
        return self.call('temporal.family.observe', {'task': task, 'candidate': candidate})

    async def aobserve_temporal_family(self, task: Mapping[str, Any],
                                       candidate: Mapping[str, Any]) -> dict[str, Any]:
        return await self.acall('temporal.family.observe', {'task': task, 'candidate': candidate})

    def _submit(self, operation: str, payload: Mapping[str, Any]):
        if not isinstance(operation, str) or '\0' in operation or len(operation.encode('utf-8')) > 128:
            raise ValueError('invalid semantic operation')
        data = json.dumps(payload, ensure_ascii=False, allow_nan=False,
                          separators=(',', ':')).encode('utf-8')
        if len(data) > 1048576:
            raise ValueError('semantic input exceeds maximum bytes')
        with self._lock:
            if self._closed:
                raise SemanticRuntimeError('semantic runtime is closed', status=1)
            if not self._slots.acquire(blocking=False):
                raise SemanticRuntimeError('semantic call queue is full', status=7)
            try:
                future = self._worker.submit(self._call, operation.encode(), data)
                future.add_done_callback(lambda _: self._slots.release())
                return future
            except BaseException:
                self._slots.release()
                raise

    def _call(self, operation: bytes, data: bytes) -> dict[str, Any]:
        result = self._ffi.new('poo_flow_semantic_result *')
        try:
            status = self._lib.poo_flow_python_semantic_call(operation, data, len(data), result)
            raw = bytes(self._ffi.buffer(result.data, result.length)) if result.data != self._ffi.NULL else b''
            if status:
                raise SemanticRuntimeError(raw.decode('utf-8', 'replace') or
                                           'semantic native call failed', status=status)
            decoded = json.loads(raw)
            if not isinstance(decoded, dict):
                raise SemanticRuntimeError('invalid semantic result shape', status=6)
            return decoded
        finally:
            self._lib.poo_flow_python_semantic_release(result)

    def call(self, operation: str, payload: Mapping[str, Any]) -> dict[str, Any]:
        return self._submit(operation, payload).result()

    async def acall(self, operation: str, payload: Mapping[str, Any]) -> dict[str, Any]:
        return await asyncio.wrap_future(self._submit(operation, payload))

    def validate_model_answer(self, task: Mapping[str, Any], output: str) -> dict[str, Any]:
        try:
            candidate = json.loads(output, object_pairs_hook=_unique_json_pairs)
        except (ValueError, TypeError) as error:
            raise SemanticRuntimeError('model output is not inert JSON', status=3) from error
        if not isinstance(candidate, dict):
            raise SemanticRuntimeError('model output must be a JSON object', status=3)
        return self.call('temporal.verify', {'task': task, 'candidate': candidate})

    def observe_model_answer(self, task: Mapping[str, Any], output: str) -> dict[str, Any]:
        """Compute current Scheme evidence after an inert model prediction."""
        try:
            candidate = json.loads(output, object_pairs_hook=_unique_json_pairs)
        except (ValueError, TypeError) as error:
            raise SemanticRuntimeError('model output is not inert JSON', status=3) from error
        return self.call('temporal.observe', {'task': task, 'candidate': candidate})

    def predict_temporal_answer(self, task: Mapping[str, Any], predictor,
                                *, observation_sink=None) -> dict[str, Any]:
        """Give model IO task data; return fresh Scheme feedback without retry.

        The callback receives a detached task, with no solved answer. Scheme
        computes evidence against the caller's current task after model IO.
        A contradiction is an observation, never permission to execute effects.
        """
        supplied = json.loads(json.dumps(task, allow_nan=False))
        output = predictor(supplied)
        receipt = self.observe_model_answer(task, output)
        result = {'candidate': json.loads(output), 'receipt': receipt,
                  'artifactDigest': self.artifact_digest}
        if observation_sink is not None:
            observation_sink(json.loads(json.dumps(result)))
        return result

    async def apredict_temporal_answer(self, task: Mapping[str, Any], predictor,
                                      *, observation_sink=None) -> dict[str, Any]:
        supplied = json.loads(json.dumps(task, allow_nan=False))
        output = await predictor(supplied)
        try:
            candidate = json.loads(output, object_pairs_hook=_unique_json_pairs)
        except (ValueError, TypeError) as error:
            raise SemanticRuntimeError('model output is not inert JSON', status=3) from error
        receipt = await self.acall('temporal.observe', {'task': task, 'candidate': candidate})
        result = {'candidate': candidate, 'receipt': receipt,
                  'artifactDigest': self.artifact_digest}
        if observation_sink is not None:
            await observation_sink(json.loads(json.dumps(result)))
        return result

    def _graph_projection(self, plan, bindings):
        # Bind the full runtime projection, including action/router/reducer names.
        # Scheme owns topology admission. Python owns actual action/IO execution.
        return {
            'nodes': list(plan.nodes), 'stepLimit': plan.step_limit,
            'edges': [[edge.source, edge.target] for edge in plan.edges],
            'conditionalEdges': [{'source': edge.source, 'router': edge.router,
                                  'routes': dict(sorted(edge.routes.items()))}
                                 for edge in plan.conditional_edges],
            'actions': dict(sorted(bindings.node_actions.items())),
            'reducers': dict(sorted(bindings.state_reducers.items())),
        }

    def bind_graph(self, plan, bindings):
        payload = self._graph_projection(plan, bindings)
        result = self.call('graph.admit', payload)
        if result.get('status') != 'admitted' or result.get('operation') != 'graph.admit':
            raise SemanticRuntimeError('Scheme graph admission rejected', status=4)
        encoded = json.dumps(payload, ensure_ascii=False, allow_nan=False, separators=(',', ':'))
        return _SemanticGraphBinding(self, encoded, result['planDigest'],
            result['receipt'].encode('utf-8'), MappingProxyType({
                key: tuple(values) for key, values in result['staticSuccessors'].items()}))

    def admit_graph(self, plan, bindings) -> bytes:
        return self.bind_graph(plan, bindings).receipt

    def close(self) -> None:
        with self._lock:
            if self._closed:
                return
            self._closed = True
            close = self._worker.submit(self._lib.poo_flow_python_semantic_close)
        try:
            status = close.result()
            if status:
                raise SemanticRuntimeError('semantic runtime close failed', status=status)
        finally:
            self._worker.shutdown(wait=True)

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()


@dataclass(frozen=True)
class _SemanticGraphBinding:
    """Immutable native plan projection used by the Python scheduler."""
    runtime: SemanticRuntime
    payload: str
    digest: str
    receipt: bytes
    static_successors: Mapping[str, tuple[str, ...]]

    def _request(self, source, mode, **fields):
        return dict(plan=self.payload, expectedDigest=self.digest, source=source, mode=mode, **fields)

    def targets(self, source, mode, **fields):
        result = self.runtime.call('graph.targets', self._request(source, mode, **fields))
        return result['targets']

    async def atargets(self, source, mode, **fields):
        result = await self.runtime.acall('graph.targets', self._request(source, mode, **fields))
        return result['targets']
