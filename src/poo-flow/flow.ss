(import :poo-flow/task)

(export make-flow
        flow?
        flow-name
        flow-steps
        flow-input-contract
        flow-output-contract
        flow-compose
        task-flow
        pure-flow
        scheme-flow
        store-flow
        external-flow
        return-flow
        flow-then
        flow-empty?
        flow-step-count)

(defstruct flow
  (name
   steps
   input-contract
   output-contract)
  transparent: #t)

(def (flow-compose name steps input-contract output-contract)
  (make-flow name steps input-contract output-contract))

(def (task-flow name task)
  (flow-compose name
                (list task)
                (task-input-contract task)
                (task-output-contract task)))

(def (pure-flow name proc input-contract output-contract)
  (task-flow name (make-pure-task name proc input-contract output-contract)))

(def (scheme-flow name proc input-contract output-contract)
  (task-flow name (make-scheme-task name proc input-contract output-contract)))

(def (store-flow name operation payload input-contract output-contract)
  (task-flow name (make-store-task name operation payload input-contract output-contract)))

(def (external-flow name operation payload input-contract output-contract)
  (task-flow name (make-external-task name operation payload input-contract output-contract)))

(def (return-flow name contract)
  (pure-flow name (lambda (value) value) contract contract))

(def (flow-then name left right)
  (flow-compose name
                (append (flow-steps left) (flow-steps right))
                (flow-input-contract left)
                (flow-output-contract right)))

(def (flow-empty? flow)
  (null? (flow-steps flow)))

(def (flow-step-count flow)
  (length (flow-steps flow)))
