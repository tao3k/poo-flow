-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import Lean
import Lean.Util.CollectAxioms
namespace PooFlowContextProof

-- Source freshness only; this metadata is not a semantic refinement proof.
def quintSourceDigest : String := "sha256:21e54b803a31ec72eaaa3999e8b79942e59171162b5e152620f39217d59d986c"
def quintInvariantNames : List String :=
  ["ExactTargetCut", "ExactReconstruction", "OnePublication",
   "CurrentConsumption", "AuthorizedConsumption"]


structure Edit (α : Type) where
  key : Nat
  expected : Option α
  replacement : Option α

def update (units : Nat → Option α) (e : Edit α) : Nat → Option α :=
  fun key => if key = e.key then e.replacement else units key

def applyEdit [DecidableEq α] (units : Nat → Option α) (e : Edit α) :
    Option (Nat → Option α) :=
  if units e.key = e.expected then some (update units e) else none

def applyEdits [DecidableEq α] (units : Nat → Option α) :
    List (Edit α) → Option (Nat → Option α)
  | [] => some units
  | e :: es => (applyEdit units e).bind (fun next => applyEdits next es)

theorem update_at_key (u : Nat → Option α) (e : Edit α) :
    update u e e.key = e.replacement := by simp [update]
theorem update_frame (u : Nat → Option α) (e : Edit α) (k : Nat)
    (outside : k ≠ e.key) : update u e k = u k := by simp [update, outside]
theorem wrong_version_refused [DecidableEq α] (u : Nat → Option α) (e : Edit α)
    (wrong : u e.key ≠ e.expected) : applyEdit u e = none := by simp [applyEdit, wrong]
theorem exact_version_applies [DecidableEq α] (u : Nat → Option α) (e : Edit α)
    (exact : u e.key = e.expected) : applyEdit u e = some (update u e) := by
  simp [applyEdit, exact]
theorem deletion_removes (u : Nat → Option α) (e : Edit α)
    (deleted : e.replacement = none) : update u e e.key = none := by
  simp [update, deleted]
theorem untouched_edits_frame [DecidableEq α] (es : List (Edit α))
    (u result : Nat → Option α) (k : Nat)
    (outside : ∀ e ∈ es, k ≠ e.key) (applied : applyEdits u es = some result) :
    result k = u k := by
  induction es generalizing u with
  | nil => simp [applyEdits] at applied; subst result; rfl
  | cons e es ih =>
    have head := outside e (by simp)
    have tail : ∀ e ∈ es, k ≠ e.key := fun e h => outside e (by simp [h])
    unfold applyEdits at applied
    unfold applyEdit at applied
    split at applied
    · simp only [Option.bind_some] at applied
      exact (ih (update u e) tail applied).trans (update_frame u e k head)
    · simp at applied

-- Full-target comparison is a differential admission guard, not a coverage axiom.
def admit [DecidableEq α] (expectedBase actualBase : Nat)
    (compatible : Bool) (candidate : List α) (full : List α) : Option (List α) :=
  if expectedBase = actualBase ∧ compatible = true ∧ candidate = full
  then some full else none

theorem accepted_equals_full [DecidableEq α] (b a : Nat) (c : Bool)
    (candidate full result : List α) (accepted : admit b a c candidate full = some result) :
    result = full := by
  unfold admit at accepted
  split at accepted
  · simp at accepted; exact accepted.symm
  · simp at accepted

theorem wrong_base_refused [DecidableEq α] (b a : Nat) (c : Bool)
    (candidate full : List α) (wrong : b ≠ a) : admit b a c candidate full = none := by
  simp [admit, wrong]
theorem incompatible_refused [DecidableEq α] (b a : Nat) (candidate full : List α) :
    admit b a false candidate full = none := by simp [admit]
theorem missing_content_refused [DecidableEq α] (b a : Nat) (candidate full : List α)
    (different : candidate ≠ full) : admit b a true candidate full = none := by
  simp [admit, different]
end PooFlowContextProof

open Lean Elab Command in
run_cmd do
  let environment ← getEnv
  let allowed := #[`propext, `Classical.choice, `Quot.sound]
  for required in #[`PooFlowContextProof.update_at_key,
      `PooFlowContextProof.update_frame, `PooFlowContextProof.wrong_version_refused,
      `PooFlowContextProof.exact_version_applies, `PooFlowContextProof.deletion_removes,
      `PooFlowContextProof.untouched_edits_frame, `PooFlowContextProof.accepted_equals_full,
      `PooFlowContextProof.wrong_base_refused, `PooFlowContextProof.incompatible_refused,
      `PooFlowContextProof.missing_content_refused] do
    unless environment.contains required do
      throwError "Required Context Delta theorem is missing: {required}"
  let mut count : Nat := 0
  for (name, info) in environment.constants.toList do
    if (`PooFlowContextProof).isPrefixOf name then
      if info.isTheorem then count := count + 1
      for axiomName in (← collectAxioms name) do
        unless allowed.contains axiomName do
          throwError "{name} depends on disallowed axiom {axiomName}"
  if count < 10 then throwError "Delta theorem inventory is incomplete"
  logInfo m!"CONTEXT-DELTA-AXIOM-AUDIT-OK: {count} theorems; standard Lean axioms only"
