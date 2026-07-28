namespace PooFlowProof.PooC3.RealizationAdmission

inductive Disposition where
  | pureValue
  | artifactBacked
  | contextBound
  | suspendedOrUncommitted
deriving Repr, DecidableEq

structure AdmissionEvidence where
  contentMatches : Prop
  loweringMatches : Prop
  dependencyMatches : Prop
  policyMatches : Prop
  portableValue : Prop
  artifactVerified : Prop
  noUnresolvedBarrier : Prop

inductive Eligible : Disposition → AdmissionEvidence → Prop where
  | pureValue
      {evidence : AdmissionEvidence}
      (content : evidence.contentMatches)
      (lowering : evidence.loweringMatches)
      (dependency : evidence.dependencyMatches)
      (policy : evidence.policyMatches)
      (portable : evidence.portableValue)
      (clear : evidence.noUnresolvedBarrier) :
      Eligible Disposition.pureValue evidence
  | artifactBacked
      {evidence : AdmissionEvidence}
      (content : evidence.contentMatches)
      (lowering : evidence.loweringMatches)
      (dependency : evidence.dependencyMatches)
      (policy : evidence.policyMatches)
      (verified : evidence.artifactVerified)
      (clear : evidence.noUnresolvedBarrier) :
      Eligible Disposition.artifactBacked evidence

theorem contextBoundNeverEligible
    (evidence : AdmissionEvidence) :
    ¬ Eligible Disposition.contextBound evidence := by
  intro eligible
  cases eligible

theorem suspendedOrUncommittedNeverEligible
    (evidence : AdmissionEvidence) :
    ¬ Eligible Disposition.suspendedOrUncommitted evidence := by
  intro eligible
  cases eligible

theorem eligibleDispositionIsPortable
    {disposition : Disposition}
    {evidence : AdmissionEvidence}
    (eligible : Eligible disposition evidence) :
    disposition = Disposition.pureValue ∨
      disposition = Disposition.artifactBacked := by
  cases eligible with
  | pureValue => exact Or.inl rfl
  | artifactBacked => exact Or.inr rfl

inductive PortablePayload where
  | valueContent (contentIdentity : Nat)
  | artifactReference (artifactIdentity verifierEvidence : Nat)
deriving Repr, DecidableEq

def payloadKind : Disposition → Option (PortablePayload → Prop)
  | Disposition.pureValue =>
      some (fun payload =>
        match payload with
        | PortablePayload.valueContent _ => True
        | _ => False)
  | Disposition.artifactBacked =>
      some (fun payload =>
        match payload with
        | PortablePayload.artifactReference _ _ => True
        | _ => False)
  | Disposition.contextBound => none
  | Disposition.suspendedOrUncommitted => none

theorem contextBoundHasNoPortablePayload :
    payloadKind Disposition.contextBound = none := by
  rfl

theorem suspendedStateHasNoPortablePayload :
    payloadKind Disposition.suspendedOrUncommitted = none := by
  rfl

inductive PayloadCompatible : Disposition → PortablePayload → Prop where
  | pureValue
      (contentIdentity : Nat) :
      PayloadCompatible
        Disposition.pureValue
        (PortablePayload.valueContent contentIdentity)
  | artifactBacked
      (artifactIdentity verifierEvidence : Nat) :
      PayloadCompatible
        Disposition.artifactBacked
        (PortablePayload.artifactReference artifactIdentity verifierEvidence)

structure AdmissionResult where
  disposition : Disposition
  evidence : AdmissionEvidence
  sourceRoot : Nat
  receivingRoot : Nat
  payload : PortablePayload
  eligible : Eligible disposition evidence
  payloadCompatible : PayloadCompatible disposition payload
  rootsDistinct : sourceRoot ≠ receivingRoot

theorem admittedRootsRemainDistinct
    (result : AdmissionResult) :
    result.sourceRoot ≠ result.receivingRoot := by
  exact result.rootsDistinct

theorem admittedResultCannotBeContextBound
    (result : AdmissionResult) :
    result.disposition ≠ Disposition.contextBound := by
  intro contextBound
  have eligible := result.eligible
  rw [contextBound] at eligible
  exact contextBoundNeverEligible result.evidence eligible

theorem admittedResultCannotBeSuspended
    (result : AdmissionResult) :
    result.disposition ≠ Disposition.suspendedOrUncommitted := by
  intro suspended
  have eligible := result.eligible
  rw [suspended] at eligible
  exact suspendedOrUncommittedNeverEligible result.evidence eligible

theorem admittedPureValueCarriesValueContent
    (result : AdmissionResult)
    (pureValue : result.disposition = Disposition.pureValue) :
    ∃ contentIdentity : Nat,
      result.payload = PortablePayload.valueContent contentIdentity := by
  have compatible := result.payloadCompatible
  rw [pureValue] at compatible
  cases payload : result.payload with
  | valueContent contentIdentity =>
      exact ⟨contentIdentity, rfl⟩
  | artifactReference artifactIdentity verifierEvidence =>
      rw [payload] at compatible
      cases compatible

theorem admittedArtifactCarriesVerifiedReference
    (result : AdmissionResult)
    (artifactBacked :
      result.disposition = Disposition.artifactBacked) :
    ∃ artifactIdentity verifierEvidence : Nat,
      result.payload =
        PortablePayload.artifactReference artifactIdentity verifierEvidence := by
  have compatible := result.payloadCompatible
  rw [artifactBacked] at compatible
  cases payload : result.payload with
  | valueContent contentIdentity =>
      rw [payload] at compatible
      cases compatible
  | artifactReference artifactIdentity verifierEvidence =>
      exact ⟨artifactIdentity, verifierEvidence, rfl⟩

end PooFlowProof.PooC3.RealizationAdmission
