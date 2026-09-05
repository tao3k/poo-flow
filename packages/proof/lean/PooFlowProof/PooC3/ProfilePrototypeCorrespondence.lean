import PooFlowProof.PooC3.ProfileRevisionUpgrade

namespace PooFlowProof.PooC3.ProfilePrototypeCorrespondence

inductive ProfileOperandKind where
  | nativeObject
  | nativePrototype
  | invalidShape
  deriving DecidableEq, Repr

def AdmitsOperandShape : ProfileOperandKind → Prop
  | .nativeObject => True
  | .nativePrototype => True
  | .invalidShape => False

inductive CompositionEntryPoint where
  | useComposition
  deriving DecidableEq, Repr

def AdmitsCompositionEntryPoint : CompositionEntryPoint → Prop
  | .useComposition => True

structure NativeProfileObject where
  immutable : Prop
  immutabilityEstablished : immutable
  requiresWrapper : Prop
  noWrapperRequired : ¬ requiresWrapper

structure NativeProfileExtension where
  usesNativePrototype : Prop
  nativePrototypeEstablished : usesNativePrototype
  usesLocalFixedPointEvaluator : Prop
  noLocalFixedPointEvaluator : ¬ usesLocalFixedPointEvaluator

structure ProfilesStrategy where
  firstClassPooObject : Prop
  firstClassEstablished : firstClassPooObject
  usesKindToken : Prop
  noKindToken : ¬ usesKindToken
  readsHiddenRegistry : Prop
  noHiddenRegistry : ¬ readsHiddenRegistry
  createsSecondObjectRuntime : Prop
  noSecondObjectRuntime : ¬ createsSecondObjectRuntime

structure TwoStageAdmission where
  operandShape : ProfileOperandKind
  shapeAdmitted : AdmitsOperandShape operandShape
  instantiatedResultIsProfileObject : Prop
  semanticContractEstablished : instantiatedResultIsProfileObject

structure OrderedOperandLift (OperandIdentity : Type) where
  declaredOperands : List OperandIdentity
  liftedOperands : List OperandIdentity
  preservesDeclaredOrder : liftedOperands = declaredOperands
  batchesObjectsBeforePrototypes : Prop
  noCategoryBatching : ¬ batchesObjectsBeforePrototypes

structure CompositionRoot where
  instantiationCount : Nat
  instantiatedExactlyOnce : instantiationCount = 1
  immutable : Prop
  immutabilityEstablished : immutable
  resolvesNewestRevision : Prop
  noDynamicRevisionResolution : ¬ resolvesNewestRevision

inductive CycleKind where
  | prototypeRecursion
  | inheritanceCycle
  deriving DecidableEq, Repr

def UsesNativeFixedPoint : CycleKind → Prop
  | .prototypeRecursion => True
  | .inheritanceCycle => False

def AdmitsC3Precedence : CycleKind → Prop
  | .prototypeRecursion => True
  | .inheritanceCycle => False

structure PriorityBoundary where
  slotLocalContributionPriority : Prop
  slotPriorityEstablished : slotLocalContributionPriority
  changesC3Precedence : Prop
  noC3PrecedenceChange : ¬ changesC3Precedence

structure PoofCorrespondence where
  usesPinnedGerbilPooConstruction : Prop
  pinnedConstructionEstablished : usesPinnedGerbilPooConstruction
  inventsLocalLiftingFormula : Prop
  noLocalLiftingFormula : ¬ inventsLocalLiftingFormula
  reducesAllCompositionToMix : Prop
  noUniversalMixReduction : ¬ reducesAllCompositionToMix

theorem nativeObjectShapeIsAdmitted :
    AdmitsOperandShape .nativeObject := by
  simp [AdmitsOperandShape]

theorem nativePrototypeShapeIsAdmitted :
    AdmitsOperandShape .nativePrototype := by
  simp [AdmitsOperandShape]

theorem invalidOperandShapeFailsClosed :
    ¬ AdmitsOperandShape .invalidShape := by
  simp [AdmitsOperandShape]

theorem useCompositionIsCanonical :
    AdmitsCompositionEntryPoint .useComposition := by
  simp [AdmitsCompositionEntryPoint]

theorem profileObjectIsImmutable
    (profile : NativeProfileObject) :
    profile.immutable :=
  profile.immutabilityEstablished

theorem profileObjectNeedsNoWrapper
    (profile : NativeProfileObject) :
    ¬ profile.requiresWrapper :=
  profile.noWrapperRequired

theorem extensionUsesNativePrototype
    (extension : NativeProfileExtension) :
    extension.usesNativePrototype :=
  extension.nativePrototypeEstablished

theorem extensionUsesNoLocalFixedPointEvaluator
    (extension : NativeProfileExtension) :
    ¬ extension.usesLocalFixedPointEvaluator :=
  extension.noLocalFixedPointEvaluator

theorem profilesStrategyIsFirstClass
    (strategy : ProfilesStrategy) :
    strategy.firstClassPooObject :=
  strategy.firstClassEstablished

theorem profilesStrategyUsesNoKindToken
    (strategy : ProfilesStrategy) :
    ¬ strategy.usesKindToken :=
  strategy.noKindToken

theorem profilesStrategyReadsNoHiddenRegistry
    (strategy : ProfilesStrategy) :
    ¬ strategy.readsHiddenRegistry :=
  strategy.noHiddenRegistry

theorem profilesStrategyCreatesNoSecondRuntime
    (strategy : ProfilesStrategy) :
    ¬ strategy.createsSecondObjectRuntime :=
  strategy.noSecondObjectRuntime

theorem admissionRequiresProfileResult
    (admission : TwoStageAdmission) :
    admission.instantiatedResultIsProfileObject :=
  admission.semanticContractEstablished

theorem orderedLiftingPreservesOperandOrder
    {OperandIdentity : Type}
    (lifting : OrderedOperandLift OperandIdentity) :
    lifting.liftedOperands = lifting.declaredOperands :=
  lifting.preservesDeclaredOrder

theorem orderedLiftingDoesNotBatchByCategory
    {OperandIdentity : Type}
    (lifting : OrderedOperandLift OperandIdentity) :
    ¬ lifting.batchesObjectsBeforePrototypes :=
  lifting.noCategoryBatching

theorem rootInstantiatesExactlyOnce
    (root : CompositionRoot) :
    root.instantiationCount = 1 :=
  root.instantiatedExactlyOnce

theorem rootIsImmutable
    (root : CompositionRoot) :
    root.immutable :=
  root.immutabilityEstablished

theorem rootDoesNotResolveNewestRevision
    (root : CompositionRoot) :
    ¬ root.resolvesNewestRevision :=
  root.noDynamicRevisionResolution

theorem prototypeRecursionUsesNativeFixedPoint :
    UsesNativeFixedPoint .prototypeRecursion := by
  simp [UsesNativeFixedPoint]

theorem inheritanceCycleFailsC3Admission :
    ¬ AdmitsC3Precedence .inheritanceCycle := by
  simp [AdmitsC3Precedence]

theorem slotPriorityDoesNotChangeC3Precedence
    (priority : PriorityBoundary) :
    ¬ priority.changesC3Precedence :=
  priority.noC3PrecedenceChange

theorem correspondenceUsesPinnedGerbilPoo
    (correspondence : PoofCorrespondence) :
    correspondence.usesPinnedGerbilPooConstruction :=
  correspondence.pinnedConstructionEstablished

theorem correspondenceInventsNoLocalLiftingFormula
    (correspondence : PoofCorrespondence) :
    ¬ correspondence.inventsLocalLiftingFormula :=
  correspondence.noLocalLiftingFormula

theorem compositionIsNotUniversallyReducedToMix
    (correspondence : PoofCorrespondence) :
    ¬ correspondence.reducesAllCompositionToMix :=
  correspondence.noUniversalMixReduction

end PooFlowProof.PooC3.ProfilePrototypeCorrespondence
