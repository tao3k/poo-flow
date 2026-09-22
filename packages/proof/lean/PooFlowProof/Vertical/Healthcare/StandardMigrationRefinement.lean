-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
--
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

namespace PooFlowProof.Vertical.Healthcare.StandardMigrationRefinement

inductive MigrationPhase where
  | inventory | mapped | conformant | humanReviewed | authorized | cutoverReady
  deriving DecidableEq

structure MigrationState where
  phase : MigrationPhase
  parserBound : Bool
  mappingComplete : Bool
  conformanceBound : Bool
  humanReviewed : Bool
  cedarPermit : Bool
  cutoverReady : Bool
  aiAuthority : Bool

def admissible (state : MigrationState) : Prop :=
  state.aiAuthority = false ∧
  (state.humanReviewed = true → state.conformanceBound = true) ∧
  (state.cedarPermit = true → state.humanReviewed = true) ∧
  (state.cutoverReady = true →
    state.parserBound = true ∧ state.mappingComplete = true ∧
    state.conformanceBound = true ∧ state.humanReviewed = true ∧
    state.cedarPermit = true)

def tlaSourceDigest : String :=
  "sha256:043ac3e0074752fddf6a2ac4dd889d75930a0deb9c06a576d3b3cdb61981c04f"

def tlaInvariantNames : List String :=
  ["AINeverGrantsAuthority", "ReviewRequiresConformance",
   "CedarPermitRequiresHumanReview", "CutoverRequiresCedarPermit",
   "CutoverRequiresCompleteEvidence"]

structure TLAImpactContract where
  tlaSourceDigest : String
  impactedLeanDeclarations : List String
  deriving DecidableEq

def migrationImpactContract : TLAImpactContract :=
  { tlaSourceDigest := tlaSourceDigest
    impactedLeanDeclarations :=
      ["aiCannotAuthorize", "cutoverRequiresHumanCedarAndEvidence",
       "tlaImpactContractBindsExactSource"] }

theorem aiCannotAuthorize (state : MigrationState)
    (accepted : admissible state) : state.aiAuthority = false :=
  accepted.1

theorem cutoverRequiresHumanCedarAndEvidence (state : MigrationState)
    (accepted : admissible state) (ready : state.cutoverReady = true) :
    state.parserBound = true ∧ state.mappingComplete = true ∧
    state.conformanceBound = true ∧ state.humanReviewed = true ∧
    state.cedarPermit = true :=
  accepted.2.2.2 ready

theorem tlaImpactContractBindsExactSource :
    migrationImpactContract.tlaSourceDigest = tlaSourceDigest := by
  rfl

end PooFlowProof.Vertical.Healthcare.StandardMigrationRefinement
