import PooFlowProof.PooC3.PersistentStateMigrationContract

namespace PooFlowProof.PooC3.GraphCompatibilityClosure

open PooFlowProof.PooC3.PersistentStateMigrationContract

structure CompatibilityClosureInput
    (Root Node Revision Edge ObservationCut Policy CutIdentity : Type) where
  canonicalRoot : Root
  selectedRevisions : List (Node × Revision)
  resolvedNodes : List Node
  resolvedEdges : List Edge
  observationCut : ObservationCut
  policyIdentity : Policy
  cutIdentity : CutIdentity

structure StronglyConnectedComponent
    (Node Edge ComponentIdentity : Type) where
  componentIdentity : ComponentIdentity
  nodes : List Node
  internalEdges : List Edge

structure GraphEdgeCompatibilityEvidence
    (Edge StateVersion EvidenceIdentity : Type) where
  edge : Edge
  directional :
    DirectionalCompatibilityEvidence StateVersion EvidenceIdentity

structure SCCClosureEvidence
    (Node Edge ComponentIdentity StateVersion EvidenceIdentity : Type) where
  component :
    StronglyConnectedComponent Node Edge ComponentIdentity
  requiredEdges : List Edge
  edgeEvidence :
    List (GraphEdgeCompatibilityEvidence Edge StateVersion EvidenceIdentity)
  everyRequiredEdgeCovered :
    ∀ edge ∈ requiredEdges,
      ∃ evidence ∈ edgeEvidence,
        evidence.edge = edge
  closureRelation : List Node → List Edge → Prop
  closureHolds :
    closureRelation component.nodes component.internalEdges

structure GraphCompatibilityProof
    (Root Node Revision Edge ObservationCut Policy CutIdentity
      ComponentIdentity StateVersion EvidenceIdentity ProofIdentity : Type)
    where
  input :
    CompatibilityClosureInput
      Root Node Revision Edge ObservationCut Policy CutIdentity
  components :
    List (StronglyConnectedComponent Node Edge ComponentIdentity)
  componentEvidence :
    List
      (SCCClosureEvidence
        Node Edge ComponentIdentity StateVersion EvidenceIdentity)
  everyComponentCovered :
    ∀ component ∈ components,
      ∃ evidence ∈ componentEvidence,
        evidence.component.componentIdentity = component.componentIdentity
  proofIdentity : ProofIdentity

structure CompatibilityViolation
    (Root Node Revision Edge ObservationCut Policy CutIdentity
      ViolationIdentity : Type) where
  input :
    CompatibilityClosureInput
      Root Node Revision Edge ObservationCut Policy CutIdentity
  violatingEdge : Edge
  violationIdentity : ViolationIdentity

structure CompatibilitySuspension
    (Root Node Revision Edge ObservationCut Policy CutIdentity
      SuspensionIdentity : Type) where
  input :
    CompatibilityClosureInput
      Root Node Revision Edge ObservationCut Policy CutIdentity
  missingEvidence : List Edge
  missingEvidenceNonempty : missingEvidence ≠ []
  suspensionIdentity : SuspensionIdentity

inductive CompatibilityOutcomeKind where
  | exactCutProof
  | pairwiseSummary
  | violation
  | suspension
  deriving DecidableEq, Repr

def AdmitsGraphActivation : CompatibilityOutcomeKind → Prop
  | .exactCutProof => True
  | .pairwiseSummary => False
  | .violation => False
  | .suspension => False

def IsDefinitiveViolation : CompatibilityOutcomeKind → Prop
  | .violation => True
  | .exactCutProof => False
  | .pairwiseSummary => False
  | .suspension => False

structure ClosureIdentityScheme
    (CutIdentity Policy ProofIdentity : Type) where
  identity : CutIdentity → Policy → ProofIdentity
  cutChangeChangesIdentity :
    ∀ cutA cutB policy,
      cutA ≠ cutB →
        identity cutA policy ≠ identity cutB policy
  policyChangeChangesIdentity :
    ∀ cut policyA policyB,
      policyA ≠ policyB →
        identity cut policyA ≠ identity cut policyB

theorem pairwiseSummaryDoesNotAdmitGraphActivation :
    ¬ AdmitsGraphActivation .pairwiseSummary := by
  simp [AdmitsGraphActivation]

theorem violationFailsClosed :
    ¬ AdmitsGraphActivation .violation := by
  simp [AdmitsGraphActivation]

theorem suspensionDoesNotAdmitGraphActivation :
    ¬ AdmitsGraphActivation .suspension := by
  simp [AdmitsGraphActivation]

theorem suspensionIsNotDefinitiveViolation :
    ¬ IsDefinitiveViolation .suspension := by
  simp [IsDefinitiveViolation]

theorem exactCutProofAdmitsGraphActivation :
    AdmitsGraphActivation .exactCutProof := by
  simp [AdmitsGraphActivation]

theorem graphProofCarriesExactSemanticCut
    {Root Node Revision Edge ObservationCut Policy CutIdentity
      ComponentIdentity StateVersion EvidenceIdentity ProofIdentity : Type}
    (proof :
      GraphCompatibilityProof
        Root Node Revision Edge ObservationCut Policy CutIdentity
        ComponentIdentity StateVersion EvidenceIdentity ProofIdentity) :
    ∃ input :
        CompatibilityClosureInput
          Root Node Revision Edge ObservationCut Policy CutIdentity,
      input = proof.input := by
  exact ⟨proof.input, rfl⟩

theorem graphProofCoversEverySCC
    {Root Node Revision Edge ObservationCut Policy CutIdentity
      ComponentIdentity StateVersion EvidenceIdentity ProofIdentity : Type}
    (proof :
      GraphCompatibilityProof
        Root Node Revision Edge ObservationCut Policy CutIdentity
        ComponentIdentity StateVersion EvidenceIdentity ProofIdentity) :
    ∀ component ∈ proof.components,
      ∃ evidence ∈ proof.componentEvidence,
        evidence.component.componentIdentity = component.componentIdentity :=
  proof.everyComponentCovered

theorem sccClosureCoversEveryRequiredEdge
    {Node Edge ComponentIdentity StateVersion EvidenceIdentity : Type}
    (evidence :
      SCCClosureEvidence
        Node Edge ComponentIdentity StateVersion EvidenceIdentity) :
    ∀ edge ∈ evidence.requiredEdges,
      ∃ edgeEvidence ∈ evidence.edgeEvidence,
        edgeEvidence.edge = edge :=
  evidence.everyRequiredEdgeCovered

theorem suspensionCarriesMissingEvidence
    {Root Node Revision Edge ObservationCut Policy CutIdentity
      SuspensionIdentity : Type}
    (suspension :
      CompatibilitySuspension
        Root Node Revision Edge ObservationCut Policy CutIdentity
        SuspensionIdentity) :
    suspension.missingEvidence ≠ [] :=
  suspension.missingEvidenceNonempty

theorem cutChangeCreatesNewClosureIdentity
    {CutIdentity Policy ProofIdentity : Type}
    (scheme :
      ClosureIdentityScheme CutIdentity Policy ProofIdentity)
    (cutA cutB : CutIdentity)
    (policy : Policy)
    (changed : cutA ≠ cutB) :
    scheme.identity cutA policy ≠ scheme.identity cutB policy :=
  scheme.cutChangeChangesIdentity cutA cutB policy changed

theorem policyChangeCreatesNewClosureIdentity
    {CutIdentity Policy ProofIdentity : Type}
    (scheme :
      ClosureIdentityScheme CutIdentity Policy ProofIdentity)
    (cut : CutIdentity)
    (policyA policyB : Policy)
    (changed : policyA ≠ policyB) :
    scheme.identity cut policyA ≠ scheme.identity cut policyB :=
  scheme.policyChangeChangesIdentity cut policyA policyB changed

end PooFlowProof.PooC3.GraphCompatibilityClosure
