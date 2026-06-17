;;; -*- Gerbil -*-
;;; Boundary: planning produces inspectable control-plane artifacts.
;;; Invariant: execution stays in the runner/runtime-adapter layer.

(import :core/flow
        :core/task)

(export make-plan-node
        plan-node?
        plan-node-id
        plan-node-ordinal
        plan-node-step
        plan-node-kind
        plan-node-name
        plan-node-dependencies
        make-execution-plan
        execution-plan?
        execution-plan-flow-name
        execution-plan-nodes
        execution-plan-input-contract
        execution-plan-output-contract
        flow->linear-plan
        plan-empty?
        plan-node-count)

;;; A node keeps both the original step and normalized metadata; dependencies
;;; expose a DAG-ready plan without moving execution into Scheme.
;; PlanNode <- Symbol Nat Step Symbol Symbol [Symbol]
(defstruct plan-node
  (id
   ordinal
   step
   kind
   name
   dependencies)
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

;;; Ordinals and predecessor pairs are data, not loop state: together they
;;; preserve order while exposing dependency edges for later schedulers.
;; [PlanNode] <- Symbol [Step]
(def (steps->plan-nodes flow-name steps)
  (map (lambda (ordinal step previous)
         (step->plan-node flow-name ordinal step previous))
       (iota (length steps))
       steps
       (cons #f steps)))

;; PlanNode <- Symbol Nat Step MaybeStep
(def (step->plan-node flow-name ordinal step previous)
  (let* ((kind (step-kind step))
         (name (step-name step))
         (id (plan-node-id-for flow-name ordinal step))
         (dependencies
          (if previous
            (list (plan-node-id-for flow-name (- ordinal 1) previous))
            '())))
    (make-plan-node id ordinal step kind name dependencies)))

;; Symbol <- Symbol Nat Step
(def (plan-node-id-for flow-name ordinal step)
  (list 'node flow-name ordinal (step-kind step) (step-name step)))

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
