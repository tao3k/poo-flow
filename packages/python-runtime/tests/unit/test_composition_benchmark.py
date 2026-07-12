from poo_flow_runtime.benchmarks import composition as benchmark


def test_composition_benchmark_runs_all_scenarios() -> None:
    results = benchmark.run_composition_benchmarks(iterations=1, fanout=3)

    assert tuple(result.scenario for result in results) == (
        "strategy-combinator-pipeline",
        "durable-fanout-strategy",
        "nested-subgraph-stream-projection",
        "funflow-cicd-sandbox-dag",
    )
    assert all(result.elapsed_micros >= 0 for result in results)


def test_composition_benchmark_receipt_is_line_oriented() -> None:
    result = benchmark.run_composition_benchmarks(iterations=1, fanout=2)[0]

    receipt = result.receipt()

    assert "schema: \"poo-flow.composition-benchmark.v1\"" in receipt
    assert "scenario: \"strategy-combinator-pipeline\"" in receipt
    assert "stages: 8" in receipt


def test_composition_benchmark_cli_emits_receipts(capsys) -> None:
    assert benchmark.main(["--iterations", "1", "--fanout", "2"]) == 0

    output = capsys.readouterr().out
    assert output.count("poo-flow.composition-benchmark.v1") == 4
