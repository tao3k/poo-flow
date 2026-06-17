(import :poo-flow/flow
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

(defstruct strategy
  (name
   capabilities
   cache-policy
   failure-policy
   planner)
  transparent: #t)

(def (make-local-eager-strategy)
  (make-strategy 'local-eager
                 '(pure scheme store external)
                 'no-cache
                 'fail-fast
                 default-linear-plan))

(def (default-linear-plan flow)
  (flow-steps flow))

(def (strategy-plan strategy flow)
  ((strategy-planner strategy) flow))

(def (strategy-can-run-locally? strategy task)
  (and (memq (task-kind task) (strategy-capabilities strategy))
       (task-local? task)))
