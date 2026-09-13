import PooFlowProof.PooC3.GenerationRetirementReclamation

namespace PooFlowProof.PooC3.PersistentStateMigrationContract

open PooFlowProof.PooC3.GenerationRetirementReclamation

inductive CompatibilityRole where
  | readOld
  | readNew
  | writeOld
  | writeNew
  | effectReplay
  | continuationResume
  | reversion
  deriving DecidableEq, Repr

structure DirectionalCompatibilityEvidence
    (StateVersion EvidenceIdentity : Type) where
  sourceVersion : StateVersion
  targetVersion : StateVersion
  role : CompatibilityRole
  evidenceIdentity : EvidenceIdentity
  relation : CompatibilityRole → StateVersion → StateVersion → Prop
  relationHolds : relation role sourceVersion targetVersion

structure ExpandReceipt
    (Generation Capability ReceiptIdentity : Type) where
  targetGeneration : Generation
  addedCapabilities : List Capability
  receiptIdentity : ReceiptIdentity

structure ActivationAdmission
    (Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity : Type) where
  expand :
    ExpandReceipt Generation Capability ExpandReceiptIdentity
  requiredRoles : List CompatibilityRole
  compatibilityEvidence :
    List
      (DirectionalCompatibilityEvidence
        StateVersion CompatibilityEvidenceIdentity)
  everyRequiredRoleCovered :
    ∀ role ∈ requiredRoles,
      ∃ evidence ∈ compatibilityEvidence,
        evidence.role = role
  activationReceiptIdentity : ActivationReceiptIdentity

structure MigrationReceipt
    (Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity : Type) where
  activation :
    ActivationAdmission
      Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity
  beforeVersion : StateVersion
  afterVersion : StateVersion
  migrationRelation : StateVersion → StateVersion → Prop
  migrationHolds : migrationRelation beforeVersion afterVersion
  reversionCompatibility :
    DirectionalCompatibilityEvidence
      StateVersion CompatibilityEvidenceIdentity
  reversionRole :
    reversionCompatibility.role = .reversion
  migrationReceiptIdentity : MigrationReceiptIdentity

structure ContractAdmission
    (Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
      ReaderIdentity WriterIdentity
      ReversionWindowReceiptIdentity ContractReceiptIdentity : Type) where
  migration :
    MigrationReceipt
      Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
  oldReaders : List ReaderIdentity
  oldWriters : List WriterIdentity
  noOldReaders : oldReaders = []
  noOldWriters : oldWriters = []
  reversionWindowReceiptIdentity : ReversionWindowReceiptIdentity
  reversionWindowClosed : ReversionWindowReceiptIdentity → Prop
  reversionWindowClosureHolds :
    reversionWindowClosed reversionWindowReceiptIdentity
  contractReceiptIdentity : ContractReceiptIdentity

structure ContractQuiescenceBridge
    (Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
      ReaderIdentity WriterIdentity
      ReversionWindowReceiptIdentity ContractReceiptIdentity
      Scope HeadVersion AdapterProtocol HeadObservationReceipt
      FenceIdentity RetirementReceiptIdentity QuiescenceReceiptIdentity :
      Type) where
  contract :
    ContractAdmission
      Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
      ReaderIdentity WriterIdentity
      ReversionWindowReceiptIdentity ContractReceiptIdentity
  quiescence :
    QuiescenceWitness
      Scope Generation HeadVersion AdapterProtocol HeadObservationReceipt
      FenceIdentity RetirementReceiptIdentity
      ReaderIdentity WriterIdentity QuiescenceReceiptIdentity
  oldReadersProjectFromLivePins :
    contract.oldReaders = quiescence.livePins
  oldWritersProjectFromOutstandingObligations :
    contract.oldWriters = quiescence.outstandingObligations

inductive CompatibilityEvidenceKind where
  | roleSpecificDirectionalEvidence
  | symmetricCompatibilitySummary
  | missingRoleEvidence
  deriving DecidableEq, Repr

def AdmitsGenerationActivation : CompatibilityEvidenceKind → Prop
  | .roleSpecificDirectionalEvidence => True
  | .symmetricCompatibilitySummary => False
  | .missingRoleEvidence => False

inductive FixedPointInputKind where
  | pureCompatibilityContract
  | hiddenLiveResourceRead
  deriving DecidableEq, Repr

def AdmittedInPureFixedPoint : FixedPointInputKind → Prop
  | .pureCompatibilityContract => True
  | .hiddenLiveResourceRead => False

theorem symmetricSummaryDoesNotAdmitActivation :
    ¬ AdmitsGenerationActivation .symmetricCompatibilitySummary := by
  simp [AdmitsGenerationActivation]

theorem missingRoleEvidenceFailsClosed :
    ¬ AdmitsGenerationActivation .missingRoleEvidence := by
  simp [AdmitsGenerationActivation]

theorem hiddenLiveReadIsNotAdmittedInPureFixedPoint :
    ¬ AdmittedInPureFixedPoint .hiddenLiveResourceRead := by
  simp [AdmittedInPureFixedPoint]

theorem activationRequiresExpandReceipt
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity : Type}
    (activation :
      ActivationAdmission
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity) :
    ∃ expand :
        ExpandReceipt Generation Capability ExpandReceiptIdentity,
      expand = activation.expand := by
  exact ⟨activation.expand, rfl⟩

theorem activationRequiresEveryDirectionalRole
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity : Type}
    (activation :
      ActivationAdmission
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity) :
    ∀ role ∈ activation.requiredRoles,
      ∃ evidence ∈ activation.compatibilityEvidence,
        evidence.role = role :=
  activation.everyRequiredRoleCovered

theorem migrationRequiresActivation
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity : Type}
    (migration :
      MigrationReceipt
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity MigrationReceiptIdentity) :
    ∃ activation :
        ActivationAdmission
          Generation Capability ExpandReceiptIdentity
          StateVersion CompatibilityEvidenceIdentity
          ActivationReceiptIdentity,
      activation = migration.activation := by
  exact ⟨migration.activation, rfl⟩

theorem migrationCarriesReversionCompatibility
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity : Type}
    (migration :
      MigrationReceipt
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity MigrationReceiptIdentity) :
    migration.reversionCompatibility.role = .reversion :=
  migration.reversionRole

theorem contractRequiresMigration
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
      ReaderIdentity WriterIdentity
      ReversionWindowReceiptIdentity ContractReceiptIdentity : Type}
    (contract :
      ContractAdmission
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity MigrationReceiptIdentity
        ReaderIdentity WriterIdentity
        ReversionWindowReceiptIdentity ContractReceiptIdentity) :
    ∃ migration :
        MigrationReceipt
          Generation Capability ExpandReceiptIdentity
          StateVersion CompatibilityEvidenceIdentity
          ActivationReceiptIdentity MigrationReceiptIdentity,
      migration = contract.migration := by
  exact ⟨contract.migration, rfl⟩

theorem contractRequiresNoOldReaders
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
      ReaderIdentity WriterIdentity
      ReversionWindowReceiptIdentity ContractReceiptIdentity : Type}
    (contract :
      ContractAdmission
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity MigrationReceiptIdentity
        ReaderIdentity WriterIdentity
        ReversionWindowReceiptIdentity ContractReceiptIdentity) :
    contract.oldReaders = [] :=
  contract.noOldReaders

theorem contractRequiresNoOldWriters
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
      ReaderIdentity WriterIdentity
      ReversionWindowReceiptIdentity ContractReceiptIdentity : Type}
    (contract :
      ContractAdmission
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity MigrationReceiptIdentity
        ReaderIdentity WriterIdentity
        ReversionWindowReceiptIdentity ContractReceiptIdentity) :
    contract.oldWriters = [] :=
  contract.noOldWriters

theorem contractRequiresClosedReversionWindow
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
      ReaderIdentity WriterIdentity
      ReversionWindowReceiptIdentity ContractReceiptIdentity : Type}
    (contract :
      ContractAdmission
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity MigrationReceiptIdentity
        ReaderIdentity WriterIdentity
        ReversionWindowReceiptIdentity ContractReceiptIdentity) :
    contract.reversionWindowClosed
      contract.reversionWindowReceiptIdentity :=
  contract.reversionWindowClosureHolds

theorem contractDrainRequiresQuiescence
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
      ReaderIdentity WriterIdentity
      ReversionWindowReceiptIdentity ContractReceiptIdentity
      Scope HeadVersion AdapterProtocol HeadObservationReceipt
      FenceIdentity RetirementReceiptIdentity QuiescenceReceiptIdentity :
      Type}
    (bridge :
      ContractQuiescenceBridge
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity MigrationReceiptIdentity
        ReaderIdentity WriterIdentity
        ReversionWindowReceiptIdentity ContractReceiptIdentity
        Scope HeadVersion AdapterProtocol HeadObservationReceipt
        FenceIdentity RetirementReceiptIdentity QuiescenceReceiptIdentity) :
    ∃ witness :
        QuiescenceWitness
          Scope Generation HeadVersion AdapterProtocol HeadObservationReceipt
          FenceIdentity RetirementReceiptIdentity
          ReaderIdentity WriterIdentity QuiescenceReceiptIdentity,
      witness = bridge.quiescence := by
  exact ⟨bridge.quiescence, rfl⟩

theorem contractReadersProjectFromQuiescentPins
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
      ReaderIdentity WriterIdentity
      ReversionWindowReceiptIdentity ContractReceiptIdentity
      Scope HeadVersion AdapterProtocol HeadObservationReceipt
      FenceIdentity RetirementReceiptIdentity QuiescenceReceiptIdentity :
      Type}
    (bridge :
      ContractQuiescenceBridge
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity MigrationReceiptIdentity
        ReaderIdentity WriterIdentity
        ReversionWindowReceiptIdentity ContractReceiptIdentity
        Scope HeadVersion AdapterProtocol HeadObservationReceipt
        FenceIdentity RetirementReceiptIdentity QuiescenceReceiptIdentity) :
    bridge.contract.oldReaders = bridge.quiescence.livePins :=
  bridge.oldReadersProjectFromLivePins

theorem contractWritersProjectFromQuiescentObligations
    {Generation Capability ExpandReceiptIdentity
      StateVersion CompatibilityEvidenceIdentity
      ActivationReceiptIdentity MigrationReceiptIdentity
      ReaderIdentity WriterIdentity
      ReversionWindowReceiptIdentity ContractReceiptIdentity
      Scope HeadVersion AdapterProtocol HeadObservationReceipt
      FenceIdentity RetirementReceiptIdentity QuiescenceReceiptIdentity :
      Type}
    (bridge :
      ContractQuiescenceBridge
        Generation Capability ExpandReceiptIdentity
        StateVersion CompatibilityEvidenceIdentity
        ActivationReceiptIdentity MigrationReceiptIdentity
        ReaderIdentity WriterIdentity
        ReversionWindowReceiptIdentity ContractReceiptIdentity
        Scope HeadVersion AdapterProtocol HeadObservationReceipt
        FenceIdentity RetirementReceiptIdentity QuiescenceReceiptIdentity) :
    bridge.contract.oldWriters =
      bridge.quiescence.outstandingObligations :=
  bridge.oldWritersProjectFromOutstandingObligations

end PooFlowProof.PooC3.PersistentStateMigrationContract
