from __future__ import annotations

from poo_flow_runtime.bindings import PooFlowRuntimeCffiBinding
from poo_flow_runtime.program import RuntimeGraphProgram, RuntimeGraphRegistries
from poo_flow_runtime.runtime_graph import linear_plan
from poo_flow_runtime.validation import RuntimeValidationInput, ValidationRuntime


def test_cffi_binding_validates_manifest() -> None:
    binding = PooFlowRuntimeCffiBinding.from_probe()

    with binding.context() as runtime:
        receipt = runtime.validate_manifest(b"runtime=python\n")

    assert b"kind=manifest-validation" in receipt


def test_cffi_binding_validates_runtime_graph_plan() -> None:
    binding = PooFlowRuntimeCffiBinding.from_probe()

    with binding.graph_plan() as graph_plan:
        graph_plan.add_node("load")
        graph_plan.add_edge("__start__", "load")
        graph_plan.add_edge("load", "__end__")
        receipt = graph_plan.validate()

    assert b"kind=runtime-graph-validation" in receipt
    assert b"nodes=1" in receipt


def test_cffi_binding_plans_runtime_graph_handoff() -> None:
    binding = PooFlowRuntimeCffiBinding.from_probe()

    with binding.context() as runtime:
        with binding.graph_plan() as graph_plan:
            graph_plan.add_node("load")
            graph_plan.add_edge("__start__", "load")
            graph_plan.add_edge("load", "__end__")
            receipt = runtime.plan_runtime_graph_handoff(
                graph_plan, b"runtime=python\nstrategy=cffi\n"
            )

    assert b"kind=runtime-graph-handoff" in receipt
    assert b"nodes=1" in receipt


def test_cffi_binding_runs_runtime_graph_program() -> None:
    program = RuntimeGraphProgram(
        plan=linear_plan("load"),
        registries=RuntimeGraphRegistries(
            actions={"load": lambda state: {"value": state["value"] + 1}},
        ),
        binding=PooFlowRuntimeCffiBinding.from_probe(),
    )

    assert program.invoke({"value": 1}) == {"value": 2}


def test_cffi_binding_runs_validation_runtime() -> None:
    result = ValidationRuntime(PooFlowRuntimeCffiBinding.from_probe()).validate(
        RuntimeValidationInput(
            b"runtime=python\n",
            b"runtime=python\nstrategy=cffi\n",
        )
    )

    assert result.status == "ok"
    assert b"kind=manifest-validation" in result.manifest_receipt
    assert b"kind=runtime-graph-handoff" in result.handoff_receipt
