;;; -*- Gerbil -*-
;;; Contract: native POO observability Type/Contract scenario tests.

(export observability-feedback-test)

(import :std/test
        "../src/observability/objects.ss"
        "../src/observability/types.ss"
        (only-in "../src/module-system/types.ss"
                 poo-flow-validation-evidence-accepted?))

(def (observability-test-ref row key)
  (cdr (assq key row)))

(def (observability-test-nested-ref row outer-key inner-key)
  (observability-test-ref (observability-test-ref row outer-key) inner-key))

(def (observability-sandbox-diagnostic severity)
  (poo-flow-observability-diagnostic-record
   severity 'contract 'sandbox-resource-validator 'build #f
   'permission-widening-denied
   "build cannot widen filesystem write scope"
   'author
   '((module . sandbox) (resource . filesystem))))

(def (observability-blocked-receipt diagnostic)
  (poo-flow-observability-feedback-receipt
   "poo-flow-observability-feedback/v1"
   'sandbox-resource
   (poo-flow-observability-graph
    'sandbox-resource '((nodes . (build)) (edges . ())))
   (list diagnostic)
   (poo-flow-observability-repair
    'author 'sandbox-resource-declaration '((field . filesystem)))
   (poo-flow-observability-readiness 'blocked #f)
   '((manifest-preview . #f))))

(def (observability-ready-receipt)
  (poo-flow-observability-feedback-receipt
   "poo-flow-observability-feedback/v1"
   'sandbox-resource
   (poo-flow-observability-graph
    'sandbox-resource
    '((nodes . (build)) (edges . ()))
    '((preview . ready)))
   '()
   (poo-flow-observability-repair #f #f)
   (poo-flow-observability-readiness 'ready #t)
   '((manifest-preview . report-only))))

(def observability-feedback-test
  (test-suite
   "native POO observability Type and Contract"

   (test-case "constructs a prototype-derived diagnostic and evidence"
     (let (diagnostic (observability-sandbox-diagnostic 'error))
       (check (poo-flow-observability-prototype?
               poo-flow-observability-receipt-prototype) => #t)
       (check (poo-flow-observability-diagnostic-contract? diagnostic) => #t)
       (check (poo-flow-validation-evidence-accepted?
               (poo-flow-observability-diagnostic-contract-evidence diagnostic))
              => #t)
       (check (poo-flow-observability-diagnostic-code diagnostic)
              => 'permission-widening-denied)))

   (test-case "rejects an invalid diagnostic obligation"
     (check-exception
      (observability-sandbox-diagnostic 'bad-severity)
      true))

   (test-case "projects blocked feedback from the admitted receipt"
     (let* ((receipt
             (observability-blocked-receipt
              (observability-sandbox-diagnostic 'error)))
            (feedback
             (poo-flow-observability-agent-feedback
              'poo-flow-agent-feedback
              'accept-sandbox-resource
              'repair-sandbox-resource
              receipt)))
       (check (poo-flow-observability-receipt-valid? receipt) => #f)
       (check (observability-test-ref feedback 'next-action)
              => 'repair-sandbox-resource)
       (check (observability-test-ref feedback 'family)
              => 'observability/receipt)
       (check (observability-test-nested-ref feedback 'graph 'kind)
              => 'sandbox-resource)
       (check (observability-test-nested-ref feedback 'repair 'target-layer)
              => 'author)
       (check (observability-test-nested-ref feedback 'readiness 'state)
              => 'blocked)
       (check (member 'permission-widening-denied
                      (observability-test-ref feedback 'diagnostic-codes))
              ? values)))

   (test-case "accepts ready feedback without diagnostics"
     (let* ((receipt (observability-ready-receipt))
            (feedback
             (poo-flow-observability-agent-feedback
              'poo-flow-agent-feedback
              'accept-sandbox-resource
              'repair-sandbox-resource
              receipt)))
       (check (poo-flow-observability-receipt-valid? receipt) => #t)
       (check (observability-test-ref feedback 'next-action)
              => 'accept-sandbox-resource)
       (check (observability-test-ref feedback 'diagnostic-codes) => '())))))
