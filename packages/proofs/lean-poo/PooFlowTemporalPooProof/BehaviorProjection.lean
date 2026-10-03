-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import Lean
/-! Generic schedule laws. The commuting-step premise needs a separate concrete
source/profile proof. These laws do not certify Scheme, TLC or real causation. -/
namespace PooFlowTemporalPooProof.BehaviorProjection

def run {S A : Type} (step : S → A → S) : S → List A → S
  | initial, [] => initial
  | initial, action :: rest => run step (step initial action) rest

def trace {S A : Type} (step : S → A → S) : S → List A → List S
  | initial, [] => [initial]
  | initial, action :: rest => initial :: trace step (step initial action) rest

theorem run_projection {S T A : Type} (left : S → A → S) (right : T → A → T)
    (project : S → T) (commutes : ∀ s a, project (left s a) = right (project s) a)
    (schedule : List A) (initial : S) :
    project (run left initial schedule) = run right (project initial) schedule := by
  induction schedule generalizing initial with
  | nil => rfl
  | cons action rest ih =>
    simp only [run]
    rw [ih, commutes]

theorem trace_projection {S T A : Type} (left : S → A → S) (right : T → A → T)
    (project : S → T) (commutes : ∀ s a, project (left s a) = right (project s) a)
    (schedule : List A) (initial : S) :
    (trace left initial schedule).map project = trace right (project initial) schedule := by
  induction schedule generalizing initial with
  | nil => rfl
  | cons action rest ih =>
    simp only [trace, List.map_cons]
    rw [ih, commutes]

theorem trace_length {S A : Type} (step : S → A → S) (schedule : List A) (initial : S) :
    (trace step initial schedule).length = schedule.length + 1 := by
  induction schedule generalizing initial with
  | nil => rfl
  | cons action rest ih => simp [trace, ih, Nat.add_assoc]

theorem safety_projection {S T A : Type} (left : S → A → S) (right : T → A → T)
    (project : S → T) (commutes : ∀ s a, project (left s a) = right (project s) a)
    (predicate : T → Prop) (schedule : List A) (initial : S) :
    (∀ s ∈ trace left initial schedule, predicate (project s)) ↔
    (∀ t ∈ trace right (project initial) schedule, predicate t) := by
  rw [← trace_projection left right project commutes schedule initial]
  simp

theorem reachability_projection {S T A : Type} (left : S → A → S) (right : T → A → T)
    (project : S → T) (commutes : ∀ s a, project (left s a) = right (project s) a)
    (predicate : T → Prop) (schedule : List A) (initial : S) :
    (∃ s ∈ trace left initial schedule, predicate (project s)) ↔
    (∃ t ∈ trace right (project initial) schedule, predicate t) := by
  rw [← trace_projection left right project commutes schedule initial]
  constructor
  · rintro ⟨s, membership, satisfies⟩
    exact ⟨project s, List.mem_map.mpr ⟨s, membership, rfl⟩, satisfies⟩
  · rintro ⟨t, membership, satisfies⟩
    obtain ⟨s, membership, equality⟩ := List.mem_map.mp membership
    exact ⟨s, membership, equality.symm ▸ satisfies⟩

theorem bounded_progress_projection {S T A : Type} (left : S → A → S) (right : T → A → T)
    (project : S → T) (commutes : ∀ s a, project (left s a) = right (project s) a)
    (predicate : T → Prop) (deadline : Nat) (schedule : List A) (initial : S) :
    (∃ s ∈ (trace left initial schedule).take (deadline + 1), predicate (project s)) ↔
    (∃ t ∈ (trace right (project initial) schedule).take (deadline + 1), predicate t) := by
  rw [← trace_projection left right project commutes schedule initial]
  have takeEquality := List.map_take (f := project) (i := deadline + 1) (l := trace left initial schedule)
  rw [← takeEquality]
  constructor
  · rintro ⟨s, membership, satisfies⟩
    exact ⟨project s, List.mem_map.mpr ⟨s, membership, rfl⟩, satisfies⟩
  · rintro ⟨t, membership, satisfies⟩
    obtain ⟨s, membership, equality⟩ := List.mem_map.mp membership
    exact ⟨s, membership, equality.symm ▸ satisfies⟩
end PooFlowTemporalPooProof.BehaviorProjection
