namespace PooFlowProof.PooC3.DomainCaseIndexedResolution

universe u v

/-- An ordered winner entry can be retired without shifting the remaining
    source-order entries. -/
structure ResolutionEntry (Value : Type u) where
  value : Value
  active : Bool
deriving Repr, DecidableEq

def activeValues : List (ResolutionEntry Value) -> List Value
  | [] => []
  | entry :: rest =>
      if entry.active then entry.value :: activeValues rest
      else activeValues rest

def retireBy
    [DecidableEq Key]
    (keyOf : Value -> Key)
    (key : Key) :
    List (ResolutionEntry Value) -> List (ResolutionEntry Value)
  | [] => []
  | entry :: rest =>
      { entry with
          active := entry.active && decide (keyOf entry.value != key) } ::
        retireBy keyOf key rest

def referenceReplace
    [DecidableEq Key]
    (keyOf : Value -> Key)
    (candidate : Value)
    (entries : List (ResolutionEntry Value)) : List Value :=
  (activeValues entries).filter
      (fun value => decide (keyOf value != keyOf candidate)) ++
    [candidate]

def indexedReplace
    [DecidableEq Key]
    (keyOf : Value -> Key)
    (candidate : Value)
    (entries : List (ResolutionEntry Value)) : List (ResolutionEntry Value) :=
  retireBy keyOf (keyOf candidate) entries ++
    [{ value := candidate, active := true }]

theorem activeValues_append
    (left right : List (ResolutionEntry Value)) :
    activeValues (left ++ right) = activeValues left ++ activeValues right := by
  induction left with
  | nil => rfl
  | cons entry rest inductionHypothesis =>
      cases active : entry.active <;>
        simp [activeValues, active, inductionHypothesis]

theorem activeValues_retireBy
    [DecidableEq Key]
    (keyOf : Value -> Key)
    (key : Key)
    (entries : List (ResolutionEntry Value)) :
    activeValues (retireBy keyOf key entries) =
      (activeValues entries).filter
        (fun value => decide (keyOf value != key)) := by
  induction entries with
  | nil => rfl
  | cons entry rest inductionHypothesis =>
      cases active : entry.active
      · simp [retireBy, activeValues, active, inductionHypothesis]
      · by_cases sameKey : keyOf entry.value = key
        · simp [retireBy, activeValues, active, sameKey,
                inductionHypothesis]
        · simp [retireBy, activeValues, active, sameKey,
                inductionHypothesis]

/-- Tombstone replacement has the same ordered projection as the former
    repeated filter-and-append reference algorithm. -/
theorem indexedReplace_preserves_reference_order
    [DecidableEq Key]
    (keyOf : Value -> Key)
    (candidate : Value)
    (entries : List (ResolutionEntry Value)) :
    activeValues (indexedReplace keyOf candidate entries) =
      referenceReplace keyOf candidate entries := by
  rw [indexedReplace, activeValues_append, activeValues_retireBy]
  simp [referenceReplace, activeValues]

end PooFlowProof.PooC3.DomainCaseIndexedResolution
