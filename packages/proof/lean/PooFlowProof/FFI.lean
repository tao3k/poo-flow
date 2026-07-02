import PooFlowProof.Manifest

namespace PooFlowProof

def proofAbiVersion : UInt32 := 1
def tagWidthUInt32 : UInt32 := 32
def proofAbiObligationCount : UInt32 := 5
def proofAbiRequiredObligationMask : UInt32 := requiredObligationMask

def uiConfigWellFormedBit : UInt32 := 1
def runtimeCommandInertBit : UInt32 := 2
def policyStrategyDeterministicBit : UInt32 := 4
def workflowAgreementLinkedBit : UInt32 := 8
def sandboxBoundaryLinkedBit : UInt32 := 16

def requiredObligationMaskFromBits : UInt32 :=
  uiConfigWellFormedBit |||
  runtimeCommandInertBit |||
  policyStrategyDeterministicBit |||
  workflowAgreementLinkedBit |||
  sandboxBoundaryLinkedBit

structure ProofAbiRaw where
  version : UInt32
  requiredObligationMask : UInt32
  tagWidth : UInt32
  obligationCount : UInt32
deriving Repr, DecidableEq

def canonicalProofAbiRaw : ProofAbiRaw :=
  { version := proofAbiVersion
    requiredObligationMask := proofAbiRequiredObligationMask
    tagWidth := tagWidthUInt32
    obligationCount := proofAbiObligationCount }

def ProofAbiRaw.isCanonical (raw : ProofAbiRaw) : Bool :=
  (raw.version == proofAbiVersion) &&
  (raw.requiredObligationMask == proofAbiRequiredObligationMask) &&
  (raw.tagWidth == tagWidthUInt32) &&
  (raw.obligationCount == proofAbiObligationCount)

def decodeProofAbi? (raw : ProofAbiRaw) : Option ProofAbi :=
  if raw.isCanonical then some canonicalProofAbi else none

theorem canonicalProofAbiRaw_decodes :
    decodeProofAbi? canonicalProofAbiRaw = some canonicalProofAbi := by
  native_decide

@[extern "poo_flow_proof_abi_version"]
opaque cAbiVersion : IO UInt32

@[extern "poo_flow_proof_tag_width"]
opaque cTagWidth : IO UInt32

@[extern "poo_flow_proof_obligation_count"]
opaque cObligationCount : IO UInt32

@[extern "poo_flow_proof_required_obligation_mask"]
opaque cRequiredObligationMask : IO UInt32

@[extern "poo_flow_proof_ui_config_well_formed_bit"]
opaque cUiConfigWellFormedBit : IO UInt32

@[extern "poo_flow_proof_runtime_command_inert_bit"]
opaque cRuntimeCommandInertBit : IO UInt32

@[extern "poo_flow_proof_policy_strategy_deterministic_bit"]
opaque cPolicyStrategyDeterministicBit : IO UInt32

@[extern "poo_flow_proof_workflow_agreement_linked_bit"]
opaque cWorkflowAgreementLinkedBit : IO UInt32

@[extern "poo_flow_proof_sandbox_boundary_linked_bit"]
opaque cSandboxBoundaryLinkedBit : IO UInt32

def cProofAbiRaw : IO ProofAbiRaw := do
  pure
    { version := (← cAbiVersion)
      requiredObligationMask := (← cRequiredObligationMask)
      tagWidth := (← cTagWidth)
      obligationCount := (← cObligationCount) }

def cMaskMatchesRequired : IO Bool := do
  pure ((← cRequiredObligationMask) == proofAbiRequiredObligationMask)

def cBridgeMatchesCanonical : IO Bool := do
  let raw ← cProofAbiRaw
  let uiConfigWellFormed ← cUiConfigWellFormedBit
  let runtimeCommandInert ← cRuntimeCommandInertBit
  let policyStrategyDeterministic ← cPolicyStrategyDeterministicBit
  let workflowAgreementLinked ← cWorkflowAgreementLinkedBit
  let sandboxBoundaryLinked ← cSandboxBoundaryLinkedBit
  pure
    ((decodeProofAbi? raw == some canonicalProofAbi) &&
     (uiConfigWellFormed == uiConfigWellFormedBit) &&
     (runtimeCommandInert == runtimeCommandInertBit) &&
     (policyStrategyDeterministic == policyStrategyDeterministicBit) &&
     (workflowAgreementLinked == workflowAgreementLinkedBit) &&
     (sandboxBoundaryLinked == sandboxBoundaryLinkedBit) &&
     (requiredObligationMaskFromBits == proofAbiRequiredObligationMask))

def obligationNamesFromMask (mask : UInt32) : List ObligationName :=
  let addIf (bit : UInt32) (name : ObligationName) (names : List ObligationName) :=
    if mask &&& bit == bit then name :: names else names
  []
    |> addIf sandboxBoundaryLinkedBit ObligationName.sandboxBoundaryLinked
    |> addIf workflowAgreementLinkedBit ObligationName.workflowAgreementLinked
    |> addIf policyStrategyDeterministicBit ObligationName.policyStrategyDeterministic
    |> addIf runtimeCommandInertBit ObligationName.runtimeCommandInert
    |> addIf uiConfigWellFormedBit ObligationName.uiConfigWellFormed

theorem requiredObligationMask_decodes_required_names :
    obligationNamesFromMask requiredObligationMask = requiredObligationNames := by
  native_decide

theorem requiredObligationMaskFromBits_matches_manifest_mask :
    requiredObligationMaskFromBits = proofAbiRequiredObligationMask := by
  native_decide

end PooFlowProof
