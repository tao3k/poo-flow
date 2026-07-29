import PooFlowProof.PooC3.EvidenceRetentionErasure

namespace PooFlowProof.PooC3.PrincipalKeyLifecycle

inductive KeyStatusKind where
  | candidate
  | active
  | expired
  | revoked
  | retired
  deriving DecidableEq, Repr

def MayAuthorizeNewSignature : KeyStatusKind → Prop
  | .active => True
  | .candidate => False
  | .expired => False
  | .revoked => False
  | .retired => False

def KeyPossessionCarriesGovernanceAuthority : KeyStatusKind → Prop
  | .candidate => False
  | .active => False
  | .expired => False
  | .revoked => False
  | .retired => False

structure KeyBinding
    (PrincipalIdentity KeyIdentity PurposeIdentity ScopeIdentity
      AlgorithmIdentity TimeAuthorityIdentity BindingIdentity : Type) where
  principalIdentity : PrincipalIdentity
  keyIdentity : KeyIdentity
  purposeIdentity : PurposeIdentity
  scopeIdentity : ScopeIdentity
  algorithmIdentity : AlgorithmIdentity
  timeAuthorityIdentity : TimeAuthorityIdentity
  bindingIdentity : BindingIdentity

structure KeyUseChecks where
  bindingMatches : Prop
  purposeMatches : Prop
  scopeMatches : Prop
  validityIntervalHolds : Prop
  notRevokedAtUse : Prop
  algorithmAllowed : Prop
  trustPathValid : Prop

def KeyUseChecksHold (checks : KeyUseChecks) : Prop :=
  checks.bindingMatches ∧
    checks.purposeMatches ∧
    checks.scopeMatches ∧
    checks.validityIntervalHolds ∧
    checks.notRevokedAtUse ∧
    checks.algorithmAllowed ∧
    checks.trustPathValid

structure KeyUseReceipt
    (PrincipalIdentity KeyIdentity PurposeIdentity ScopeIdentity
      AlgorithmIdentity TimeAuthorityIdentity BindingIdentity
      ReceiptIdentity : Type) where
  binding :
    KeyBinding
      PrincipalIdentity KeyIdentity PurposeIdentity ScopeIdentity
      AlgorithmIdentity TimeAuthorityIdentity BindingIdentity
  checks : KeyUseChecks
  checksHold : KeyUseChecksHold checks
  receiptIdentity : ReceiptIdentity

structure KeyRotation
    (PrincipalIdentity KeyIdentity BindingIdentity RotationIdentity : Type) where
  principalIdentity : PrincipalIdentity
  predecessorKey : KeyIdentity
  successorKey : KeyIdentity
  keysDistinct : predecessorKey ≠ successorKey
  predecessorBinding : BindingIdentity
  successorBinding : BindingIdentity
  bindingsDistinct : predecessorBinding ≠ successorBinding
  rotationIdentity : RotationIdentity

structure SigningEncryptionSeparation
    (SigningKeyIdentity EncryptionKeyIdentity : Type) where
  signingKey : SigningKeyIdentity
  encryptionKey : EncryptionKeyIdentity
  rolesSeparated : Prop
  separationEstablished : rolesSeparated

structure KeyRevocationObservation
    (KeyIdentity ObservationIdentity RevocationIdentity : Type) where
  keyIdentity : KeyIdentity
  effectiveObservationIdentity : ObservationIdentity
  revocationIdentity : RevocationIdentity
  newUseAllowed : Prop
  revokedKeyCannotAuthorizeNewUse : ¬ newUseAllowed

structure HistoricalSignatureEvidence
    (ContentCommitment SignatureIdentity PrincipalIdentity KeyBindingIdentity
      AlgorithmIdentity SigningObservationIdentity TrustPolicyIdentity
      RevocationObservationIdentity : Type) where
  contentCommitment : ContentCommitment
  signatureIdentity : SignatureIdentity
  principalIdentity : PrincipalIdentity
  keyBindingIdentity : KeyBindingIdentity
  algorithmIdentity : AlgorithmIdentity
  signingObservationIdentity : SigningObservationIdentity
  trustPolicyIdentity : TrustPolicyIdentity
  revocationObservationIdentity : RevocationObservationIdentity
  verificationMaterialRetained : Prop
  retentionEstablished : verificationMaterialRetained

structure HistoricalVerificationDecision
    (SignatureIdentity DecisionIdentity : Type) where
  signatureIdentity : SignatureIdentity
  signingTimeBindingValid : Prop
  trustPolicyAdmits : Prop
  revocationPolicyAdmits : Prop
  algorithmVerificationAvailable : Prop
  allHistoricalChecks :
    signingTimeBindingValid ∧
      trustPolicyAdmits ∧
      revocationPolicyAdmits ∧
      algorithmVerificationAvailable
  decisionIdentity : DecisionIdentity

structure AlgorithmMigration
    (OldAlgorithmIdentity NewAlgorithmIdentity AttestationIdentity : Type) where
  oldAlgorithmIdentity : OldAlgorithmIdentity
  newAlgorithmIdentity : NewAlgorithmIdentity
  algorithmsDistinct : Prop
  distinctionEstablished : algorithmsDistinct
  newAttestationIdentity : AttestationIdentity
  rewritesHistoricalSignature : Prop
  preservesHistoricalSignature : ¬ rewritesHistoricalSignature

structure KeyBindingIdentityScheme
    (PrincipalIdentity KeyIdentity PurposeIdentity ScopeIdentity
      AlgorithmIdentity BindingIdentity : Type) where
  identity :
    PrincipalIdentity →
      KeyIdentity →
      PurposeIdentity →
      ScopeIdentity →
      AlgorithmIdentity →
      BindingIdentity
  keyChangeChangesBinding :
    ∀ principal keyA keyB purpose scope algorithm,
      keyA ≠ keyB →
        identity principal keyA purpose scope algorithm ≠
          identity principal keyB purpose scope algorithm
  algorithmChangeChangesBinding :
    ∀ principal key purpose scope algorithmA algorithmB,
      algorithmA ≠ algorithmB →
        identity principal key purpose scope algorithmA ≠
          identity principal key purpose scope algorithmB

theorem activeKeyMayAuthorizeNewSignature :
    MayAuthorizeNewSignature .active := by
  simp [MayAuthorizeNewSignature]

theorem expiredKeyFailsClosedForNewSignature :
    ¬ MayAuthorizeNewSignature .expired := by
  simp [MayAuthorizeNewSignature]

theorem revokedKeyFailsClosedForNewSignature :
    ¬ MayAuthorizeNewSignature .revoked := by
  simp [MayAuthorizeNewSignature]

theorem activeKeyPossessionIsNotGovernanceAuthority :
    ¬ KeyPossessionCarriesGovernanceAuthority .active := by
  simp [KeyPossessionCarriesGovernanceAuthority]

theorem keyUseCarriesAllBindingChecks
    {PrincipalIdentity KeyIdentity PurposeIdentity ScopeIdentity
      AlgorithmIdentity TimeAuthorityIdentity BindingIdentity
      ReceiptIdentity : Type}
    (receipt :
      KeyUseReceipt
        PrincipalIdentity KeyIdentity PurposeIdentity ScopeIdentity
        AlgorithmIdentity TimeAuthorityIdentity BindingIdentity
        ReceiptIdentity) :
    KeyUseChecksHold receipt.checks :=
  receipt.checksHold

theorem rotationChangesKeyIdentity
    {PrincipalIdentity KeyIdentity BindingIdentity RotationIdentity : Type}
    (rotation :
      KeyRotation
        PrincipalIdentity KeyIdentity BindingIdentity RotationIdentity) :
    rotation.predecessorKey ≠ rotation.successorKey :=
  rotation.keysDistinct

theorem rotationChangesBindingIdentity
    {PrincipalIdentity KeyIdentity BindingIdentity RotationIdentity : Type}
    (rotation :
      KeyRotation
        PrincipalIdentity KeyIdentity BindingIdentity RotationIdentity) :
    rotation.predecessorBinding ≠ rotation.successorBinding :=
  rotation.bindingsDistinct

theorem signingAndEncryptionRolesRemainSeparated
    {SigningKeyIdentity EncryptionKeyIdentity : Type}
    (separation :
      SigningEncryptionSeparation
        SigningKeyIdentity EncryptionKeyIdentity) :
    separation.rolesSeparated :=
  separation.separationEstablished

theorem revocationPreventsNewKeyUse
    {KeyIdentity ObservationIdentity RevocationIdentity : Type}
    (revocation :
      KeyRevocationObservation
        KeyIdentity ObservationIdentity RevocationIdentity) :
    ¬ revocation.newUseAllowed :=
  revocation.revokedKeyCannotAuthorizeNewUse

theorem historicalSignatureRetainsVerificationMaterial
    {ContentCommitment SignatureIdentity PrincipalIdentity KeyBindingIdentity
      AlgorithmIdentity SigningObservationIdentity TrustPolicyIdentity
      RevocationObservationIdentity : Type}
    (evidence :
      HistoricalSignatureEvidence
        ContentCommitment SignatureIdentity PrincipalIdentity
        KeyBindingIdentity AlgorithmIdentity SigningObservationIdentity
        TrustPolicyIdentity RevocationObservationIdentity) :
    evidence.verificationMaterialRetained :=
  evidence.retentionEstablished

theorem historicalVerificationUsesSigningTimeBinding
    {SignatureIdentity DecisionIdentity : Type}
    (decision :
      HistoricalVerificationDecision
        SignatureIdentity DecisionIdentity) :
    decision.signingTimeBindingValid :=
  decision.allHistoricalChecks.1

theorem historicalVerificationUsesRevocationPolicy
    {SignatureIdentity DecisionIdentity : Type}
    (decision :
      HistoricalVerificationDecision
        SignatureIdentity DecisionIdentity) :
    decision.revocationPolicyAdmits :=
  decision.allHistoricalChecks.2.2.1

theorem historicalVerificationRequiresAlgorithmAvailability
    {SignatureIdentity DecisionIdentity : Type}
    (decision :
      HistoricalVerificationDecision
        SignatureIdentity DecisionIdentity) :
    decision.algorithmVerificationAvailable :=
  decision.allHistoricalChecks.2.2.2

theorem algorithmMigrationPreservesHistoricalSignature
    {OldAlgorithmIdentity NewAlgorithmIdentity AttestationIdentity : Type}
    (migration :
      AlgorithmMigration
        OldAlgorithmIdentity NewAlgorithmIdentity AttestationIdentity) :
    ¬ migration.rewritesHistoricalSignature :=
  migration.preservesHistoricalSignature

theorem keyChangeCreatesNewBindingIdentity
    {PrincipalIdentity KeyIdentity PurposeIdentity ScopeIdentity
      AlgorithmIdentity BindingIdentity : Type}
    (scheme :
      KeyBindingIdentityScheme
        PrincipalIdentity KeyIdentity PurposeIdentity ScopeIdentity
        AlgorithmIdentity BindingIdentity)
    (principal : PrincipalIdentity)
    (keyA keyB : KeyIdentity)
    (purpose : PurposeIdentity)
    (scope : ScopeIdentity)
    (algorithm : AlgorithmIdentity)
    (changed : keyA ≠ keyB) :
    scheme.identity principal keyA purpose scope algorithm ≠
      scheme.identity principal keyB purpose scope algorithm :=
  scheme.keyChangeChangesBinding
    principal keyA keyB purpose scope algorithm changed

theorem algorithmChangeCreatesNewBindingIdentity
    {PrincipalIdentity KeyIdentity PurposeIdentity ScopeIdentity
      AlgorithmIdentity BindingIdentity : Type}
    (scheme :
      KeyBindingIdentityScheme
        PrincipalIdentity KeyIdentity PurposeIdentity ScopeIdentity
        AlgorithmIdentity BindingIdentity)
    (principal : PrincipalIdentity)
    (key : KeyIdentity)
    (purpose : PurposeIdentity)
    (scope : ScopeIdentity)
    (algorithmA algorithmB : AlgorithmIdentity)
    (changed : algorithmA ≠ algorithmB) :
    scheme.identity principal key purpose scope algorithmA ≠
      scheme.identity principal key purpose scope algorithmB :=
  scheme.algorithmChangeChangesBinding
    principal key purpose scope algorithmA algorithmB changed

end PooFlowProof.PooC3.PrincipalKeyLifecycle
