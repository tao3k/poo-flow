namespace PooFlowProof.PooC3.CompositionIdentity

structure LexicalName where
  value : String
deriving Repr, DecidableEq

structure RuntimeRoot where
  value : Nat
deriving Repr, DecidableEq

structure ContentIdentity where
  value : Nat
deriving Repr, DecidableEq

structure Identity where
  lexical : LexicalName
  runtimeRoot : RuntimeRoot
  content : ContentIdentity
deriving Repr, DecidableEq

def rename
    (identity : Identity)
    (lexical : LexicalName) :
    Identity :=
  { identity with lexical := lexical }

theorem renamePreservesRuntimeRoot
    (identity : Identity)
    (lexical : LexicalName) :
    (rename identity lexical).runtimeRoot = identity.runtimeRoot := by
  rfl

theorem renamePreservesContentIdentity
    (identity : Identity)
    (lexical : LexicalName) :
    (rename identity lexical).content = identity.content := by
  rfl

structure DemandCellKey where
  context : Nat
  runtimeRoot : RuntimeRoot
  coordinate : Nat
deriving Repr, DecidableEq

def demandCellKey
    (context : Nat)
    (identity : Identity)
    (coordinate : Nat) :
    DemandCellKey :=
  { context := context
    runtimeRoot := identity.runtimeRoot
    coordinate := coordinate }

theorem renamePreservesDemandCellKey
    (context coordinate : Nat)
    (identity : Identity)
    (lexical : LexicalName) :
    demandCellKey context (rename identity lexical) coordinate =
      demandCellKey context identity coordinate := by
  rfl

def declare
    (lexical : LexicalName)
    (runtimeRoot : RuntimeRoot)
    (content : ContentIdentity) :
    Identity :=
  { lexical := lexical
    runtimeRoot := runtimeRoot
    content := content }

theorem distinctDeclarationsKeepDistinctRuntimeRoots
    (leftName rightName : LexicalName)
    (leftRoot rightRoot : RuntimeRoot)
    (content : ContentIdentity)
    (fresh : leftRoot ≠ rightRoot) :
    (declare leftName leftRoot content).runtimeRoot ≠
      (declare rightName rightRoot content).runtimeRoot := by
  exact fresh

theorem equalContentDoesNotIdentifyRuntimeRoots :
    ∃ left right : Identity,
      left.content = right.content ∧
      left.runtimeRoot ≠ right.runtimeRoot := by
  let content : ContentIdentity := ⟨7⟩
  let left : Identity :=
    declare ⟨"left"⟩ ⟨0⟩ content
  let right : Identity :=
    declare ⟨"right"⟩ ⟨1⟩ content
  refine ⟨left, right, rfl, ?_⟩
  decide

structure DerivedReceipt where
  parentRoot : RuntimeRoot
  orderedRefinements : List Nat
  sourceContent : ContentIdentity
  dependencyRevision : Nat
  loweringEvidence : Nat
deriving Repr, DecidableEq

def derive
    (parent : Identity)
    (lexical : LexicalName)
    (freshRoot : RuntimeRoot)
    (orderedRefinements : List Nat)
    (derivedContent : ContentIdentity)
    (dependencyRevision loweringEvidence : Nat) :
    Identity × DerivedReceipt :=
  ( { lexical := lexical
      runtimeRoot := freshRoot
      content := derivedContent }
  , { parentRoot := parent.runtimeRoot
      orderedRefinements := orderedRefinements
      sourceContent := parent.content
      dependencyRevision := dependencyRevision
      loweringEvidence := loweringEvidence } )

theorem derivedReceiptLinksParentRoot
    (parent : Identity)
    (lexical : LexicalName)
    (freshRoot : RuntimeRoot)
    (orderedRefinements : List Nat)
    (derivedContent : ContentIdentity)
    (dependencyRevision loweringEvidence : Nat) :
    (derive parent lexical freshRoot orderedRefinements derivedContent
      dependencyRevision loweringEvidence).2.parentRoot =
      parent.runtimeRoot := by
  rfl

theorem derivedCompositionUsesFreshRoot
    (parent : Identity)
    (lexical : LexicalName)
    (freshRoot : RuntimeRoot)
    (orderedRefinements : List Nat)
    (derivedContent : ContentIdentity)
    (dependencyRevision loweringEvidence : Nat)
    (fresh : freshRoot ≠ parent.runtimeRoot) :
    (derive parent lexical freshRoot orderedRefinements derivedContent
      dependencyRevision loweringEvidence).1.runtimeRoot ≠
      parent.runtimeRoot := by
  exact fresh

end PooFlowProof.PooC3.CompositionIdentity
