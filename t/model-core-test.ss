(import :std/test
        :clan/poo/object
        :poo-flow/src/modules/model-core/objects
        :poo-flow/src/modules/model-core/config)

(def (model-core-test-row-ref row key)
  (let (entry (assq key row))
    (and entry (cdr entry))))

(export model-core-test)

(def model-core-test
  (test-suite "model core"
    (test-case "model specs expose POO-native accessors and projections"
      (check-equal? (poo-flow-model-spec-ref poo-flow-model-core-tool-json-model)
                    'tool-json)
      (check-equal? (poo-flow-model-spec-provider poo-flow-model-core-tool-json-model)
                    'runtime-local)
      (check-equal? (poo-flow-model-spec-model-id poo-flow-model-core-tool-json-model)
                    "local-tool-json")
      (check-equal? (poo-flow-model-spec-capabilities poo-flow-model-core-tool-json-model)
                    '(chat text json tool-calling))
      (check-equal? (model-core-test-row-ref
                     (poo-flow-model-spec->alist
                      poo-flow-model-core-tool-json-model)
                     'runtime-executed)
                    #f))
    (test-case "model catalog summarizes refs without runtime execution"
      (check-equal? (poo-flow-model-catalog-ref poo-flow-model-core-default-catalog)
                    'model-core-default)
      (check-equal? (poo-flow-model-catalog-model-refs
                     poo-flow-model-core-default-catalog)
                    '(fast-text tool-json))
      (check-equal? (poo-flow-model-catalog-model-count
                     poo-flow-model-core-default-catalog)
                    2)
      (check-equal? (poo-flow-model-spec-ref
                     (poo-flow-model-catalog-find
                      poo-flow-model-core-default-catalog
                      'fast-text))
                    'fast-text))
    (test-case "selection policy chooses the first compatible model"
      (def receipt
        (poo-flow-model-select
         poo-flow-model-core-default-selection-policy
         poo-flow-model-core-default-catalog))
      (check-equal? (poo-flow-model-selection-receipt-valid? receipt)
                    #t)
      (check-equal? (poo-flow-model-selection-receipt-selected-model-ref receipt)
                    'tool-json)
      (check-equal? (poo-flow-model-selection-receipt-diagnostics receipt)
                    '())
      (check-equal? (model-core-test-row-ref
                     (poo-flow-model-selection-receipt->alist receipt)
                     'runtime-executed)
                    #f))
    (test-case "selection policy records diagnostics before fallback"
      (def small-catalog
        (poo-flow-model-catalog
         'small
         (list poo-flow-model-core-fast-text-model)))
      (def policy
        (poo-flow-model-selection-policy
         'needs-json
         '(missing tool-json)
         'fast-text
         '(chat text)
         'first-compatible
         '()))
      (def receipt (poo-flow-model-select policy small-catalog))
      (check-equal? (poo-flow-model-selection-receipt-valid? receipt)
                    #t)
      (check-equal? (poo-flow-model-selection-receipt-selected-model-ref receipt)
                    'fast-text)
      (check-equal? (model-core-test-row-ref
                     (car (poo-flow-model-selection-receipt-diagnostics receipt))
                     'reason)
                    'missing-model))))
