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

(defstruct plan-node
  (id
   ordinal
   step
   kind
   name)
  transparent: #t)

(defstruct execution-plan
  (flow-name
   nodes
   input-contract
   output-contract)
  transparent: #t)

(def (flow->linear-plan flow)
  (make-execution-plan (flow-name flow)
                       (steps->plan-nodes (flow-name flow) (flow-steps flow))
                       (flow-input-contract flow)
                       (flow-output-contract flow)))

(def (steps->plan-nodes flow-name steps)
  (let loop ((remaining steps)
             (ordinal 0)
             (nodes '()))
    (if (null? remaining)
      (reverse nodes)
      (let* ((step (car remaining))
             (kind (step-kind step))
             (name (step-name step))
             (id (list 'node flow-name ordinal kind name)))
        (loop (cdr remaining)
              (+ ordinal 1)
              (cons (make-plan-node id ordinal step kind name) nodes))))))

(def (step-kind step)
  (cond
   ((task? step) (task-kind step))
   ((flow? step) 'flow)
   (else (error "flow step is neither task nor flow" step))))

(def (step-name step)
  (cond
   ((task? step) (task-name step))
   ((flow? step) (flow-name step))
   (else (error "flow step is neither task nor flow" step))))

(def (plan-empty? plan)
  (null? (execution-plan-nodes plan)))

(def (plan-node-count plan)
  (length (execution-plan-nodes plan)))
