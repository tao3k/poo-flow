;;; -*- Gerbil -*-
;;; Boundary: planning produces inspectable control-plane artifacts.
;;; Invariant: execution stays in the runner/runtime-adapter layer.

(import :poo-flow/flow
        :poo-flow/task)

(export make-plan-node
        plan-node?
        plan-node-id
        plan-node-ordinal
        plan-node-step
        plan-node-kind
        plan-node-name
        make-execution-plan
        execution-plan?
        execution-plan-flow-name
        execution-plan-nodes
        execution-plan-input-contract
        execution-plan-output-contract
        flow->linear-plan
        plan-empty?
        plan-node-count)

;;; A node keeps both the original step and the normalized metadata used by
;;; strategy/policy code, so adapters do not need to reclassify steps.
;; PlanNode <- Symbol Nat Step Symbol Symbol
(defstruct plan-node
  (id
   ordinal
   step
   kind
   name)
  transparent: #t)

;;; The plan mirrors the flow boundary contracts while exposing a flat node
;;; stream for strategy selection and audit receipts.
;; ExecutionPlan <- Symbol [PlanNode] Contract Contract
(defstruct execution-plan
  (flow-name
   nodes
   input-contract
   output-contract)
  transparent: #t)

;; ExecutionPlan <- Flow
(def (flow->linear-plan flow)
  (make-execution-plan (flow-name flow)
                       (steps->plan-nodes (flow-name flow) (flow-steps flow))
                       (flow-input-contract flow)
                       (flow-output-contract flow)))

;;; Ordinals are data, not loop state: the index list is the stable source for
;;; node identity and preserves the flow step order.
;; [PlanNode] <- Symbol [Step]
(def (steps->plan-nodes flow-name steps)
  (map (lambda (ordinal step)
         (let* ((kind (step-kind step))
                (name (step-name step))
                (id (list 'node flow-name ordinal kind name)))
           (make-plan-node id ordinal step kind name)))
       (iota (length steps))
       steps))

;; Symbol <- Step
(def (step-kind step)
  (cond
   ((task? step) (task-kind step))
   ((flow? step) 'flow)
   (else (error "flow step is neither task nor flow" step))))

;; Symbol <- Step
(def (step-name step)
  (cond
   ((task? step) (task-name step))
   ((flow? step) (flow-name step))
   (else (error "flow step is neither task nor flow" step))))

;; Boolean <- ExecutionPlan
(def (plan-empty? plan)
  (null? (execution-plan-nodes plan)))

;; Nat <- ExecutionPlan
(def (plan-node-count plan)
  (length (execution-plan-nodes plan)))
