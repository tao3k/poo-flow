(export poo-flow-stage-result-prototype
        make-poo-flow-stage-result
        poo-flow-stage-result?
        poo-flow-stage-result-label
        poo-flow-stage-result-specs
        poo-flow-stage-result-outcome
        poo-flow-stage-result-reason
        poo-flow-stage-result-cache-status
        poo-flow-stage-result-elapsed-micros
        poo-flow-stage-result->contract)

(import :poo-flow/src/core/object-syntax
        (only-in :clan/poo/object .ref object?))

;; : (-> PooFlowStageResultPrototype)
(def poo-flow-stage-result-prototype
  (poo-core-role-object
   (slots ((kind 'poo-flow-stage-result)))
   (supers)))

;; : (-> String List Symbol Symbol Symbol Integer PooFlowStageResult)
(def (make-poo-flow-stage-result label specs outcome reason cache-status elapsed-micros)
  (poo-core-role-object
   (slot-rows
    (list (cons 'label label)
          (cons 'specs specs)
          (cons 'outcome outcome)
          (cons 'reason reason)
          (cons 'cache-status cache-status)
          (cons 'elapsed-micros elapsed-micros)))
   (supers poo-flow-stage-result-prototype)))

;; : (-> Any Boolean)
(def (poo-flow-stage-result? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow-stage-result)))

;; : (-> PooFlowStageResult String)
(def (poo-flow-stage-result-label result)
  (.ref result 'label))

;; : (-> PooFlowStageResult List)
(def (poo-flow-stage-result-specs result)
  (.ref result 'specs))

;; : (-> PooFlowStageResult Symbol)
(def (poo-flow-stage-result-outcome result)
  (.ref result 'outcome))

;; : (-> PooFlowStageResult Symbol)
(def (poo-flow-stage-result-reason result)
  (.ref result 'reason))

;; : (-> PooFlowStageResult Symbol)
(def (poo-flow-stage-result-cache-status result)
  (.ref result 'cache-status))

;; : (-> PooFlowStageResult Integer)
(def (poo-flow-stage-result-elapsed-micros result)
  (.ref result 'elapsed-micros))

;; : (-> PooFlowStageResult Alist)
(def (poo-flow-stage-result->contract result)
  (list (cons 'kind 'poo-flow-stage-result)
        (cons 'label (poo-flow-stage-result-label result))
        (cons 'specs (poo-flow-stage-result-specs result))
        (cons 'outcome (poo-flow-stage-result-outcome result))
        (cons 'reason (poo-flow-stage-result-reason result))
        (cons 'cache-status (poo-flow-stage-result-cache-status result))
        (cons 'elapsed-micros
              (poo-flow-stage-result-elapsed-micros result))))
