;;; -*- Gerbil -*-
;;; Boundary: strategies choose planning policy, not runtime execution.
;;; Invariant: heavy execution remains in runner/runtime-adapter code.

(import :core/flow
        :core/plan
        :core/task)

(export make-strategy
        strategy?
        strategy-name
        strategy-capabilities
        strategy-cache-policy
        strategy-failure-policy
        strategy-planner
        make-local-eager-strategy
        make-cached-local-eager-strategy
        strategy-plan
        strategy-planner-for-flow
        strategy-can-select-frontier?
        strategy-ready-frontier
        strategy-ready-frontier-ids
        strategy-can-run-locally?
        strategy-cache-decision)

;;; The planner slot is the only executable policy hook; other fields are
;;; declarative metadata used for task and graph-frontier capability checks.
;; Strategy <- Symbol [Symbol] Symbol Symbol Planner
(defstruct strategy
  (name
   capabilities
   cache-policy
   failure-policy
   planner)
  transparent: #t)

;;; The default strategy mirrors Funflow's eager local path while still lowering
;;; to an inspectable plan before any runner touches execution.
;; Strategy <- Unit
(def (make-local-eager-strategy)
  (make-strategy 'local-eager
                 '(pure scheme store external branch graph-frontier)
                 'no-cache
                 'fail-fast
                 default-linear-plan))

;;; Cached eager execution records cache intent in receipts but leaves durable
;;; cache materialization to the runtime adapter/Rust boundary.
;; Strategy <- Unit
(def (make-cached-local-eager-strategy)
  (make-strategy 'cached-local-eager
                 '(pure scheme store external branch graph-frontier)
                 'cache-output
                 'fail-fast
                 default-linear-plan))

;; ExecutionPlan <- Flow
(def (default-linear-plan flow)
  (flow->linear-plan flow))

;; ExecutionPlan <- Strategy Flow
(def (strategy-plan strategy flow)
  ((strategy-planner-for-flow strategy flow) flow))

;;; Flow descriptors declare the planner policy; strategies bind supported
;;; descriptor planner names to concrete plan functions.
;; Planner <- Strategy Flow
(def (strategy-planner-for-flow strategy flow)
  (let ((planner (flow-declaration-planner (flow-declaration-descriptor flow))))
    (cond
     ((eq? planner 'linear-dag) (strategy-planner strategy))
     (else (error "strategy does not support flow planner" planner)))))

;;; Frontier support is capability-gated so later strategies can opt out of
;;; graph scheduling without changing the execution-plan data model.
;; Boolean <- Strategy
(def (strategy-can-select-frontier? strategy)
  (and (memq 'graph-frontier (strategy-capabilities strategy)) #t))

;;; Strategy owns the policy decision to expose a ready frontier; plan owns the
;;; pure graph predicate that computes it.
;; [PlanNode] <- Strategy ExecutionPlan [Id]
(def (strategy-ready-frontier strategy plan completed-node-ids)
  (if (strategy-can-select-frontier? strategy)
    (execution-plan-ready-nodes plan completed-node-ids)
    (error "strategy cannot select graph frontier" (strategy-name strategy))))

;;; The id projection is the stable receipt/adapter surface for frontier
;;; evidence when callers do not need plan-node payloads.
;; [Id] <- Strategy ExecutionPlan [Id]
(def (strategy-ready-frontier-ids strategy plan completed-node-ids)
  (if (strategy-can-select-frontier? strategy)
    (execution-plan-ready-node-ids plan completed-node-ids)
    (error "strategy cannot select graph frontier" (strategy-name strategy))))

;; Boolean <- Strategy Task
(def (strategy-can-run-locally? strategy task)
  (and (memq (task-capability task) (strategy-capabilities strategy))
       (task-local? task)))

;;; Cache decisions are evidence values, not storage actions; runners copy them
;;; into receipts so adapters can later materialize the policy.
;; CacheDecision <- Strategy Task Input Output
(def (strategy-cache-decision strategy task input output)
  (let ((policy (strategy-cache-policy strategy)))
    (cond
     ((eq? policy 'no-cache)
      (list 'cache-bypass (task-name task) (task-kind task)))
     ((eq? policy 'cache-output)
      (list 'cache-miss (task-name task) (task-kind task) input output))
     (else
      (list 'cache-policy policy (task-name task) (task-kind task) input output)))))
