;;; -*- Gerbil -*-
;;; Opt-in pure consumer. No default Observability dispatch or output changes.
(import (only-in :clan/poo/object .cc .mix)
        "interface.ss"
        (only-in "../../observability/interface.ss"
                 poo-flow-observation-summary
                 poo-flow-observation-explain))
(export poo-observation-combination-renderer poo-observation-combination-summary)
(def summary-generic
  (poo-combination-generic 'observation-summary 'research/summary-plan required: 1 rest?: #f))
;; : (-> CombinationFrame POOObject PooFlowObservation PooFlowObservationSummary)
(def (base-summary _frame _receiver event) (poo-flow-observation-summary event))
;; : (-> CombinationFrame POOObject PooFlowObservation PooFlowObservationSummary)
(def (detailed-summary frame _receiver event)
  (.cc (poo-call-next-method frame) 'explanation (poo-flow-observation-explain event)))
(def SummaryRenderer.
  (poo-method-prototype (poo-method-root summary-generic) summary-generic
    (poo-method-bundle primary: (poo-combination-method 'summary base-summary))))
(def DetailedSummaryRenderer.
  (poo-method-prototype SummaryRenderer. summary-generic
    (poo-method-bundle primary: (poo-combination-method 'explanation detailed-summary))))
;; : (-> explanation?: Boolean POOObject)
(def (poo-observation-combination-renderer explanation?: (explanation? #f))
  (unless (boolean? explanation?) (error "Expected boolean explanation selection"))
  (.mix (if explanation? DetailedSummaryRenderer. SummaryRenderer.)))
(def poo-observation-combination-summary (poo-combination-bind summary-generic))
