import PooFlowProof.Manifest

namespace PooFlowProof.Generated.LoopEngine

open PooFlowProof

def generatedObligations : List Obligation :=
  [
  { name := ObligationName.uiConfigWellFormed
    claim := ObligationClaim.allRuntimeHandoffReferencesArePresent
    source := ObligationSource.schemeProjection },
  { name := ObligationName.runtimeCommandInert
    claim := ObligationClaim.schemeEmitsManifestWithoutRuntimeExecution
    source := ObligationSource.runtimeCommandManifest },
  { name := ObligationName.policyStrategyDeterministic
    claim := ObligationClaim.policyAndStrategyProjectionHasStablePrecedence
    source := ObligationSource.policyProfilePacket },
  { name := ObligationName.workflowAgreementLinked
    claim := ObligationClaim.workflowAgreementIsCarriedIntoRuntimeEnvelope
    source := ObligationSource.workflowAgreement },
  { name := ObligationName.sandboxBoundaryLinked
    claim := ObligationClaim.sandboxHandoffAgreementIsCarriedIntoProofScope
    source := ObligationSource.sandboxHandoffAgreement }
  ]

def generatedManifest : ProofManifest :=
  { kind := ManifestKind.loopEngineProofManifest
    contract := ProofManifestContract.v1
    source := ManifestSource.userConfigLoopEngine
    proofOwner := ProofOwner.lean
    proofChecker := ProofChecker.axle
    runtimeOwner := RuntimeOwner.marlinAgentCore
    schemeProjection := SchemeProjection.loopEngineRuntimeCommandManifest
    proofScope :=
      [ ProofScope.userInterface
      , ProofScope.policy
      , ProofScope.strategy
      , ProofScope.workflow
      , ProofScope.runtimeHandoff
      ]
    requestId := "loop-engine/current-system-build-loop/request"
    artifactHandle := "loop-engine/current-system-build-loop/artifact"
    runtimeCommandContract := RuntimeCommandContract.loopGovernorRuntimeCommandManifestV1
    objectFamilies := [ObjectFamily.agentProfile, ObjectFamily.runtimeSnapshot]
    receiptContracts := [ReceiptContract.lineageReceiptV1]
    runtimePacketContracts := [RuntimePacketContract.actionPacketV1]
    cAbi := {
      version := 1
      requiredObligationMask := 31
      tagWidth := TagWidth.uint32
      obligationCount := 5
    }
    obligations := generatedObligations
    leanArtifactKind := LeanArtifactKind.theoremStubs
    runtimeExecution := RuntimeExecution.inert }

theorem generatedManifest_runtime_inert :
    generatedManifest.runtimeExecution = RuntimeExecution.inert :=
  ProofManifest.runtime_inert_by_type generatedManifest

theorem generatedManifest_has_required_obligations :
    generatedManifest.hasAllRequiredObligations = true := by
  native_decide

theorem generatedManifest_valid : generatedManifest.Valid where
  abiMatches := by native_decide
  hasRequiredObligations := generatedManifest_has_required_obligations

end PooFlowProof.Generated.LoopEngine
