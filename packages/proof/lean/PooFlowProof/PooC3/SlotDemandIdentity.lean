import PooFlowProof.PooC3.StrategyFacetPurity

namespace PooFlowProof.PooC3.SlotDemandIdentity

open PooFlowProof.PooC3.StrategyFacetPurity

universe u

structure PureSlotDemand
    (SemanticTarget DemandCausal EvidenceRequest ExecutionPolicy : Type u)
    where
  semanticTarget : SemanticTarget
  demandCausal : DemandCausal
  evidenceRequest : EvidenceRequest
  executionPolicy : ExecutionPolicy
deriving Repr, DecidableEq

def businessResultCacheKey
    {SemanticTarget DemandCausal EvidenceRequest ExecutionPolicy : Type u}
    (demand :
      PureSlotDemand
        SemanticTarget
        DemandCausal
        EvidenceRequest
        ExecutionPolicy) :
    SemanticTarget :=
  demand.semanticTarget

structure LiveDemandRequest
    (SemanticTarget DemandCausal EvidenceRequest ExecutionPolicy : Type u)
    where
  demand :
    PureSlotDemand
      SemanticTarget
      DemandCausal
      EvidenceRequest
      ExecutionPolicy
  context : LiveEvaluationContext
deriving Repr, DecidableEq

def liveBusinessResultCacheKey
    {SemanticTarget DemandCausal EvidenceRequest ExecutionPolicy : Type u}
    (request :
      LiveDemandRequest
        SemanticTarget
        DemandCausal
        EvidenceRequest
        ExecutionPolicy) :
    SemanticTarget :=
  businessResultCacheKey request.demand

theorem sameSemanticTargetSameBusinessResultCacheKey
    {SemanticTarget DemandCausal EvidenceRequest ExecutionPolicy : Type u}
    (left right :
      PureSlotDemand
        SemanticTarget
        DemandCausal
        EvidenceRequest
        ExecutionPolicy)
    (sameTarget : left.semanticTarget = right.semanticTarget) :
    businessResultCacheKey left =
      businessResultCacheKey right := by
  exact sameTarget

theorem causalIdentityCannotSplitBusinessResultCache
    {SemanticTarget DemandCausal EvidenceRequest ExecutionPolicy : Type u}
    (target : SemanticTarget)
    (leftCausal rightCausal : DemandCausal)
    (evidence : EvidenceRequest)
    (policy : ExecutionPolicy) :
    businessResultCacheKey
        ({ semanticTarget := target
           demandCausal := leftCausal
           evidenceRequest := evidence
           executionPolicy := policy } :
          PureSlotDemand
            SemanticTarget
            DemandCausal
            EvidenceRequest
            ExecutionPolicy) =
      businessResultCacheKey
        ({ semanticTarget := target
           demandCausal := rightCausal
           evidenceRequest := evidence
           executionPolicy := policy } :
          PureSlotDemand
            SemanticTarget
            DemandCausal
            EvidenceRequest
            ExecutionPolicy) := by
  rfl

theorem evidenceRequestCannotSplitBusinessResultCache
    {SemanticTarget DemandCausal EvidenceRequest ExecutionPolicy : Type u}
    (target : SemanticTarget)
    (causal : DemandCausal)
    (leftEvidence rightEvidence : EvidenceRequest)
    (policy : ExecutionPolicy) :
    businessResultCacheKey
        ({ semanticTarget := target
           demandCausal := causal
           evidenceRequest := leftEvidence
           executionPolicy := policy } :
          PureSlotDemand
            SemanticTarget
            DemandCausal
            EvidenceRequest
            ExecutionPolicy) =
      businessResultCacheKey
        ({ semanticTarget := target
           demandCausal := causal
           evidenceRequest := rightEvidence
           executionPolicy := policy } :
          PureSlotDemand
            SemanticTarget
            DemandCausal
            EvidenceRequest
            ExecutionPolicy) := by
  rfl

theorem executionPolicyCannotSplitBusinessResultCache
    {SemanticTarget DemandCausal EvidenceRequest ExecutionPolicy : Type u}
    (target : SemanticTarget)
    (causal : DemandCausal)
    (evidence : EvidenceRequest)
    (leftPolicy rightPolicy : ExecutionPolicy) :
    businessResultCacheKey
        ({ semanticTarget := target
           demandCausal := causal
           evidenceRequest := evidence
           executionPolicy := leftPolicy } :
          PureSlotDemand
            SemanticTarget
            DemandCausal
            EvidenceRequest
            ExecutionPolicy) =
      businessResultCacheKey
        ({ semanticTarget := target
           demandCausal := causal
           evidenceRequest := evidence
           executionPolicy := rightPolicy } :
          PureSlotDemand
            SemanticTarget
            DemandCausal
            EvidenceRequest
            ExecutionPolicy) := by
  rfl

theorem liveContextCannotSplitBusinessResultCache
    {SemanticTarget DemandCausal EvidenceRequest ExecutionPolicy : Type u}
    (demand :
      PureSlotDemand
        SemanticTarget
        DemandCausal
        EvidenceRequest
        ExecutionPolicy)
    (leftContext rightContext : LiveEvaluationContext) :
    liveBusinessResultCacheKey
        ({ demand := demand
           context := leftContext } :
          LiveDemandRequest
            SemanticTarget
            DemandCausal
            EvidenceRequest
            ExecutionPolicy) =
      liveBusinessResultCacheKey
        ({ demand := demand
           context := rightContext } :
          LiveDemandRequest
            SemanticTarget
            DemandCausal
            EvidenceRequest
            ExecutionPolicy) := by
  rfl

end PooFlowProof.PooC3.SlotDemandIdentity
