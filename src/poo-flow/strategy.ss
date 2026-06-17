;;; -*- Gerbil -*-
;;; Boundary: strategies choose planning policy, not runtime execution.
;;; Invariant: heavy execution remains in runner/runtime-adapter code.

(import :poo-flow/plan
        :poo-flow/task)

(export make-strategy
        strategy?
        strategy-name
        strategy-capabilities
        strategy-cache-policy
        strategy-failure-policy
        strategy-planner
        make-local-eager-strategy
        strategy-plan
        strategy-can-run-locally?)

;;; The planner slot is the only executable policy hook; other fields are
;;; declarative metadata used for local capability checks.
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
                 '(pure scheme store external)
                 'no-cache
                 'fail-fast
                 default-linear-plan))

;; ExecutionPlan <- Flow
(def (default-linear-plan flow)
  (flow->linear-plan flow))

;; ExecutionPlan <- Strategy Flow
(def (strategy-plan strategy flow)
  ((strategy-planner strategy) flow))

;; Boolean <- Strategy Task
(def (strategy-can-run-locally? strategy task)
  (and (memq (task-kind task) (strategy-capabilities strategy))
       (task-local? task)))
