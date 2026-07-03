namespace PooFlowProof.PooC3

structure ScopeOrder (Scope : Type u) where
  le : Scope -> Scope -> Prop
  refl : (scope : Scope) -> le scope scope
  trans : {a b c : Scope} -> le a b -> le b c -> le a c
  antisymm : {a b : Scope} -> le a b -> le b a -> a = b

structure FlowSpec
    (Module Scope State : Type u) where
  scopeOrder : ScopeOrder Scope
  moduleScope : Module -> Scope
  activeScope : State -> Scope
  dependsOn : Module -> Module -> Prop
  policyAllows : State -> Module -> Prop
  precondition : State -> Module -> Prop
  guard : State -> Module -> Prop
  branchSibling : Module -> Module -> Prop
  completed : State -> Module -> Prop

structure CanStart
    {Module Scope State : Type u}
    (spec : FlowSpec Module Scope State)
    (state : State)
    (module : Module) : Prop where
  depsCompleted :
    (dependency : Module) ->
    spec.dependsOn module dependency ->
    spec.completed state dependency
  scopeAllowed :
    spec.scopeOrder.le (spec.moduleScope module) (spec.activeScope state)
  policyHolds : spec.policyAllows state module
  preconditionHolds : spec.precondition state module
  guardHolds : spec.guard state module

structure Step
    {Module Scope State : Type u}
    (spec : FlowSpec Module Scope State)
    (state : State) where
  module : Module
  next : State
  canStart : CanStart spec state module

theorem start_sound
    {Module Scope State : Type u}
    {spec : FlowSpec Module Scope State}
    {state : State}
    (step : Step spec state) :
    CanStart spec state step.module :=
  step.canStart

theorem deps_completed_of_can_start
    {Module Scope State : Type u}
    {spec : FlowSpec Module Scope State}
    {state : State}
    {module dependency : Module}
    (canStart : CanStart spec state module)
    (depends : spec.dependsOn module dependency) :
    spec.completed state dependency :=
  canStart.depsCompleted dependency depends

theorem scope_allowed_of_can_start
    {Module Scope State : Type u}
    {spec : FlowSpec Module Scope State}
    {state : State}
    {module : Module}
    (canStart : CanStart spec state module) :
    spec.scopeOrder.le (spec.moduleScope module) (spec.activeScope state) :=
  canStart.scopeAllowed

theorem scope_allowed_transitive
    {Module Scope State : Type u}
    {spec : FlowSpec Module Scope State}
    {state : State}
    {module : Module}
    {parentScope : Scope}
    (canStart : CanStart spec state module)
    (activeWithinParent :
      spec.scopeOrder.le (spec.activeScope state) parentScope) :
    spec.scopeOrder.le (spec.moduleScope module) parentScope :=
  spec.scopeOrder.trans canStart.scopeAllowed activeWithinParent

def BranchExclusiveAt
    {Module Scope State : Type u}
    (spec : FlowSpec Module Scope State)
    (state : State) : Prop :=
  {left right : Module} ->
    spec.branchSibling left right ->
    spec.guard state left ->
    spec.guard state right ->
    False

theorem no_sibling_branch_start
    {Module Scope State : Type u}
    {spec : FlowSpec Module Scope State}
    {state : State}
    {left right : Module}
    (exclusive : BranchExclusiveAt spec state)
    (sibling : spec.branchSibling left right)
    (leftStart : CanStart spec state left)
    (rightStart : CanStart spec state right) :
    False :=
  exclusive sibling leftStart.guardHolds rightStart.guardHolds

def AppearsBefore
    {Module : Type u}
    (order : List Module)
    (before after : Module) : Prop :=
  ∃ pre mid post,
    order = pre ++ before :: mid ++ after :: post

structure Linearization
    {Module Scope State : Type u}
    (spec : FlowSpec Module Scope State) where
  order : List Module
  dependencyOrder :
    {module dependency : Module} ->
    spec.dependsOn module dependency ->
    AppearsBefore order dependency module

theorem dependency_order_of_linearization
    {Module Scope State : Type u}
    {spec : FlowSpec Module Scope State}
    (linearization : Linearization spec)
    {module dependency : Module}
    (depends : spec.dependsOn module dependency) :
    AppearsBefore linearization.order dependency module :=
  linearization.dependencyOrder depends

end PooFlowProof.PooC3
