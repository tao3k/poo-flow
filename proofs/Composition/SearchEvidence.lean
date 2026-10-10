-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import SearchDag
namespace POO.Flow.SearchEvidence
open POO.Flow.SearchAttempt
def quintSourceDigest : String := "sha256:095affffc7d2c30046c04dfba89c6a54e7d2b6d784c368666f50514fe9663e60"
def quintInvariantNames : List String :=
  ["ExactCausalParents", "ObservationScope", "TemporalOrder", "CommittedEvidence"]

structure Event where
  identity : Nat
  stage : Nat
  generation : Nat
  sourceCut : Nat
  position : Nat
  parents : List Nat
  committed : Bool
  admissibleModality : Bool

/-- Current predecessor observations must already be owner-admitted.
Their identities are evidence; structural edges alone cannot manufacture them. -/
def AdmitsEvidence (node : LeanPoo.C4.Node) (state : State) (request : Request)
    (observations : String → Option Event) (retained : List Nat) (event : Event) : Prop :=
  Admits state request ∧
  event.stage = state.scope.stage ∧ event.generation = state.scope.generation ∧
  event.sourceCut = state.scope.sourceCut ∧ event.committed = true ∧
  event.admissibleModality = true ∧ event.identity ∉ retained ∧ event.parents.Nodup ∧
  (∀ identity, identity ∈ event.parents ↔
    ∃ parent ∈ node.parentOrders.flatten, ∃ observed,
      observations parent = some observed ∧ observed.identity = identity) ∧
  (∀ parent ∈ node.parentOrders.flatten, ∃ observed,
    observations parent = some observed ∧ observed.position < event.position)

theorem observation_scope {node : LeanPoo.C4.Node} {state : State} {request : Request}
    {observations : String → Option Event} {retained : List Nat} {event : Event}
    (admitted : AdmitsEvidence node state request observations retained event) :
    event.generation = state.scope.generation ∧ event.sourceCut = state.scope.sourceCut :=
  ⟨admitted.2.2.1, admitted.2.2.2.1⟩

theorem missing_observed_parent_rejects {node : LeanPoo.C4.Node} {state : State}
    {request : Request} {observations : String → Option Event}
    {retained : List Nat} {event : Event} {parent : String}
    (edge : parent ∈ node.parentOrders.flatten) (missing : observations parent = none) :
    ¬ AdmitsEvidence node state request observations retained event := by
  intro admitted
  obtain ⟨observed, present, _⟩ := admitted.2.2.2.2.2.2.2.2.2 parent edge
  simp [missing] at present

theorem invalidated_descendant_rejects {graph : LeanPoo.C4.Graph} {changed : List String}
    (certificate : POO.Flow.SearchTemporal.ImpactCertificate graph changed)
    (states : String → State) (cut : Nat) (node : LeanPoo.C4.Node)
    (request : Request) (observations : String → Option Event)
    (retained : List Nat) (event : Event) (origin : String) (steps : Nat)
    (changedOrigin : origin ∈ changed)
    (path : LeanPoo.Proof.Descendant graph origin steps node.name) :
    ¬ AdmitsEvidence node (POO.Flow.SearchDag.invalidateStates certificate states cut node.name)
      request observations retained event := by
  intro admitted
  have cleared := POO.Flow.SearchDag.descendant_settlement_rejected
    certificate states cut node.name origin steps request changedOrigin path
  have accepted : settle (POO.Flow.SearchDag.invalidateStates certificate states cut node.name)
      request ≠ none := by simp [settle, admitted.1]
  exact accepted cleared

theorem uncommitted_rejects {node : LeanPoo.C4.Node} {state : State}
    {request : Request} {observations : String → Option Event}
    {retained : List Nat} {event : Event} (uncommitted : event.committed = false) :
    ¬ AdmitsEvidence node state request observations retained event := by
  intro admitted
  have committed := admitted.2.2.2.2.1
  simp [uncommitted] at committed

theorem nonpreceding_parent_rejects {node : LeanPoo.C4.Node} {state : State}
    {request : Request} {observations : String → Option Event}
    {retained : List Nat} {event observed : Event} {parent : String}
    (edge : parent ∈ node.parentOrders.flatten)
    (present : observations parent = some observed)
    (unordered : ¬ observed.position < event.position) :
    ¬ AdmitsEvidence node state request observations retained event := by
  intro admitted
  obtain ⟨actual, found, precedes⟩ := admitted.2.2.2.2.2.2.2.2.2 parent edge
  have same : actual = observed := Option.some.inj (found.symm.trans present)
  exact unordered (same ▸ precedes)

end POO.Flow.SearchEvidence
