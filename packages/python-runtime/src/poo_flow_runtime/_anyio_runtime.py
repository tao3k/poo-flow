"""AnyIO adapters for ordered runtime graph execution."""

from __future__ import annotations

from collections.abc import Awaitable, Callable, Iterable
from functools import partial
from typing import Any, TypeVar

import anyio

Input = TypeVar("Input")
Output = TypeVar("Output")


async def run_blocking(call: Callable[..., Output], *args: Any, **kwargs: Any) -> Output:
    return await anyio.to_thread.run_sync(partial(call, *args, **kwargs))


async def map_ordered_blocking(
    call: Callable[[Input], Output],
    inputs: Iterable[Input],
    *,
    max_concurrency: int | None = None,
) -> list[Output]:
    values = list(inputs)
    results: list[Output | None] = [None] * len(values)
    limiter = _capacity_limiter(max_concurrency)

    async def worker(index: int, value: Input) -> None:
        if limiter is None:
            results[index] = await run_blocking(call, value)
            return
        async with limiter:
            results[index] = await run_blocking(call, value)

    async with anyio.create_task_group() as task_group:
        for index, value in enumerate(values):
            task_group.start_soon(worker, index, value)
    return [result for result in results if result is not None]


async def map_ordered_async(
    call: Callable[[Input], Awaitable[Output]],
    inputs: Iterable[Input],
    *,
    max_concurrency: int | None = None,
) -> list[Output]:
    values = list(inputs)
    results: list[Output | None] = [None] * len(values)
    limiter = _capacity_limiter(max_concurrency)

    async def worker(index: int, value: Input) -> None:
        if limiter is None:
            results[index] = await call(value)
            return
        async with limiter:
            results[index] = await call(value)

    async with anyio.create_task_group() as task_group:
        for index, value in enumerate(values):
            task_group.start_soon(worker, index, value)
    return [result for result in results if result is not None]


def _capacity_limiter(max_concurrency: int | None) -> anyio.CapacityLimiter | None:
    if max_concurrency is None:
        return None
    if max_concurrency < 1:
        raise ValueError("max_concurrency must be positive")
    return anyio.CapacityLimiter(max_concurrency)


__all__ = ["map_ordered_async", "map_ordered_blocking", "run_blocking"]
