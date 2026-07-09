;;; -*- Gerbil -*-
;;; Contract: standalone scenario test for observability feedback receipts.

(eval '(import "./src/observability/objects.ss"))
(eval '(import "./src/observability/types.ss"))
(eval '(import "./src/utilities/contracts.ss"))

;; : (-> PooFlowObservabilityExpr PooFlowObservabilityValue)
(def (observability-eval expr)
  (eval expr))

;; : (-> Alist Symbol PooFlowAlistValue)
(def (observability-test-ref row key)
  (cdr (assq key row)))

;; : (-> Alist Symbol Symbol PooFlowAlistValue)
(def (observability-test-nested-ref row outer-key inner-key)
  (observability-test-ref (observability-test-ref row outer-key) inner-key))

(unless (observability-eval
         '(poo-flow-observability-prototype?
           poo-flow-observability-receipt-prototype))
  (error "receipt prototype should be a canonical observability prototype"))

(unless (observability-eval
         '(poo-flow-object-type-contract?
           +poo-flow-observability-receipt-type-contract+))
  (error "receipt type contract should be a structured contract object"))

(let (receipt-type-row
      (observability-eval
       '(poo-flow-object-type-contract->alist
         +poo-flow-observability-receipt-type-contract+)))
  (unless (and (eq? (observability-test-ref receipt-type-row 'object-kind)
                    'PooFlowObservabilityReceipt)
               (pair? (observability-test-ref receipt-type-row 'slots)))
    (error "receipt type contract should project object kind and slot contracts")))

(def sandbox-diagnostic
  (observability-eval
   '(poo-flow-observability-diagnostic-record
     'error
     'contract
     'sandbox-resource-validator
     'build
     #f
     'permission-widening-denied
     "build cannot widen filesystem write scope"
     'author
     '((module . sandbox) (resource . filesystem)))))

(when (observability-eval
       '(with-catch
         (lambda (_failure) #f)
         (lambda ()
           (poo-flow-observability-diagnostic-record
            'bad-severity
            'contract
            'sandbox-resource-validator
            'build
            #f
            'permission-widening-denied
            "build cannot widen filesystem write scope"
            'author)
           #t)))
  (error "invalid diagnostic severity should fail the structured slot contract"))

(unless (eq? (observability-eval
              `(poo-flow-observability-diagnostic-code ',sandbox-diagnostic))
             'permission-widening-denied)
  (error "diagnostic code should come from the validator reason"))

(def blocked-receipt
  (observability-eval
   `(poo-flow-observability-feedback-receipt
     "poo-flow-observability-feedback/v1"
     'sandbox-resource
     (poo-flow-observability-graph
      'sandbox-resource
      '((nodes . (build)) (edges . ())))
     (list ',sandbox-diagnostic)
     (poo-flow-observability-repair
      'author
      'sandbox-resource-declaration
      '((field . filesystem)))
     (poo-flow-observability-readiness
      'blocked
      #f)
     '((manifest-preview . #f)))))

(when (observability-eval
       `(poo-flow-observability-receipt-valid? ',blocked-receipt))
  (error "blocked receipt with diagnostics should not validate as ready"))

(let (feedback
      (observability-eval
       `(poo-flow-observability-agent-feedback
         'poo-flow-agent-feedback
         'accept-sandbox-resource
         'repair-sandbox-resource
         ',blocked-receipt)))
  (unless (and (eq? (observability-test-ref feedback 'next-action)
                    'repair-sandbox-resource)
               (eq? (observability-test-ref feedback 'family)
                    'observability/receipt)
               (eq? (observability-test-nested-ref feedback 'graph 'kind)
                    'sandbox-resource)
               (eq? (observability-test-nested-ref feedback 'repair 'target-layer)
                    'author)
               (eq? (observability-test-nested-ref feedback 'readiness 'state)
                    'blocked)
               (member 'permission-widening-denied
                       (observability-test-ref feedback 'diagnostic-codes)))
    (error "blocked observability feedback should expose graph, repair, readiness, and diagnostic code")))

(def ready-receipt
  (observability-eval
   '(poo-flow-observability-feedback-receipt
     "poo-flow-observability-feedback/v1"
     'sandbox-resource
     (poo-flow-observability-graph
      'sandbox-resource
      '((nodes . (build)) (edges . ()))
      '((preview . ready)))
     '()
     (poo-flow-observability-repair #f #f)
     (poo-flow-observability-readiness 'ready #t)
     '((manifest-preview . report-only)))))

(let (feedback
      (observability-eval
       `(poo-flow-observability-agent-feedback
         'poo-flow-agent-feedback
         'accept-sandbox-resource
         'repair-sandbox-resource
         ',ready-receipt)))
  (unless (and (observability-eval
                `(poo-flow-observability-receipt-valid? ',ready-receipt))
               (eq? (observability-test-ref feedback 'next-action)
                    'accept-sandbox-resource)
               (null? (observability-test-ref feedback 'diagnostic-codes)))
    (error "ready observability feedback should accept and carry no diagnostic codes")))
