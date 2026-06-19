;;; -*- Gerbil -*-
;;; Boundary: module option/schema validation and runtime-facing projections.
;;; Invariant: projection returns inspectable Scheme values, not runtime handles.
;; | PooModuleOptionConfigCandidate = Value
;; | PooModuleOptionSchemaCandidate = Value
;; | PooModuleOptionValidationReceiptCandidate = Value

(import (only-in :clan/poo/object .all-slots .o .@ .ref object?)
        :poo-flow/src/modules/interface
        :poo-flow/src/modules/descriptor
        :poo-flow/src/modules/context)

(export make-poo-flow-module-option-config
        poo-flow-module-option-config?
        poo-flow-module-option-config-id
        poo-flow-module-option-config-value
        poo-flow-module-option-config-source-module
        poo-flow-module-option-config-metadata
        make-poo-flow-module-option-schema
        poo-flow-module-option-schema?
        poo-flow-module-option-schema-id
        poo-flow-module-option-schema-source-module
        poo-flow-module-option-schema-type
        poo-flow-module-option-schema-rule
        poo-flow-module-option-schema-value
        poo-flow-module-option-schema-metadata
        make-poo-flow-module-option-validation-receipt
        poo-flow-module-option-validation-receipt?
        poo-flow-module-option-validation-receipt-id
        poo-flow-module-option-validation-receipt-source-module
        poo-flow-module-option-validation-receipt-valid?
        poo-flow-module-option-validation-receipt-code
        poo-flow-module-option-validation-receipt-messages
        poo-flow-module-option-validation-receipt-metadata
        poo-flow-module-option-configs
        poo-flow-module-option-schemas
        poo-flow-module-find-schema
        poo-flow-module-missing-schema-receipt
        poo-flow-module-option-validation-receipts
        poo-flow-module-validation-receipts
        poo-flow-module-runtime-import
        poo-flow-module-apply
        poo-flow-module-evaluate
        poo-flow-module-workflow
        pooFlowModuleCatalog
        poo-flow-module-catalog
        poo-flow-module-value-catalog-find
        poo-flow-module-value-catalog-active?
        poo-flow-module-value-catalog-root
        pooFlowModuleActive?
        poo-flow-module-active?
        pooFlowEvalModules
        poo-flow-eval-modules
        pooFlowModuleSystemPresentation
        poo-flow-module-system-presentation)

;;; Option configs and schemas are the Scheme-side projection layer equivalent
;;; to Marlin's deck-runtime option receipts, but without a Rust dependency.
;; : (-> String Value Value Alist PooModuleOptionConfig)
(defstruct poo-flow-module-option-config
  (id
   value
   source-module
   metadata)
  transparent: #t)

;; : (-> String Value Value Symbol Value Alist PooModuleOptionSchema)
(defstruct poo-flow-module-option-schema
  (id
   source-module
   type
   rule
   value
   metadata)
  transparent: #t)

;; : (-> String Value Boolean Symbol [String] Alist PooModuleOptionValidationReceipt)
(defstruct poo-flow-module-option-validation-receipt
  (id
   source-module
   valid?
   code
   messages
   metadata)
  transparent: #t)

;;; Boundary: option ids use the public slot name form.
;; : (-> OptionSlotName OptionId)
(def (poo-flow-module-option-id slot-name)
  (if (symbol? slot-name)
    (symbol->string slot-name)
    slot-name))

;;; Boundary: schema specs default to String when the interface is concise.
;; : (-> PooModuleSchemaSpec OptionValueType)
(def (poo-flow-module-schema-spec-type schema-spec)
  (poo-flow-module-object-ref/default schema-spec 'type 'String))

;;; Boundary: schema metadata is optional and never required for validation.
;; : (-> PooModuleSchemaSpec SchemaMetadata)
(def (poo-flow-module-schema-spec-metadata schema-spec)
  (poo-flow-module-object-ref/default schema-spec 'metadata '()))

;;; Boundary: one schema spec records required/default/constant/optional rule.
;; : (-> ModuleName OptionId PooModuleSchemaSpec PooModuleOptionSchema)
(def (poo-flow-module-schema-from-spec module-id-value option-id-value schema-spec)
  (let ((value-type (poo-flow-module-schema-spec-type schema-spec))
        (metadata-value (poo-flow-module-schema-spec-metadata schema-spec)))
    (cond
     ((poo-flow-module-object-has-slot? schema-spec 'policy)
      (make-poo-flow-module-option-schema
       option-id-value
       module-id-value
       value-type
       (.ref schema-spec 'policy)
       (poo-flow-module-object-ref/default schema-spec 'default #f)
       metadata-value))
     ((poo-flow-module-object-has-slot? schema-spec 'constant)
      (make-poo-flow-module-option-schema
       option-id-value
       module-id-value
       value-type
       'constant
       (.ref schema-spec 'constant)
       metadata-value))
     ((poo-flow-module-object-has-slot? schema-spec 'default)
      (make-poo-flow-module-option-schema
       option-id-value
       module-id-value
       value-type
       'default
       (.ref schema-spec 'default)
       metadata-value))
     ((poo-flow-module-object-ref/default schema-spec 'optional? #f)
      (make-poo-flow-module-option-schema
       option-id-value
       module-id-value
       value-type
       'optional
       #f
       metadata-value))
     (else
      (make-poo-flow-module-option-schema
       option-id-value
       module-id-value
       value-type
       'required
       #f
       metadata-value)))))

;;; Boundary: config objects become option config receipts at projection time.
;; : (-> PooModuleDescriptor [PooModuleOptionConfig])
(def (poo-flow-module-option-configs module)
  (let ((module-id-value (poo-flow-module-name module))
        (option-object (poo-flow-module-config module)))
    (cond
     ((object? option-object)
      (map (lambda (slot-name)
             (make-poo-flow-module-option-config
              (poo-flow-module-option-id slot-name)
              (.ref option-object slot-name)
              module-id-value
              '()))
           (.all-slots option-object)))
     (else
      (map (lambda (option-pair)
             (make-poo-flow-module-option-config
              (poo-flow-module-option-id (car option-pair))
              (cdr option-pair)
              module-id-value
              '()))
           (poo-flow-module-options module))))))

;;; Boundary: option schemas are projected from interface schema slots.
;; : (-> PooModuleDescriptor [PooModuleOptionSchema])
(def (poo-flow-module-option-schemas module)
  (let ((module-id-value (poo-flow-module-name module))
        (schema-object (poo-flow-module-schemas module)))
    (if (object? schema-object)
      (map (lambda (slot-name)
             (poo-flow-module-schema-from-spec
              module-id-value
              (poo-flow-module-option-id slot-name)
              (.ref schema-object slot-name)))
           (.all-slots schema-object))
      '())))

;;; Boundary: schema lookup matches projected option ids exactly.
;; : (-> [PooModuleOptionSchema] OptionId MaybePooModuleOptionSchema)
(def (poo-flow-module-find-schema schemas option-id-value)
  (find (lambda (schema)
          (poo-flow-module-kind=? (poo-flow-module-option-schema-id schema)
                                  option-id-value))
        schemas))

;;; Boundary: missing-schema receipts keep validation non-throwing.
;; : (-> PooModuleOptionConfig PooModuleOptionValidationReceipt)
(def (poo-flow-module-missing-schema-receipt config)
  (make-poo-flow-module-option-validation-receipt
   (poo-flow-module-option-config-id config)
   (poo-flow-module-option-config-source-module config)
   #f
   'missing-schema
   '("option schema is not declared")
   '()))

;;; Boundary: this slice validates constants and records other schema rules.
;; : (-> PooModuleOptionSchema PooModuleOptionConfig Boolean)
(def (poo-flow-module-option-schema-valid? schema config)
  (cond
   ((eq? (poo-flow-module-option-schema-rule schema) 'constant)
    (equal? (poo-flow-module-option-config-value config)
            (poo-flow-module-option-schema-value schema)))
   (else #t)))

;;; Boundary: validation receipts carry outcome, not exceptions.
;; : (-> PooModuleOptionSchema PooModuleOptionConfig PooModuleOptionValidationReceipt)
(def (poo-flow-module-option-schema-validation-receipt schema config)
  (if (poo-flow-module-option-schema-valid? schema config)
    (make-poo-flow-module-option-validation-receipt
     (poo-flow-module-option-config-id config)
     (poo-flow-module-option-config-source-module config)
     #t
     'ok
     '()
     (poo-flow-module-option-schema-metadata schema))
    (make-poo-flow-module-option-validation-receipt
     (poo-flow-module-option-config-id config)
     (poo-flow-module-option-config-source-module config)
     #f
     'constant-mismatch
     '("option value does not match constant schema")
     (poo-flow-module-option-schema-metadata schema))))

;;; Boundary: per-module receipts validate declared option configs only.
;; : (-> PooModuleDescriptor [PooModuleOptionValidationReceipt])
(def (poo-flow-module-option-validation-receipts module)
  (let (schemas (poo-flow-module-option-schemas module))
    (map (lambda (config)
           (let (schema
                 (poo-flow-module-find-schema
                  schemas
                  (poo-flow-module-option-config-id config)))
             (if schema
               (poo-flow-module-option-schema-validation-receipt schema config)
               (poo-flow-module-missing-schema-receipt config))))
         (poo-flow-module-option-configs module))))

;;; Boundary: module validation stays recursive over inline import profiles.
;; : (-> PooModuleDescriptor [PooModuleOptionValidationReceipt])
(def (poo-flow-module-validation-receipts module)
  (append
   (foldr append
          '()
          (map poo-flow-module-validation-receipts
               (poo-flow-module-import-configs (poo-flow-module-imports module))))
   (poo-flow-module-option-validation-receipts module)))

;;; Boundary: runtime imports unwrap structured imports but preserve payloads.
;; : (-> ModuleImportValue RuntimeImport)
(def (poo-flow-module-runtime-import import-value)
  (let (profile (poo-flow-module-import-profile import-value))
    (cond
     ((poo-flow-module-config? profile)
      (poo-flow-module-apply profile))
     (else profile))))

;;; Boundary: apply creates an inspectable runtime-module value, not a handle.
;; : (-> PooModuleDescriptor POOObject)
(def (poo-flow-module-apply module)
  (.o kind: "poo-flow.modules.runtime-module.v1"
      id: (poo-flow-module-name module)
      group: (poo-flow-module-group module)
      flags: (poo-flow-module-flags module)
      features: (poo-flow-module-features module)
      depth: (poo-flow-module-depth module)
      phase-files: (poo-flow-module-phase-files module)
      hooks: (poo-flow-module-hooks module)
      imports: (map poo-flow-module-runtime-import (poo-flow-module-imports module))
      extensions: (poo-flow-module-extensions module)
      scripts: (poo-flow-module-scripts module)
      options: (poo-flow-module-option-configs module)
      metadata: (poo-flow-module-metadata module)))

;;; Boundary: projection append preserves closure module order.
;; : (-> [PooModuleDescriptor] (-> PooModuleDescriptor ProjectionValueList) [ProjectionValue])
(def (poo-flow-module-append-projection modules projector)
  (foldr append '() (map projector modules)))

;;; Boundary: evaluation folds the import closure into one receipt object.
;; : (-> PooModuleDescriptor POOObject)
(def (poo-flow-module-evaluate module)
  (let (closed-modules (poo-flow-module-closure (list module)))
    (.o kind: "poo-flow.modules.runtime-evaluation.v1"
        module-ids: (poo-flow-module-names closed-modules)
        init-module-ids:
        (poo-flow-module-names
         (poo-flow-module-phase-order closed-modules 'init))
        config-module-ids:
        (poo-flow-module-names
         (poo-flow-module-phase-order closed-modules 'config))
        hooks: (poo-flow-module-append-projection closed-modules poo-flow-module-hooks)
        extensions: (poo-flow-module-append-projection closed-modules poo-flow-module-extensions)
        scripts: (poo-flow-module-append-projection closed-modules poo-flow-module-scripts)
        options: (poo-flow-module-append-projection closed-modules poo-flow-module-option-configs)
        validation-receipts:
        (poo-flow-module-append-projection
         closed-modules
         poo-flow-module-option-validation-receipts))))

;;; Boundary: workflow groups root projections and validation receipts.
;; : (-> PooModuleDescriptor [AllowedHookId] POOObject)
(def (poo-flow-module-workflow module . maybe-allowed-hook-id-values)
  (let* ((allowed-hook-id-values
          (if (null? maybe-allowed-hook-id-values)
            '()
            (car maybe-allowed-hook-id-values)))
         (runtime-module-value (poo-flow-module-apply module))
         (evaluation-value (poo-flow-module-evaluate module)))
    (.o kind: poo-flow-module-workflow-kind
        config: module
        runtime-module: runtime-module-value
        evaluation: evaluation-value
        allowed-hook-ids: allowed-hook-id-values
        root-options: (poo-flow-module-option-configs module)
        option-schemas: (poo-flow-module-option-schemas module)
        root-validation-receipts:
        (poo-flow-module-option-validation-receipts module)
        validation-receipts:
        (.ref evaluation-value 'validation-receipts))))

;;; Boundary: value catalog is a user-facing catalog, separate from source catalog.
;; : (-> [PooModuleDescriptor] POOObject)
(def (poo-flow-module-catalog . module-values)
  (.o kind: poo-flow-module-value-catalog-kind
      modules: module-values))

;; : (-> [PooModuleDescriptor] POOObject)
(def (pooFlowModuleCatalog . module-values)
  (apply poo-flow-module-catalog module-values))

;;; Boundary: value catalog lookup is by module id only.
;; : (-> PooModuleValueCatalog ModuleName MaybePooModuleDescriptor)
(def (poo-flow-module-value-catalog-find catalog module-id-value)
  (find (lambda (module)
          (equal? (poo-flow-module-name module) module-id-value))
        (.ref catalog 'modules)))

;;; Boundary: catalog active checks make Doom's modulep behavior data-driven.
;; : (-> PooModuleValueCatalog ModuleName [ModuleFlag] Boolean)
(def (poo-flow-module-value-catalog-active? catalog module-id-value . required-flags)
  (let (module (poo-flow-module-value-catalog-find catalog module-id-value))
    (and module
         (apply poo-flow-module-active? module required-flags))))

;; : (-> PooModuleValueCatalog ModuleName [ModuleFlag] Boolean)
(def (pooFlowModuleActive? catalog module-id-value . required-flags)
  (apply poo-flow-module-value-catalog-active?
         catalog
         module-id-value
         required-flags))

;;; Boundary: missing root id falls back to the first catalog module.
;; : (-> PooModuleValueCatalog MaybeModuleName PooModuleDescriptor)
(def (poo-flow-module-value-catalog-root catalog module-id-value)
  (cond
   (module-id-value
    (or (poo-flow-module-value-catalog-find catalog module-id-value)
        (error "poo-flow module root not found" module-id-value)))
   ((pair? (.ref catalog 'modules))
    (car (.ref catalog 'modules)))
   (else
    (error "poo-flow module catalog is empty"))))

;;; Boundary: evalModules mirrors Marlin without entering runtime execution.
;; | PooFlowEvalModuleOptions = [MaybeModuleName [AllowedHookId]]
;; pooFlowEvalModules
;;   : (-> PooModuleValueCatalog PooFlowEvalModuleOptions POOObject)
;;   | contract: returns branded POO Flow evaluation data, never runtime handles
;;   | doc m%
;;   | # Examples
;;   | ```scheme
;;   | (pooFlowEvalModules catalog 'root '("after-config"))
;;   | ```
;;   | result: replayable module evaluation receipt with brand and owner fields.
;; : (-> PooModuleValueCatalog PooFlowEvalModuleOptions POOObject)
(def (poo-flow-eval-modules catalog . eval-options)
  (let* ((root-module-id-value
          (if (null? eval-options) #f (car eval-options)))
         (allowed-hook-id-values
          (if (or (null? eval-options)
                  (null? (cdr eval-options)))
            '()
            (cadr eval-options)))
         (root-module
          (poo-flow-module-value-catalog-root catalog root-module-id-value))
         (workflow
          (poo-flow-module-workflow root-module allowed-hook-id-values))
         (evaluation-value (.ref workflow 'evaluation)))
    (.o kind: poo-flow-eval-modules-result-kind
        catalog-kind: (.ref catalog 'kind)
        root-module-id: (poo-flow-module-name root-module)
        root-module-kind: (.@ root-module kind)
        workflow-kind: (.ref workflow 'kind)
        module-evaluation-kind: (.ref evaluation-value 'kind)
        module-count: (length (.ref evaluation-value 'module-ids))
        init-module-count: (length (.ref evaluation-value 'init-module-ids))
        config-module-count: (length (.ref evaluation-value 'config-module-ids))
        hook-count: (length (.ref evaluation-value 'hooks))
        extension-count: (length (.ref evaluation-value 'extensions))
        script-count: (length (.ref evaluation-value 'scripts))
        option-count: (length (.ref evaluation-value 'options))
        validation-receipt-count:
        (length (.ref evaluation-value 'validation-receipts))
        brand-name: poo-flow-brand-name
        brand-group: poo-flow-brand-group
        scheme-owner: poo-flow-scheme-owner
        module-system-owner: poo-flow-module-system-owner
        runtime-owner: "marlin-agent-core"
        runtime-boundary-owner: "marlin-agent-core"
        runtime-executed: #f
        replayable: #t)))

;; : (-> PooModuleValueCatalog PooFlowEvalModuleOptions POOObject)
(def (pooFlowEvalModules catalog . eval-options)
  (apply poo-flow-eval-modules catalog eval-options))

;;; Boundary: presentation is the debug/doctor scalar summary of evalModules.
;; | PooFlowModulePresentationOptions = [MaybeModuleName [AllowedHookId]]
;; pooFlowModuleSystemPresentation
;;   : (-> PooModuleValueCatalog PooFlowModulePresentationOptions POOObject)
;;   | contract: presents POO Flow brand, module counts, and owner boundaries
;;   | doc m%
;;   | # Examples
;;   | ```scheme
;;   | (pooFlowModuleSystemPresentation catalog 'root)
;;   | ```
;;   | result: user-facing presentation object with runtime-executed set to #f.
;; : (-> PooModuleValueCatalog PooFlowModulePresentationOptions POOObject)
(def (poo-flow-module-system-presentation catalog . eval-options)
  (let* ((root-module-id-value
          (if (null? eval-options) #f (car eval-options)))
         (allowed-hook-id-values
          (if (or (null? eval-options)
                  (null? (cdr eval-options)))
            '()
            (cadr eval-options)))
         (root-module
          (poo-flow-module-value-catalog-root catalog root-module-id-value))
         (eval-result
          (cond
           ((null? eval-options)
            (poo-flow-eval-modules catalog))
           ((null? (cdr eval-options))
            (poo-flow-eval-modules catalog root-module-id-value))
           (else
            (poo-flow-eval-modules
             catalog
             root-module-id-value
             allowed-hook-id-values)))))
    (.o kind: poo-flow-module-system-presentation-kind
        catalog-kind: (.ref catalog 'kind)
        catalog-module-count: (length (.ref catalog 'modules))
        root-module-id: (poo-flow-module-name root-module)
        root-module-kind: (.@ root-module kind)
        root-import-count: (length (poo-flow-module-imports root-module))
        root-flag-count: (length (poo-flow-module-flags root-module))
        root-hook-count: (length (poo-flow-module-hooks root-module))
        root-extension-count: (length (poo-flow-module-extensions root-module))
        root-script-count: (length (poo-flow-module-scripts root-module))
        allowed-hook-count: (length allowed-hook-id-values)
        user-entrypoints:
        '("poo-flow-modules"
          "poo-flow-module-catalog"
          "poo-flow-module-active?"
          "poo-flow-module-value-catalog-active?"
          "poo-flow-eval-modules"
          "poo-flow-module-system-presentation")
        module-eval-result-kind: (.ref eval-result 'kind)
        workflow-kind: (.ref eval-result 'workflow-kind)
        module-evaluation-receipt-kind:
        (.ref eval-result 'module-evaluation-kind)
        module-count: (.ref eval-result 'module-count)
        init-module-count: (.ref eval-result 'init-module-count)
        config-module-count: (.ref eval-result 'config-module-count)
        hook-count: (.ref eval-result 'hook-count)
        extension-count: (.ref eval-result 'extension-count)
        script-count: (.ref eval-result 'script-count)
        option-count: (.ref eval-result 'option-count)
        validation-receipt-count:
        (.ref eval-result 'validation-receipt-count)
        import-graph-owner: "poo-flow-module-system"
        brand-name: poo-flow-brand-name
        brand-group: poo-flow-brand-group
        option-policy-owner: poo-flow-module-system-owner
        extension-composition-owner: poo-flow-module-system-owner
        scheme-owner: (.ref eval-result 'scheme-owner)
        module-system-owner: (.ref eval-result 'module-system-owner)
        runtime-owner: (.ref eval-result 'runtime-owner)
        runtime-boundary-owner: (.ref eval-result 'runtime-boundary-owner)
        runtime-lifecycle-owner: "marlin-agent-core"
        runtime-executed: (.ref eval-result 'runtime-executed)
        runtime-parses-scheme-source: #f
        scheme-manufactures-runtime-handlers: #f
        replayable: (.ref eval-result 'replayable))))

;; : (-> PooModuleValueCatalog PooFlowModulePresentationOptions POOObject)
(def (pooFlowModuleSystemPresentation catalog . eval-options)
  (apply poo-flow-module-system-presentation catalog eval-options))
