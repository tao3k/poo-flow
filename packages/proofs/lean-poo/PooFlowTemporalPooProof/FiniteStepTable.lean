-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
import Lean
/-! Finite graph transport. Table equality and source identity are explicit
premises. Actual native/TLC step checks remain separate executable evidence. -/
namespace PooFlowTemporalPooProof.FiniteStepTable

structure SourceIdentity where
  sourceDigest : String
  modelDigest : String
  profile : String
  deriving DecidableEq

structure Edge (State Action : Type) where
  before : State
  action : Action
  after : State
  deriving DecidableEq

def projectEdge {S T A : Type} (project : S → T) (edge : Edge S A) : Edge T A :=
  ⟨project edge.before, edge.action, project edge.after⟩

def Step {S A : Type} (table : List (Edge S A)) (before : S) (action : A) (after : S) : Prop :=
  Edge.mk before action after ∈ table

inductive Trace {S A : Type} (table : List (Edge S A)) : S → List A → S → Prop where
  | empty (state) : Trace table state [] state
  | advance {before middle after action rest} :
      Step table before action middle → Trace table middle rest after →
      Trace table before (action :: rest) after

theorem step_forward {S T A : Type} (project : S → T) (table : List (Edge S A))
    {before after : S} {action : A} (h : Step table before action after) :
    Step (table.map (projectEdge project)) (project before) action (project after) := by
  exact List.mem_map.mpr ⟨⟨before, action, after⟩, h, rfl⟩

theorem step_equivalence {S T A : Type} (project : S → T) (injective : Function.Injective project)
    (table : List (Edge S A)) (before after : S) (action : A) :
    Step (table.map (projectEdge project)) (project before) action (project after) ↔
    Step table before action after := by
  constructor
  · intro h
    obtain ⟨edge, member, equality⟩ := List.mem_map.mp h
    have left := congrArg Edge.before equality
    have right := congrArg Edge.after equality
    have actor := congrArg Edge.action equality
    have beforeEqual : edge.before = before := injective left
    have afterEqual : edge.after = after := injective right
    cases edge with
    | mk b a t =>
      simp only [projectEdge] at actor
      simp only at beforeEqual afterEqual
      subst b; subst t; subst a
      exact member
  · exact step_forward project table

theorem trace_forward {S T A : Type} (project : S → T) (table : List (Edge S A))
    {before after : S} {schedule : List A} (h : Trace table before schedule after) :
    Trace (table.map (projectEdge project)) (project before) schedule (project after) := by
  induction h with
  | empty state => exact Trace.empty _
  | advance step _ continuation => exact Trace.advance (step_forward project table step) continuation

structure BoundTable (S A : Type) where
  identity : SourceIdentity
  edges : List (Edge S A)

theorem bound_trace_transport {S T A : Type} (project : S → T)
    (native : BoundTable S A) (source : BoundTable T A)
    (identity : native.identity = source.identity)
    (rows : source.edges = native.edges.map (projectEdge project))
    {before after : S} {schedule : List A} (h : Trace native.edges before schedule after) :
    native.identity = source.identity ∧ Trace source.edges (project before) schedule (project after) := by
  exact ⟨identity, rows.symm ▸ trace_forward project native.edges h⟩

theorem source_mismatch_rejects {S T A : Type} (native : BoundTable S A) (source : BoundTable T A)
    (different : native.identity.sourceDigest ≠ source.identity.sourceDigest) :
    native.identity ≠ source.identity := by
  intro same
  exact different (congrArg SourceIdentity.sourceDigest same)
end PooFlowTemporalPooProof.FiniteStepTable
