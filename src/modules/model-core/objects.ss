(export +poo-flow-model-core-spec-kind+
        +poo-flow-model-core-catalog-kind+
        +poo-flow-model-core-selection-policy-kind+
        +poo-flow-model-core-selection-receipt-kind+
        poo-flow-model-field-rows
        poo-flow-model-symbol-list?
        poo-flow-model-alist?
        poo-flow-model-spec
        poo-flow-model-spec?
        poo-flow-model-spec-ref
        poo-flow-model-spec-provider
        poo-flow-model-spec-model-id
        poo-flow-model-spec-capabilities
        poo-flow-model-spec-modalities
        poo-flow-model-spec-context-window
        poo-flow-model-spec-max-output-tokens
        poo-flow-model-spec->alist
        poo-flow-model-catalog
        poo-flow-model-catalog?
        poo-flow-model-catalog-ref
        poo-flow-model-catalog-model-refs
        poo-flow-model-catalog-model-count
        poo-flow-model-catalog-find
        poo-flow-model-selection-policy
        poo-flow-model-selection-policy?
        poo-flow-model-selection-policy-ref
        poo-flow-model-selection-policy-candidate-model-refs
        poo-flow-model-selection-policy-required-capabilities
        poo-flow-model-selection-receipt
        poo-flow-model-selection-receipt?
        poo-flow-model-selection-receipt-valid?
        poo-flow-model-selection-receipt-selected-model-ref
        poo-flow-model-selection-receipt-diagnostics
        poo-flow-model-selection-receipt->alist
        poo-flow-model-select)

(import (only-in :clan/poo/object .ref object<-alist object?)
        :poo-flow/src/module-system/object-family-syntax
        :poo-flow/src/modules/session/policy
        (only-in :poo-flow/src/modules/session/objects-core
                 poo-flow-session-every?
                 poo-flow-session-require))

(def +poo-flow-model-core-spec-kind+ 'poo-flow-model-core-spec)
(def +poo-flow-model-core-catalog-kind+ 'poo-flow-model-core-catalog)
(def +poo-flow-model-core-selection-policy-kind+ 'poo-flow-model-core-selection-policy)
(def +poo-flow-model-core-selection-receipt-kind+ 'poo-flow-model-core-selection-receipt)

(defrules poo-flow-model-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

(def (poo-flow-model-symbol-list? value)
  (and (list? value)
       (poo-flow-session-every? symbol? value)))

(def (poo-flow-model-alist? value)
  (and (list? value)
       (poo-flow-session-every? pair? value)))

(def (poo-flow-model-positive-integer? value)
  (and (integer? value)
       (> value 0)))

(def (poo-flow-model-optional-symbol? value)
  (or (not value)
      (symbol? value)))

(def (poo-flow-model-kind? value kind)
  (eq? (.ref value 'kind) kind))

(def (poo-flow-model-spec model-ref
                          provider
                          model-id
                          capabilities
                          modalities
                          context-window
                          max-output-tokens
                          runtime-owner
                          handoff-operation
                          runtime-backend
                          . maybe-metadata)
  (poo-flow-session-require "model ref must be a symbol"
                            (symbol? model-ref)
                            model-ref)
  (poo-flow-session-require "model provider must be a symbol"
                            (symbol? provider)
                            provider)
  (poo-flow-session-require "model id must be a string"
                            (string? model-id)
                            model-id)
  (poo-flow-session-require "model capabilities must be symbols"
                            (poo-flow-model-symbol-list? capabilities)
                            capabilities)
  (poo-flow-session-require "model modalities must be symbols"
                            (poo-flow-model-symbol-list? modalities)
                            modalities)
  (poo-flow-session-require "model context window must be a positive integer"
                            (poo-flow-model-positive-integer? context-window)
                            context-window)
  (poo-flow-session-require "model max output tokens must be a positive integer"
                            (poo-flow-model-positive-integer? max-output-tokens)
                            max-output-tokens)
  (poo-flow-session-require "model runtime owner must be a string"
                            (string? runtime-owner)
                            runtime-owner)
  (poo-flow-session-require "model handoff operation must be a symbol"
                            (symbol? handoff-operation)
                            handoff-operation)
  (poo-flow-session-require "model runtime backend must be a symbol"
                            (symbol? runtime-backend)
                            runtime-backend)
  (object<-alist
   (list
    (cons 'kind +poo-flow-model-core-spec-kind+)
    (cons 'schema 'poo-flow.modules.model-core.spec.v1)
    (cons 'model-ref model-ref)
    (cons 'provider provider)
    (cons 'model-id model-id)
    (cons 'capabilities capabilities)
    (cons 'modalities modalities)
    (cons 'context-window context-window)
    (cons 'max-output-tokens max-output-tokens)
    (cons 'runtime-owner runtime-owner)
    (cons 'handoff-operation handoff-operation)
    (cons 'runtime-backend runtime-backend)
    (cons 'runtime-executed #f)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata))))))

(defpoo-object-family +poo-flow-model-core-spec-kind+
  poo-flow-model-spec?
  (accessors
   (poo-flow-model-spec-ref model-ref)
   (poo-flow-model-spec-provider provider)
   (poo-flow-model-spec-model-id model-id)
   (poo-flow-model-spec-capabilities capabilities)
   (poo-flow-model-spec-modalities modalities)
   (poo-flow-model-spec-context-window context-window)
   (poo-flow-model-spec-max-output-tokens max-output-tokens))
  (projections
   (poo-flow-model-spec->alist
    (schema schema)
    (model-ref model-ref)
    (provider provider)
    (model-id model-id)
    (capabilities capabilities)
    (modalities modalities)
    (context-window context-window)
    (max-output-tokens max-output-tokens)
    (runtime-owner runtime-owner)
    (handoff-operation handoff-operation)
    (runtime-backend runtime-backend)
    (runtime-executed runtime-executed)
    (metadata metadata))))

(def (poo-flow-model-catalog-summary models)
  (let loop ((rest models)
             (refs '())
             (count 0))
    (if (null? rest)
      (cons (reverse refs) count)
      (loop (cdr rest)
            (cons (poo-flow-model-spec-ref (car rest)) refs)
            (+ count 1)))))

(def (poo-flow-model-catalog catalog-ref models . maybe-metadata)
  (poo-flow-session-require "model catalog ref must be a symbol"
                            (symbol? catalog-ref)
                            catalog-ref)
  (poo-flow-session-require "model catalog models must be model specs"
                            (poo-flow-session-every? poo-flow-model-spec?
                                                     models)
                            models)
  (let* ((catalog-summary (poo-flow-model-catalog-summary models))
         (model-refs (car catalog-summary))
         (model-count (cdr catalog-summary)))
    (object<-alist
     (list
      (cons 'kind +poo-flow-model-core-catalog-kind+)
      (cons 'schema 'poo-flow.modules.model-core.catalog.v1)
      (cons 'catalog-ref catalog-ref)
      (cons 'models models)
      (cons 'model-refs model-refs)
      (cons 'model-count model-count)
      (cons 'runtime-owner "runtime-model-adapter")
      (cons 'runtime-executed #f)
      (cons 'metadata (if (null? maybe-metadata)
                        '()
                        (car maybe-metadata)))))))

(defpoo-object-family +poo-flow-model-core-catalog-kind+
  poo-flow-model-catalog?
  (accessors
   (poo-flow-model-catalog-ref catalog-ref)
   (poo-flow-model-catalog-model-refs model-refs)
   (poo-flow-model-catalog-model-count model-count))
  (projections))

(def (poo-flow-model-spec-find model-ref models)
  (cond
   ((null? models) #f)
   ((eq? model-ref (poo-flow-model-spec-ref (car models)))
    (car models))
   (else
    (poo-flow-model-spec-find model-ref (cdr models)))))

(def (poo-flow-model-catalog-find catalog model-ref)
  (poo-flow-model-spec-find model-ref (.ref catalog 'models)))

(def (poo-flow-model-selection-policy policy-ref
                                      candidate-model-refs
                                      fallback-model-ref
                                      required-capabilities
                                      routing-strategy
                                      budget-policy
                                      . maybe-metadata)
  (poo-flow-session-require "model selection policy ref must be a symbol"
                            (symbol? policy-ref)
                            policy-ref)
  (poo-flow-session-require "model selection candidates must be symbols"
                            (poo-flow-model-symbol-list? candidate-model-refs)
                            candidate-model-refs)
  (poo-flow-session-require "model selection fallback must be false or a symbol"
                            (poo-flow-model-optional-symbol? fallback-model-ref)
                            fallback-model-ref)
  (poo-flow-session-require "model selection required capabilities must be symbols"
                            (poo-flow-model-symbol-list? required-capabilities)
                            required-capabilities)
  (poo-flow-session-require "model routing strategy must be a symbol"
                            (symbol? routing-strategy)
                            routing-strategy)
  (poo-flow-session-require "model budget policy must be an alist"
                            (poo-flow-model-alist? budget-policy)
                            budget-policy)
  (object<-alist
   (list
    (cons 'kind +poo-flow-model-core-selection-policy-kind+)
    (cons 'schema 'poo-flow.modules.model-core.selection-policy.v1)
    (cons 'policy-ref policy-ref)
    (cons 'candidate-model-refs candidate-model-refs)
    (cons 'fallback-model-ref fallback-model-ref)
    (cons 'required-capabilities required-capabilities)
    (cons 'routing-strategy routing-strategy)
    (cons 'budget-policy budget-policy)
    (cons 'runtime-owner "runtime-model-adapter")
    (cons 'runtime-executed #f)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata))))))

(defpoo-object-family +poo-flow-model-core-selection-policy-kind+
  poo-flow-model-selection-policy?
  (accessors
   (poo-flow-model-selection-policy-ref policy-ref)
   (poo-flow-model-selection-policy-candidate-model-refs candidate-model-refs)
   (poo-flow-model-selection-policy-required-capabilities required-capabilities))
  (projections))

(def (poo-flow-model-supports-capability? spec capability)
  (if (memq capability (poo-flow-model-spec-capabilities spec))
    #t
    #f))

(def (poo-flow-model-supports-capabilities? spec capabilities)
  (poo-flow-session-every?
   (lambda (capability)
     (poo-flow-model-supports-capability? spec capability))
   capabilities))

(def (poo-flow-model-selection-diagnostic model-ref reason)
  (poo-flow-model-field-rows
   (model-ref model-ref)
   (reason reason)))

(defstruct poo-flow-model-selection-receipt-record
  (kind
   schema
   policy-ref
   catalog-ref
   valid?
   selected-model-ref
   selected-model
   diagnostics
   runtime-executed)
  transparent: #t)

(def (poo-flow-model-selection-receipt-ref receipt key default)
  (cond
   ((poo-flow-model-selection-receipt-record? receipt)
    (case key
      ((kind) (poo-flow-model-selection-receipt-record-kind receipt))
      ((schema) (poo-flow-model-selection-receipt-record-schema receipt))
      ((policy-ref) (poo-flow-model-selection-receipt-record-policy-ref receipt))
      ((catalog-ref) (poo-flow-model-selection-receipt-record-catalog-ref receipt))
      ((valid?) (poo-flow-model-selection-receipt-record-valid? receipt))
      ((selected-model-ref)
       (poo-flow-model-selection-receipt-record-selected-model-ref receipt))
      ((selected-model)
       (poo-flow-model-selection-receipt-record-selected-model receipt))
      ((diagnostics) (poo-flow-model-selection-receipt-record-diagnostics receipt))
      ((runtime-executed)
       (poo-flow-model-selection-receipt-record-runtime-executed receipt))
      (else default)))
   ((object? receipt) (.ref receipt key))
   (else default)))

(def (poo-flow-model-selection-receipt policy
                                      catalog
                                      valid?
                                      selected-model
                                      diagnostics)
  (make-poo-flow-model-selection-receipt-record
   +poo-flow-model-core-selection-receipt-kind+
   'poo-flow.modules.model-core.selection-receipt.v1
   (poo-flow-model-selection-policy-ref policy)
   (poo-flow-model-catalog-ref catalog)
   valid?
   (if selected-model
     (poo-flow-model-spec-ref selected-model)
     #f)
   selected-model
   diagnostics
   #f))

(def (poo-flow-model-selection-receipt? value)
  (or (poo-flow-model-selection-receipt-record? value)
      (poo-flow-model-kind? value +poo-flow-model-core-selection-receipt-kind+)))

(def (poo-flow-model-selection-receipt-valid? receipt)
  (poo-flow-model-selection-receipt-ref receipt 'valid? #f))

(def (poo-flow-model-selection-receipt-selected-model-ref receipt)
  (poo-flow-model-selection-receipt-ref receipt 'selected-model-ref #f))

(def (poo-flow-model-selection-receipt-diagnostics receipt)
  (poo-flow-model-selection-receipt-ref receipt 'diagnostics '()))

(def (poo-flow-model-selection-receipt->alist receipt)
  (poo-flow-model-field-rows
   (schema (poo-flow-model-selection-receipt-ref receipt 'schema #f))
   (policy-ref (poo-flow-model-selection-receipt-ref receipt 'policy-ref #f))
   (catalog-ref (poo-flow-model-selection-receipt-ref receipt 'catalog-ref #f))
   (valid? (poo-flow-model-selection-receipt-ref receipt 'valid? #f))
   (selected-model-ref
    (poo-flow-model-selection-receipt-ref receipt 'selected-model-ref #f))
   (diagnostics (poo-flow-model-selection-receipt-ref receipt 'diagnostics '()))
   (runtime-executed
    (poo-flow-model-selection-receipt-ref receipt 'runtime-executed #f))))

(def (poo-flow-model-selection-fallback-receipt policy
                                                catalog
                                                fallback-ref
                                                fallback-model
                                                fallback-valid?
                                                diagnostics)
  (poo-flow-model-selection-receipt
   policy
   catalog
   (if fallback-valid? #t #f)
   (if fallback-valid? fallback-model #f)
   (if fallback-valid?
     diagnostics
     (cons (poo-flow-model-selection-diagnostic fallback-ref
                                                'no-model-selected)
           diagnostics))))

(def (poo-flow-model-select-candidates catalog candidate-model-refs capabilities diagnostics)
  (cond
   ((null? candidate-model-refs)
    (cons #f (reverse diagnostics)))
   (else
    (let* ((model-ref (car candidate-model-refs))
           (model (poo-flow-model-catalog-find catalog model-ref)))
      (cond
       ((not model)
        (poo-flow-model-select-candidates
         catalog
         (cdr candidate-model-refs)
         capabilities
         (cons (poo-flow-model-selection-diagnostic model-ref 'missing-model)
               diagnostics)))
       ((poo-flow-model-supports-capabilities? model capabilities)
        (cons model (reverse diagnostics)))
       (else
        (poo-flow-model-select-candidates
         catalog
         (cdr candidate-model-refs)
         capabilities
         (cons (poo-flow-model-selection-diagnostic model-ref 'missing-capability)
               diagnostics))))))))

(def (poo-flow-model-select policy catalog)
  (poo-flow-session-require "model selection policy must be a model policy"
                            (poo-flow-model-selection-policy? policy)
                            policy)
  (poo-flow-session-require "model selection catalog must be a model catalog"
                            (poo-flow-model-catalog? catalog)
                            catalog)
  (let* ((required-capabilities (.ref policy 'required-capabilities))
         (candidate-result
          (poo-flow-model-select-candidates
           catalog
           (.ref policy 'candidate-model-refs)
           required-capabilities
           '()))
         (selected-model (car candidate-result))
         (diagnostics (cdr candidate-result)))
    (if selected-model
      (poo-flow-model-selection-receipt policy catalog #t selected-model diagnostics)
      (let* ((fallback-ref (.ref policy 'fallback-model-ref))
             (fallback-model (and fallback-ref
                                  (poo-flow-model-catalog-find catalog fallback-ref)))
             (fallback-valid? (and fallback-model
                                   (poo-flow-model-supports-capabilities?
                                    fallback-model
                                    required-capabilities))))
        (poo-flow-model-selection-fallback-receipt
         policy
         catalog
         fallback-ref
         fallback-model
         fallback-valid?
         diagnostics)))))
