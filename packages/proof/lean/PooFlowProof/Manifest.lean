namespace PooFlowProof

inductive ManifestKind where
  | loopEngineProofManifest
deriving Repr, DecidableEq

inductive ProofManifestContract where
  | v1
deriving Repr, DecidableEq

inductive ManifestSource where
  | userConfigLoopEngine
deriving Repr, DecidableEq

inductive ProofOwner where
  | lean
deriving Repr, DecidableEq

inductive ProofChecker where
  | lean
  | axle
deriving Repr, DecidableEq

inductive RuntimeOwner where
  | marlinAgentCore
deriving Repr, DecidableEq

inductive SchemeProjection where
  | loopEngineRuntimeCommandManifest
deriving Repr, DecidableEq

inductive ProofScope where
  | userInterface
  | policy
  | strategy
  | workflow
  | runtimeHandoff
deriving Repr, DecidableEq

inductive RuntimeCommandContract where
  | loopGovernorRuntimeCommandManifestV1
deriving Repr, DecidableEq

inductive ObjectFamily where
  | agentProfile
  | agentHarness
  | agentSession
  | sessionAgentGraph
  | workflowRun
  | dispatchReceipt
  | agentOperation
  | lineageReceipt
  | selectorReceipt
  | resourceDispatchReceipt
  | capabilityReceipt
  | memoryReceipt
  | compressionReceipt
  | policyExtensionReceipt
  | specEvolutionReviewItem
  | specEvolutionRuntimeManifestRow
  | runtimeCapabilityDescriptor
  | policyProfilePacket
  | runtimeActionPacket
  | runtimeReceiptBatch
  | runtimeSnapshot
deriving Repr, DecidableEq

inductive ReceiptContract where
  | lineageReceiptV1
  | selectorReceiptV1
  | sessionAgentGraphV1
  | resourceDispatchReceiptV1
  | capabilityReceiptV1
  | memoryReceiptV1
  | compressionReceiptV1
  | policyExtensionReceiptV1
  | specEvolutionReviewItemV1
  | specEvolutionRuntimeManifestRowV1
  | runtimeCapabilityDescriptorV1
  | policyProfilePacketV1
  | runtimeActionPacketV1
  | runtimeReceiptBatchV1
  | sandboxHandoffAgreementV1
deriving Repr, DecidableEq

inductive RuntimePacketContract where
  | capabilityDescriptorV1
  | policyProfilePacketV1
  | actionPacketV1
  | receiptBatchV1
deriving Repr, DecidableEq

inductive ObligationName where
  | uiConfigWellFormed
  | runtimeCommandInert
  | policyStrategyDeterministic
  | workflowAgreementLinked
  | sandboxBoundaryLinked
deriving Repr, DecidableEq

inductive ObligationClaim where
  | allRuntimeHandoffReferencesArePresent
  | schemeEmitsManifestWithoutRuntimeExecution
  | policyAndStrategyProjectionHasStablePrecedence
  | workflowAgreementIsCarriedIntoRuntimeEnvelope
  | sandboxHandoffAgreementIsCarriedIntoProofScope
deriving Repr, DecidableEq

inductive ObligationSource where
  | schemeProjection
  | runtimeCommandManifest
  | policyProfilePacket
  | workflowAgreement
  | sandboxHandoffAgreement
deriving Repr, DecidableEq

inductive LeanArtifactKind where
  | theoremStubs
deriving Repr, DecidableEq

-- A proof manifest is inert by type. There is no constructor for a manifest
-- that claims Scheme already executed runtime work.
inductive RuntimeExecution where
  | inert
deriving Repr, DecidableEq

inductive TagWidth where
  | uint32
deriving Repr, DecidableEq

structure ProofAbi where
  version : Nat
  requiredObligationMask : UInt32
  tagWidth : TagWidth
  obligationCount : Nat
deriving Repr, DecidableEq

structure Obligation where
  name : ObligationName
  claim : ObligationClaim
  source : ObligationSource
deriving Repr, DecidableEq

structure ProofManifest where
  kind : ManifestKind
  contract : ProofManifestContract
  source : ManifestSource
  proofOwner : ProofOwner
  proofChecker : ProofChecker
  runtimeOwner : RuntimeOwner
  schemeProjection : SchemeProjection
  proofScope : List ProofScope
  requestId : String
  artifactHandle : String
  runtimeCommandContract : RuntimeCommandContract
  objectFamilies : List ObjectFamily
  receiptContracts : List ReceiptContract
  runtimePacketContracts : List RuntimePacketContract
  cAbi : ProofAbi
  obligations : List Obligation
  leanArtifactKind : LeanArtifactKind
  runtimeExecution : RuntimeExecution
deriving Repr, DecidableEq

def requiredObligationNames : List ObligationName :=
  [ ObligationName.uiConfigWellFormed
  , ObligationName.runtimeCommandInert
  , ObligationName.policyStrategyDeterministic
  , ObligationName.workflowAgreementLinked
  , ObligationName.sandboxBoundaryLinked
  ]

def requiredObligationMask : UInt32 := 31

def canonicalProofAbi : ProofAbi :=
  { version := 1
    requiredObligationMask := requiredObligationMask
    tagWidth := TagWidth.uint32
    obligationCount := 5 }

def ProofManifest.hasObligationName
    (manifest : ProofManifest)
    (name : ObligationName) : Bool :=
  manifest.obligations.any (fun obligation => obligation.name == name)

def ProofManifest.hasAllRequiredObligations
    (manifest : ProofManifest) : Bool :=
  requiredObligationNames.all (manifest.hasObligationName ·)

structure ProofManifest.Valid (manifest : ProofManifest) : Prop where
  abiMatches : manifest.cAbi = canonicalProofAbi
  hasRequiredObligations : manifest.hasAllRequiredObligations = true

theorem ProofManifest.runtime_inert_by_type
    (manifest : ProofManifest) :
    manifest.runtimeExecution = RuntimeExecution.inert := by
  cases manifest.runtimeExecution
  rfl

theorem ProofManifest.has_required_obligations_of_valid
    {manifest : ProofManifest}
    (valid : manifest.Valid) :
    manifest.hasAllRequiredObligations = true :=
  valid.hasRequiredObligations

theorem ProofManifest.abi_matches_of_valid
    {manifest : ProofManifest}
    (valid : manifest.Valid) :
    manifest.cAbi = canonicalProofAbi :=
  valid.abiMatches

end PooFlowProof
