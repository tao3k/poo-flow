;;; -*- Gerbil -*-
;;; Boundary: flows describe workflow composition and contract shape.
;;; Invariant: task execution is deferred to runner/runtime-adapter code.

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

;;; Boundary: a flow stores ordered steps plus its input/output contract edge.
;;; Invariant: nested flows remain steps until a planner chooses lowering.
;; Flow <- Symbol [Step] Contract Contract
(defstruct flow
  (name
   steps
   input-contract
   output-contract)
  transparent: #t)

;; Flow <- Symbol [Step] Contract Contract
(def (flow-compose name steps input-contract output-contract)
  (make-flow name steps input-contract output-contract))

;; Flow <- Symbol Task
(def (task-flow name task)
  (flow-compose name
                (list task)
                (task-input-contract task)
                (task-output-contract task)))

;; Flow <- Symbol Procedure Contract Contract
(def (pure-flow name proc input-contract output-contract)
  (task-flow name (make-pure-task name proc input-contract output-contract)))

;; Flow <- Symbol Procedure Contract Contract
(def (scheme-flow name proc input-contract output-contract)
  (task-flow name (make-scheme-task name proc input-contract output-contract)))

;; Flow <- Symbol Symbol Payload Contract Contract
(def (store-flow name operation payload input-contract output-contract)
  (task-flow name (make-store-task name operation payload input-contract output-contract)))

;; Flow <- Symbol Symbol Payload Contract Contract
(def (external-flow name operation payload input-contract output-contract)
  (task-flow name (make-external-task name operation payload input-contract output-contract)))

;;; The identity lambda is the unit flow: it preserves value and contract while
;;; still presenting the same task-backed flow shape as non-trivial steps.
;; Flow <- Symbol Contract
(def (return-flow name contract)
  (pure-flow name (lambda (value) value) contract contract))

;;; Composition concatenates logical steps and keeps the left input/right output
;;; edge, matching pipeline composition without running either side.
;; Flow <- Symbol Flow Flow
(def (flow-then name left right)
  (flow-compose name
                (append (flow-steps left) (flow-steps right))
                (flow-input-contract left)
                (flow-output-contract right)))

;; Boolean <- Flow
(def (flow-empty? flow)
  (null? (flow-steps flow)))

;; Nat <- Flow
(def (flow-step-count flow)
  (length (flow-steps flow)))
