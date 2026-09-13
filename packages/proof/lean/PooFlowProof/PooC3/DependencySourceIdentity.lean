namespace PooFlowProof.PooC3.DependencySourceIdentity

inductive CandidateCardinality where
  | zero
  | one
  | many
  deriving DecidableEq, Repr

def Resolvable : CandidateCardinality → Prop
  | .one => True
  | .zero | .many => False

theorem zero_candidates_fail_closed : ¬ Resolvable .zero := by
  simp [Resolvable]

theorem multiple_candidates_fail_closed : ¬ Resolvable .many := by
  simp [Resolvable]

theorem exactly_one_candidate_resolves : Resolvable .one := by
  simp [Resolvable]

structure SourceIdentity where
  logicalName : String
  canonicalNamespace : String
  canonicalUri : String
  revision : String
  manifestDigest : String
  sourceDigest : String
  deriving DecidableEq, Repr

def Complete (identity : SourceIdentity) : Prop :=
  identity.logicalName ≠ "" ∧
  identity.canonicalNamespace ≠ "" ∧
  identity.canonicalUri ≠ "" ∧
  identity.revision ≠ "" ∧
  identity.manifestDigest ≠ "" ∧
  identity.sourceDigest ≠ ""

theorem empty_namespace_is_incomplete
    (identity : SourceIdentity)
    (emptyNamespace : identity.canonicalNamespace = "") :
    ¬ Complete identity := by
  intro complete
  exact complete.2.1 emptyNamespace

theorem empty_revision_is_incomplete
    (identity : SourceIdentity)
    (emptyRevision : identity.revision = "") :
    ¬ Complete identity := by
  intro complete
  exact complete.2.2.2.1 emptyRevision

theorem empty_source_digest_is_incomplete
    (identity : SourceIdentity)
    (emptyDigest : identity.sourceDigest = "") :
    ¬ Complete identity := by
  intro complete
  exact complete.2.2.2.2.2 emptyDigest

theorem logical_name_does_not_determine_identity
    (left right : SourceIdentity)
    (_sameLogicalName : left.logicalName = right.logicalName)
    (differentNamespace :
      left.canonicalNamespace ≠ right.canonicalNamespace) :
    left ≠ right := by
  intro sameIdentity
  apply differentNamespace
  simp [sameIdentity]

end PooFlowProof.PooC3.DependencySourceIdentity
