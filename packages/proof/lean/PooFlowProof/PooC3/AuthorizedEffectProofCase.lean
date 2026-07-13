import PooFlowProof.Generated.ProofCaseVector

namespace PooFlowProof.PooC3.AuthorizedEffectProofCase

open PooFlowProof.Generated.ProofCaseVector

deriving instance DecidableEq for Except

inductive DecodeError where
  | abiVersionMismatch
  | schemaFingerprintMismatch
  | unsupportedCaseKind
  | unsupportedMediationOutcome
  | unsupportedDurabilityProfile
  | unsupportedObligation
  | malformedDigest
  | malformedEvidence
deriving Repr, DecidableEq

inductive CaseKind where
  | authorizedEffectToken
deriving Repr, DecidableEq

inductive MediationOutcome where
  | allow
  | deny
  | invalidToken
deriving Repr, DecidableEq

inductive DurabilityProfile where
  | strict
  | batched
  | diagnostic
deriving Repr, DecidableEq

structure Digest32 where
  bytes : List UInt8
deriving Repr, DecidableEq

def Digest32.NonZero (digest : Digest32) : Prop :=
  digest.bytes ≠ List.replicate 32 0

structure RawProofCaseVector where
  abiVersion : UInt32
  caseKind : UInt32
  schemaFingerprintHex : String
  tokenDigest : List UInt8
  policyRevision : List UInt8
  effectDigest : List UInt8
  semanticRoot : List UInt8
  executionRoot : List UInt8
  batchRoot : List UInt8
  subjectBinding : List UInt8
  resourceBinding : List UInt8
  actionBinding : List UInt8
  previousEvidenceRoot : List UInt8
  nonce : UInt64
  epoch : UInt64
  sequence : UInt64
  requiredObligationMask : UInt64
  presentObligationMask : UInt64
  obligationCount : UInt32
  mediationOutcome : UInt32
  durabilityProfile : UInt32
  reservedZero : Bool
deriving Repr, DecidableEq

structure ProofCaseVector where
  caseKind : CaseKind
  tokenDigest : Digest32
  policyRevision : Digest32
  effectDigest : Digest32
  semanticRoot : Digest32
  executionRoot : Digest32
  batchRoot : Digest32
  subjectBinding : Digest32
  resourceBinding : Digest32
  actionBinding : Digest32
  previousEvidenceRoot : Digest32
  nonce : UInt64
  epoch : UInt64
  sequence : UInt64
  requiredObligationMask : UInt64
  presentObligationMask : UInt64
  obligationCount : UInt32
  mediationOutcome : MediationOutcome
  durabilityProfile : DurabilityProfile
deriving Repr, DecidableEq

def decodeDigest (bytes : List UInt8) : Except DecodeError Digest32 :=
  if bytes.length = 32 then
    .ok { bytes := bytes }
  else
    .error .malformedDigest

def decodeCaseKind (tag : UInt32) : Except DecodeError CaseKind :=
  if tag = caseKindAuthorizedEffectToken then
    .ok .authorizedEffectToken
  else
    .error .unsupportedCaseKind

def decodeMediationOutcome
    (tag : UInt32) : Except DecodeError MediationOutcome :=
  if tag = mediationAllow then
    .ok .allow
  else if tag = mediationDeny then
    .ok .deny
  else if tag = mediationInvalidToken then
    .ok .invalidToken
  else
    .error .unsupportedMediationOutcome

def decodeDurabilityProfile
    (tag : UInt32) : Except DecodeError DurabilityProfile :=
  if tag = durabilityStrict then
    .ok .strict
  else if tag = durabilityBatched then
    .ok .batched
  else if tag = durabilityDiagnostic then
    .ok .diagnostic
  else
    .error .unsupportedDurabilityProfile

def decode (raw : RawProofCaseVector) : Except DecodeError ProofCaseVector := do
  if raw.abiVersion ≠ abiVersion then
    throw .abiVersionMismatch
  if raw.schemaFingerprintHex ≠ schemaFingerprintHex then
    throw .schemaFingerprintMismatch
  if raw.requiredObligationMask > requiredObligationMask ||
      raw.presentObligationMask > requiredObligationMask then
    throw .unsupportedObligation
  if raw.obligationCount > 8 || !raw.reservedZero then
    throw .malformedEvidence
  let caseKind ← decodeCaseKind raw.caseKind
  let mediationOutcome ← decodeMediationOutcome raw.mediationOutcome
  let durabilityProfile ← decodeDurabilityProfile raw.durabilityProfile
  let tokenDigest ← decodeDigest raw.tokenDigest
  let policyRevision ← decodeDigest raw.policyRevision
  let effectDigest ← decodeDigest raw.effectDigest
  let semanticRoot ← decodeDigest raw.semanticRoot
  let executionRoot ← decodeDigest raw.executionRoot
  let batchRoot ← decodeDigest raw.batchRoot
  let subjectBinding ← decodeDigest raw.subjectBinding
  let resourceBinding ← decodeDigest raw.resourceBinding
  let actionBinding ← decodeDigest raw.actionBinding
  let previousEvidenceRoot ← decodeDigest raw.previousEvidenceRoot
  pure {
    caseKind := caseKind
    tokenDigest := tokenDigest
    policyRevision := policyRevision
    effectDigest := effectDigest
    semanticRoot := semanticRoot
    executionRoot := executionRoot
    batchRoot := batchRoot
    subjectBinding := subjectBinding
    resourceBinding := resourceBinding
    actionBinding := actionBinding
    previousEvidenceRoot := previousEvidenceRoot
    nonce := raw.nonce
    epoch := raw.epoch
    sequence := raw.sequence
    requiredObligationMask := raw.requiredObligationMask
    presentObligationMask := raw.presentObligationMask
    obligationCount := raw.obligationCount
    mediationOutcome := mediationOutcome
    durabilityProfile := durabilityProfile
  }

def CompleteAuthorizedEffect (vector : ProofCaseVector) : Prop :=
  vector.caseKind = .authorizedEffectToken ∧
  vector.requiredObligationMask = requiredObligationMask ∧
  vector.presentObligationMask = requiredObligationMask ∧
  vector.obligationCount = 8 ∧
  vector.mediationOutcome = .allow ∧
  vector.durabilityProfile ≠ .diagnostic ∧
  vector.tokenDigest.NonZero ∧
  vector.policyRevision.NonZero ∧
  vector.effectDigest.NonZero ∧
  vector.semanticRoot.NonZero ∧
  vector.executionRoot.NonZero

instance (vector : ProofCaseVector) : Decidable (CompleteAuthorizedEffect vector) := by
  unfold CompleteAuthorizedEffect Digest32.NonZero
  infer_instance

theorem completeByVerifiedBindings
    (vector : ProofCaseVector)
    (hkind : vector.caseKind = .authorizedEffectToken)
    (hrequired : vector.requiredObligationMask = requiredObligationMask)
    (hpresent : vector.presentObligationMask = requiredObligationMask)
    (hcount : vector.obligationCount = 8)
    (hmediation : vector.mediationOutcome = .allow)
    (hdurability : vector.durabilityProfile ≠ .diagnostic)
    (htoken : vector.tokenDigest.NonZero)
    (hpolicy : vector.policyRevision.NonZero)
    (heffect : vector.effectDigest.NonZero)
    (hsemantic : vector.semanticRoot.NonZero)
    (hexecution : vector.executionRoot.NonZero) :
    CompleteAuthorizedEffect vector := by
  exact ⟨hkind, hrequired, hpresent, hcount, hmediation, hdurability,
    htoken, hpolicy, heffect, hsemantic, hexecution⟩

theorem missingObligationRejectsComplete
    (vector : ProofCaseVector)
    (hmissing : vector.presentObligationMask ≠ requiredObligationMask) :
    ¬ CompleteAuthorizedEffect vector := by
  intro complete
  exact hmissing complete.2.2.1

theorem diagnosticRejectsComplete
    (vector : ProofCaseVector)
    (hdiagnostic : vector.durabilityProfile = .diagnostic) :
    ¬ CompleteAuthorizedEffect vector := by
  intro complete
  exact complete.2.2.2.2.2.1 hdiagnostic

theorem deniedMediationRejectsComplete
    (vector : ProofCaseVector)
    (hdenied : vector.mediationOutcome = .deny) :
    ¬ CompleteAuthorizedEffect vector := by
  intro complete
  have hallow := complete.2.2.2.2.1
  rw [hdenied] at hallow
  cases hallow

theorem zeroSemanticRootRejectsComplete
    (vector : ProofCaseVector)
    (hzero : vector.semanticRoot.bytes = List.replicate 32 0) :
    ¬ CompleteAuthorizedEffect vector := by
  intro complete
  exact complete.2.2.2.2.2.2.2.2.2.1 hzero

structure ProofReceipt where
  vectorDigest : Digest32
  theoremSetDigest : Digest32
  semanticRoot : Digest32
  executionRoot : Digest32
  batchRoot : Digest32
  nonce : UInt64
  epoch : UInt64
deriving Repr, DecidableEq

def verifiedProofReceipt
    (vector : ProofCaseVector)
    (_verified : CompleteAuthorizedEffect vector)
    (vectorDigest theoremSetDigest : Digest32) : ProofReceipt :=
  {
    vectorDigest := vectorDigest
    theoremSetDigest := theoremSetDigest
    semanticRoot := vector.semanticRoot
    executionRoot := vector.executionRoot
    batchRoot := vector.batchRoot
    nonce := vector.nonce
    epoch := vector.epoch
  }

end PooFlowProof.PooC3.AuthorizedEffectProofCase
