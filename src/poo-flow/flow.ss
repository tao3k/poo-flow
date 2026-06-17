(import :poo-flow/task)

(export make-flow
        flow?
        flow-name
        flow-steps
        flow-input-contract
        flow-output-contract
        flow-compose
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

(def (flow-empty? flow)
  (null? (flow-steps flow)))

(def (flow-step-count flow)
  (length (flow-steps flow)))
