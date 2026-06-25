;;; -*- Gerbil -*-
;;; Boundary: runner validation checks planned steps against strategy/adapter support.

(import :poo-flow/src/core/failure
        :poo-flow/src/core/task
        :poo-flow/src/core/plan
        :poo-flow/src/core/strategy
        :poo-flow/src/core/runtime-adapter)

(export validate-plan-node)

;; : (-> TaskFamilyRegistry Strategy RuntimeAdapter PlanNode Boolean)
(def (validate-plan-node task-registry strategy adapter node)
  (validate-step task-registry strategy adapter (plan-node-step node)))

;; : (-> TaskFamilyRegistry Strategy RuntimeAdapter Step Boolean)
(def (validate-step task-registry strategy adapter step)
  (when (task? step)
    (validate-task task-registry strategy adapter step)))

;; : (-> TaskFamilyRegistry Strategy RuntimeAdapter Task Boolean)
(def (validate-task task-registry strategy adapter task)
  (let ((capability (task-capability-in task-registry task)))
    (unless (memq capability (strategy-capabilities strategy))
      (raise-control-plane-failure
       'runner
       'unsupported-task-capability
       "strategy does not support task kind"
       (list (cons 'strategy (strategy-name strategy))
             (cons 'capability capability)
             (cons 'task-kind (task-kind task)))))
    (when (task-adapter-routed?-in task-registry task)
      (unless (adapter-supports? adapter capability)
        (raise-control-plane-failure
         'runner
         'unsupported-adapter-capability
         "adapter does not support task kind"
         (list (cons 'adapter (runtime-adapter-name adapter))
               (cons 'capability capability)
               (cons 'task-kind (task-kind task))))))))
