import PooFlowProof.Examples

namespace PooFlowProof.Generated.LoopEngine

open PooFlowProof

def generatedObligations : List Obligation :=
  requiredObligations

def generatedManifest : ProofManifest :=
  { kind := ManifestKind.loopEngineProofManifest
    contract := ProofManifestContract.v1
    source := ManifestSource.userConfigLoopEngine
    proofOwner := ProofOwner.lean
    proofChecker := ProofChecker.axle
    runtimeOwner := RuntimeOwner.marlinAgentCore
    schemeProjection := SchemeProjection.loopEngineRuntimeCommandManifest
    proofScope := requiredProofScopes
    requestId := "loop-engine/current-system-build-loop/request"
    artifactHandle := "loop-engine/current-system-build-loop/artifact"
    runtimeCommandContract := RuntimeCommandContract.loopGovernorRuntimeCommandManifestV1
    objectFamilies := [ObjectFamily.agentProfile, ObjectFamily.runtimeSnapshot]
    receiptContracts := [ReceiptContract.lineageReceiptV1]
    runtimePacketContracts := [RuntimePacketContract.actionPacketV1]
    cAbi := canonicalProofAbi
    obligations := generatedObligations
    leanArtifactKind := LeanArtifactKind.theoremStubs
    runtimeExecution := RuntimeExecution.inert }

theorem generatedManifest_runtime_inert :
    generatedManifest.runtimeExecution = RuntimeExecution.inert :=
  ProofManifest.runtime_inert_by_type generatedManifest

theorem generatedManifest_has_required_obligations :
    generatedManifest.hasAllRequiredObligations = true := by
  native_decide

theorem generatedManifest_has_required_scopes :
    generatedManifest.hasAllRequiredProofScopes = true := by
  native_decide

theorem generatedManifest_obligations_runtime_inert :
    generatedManifest.allObligationsRuntimeInert = true := by
  native_decide

theorem generatedManifest_valid : generatedManifest.Valid where
  abiMatches := by native_decide
  hasRequiredObligations := generatedManifest_has_required_obligations
  hasRequiredProofScopes := generatedManifest_has_required_scopes
  obligationsRuntimeInert := generatedManifest_obligations_runtime_inert

theorem generatedManifest_proof_case_vector_complete :
    generatedManifest.proofCaseVectorComplete = true :=
  ProofManifest.proof_case_vector_complete_of_valid generatedManifest_valid

end PooFlowProof.Generated.LoopEngine
