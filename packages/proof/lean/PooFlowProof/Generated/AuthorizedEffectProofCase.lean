import PooFlowProof.PooC3.AuthorizedEffectProofCase

namespace PooFlowProof.Generated.AuthorizedEffectProofCase

open PooFlowProof.Generated.ProofCaseVector
open PooFlowProof.PooC3.AuthorizedEffectProofCase

def digest (value : UInt8) : Digest32 :=
  { bytes := List.replicate 32 value }

def validVector : ProofCaseVector where
  caseKind := .authorizedEffectToken
  tokenDigest := digest 1
  policyRevision := digest 2
  effectDigest := digest 3
  semanticRoot := digest 4
  executionRoot := digest 5
  batchRoot := digest 6
  previousEvidenceRoot := digest 7
  nonce := 11
  epoch := 4
  sequence := 19
  requiredObligationMask := requiredObligationMask
  presentObligationMask := requiredObligationMask
  obligationCount := 8
  mediationOutcome := .allow
  durabilityProfile := .strict

theorem validVectorComplete : CompleteAuthorizedEffect validVector := by
  native_decide

def validRaw : RawProofCaseVector where
  abiVersion := abiVersion
  caseKind := caseKindAuthorizedEffectToken
  schemaFingerprintHex := schemaFingerprintHex
  tokenDigest := (digest 1).bytes
  policyRevision := (digest 2).bytes
  effectDigest := (digest 3).bytes
  semanticRoot := (digest 4).bytes
  executionRoot := (digest 5).bytes
  batchRoot := (digest 6).bytes
  previousEvidenceRoot := (digest 7).bytes
  nonce := 11
  epoch := 4
  sequence := 19
  requiredObligationMask := requiredObligationMask
  presentObligationMask := requiredObligationMask
  obligationCount := 8
  mediationOutcome := mediationAllow
  durabilityProfile := durabilityStrict
  reservedZero := true

theorem validRawDecodes : decode validRaw = .ok validVector := by
  native_decide

def invalidSchemaRaw : RawProofCaseVector :=
  { validRaw with schemaFingerprintHex := "invalid" }

theorem invalidSchemaRejected :
    decode invalidSchemaRaw = .error .schemaFingerprintMismatch := by
  native_decide

def unsupportedObligationRaw : RawProofCaseVector :=
  { validRaw with requiredObligationMask := 0x100 }

theorem unsupportedObligationRejected :
    decode unsupportedObligationRaw = .error .unsupportedObligation := by
  native_decide

def malformedDigestRaw : RawProofCaseVector :=
  { validRaw with semanticRoot := List.replicate 31 4 }

theorem malformedDigestRejected :
    decode malformedDigestRaw = .error .malformedDigest := by
  native_decide

def diagnosticVector : ProofCaseVector :=
  { validVector with durabilityProfile := .diagnostic }

theorem diagnosticVectorRejected :
    ¬ CompleteAuthorizedEffect diagnosticVector :=
  diagnosticRejectsComplete diagnosticVector rfl

def missingObligationVector : ProofCaseVector :=
  { validVector with presentObligationMask := 0x7f }

theorem missingObligationVectorRejected :
    ¬ CompleteAuthorizedEffect missingObligationVector :=
  missingObligationRejectsComplete missingObligationVector (by native_decide)

def vectorDigest : Digest32 := digest 8
def theoremSetDigest : Digest32 := digest 9

def validProofReceipt : ProofReceipt :=
  verifiedProofReceipt validVector validVectorComplete vectorDigest theoremSetDigest

theorem validReceiptBindsSemanticRoot :
    validProofReceipt.semanticRoot = validVector.semanticRoot := rfl

theorem validReceiptBindsExecutionRoot :
    validProofReceipt.executionRoot = validVector.executionRoot := rfl

end PooFlowProof.Generated.AuthorizedEffectProofCase
