-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
--
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

/-!
The formal core shared by native POO Objects, identity-bearing Entity roles,
Contract-scoped Elements, Relations and bounded read-only Queries.

This model deliberately does not formalize GQL syntax or execution. A GQL
provider may return a result, but the result remains bound to the Query and
semantic revision and carries no action authority.
-/

namespace PooFlowProof.PooC4.NativeSemanticQueryModel

abbrev ObjectIdentity := String
abbrev QueryIdentity := String
abbrev SemanticRevision := Nat

structure NativeObject where
  identity : ObjectIdentity
  deriving DecidableEq, Repr

/-- Entity is a role of one native Object, not a second stored object. -/
structure EntityRole where
  objectIdentity : ObjectIdentity
  deriving DecidableEq, Repr

/-- Element membership references canonical Object identities. -/
structure ElementSpace where
  revision : SemanticRevision
  objectIdentities : List ObjectIdentity
  deriving DecidableEq, Repr

structure Relation where
  identity : String
  sourceIdentity : ObjectIdentity
  targetIdentity : ObjectIdentity
  deriving DecidableEq, Repr

def Relation.Closed (space : ElementSpace) (relation : Relation) : Prop :=
  relation.sourceIdentity ∈ space.objectIdentities ∧
    relation.targetIdentity ∈ space.objectIdentities

structure Query where
  identity : QueryIdentity
  selectedIdentities : List ObjectIdentity
  readOnly : Bool
  bounded : Bool
  deriving DecidableEq, Repr

def Query.Admitted (space : ElementSpace) (query : Query) : Prop :=
  query.identity ≠ "" ∧
    query.readOnly = true ∧
    query.bounded = true ∧
    ∀ identity ∈ query.selectedIdentities, identity ∈ space.objectIdentities

structure QueryResult where
  queryIdentity : QueryIdentity
  sourceRevision : SemanticRevision
  selectedIdentities : List ObjectIdentity
  carriesActionAuthority : Bool
  runtimeExecuted : Bool
  deriving DecidableEq, Repr

/-- A Provider projects evidence from an admitted Query without changing the
semantic space or manufacturing authority. -/
def evaluateQuery (space : ElementSpace) (query : Query) : QueryResult :=
  { queryIdentity := query.identity
    sourceRevision := space.revision
    selectedIdentities := query.selectedIdentities
    carriesActionAuthority := false
    runtimeExecuted := true }

theorem entityRolePreservesNativeObjectIdentity (object : NativeObject) :
    (EntityRole.mk object.identity).objectIdentity = object.identity := by
  rfl

theorem closedRelationReferencesOneElementSpace
    (space : ElementSpace)
    (relation : Relation)
    (closed : relation.Closed space) :
    relation.sourceIdentity ∈ space.objectIdentities ∧
      relation.targetIdentity ∈ space.objectIdentities :=
  closed

theorem admittedQuerySelectsOnlyElements
    (space : ElementSpace)
    (query : Query)
    (admitted : query.Admitted space)
    (identity : ObjectIdentity)
    (selected : identity ∈ query.selectedIdentities) :
    identity ∈ space.objectIdentities :=
  admitted.2.2.2 identity selected

theorem queryEvaluationPreservesSemanticRevision
    (space : ElementSpace)
    (query : Query) :
    (evaluateQuery space query).sourceRevision = space.revision := by
  rfl

theorem queryEvaluationBindsQueryIdentity
    (space : ElementSpace)
    (query : Query) :
    (evaluateQuery space query).queryIdentity = query.identity := by
  rfl

theorem queryEvaluationNeverCarriesActionAuthority
    (space : ElementSpace)
    (query : Query) :
    (evaluateQuery space query).carriesActionAuthority = false := by
  rfl

end PooFlowProof.PooC4.NativeSemanticQueryModel
