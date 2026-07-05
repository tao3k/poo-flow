import PooFlowProof.PooC3.Semantics

namespace PooFlowProof.PooC3

def natScopeOrder : ScopeOrder Nat :=
  { le := Nat.le
    refl := Nat.le_refl
    trans := by
      intro _ _ _ left right
      exact Nat.le_trans left right
    antisymm := by
      intro _ _ left right
      exact Nat.le_antisymm left right }

end PooFlowProof.PooC3
