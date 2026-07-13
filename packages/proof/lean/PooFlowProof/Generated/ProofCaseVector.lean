/- Generated from proof-case-vector-v1.toml. Do not edit. -/
namespace PooFlowProof.Generated.ProofCaseVector

def abiVersion : UInt32 := 1
def vectorSize : Nat := 424
def vectorAlignment : Nat := 8
def schemaFingerprintHex : String := "bad9c5d0781d0a99e2f8d58cb94abae9dfc2eda4c71a01009897f7fc5419e0e7"
def requiredObligationMask : UInt64 := 0x00000000000000ff

def caseKindAuthorizedEffectToken : UInt32 := 1
def mediationAllow : UInt32 := 1
def mediationDeny : UInt32 := 2
def mediationInvalidToken : UInt32 := 3
def durabilityStrict : UInt32 := 1
def durabilityBatched : UInt32 := 2
def durabilityDiagnostic : UInt32 := 3

def fieldAbiVersionOffset : Nat := 0
def fieldCaseKindOffset : Nat := 4
def fieldSchemaFingerprintOffset : Nat := 8
def fieldTokenDigestOffset : Nat := 40
def fieldPolicyRevisionOffset : Nat := 72
def fieldEffectDigestOffset : Nat := 104
def fieldSemanticRootOffset : Nat := 136
def fieldExecutionRootOffset : Nat := 168
def fieldBatchRootOffset : Nat := 200
def fieldSubjectBindingOffset : Nat := 232
def fieldResourceBindingOffset : Nat := 264
def fieldActionBindingOffset : Nat := 296
def fieldPreviousEvidenceRootOffset : Nat := 328
def fieldNonceOffset : Nat := 360
def fieldEpochOffset : Nat := 368
def fieldSequenceOffset : Nat := 376
def fieldRequiredObligationMaskOffset : Nat := 384
def fieldPresentObligationMaskOffset : Nat := 392
def fieldObligationCountOffset : Nat := 400
def fieldMediationOutcomeOffset : Nat := 404
def fieldDurabilityProfileOffset : Nat := 408
def fieldReservedOffset : Nat := 412

def obligationPolicyRevisionBound : UInt64 := 0x0000000000000001
def obligationEffectDigestBound : UInt64 := 0x0000000000000002
def obligationSemanticRootBound : UInt64 := 0x0000000000000004
def obligationExecutionRootBound : UInt64 := 0x0000000000000008
def obligationObligationSetComplete : UInt64 := 0x0000000000000010
def obligationNonceEpochFresh : UInt64 := 0x0000000000000020
def obligationDiagnosticNonExecutable : UInt64 := 0x0000000000000040
def obligationL3ChainComplete : UInt64 := 0x0000000000000080

end PooFlowProof.Generated.ProofCaseVector
