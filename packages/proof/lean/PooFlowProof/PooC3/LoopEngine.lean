import PooFlowProof.PooC3.Semantics

namespace PooFlowProof.PooC3.LoopEngine

open PooFlowProof.PooC3

inductive LoopModule where
  | readProfile
  | resolvePolicy
  | chooseStrategy
  | cacheHitBranch
  | cacheMissBranch
  | prepareWorkflow
  | enforceSandbox
  | runtimeHandoff
deriving Repr, DecidableEq

abbrev LoopScope := Nat

def uiScope : LoopScope := 0
def profileScope : LoopScope := 1
def policyScope : LoopScope := 2
def strategyScope : LoopScope := 3
def workflowScope : LoopScope := 4
def sandboxScope : LoopScope := 5
def runtimeScope : LoopScope := 6

def loopScopeOrder : ScopeOrder LoopScope :=
  { le := Nat.le
    refl := Nat.le_refl
    trans := fun first second => Nat.le_trans first second
    antisymm := fun first second => Nat.le_antisymm first second }

structure LoopState where
  activeScope : LoopScope
  profileDone : Prop
  policyDone : Prop
  strategyDone : Prop
  cacheHit : Prop
  cacheMiss : Prop
  workflowDone : Prop
  sandboxDone : Prop

inductive LoopDependsOn : LoopModule -> LoopModule -> Prop where
  | policyProfile :
      LoopDependsOn LoopModule.resolvePolicy LoopModule.readProfile
  | strategyPolicy :
      LoopDependsOn LoopModule.chooseStrategy LoopModule.resolvePolicy
  | cacheHitStrategy :
      LoopDependsOn LoopModule.cacheHitBranch LoopModule.chooseStrategy
  | cacheMissStrategy :
      LoopDependsOn LoopModule.cacheMissBranch LoopModule.chooseStrategy
  | workflowStrategy :
      LoopDependsOn LoopModule.prepareWorkflow LoopModule.chooseStrategy
  | sandboxWorkflow :
      LoopDependsOn LoopModule.enforceSandbox LoopModule.prepareWorkflow
  | runtimeSandbox :
      LoopDependsOn LoopModule.runtimeHandoff LoopModule.enforceSandbox

inductive LoopBranchSibling : LoopModule -> LoopModule -> Prop where
  | hitMiss :
      LoopBranchSibling LoopModule.cacheHitBranch LoopModule.cacheMissBranch
  | missHit :
      LoopBranchSibling LoopModule.cacheMissBranch LoopModule.cacheHitBranch

def loopModuleScope : LoopModule -> LoopScope
  | LoopModule.readProfile => profileScope
  | LoopModule.resolvePolicy => policyScope
  | LoopModule.chooseStrategy => strategyScope
  | LoopModule.cacheHitBranch => strategyScope
  | LoopModule.cacheMissBranch => strategyScope
  | LoopModule.prepareWorkflow => workflowScope
  | LoopModule.enforceSandbox => sandboxScope
  | LoopModule.runtimeHandoff => runtimeScope

def loopCompleted (state : LoopState) : LoopModule -> Prop
  | LoopModule.readProfile => state.profileDone
  | LoopModule.resolvePolicy => state.policyDone
  | LoopModule.chooseStrategy => state.strategyDone
  | LoopModule.cacheHitBranch => state.cacheHit
  | LoopModule.cacheMissBranch => state.cacheMiss
  | LoopModule.prepareWorkflow => state.workflowDone
  | LoopModule.enforceSandbox => state.sandboxDone
  | LoopModule.runtimeHandoff => False

def loopPolicyAllows (state : LoopState) : LoopModule -> Prop
  | LoopModule.readProfile => True
  | LoopModule.resolvePolicy => state.profileDone
  | LoopModule.chooseStrategy => state.policyDone
  | LoopModule.cacheHitBranch => state.strategyDone
  | LoopModule.cacheMissBranch => state.strategyDone
  | LoopModule.prepareWorkflow => state.strategyDone
  | LoopModule.enforceSandbox => state.workflowDone
  | LoopModule.runtimeHandoff => state.sandboxDone

def loopPrecondition (state : LoopState) : LoopModule -> Prop
  | LoopModule.readProfile => True
  | LoopModule.resolvePolicy => state.profileDone
  | LoopModule.chooseStrategy => state.policyDone
  | LoopModule.cacheHitBranch => state.strategyDone ∧ state.cacheHit
  | LoopModule.cacheMissBranch => state.strategyDone ∧ state.cacheMiss
  | LoopModule.prepareWorkflow => state.strategyDone
  | LoopModule.enforceSandbox => state.workflowDone
  | LoopModule.runtimeHandoff => state.sandboxDone

def loopGuard (state : LoopState) : LoopModule -> Prop
  | LoopModule.cacheHitBranch => state.cacheHit
  | LoopModule.cacheMissBranch => state.cacheMiss
  | _ => True

def loopSpec : FlowSpec LoopModule LoopScope LoopState :=
  { scopeOrder := loopScopeOrder
    moduleScope := loopModuleScope
    activeScope := LoopState.activeScope
    dependsOn := LoopDependsOn
    policyAllows := loopPolicyAllows
    precondition := loopPrecondition
    guard := loopGuard
    branchSibling := LoopBranchSibling
    completed := loopCompleted }

theorem choose_strategy_requires_policy
    {state : LoopState}
    (canStart :
      CanStart loopSpec state LoopModule.chooseStrategy) :
    loopCompleted state LoopModule.resolvePolicy :=
  deps_completed_of_can_start canStart LoopDependsOn.strategyPolicy

theorem runtime_handoff_requires_sandbox
    {state : LoopState}
    (canStart :
      CanStart loopSpec state LoopModule.runtimeHandoff) :
    loopCompleted state LoopModule.enforceSandbox :=
  deps_completed_of_can_start canStart LoopDependsOn.runtimeSandbox

def afterStrategyCacheHit : LoopState :=
  { activeScope := runtimeScope
    profileDone := True
    policyDone := True
    strategyDone := True
    cacheHit := True
    cacheMiss := False
    workflowDone := False
    sandboxDone := False }

def cacheHitCanStart :
    CanStart loopSpec afterStrategyCacheHit LoopModule.cacheHitBranch :=
  { depsCompleted := by
      intro dependency depends
      cases depends
      exact True.intro
    scopeAllowed := by
      change 3 <= 6
      exact
        Nat.succ_le_succ
          (Nat.succ_le_succ
            (Nat.succ_le_succ (Nat.zero_le 3)))
    policyHolds := True.intro
    preconditionHolds := And.intro True.intro True.intro
    guardHolds := True.intro }

theorem cache_miss_guard_false :
    ¬ loopGuard afterStrategyCacheHit LoopModule.cacheMissBranch := by
  intro guard
  exact guard

theorem cache_branch_exclusive_at_after_strategy :
    BranchExclusiveAt loopSpec afterStrategyCacheHit := by
  intro left right sibling leftGuard rightGuard
  cases sibling
  · exact rightGuard
  · exact leftGuard

theorem cache_hit_and_cache_miss_cannot_both_start
    (hitStart :
      CanStart loopSpec afterStrategyCacheHit LoopModule.cacheHitBranch)
    (missStart :
      CanStart loopSpec afterStrategyCacheHit LoopModule.cacheMissBranch) :
    False :=
  no_sibling_branch_start
    cache_branch_exclusive_at_after_strategy
    LoopBranchSibling.hitMiss
    hitStart
    missStart

def loopLinearization : Linearization loopSpec :=
  { order :=
      [ LoopModule.readProfile
      , LoopModule.resolvePolicy
      , LoopModule.chooseStrategy
      , LoopModule.cacheHitBranch
      , LoopModule.cacheMissBranch
      , LoopModule.prepareWorkflow
      , LoopModule.enforceSandbox
      , LoopModule.runtimeHandoff
      ]
    dependencyOrder := by
      intro module dependency depends
      cases depends
      · exact ⟨[], [], [ LoopModule.chooseStrategy
                       , LoopModule.cacheHitBranch
                       , LoopModule.cacheMissBranch
                       , LoopModule.prepareWorkflow
                       , LoopModule.enforceSandbox
                       , LoopModule.runtimeHandoff
                       ], rfl⟩
      · exact ⟨[LoopModule.readProfile], [], [ LoopModule.cacheHitBranch
                                             , LoopModule.cacheMissBranch
                                             , LoopModule.prepareWorkflow
                                             , LoopModule.enforceSandbox
                                             , LoopModule.runtimeHandoff
                                             ], rfl⟩
      · exact ⟨[ LoopModule.readProfile
                , LoopModule.resolvePolicy
                ], [], [ LoopModule.cacheMissBranch
                       , LoopModule.prepareWorkflow
                       , LoopModule.enforceSandbox
                       , LoopModule.runtimeHandoff
                       ], rfl⟩
      · exact ⟨[ LoopModule.readProfile
                , LoopModule.resolvePolicy
                ], [LoopModule.cacheHitBranch], [ LoopModule.prepareWorkflow
                                                , LoopModule.enforceSandbox
                                                , LoopModule.runtimeHandoff
                                                ], rfl⟩
      · exact ⟨[ LoopModule.readProfile
                , LoopModule.resolvePolicy
                ], [ LoopModule.cacheHitBranch
                   , LoopModule.cacheMissBranch
                   ], [ LoopModule.enforceSandbox
                      , LoopModule.runtimeHandoff
                      ], rfl⟩
      · exact ⟨[ LoopModule.readProfile
                , LoopModule.resolvePolicy
                , LoopModule.chooseStrategy
                , LoopModule.cacheHitBranch
                , LoopModule.cacheMissBranch
                ], [], [LoopModule.runtimeHandoff], rfl⟩
      · exact ⟨[ LoopModule.readProfile
                , LoopModule.resolvePolicy
                , LoopModule.chooseStrategy
                , LoopModule.cacheHitBranch
                , LoopModule.cacheMissBranch
                , LoopModule.prepareWorkflow
                ], [], [], rfl⟩ }

theorem loop_dependency_order
    {module dependency : LoopModule}
    (depends : loopSpec.dependsOn module dependency) :
    AppearsBefore loopLinearization.order dependency module :=
  dependency_order_of_linearization loopLinearization depends

end PooFlowProof.PooC3.LoopEngine
