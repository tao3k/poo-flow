import PooFlowProof.Manifest

namespace PooFlowProof

def uiConfigWellFormed : Obligation :=
  { name := ObligationName.uiConfigWellFormed
    claim := ObligationClaim.allRuntimeHandoffReferencesArePresent
    source := ObligationSource.schemeProjection }

def runtimeCommandInert : Obligation :=
  { name := ObligationName.runtimeCommandInert
    claim := ObligationClaim.schemeEmitsManifestWithoutRuntimeExecution
    source := ObligationSource.runtimeCommandManifest }

def policyStrategyDeterministic : Obligation :=
  { name := ObligationName.policyStrategyDeterministic
    claim := ObligationClaim.policyAndStrategyProjectionHasStablePrecedence
    source := ObligationSource.policyProfilePacket }

def workflowAgreementLinked : Obligation :=
  { name := ObligationName.workflowAgreementLinked
    claim := ObligationClaim.workflowAgreementIsCarriedIntoRuntimeEnvelope
    source := ObligationSource.workflowAgreement }

def sandboxBoundaryLinked : Obligation :=
  { name := ObligationName.sandboxBoundaryLinked
    claim := ObligationClaim.sandboxHandoffAgreementIsCarriedIntoProofScope
    source := ObligationSource.sandboxHandoffAgreement }

def requiredObligations : List Obligation :=
  [ uiConfigWellFormed
  , runtimeCommandInert
  , policyStrategyDeterministic
  , workflowAgreementLinked
  , sandboxBoundaryLinked
  ]

def exampleManifest : ProofManifest :=
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
    cAbi := canonicalProofAbi
    obligations := requiredObligations
    leanArtifactKind := LeanArtifactKind.theoremStubs
    runtimeExecution := RuntimeExecution.inert }

theorem exampleManifest_runtime_inert :
    exampleManifest.runtimeExecution = RuntimeExecution.inert :=
  ProofManifest.runtime_inert_by_type exampleManifest

theorem exampleManifest_has_required_obligations :
    exampleManifest.hasAllRequiredObligations = true := by
  native_decide

theorem exampleManifest_valid : exampleManifest.Valid where
  abiMatches := by native_decide
  hasRequiredObligations := exampleManifest_has_required_obligations

end PooFlowProof
