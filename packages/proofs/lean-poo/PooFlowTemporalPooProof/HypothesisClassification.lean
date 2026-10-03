-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import Lean

/-!
Generic laws for the finite hypothesis profile v2. This is the abstract
classification kernel, not a theorem about Gerbil code or arbitrary TLA+
actions. The source profile and executable differential have separate gates.
-/
namespace PooFlowTemporalPooProof.HypothesisClassification

inductive Mode where
  | exclusive | overlapping
  deriving DecidableEq, Repr
inductive Status where
  | admitted | refuted | unknown
  deriving DecidableEq, Repr
inductive Classification where
  | possible | necessary | refuted | unknown
  deriving DecidableEq, Repr

structure Frontier where
  target : Status
  mode : Mode
  complete : Bool
  exhausted : Bool
  admittedCount : Nat
  unknownCount : Nat
  deriving DecidableEq, Repr

def classify (f : Frontier) : Classification :=
  match f.target with
  | .refuted => .refuted
  | .unknown => .unknown
  | .admitted =>
    if f.mode = .exclusive ∧ f.complete = true ∧ f.exhausted = true ∧
        f.admittedCount = 1 ∧ f.unknownCount = 0
    then .necessary else .possible

theorem overlappingNeverNecessary (f : Frontier) (mode : f.mode = .overlapping) :
    classify f ≠ .necessary := by
  cases target : f.target <;> simp [classify, target, mode]

theorem incompleteNeverNecessary (f : Frontier) (complete : f.complete = false) :
    classify f ≠ .necessary := by
  cases target : f.target <;> simp [classify, target, complete]

theorem unexploredNeverNecessary (f : Frontier) (exhausted : f.exhausted = false) :
    classify f ≠ .necessary := by
  cases target : f.target <;> simp [classify, target, exhausted]

theorem necessityPremises (f : Frontier) (result : classify f = .necessary) :
    f.target = .admitted ∧ f.mode = .exclusive ∧ f.complete = true ∧
    f.exhausted = true ∧ f.admittedCount = 1 ∧ f.unknownCount = 0 := by
  cases target : f.target with
  | refuted => simp [classify, target] at result
  | unknown => simp [classify, target] at result
  | admitted =>
    simp only [classify, target] at result
    split at result
    next premises => exact ⟨rfl, premises⟩
    next => contradiction

/-- A literal projection preserving the classification inputs preserves its
interpretation. Executable roundtrip must establish the equality premise. -/
theorem projectionPreservesClassification (native projected : Frontier)
    (sameInputs : projected = native) : classify projected = classify native := by
  rw [sameInputs]

structure Instant where
  domain : String
  coordinate : Nat
  observed : Bool
  deriving DecidableEq, Repr

def Before (a b : Instant) : Prop :=
  a.observed = true ∧ b.observed = true ∧ a.domain = b.domain ∧
    a.coordinate < b.coordinate

theorem beforeTransitive (a b c : Instant)
    (ab : Before a b) (bc : Before b c) : Before a c :=
  ⟨ab.1, bc.2.1, ab.2.2.1.trans bc.2.2.1, Nat.lt_trans ab.2.2.2 bc.2.2.2⟩

theorem beforeIrreflexive (a : Instant) : ¬ Before a a := by
  intro proof
  exact Nat.lt_irrefl a.coordinate proof.2.2.2

theorem distinctDomainsUnordered (a b : Instant) (different : a.domain ≠ b.domain) :
    ¬ Before a b := by
  intro proof
  exact different proof.2.2.1

end PooFlowTemporalPooProof.HypothesisClassification
