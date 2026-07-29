from poo_flow_proof.axle_verify import independent_source


def test_independent_source_replaces_project_imports_with_one_mathlib_header() -> None:
    source = (
        "import PooFlowProof.PooC3.First\n"
        "import Mathlib\n"
        "import PooFlowProof.PooC3.Second\n"
        "\n"
        "theorem proof_surface : True := by trivial\n"
    )

    independent = independent_source(source)

    assert independent.count("import Mathlib\n") == 1
    assert "import PooFlowProof." not in independent
    assert "theorem proof_surface : True := by trivial" in independent
