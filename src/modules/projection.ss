;;; -*- Gerbil -*-
;;; Boundary: module option/schema validation and runtime-facing projections.
;;; Invariant: projection returns inspectable Scheme values, not runtime handles.

(import (only-in :clan/poo/object .all-slots .o .@ .ref object?)
        :modules/interface
        :modules/descriptor
        :modules/context)

(export make-poo-module-option-config
        poo-module-option-config?
        poo-module-option-config-id
        poo-module-option-config-value
        poo-module-option-config-source-module
        poo-module-option-config-metadata
        make-poo-module-option-schema
        poo-module-option-schema?
        poo-module-option-schema-id
        poo-module-option-schema-source-module
        poo-module-option-schema-type
        poo-module-option-schema-rule
        poo-module-option-schema-value
        poo-module-option-schema-metadata
        make-poo-module-option-validation-receipt
        poo-module-option-validation-receipt?
        poo-module-option-validation-receipt-id
        poo-module-option-validation-receipt-source-module
        poo-module-option-validation-receipt-valid?
        poo-module-option-validation-receipt-code
        poo-module-option-validation-receipt-messages
        poo-module-option-validation-receipt-metadata
        poo-module-option-configs
        poo-module-option-schemas
        poo-module-find-schema
        poo-module-missing-schema-receipt
        poo-module-option-validation-receipts
        poo-module-validation-receipts
        poo-module-runtime-import
        poo-module-apply
        poo-module-evaluate
        poo-module-workflow
        pooModuleCatalog
        poo-module-value-catalog-find
        poo-module-value-catalog-active?
        poo-module-value-catalog-root
        pooModuleActive?
        pooEvalModules
        pooModuleSystemPresentation)

;;; Option configs and schemas are the Scheme-side projection layer equivalent
;;; to Marlin's deck-runtime option receipts, but without a Rust dependency.
;; PooModuleOptionConfig <- String Value Value Alist
(defstruct poo-module-option-config
  (id
   value
   source-module
   metadata)
  transparent: #t)

;; PooModuleOptionSchema <- String Value Value Symbol Value Alist
(defstruct poo-module-option-schema
  (id
   source-module
   type
   rule
   value
   metadata)
  transparent: #t)

;; PooModuleOptionValidationReceipt <- String Value Boolean Symbol [String] Alist
(defstruct poo-module-option-validation-receipt
  (id
   source-module
   valid?
   code
   messages
   metadata)
  transparent: #t)

;;; Boundary: option ids use the public slot name form.
;; OptionId <- OptionSlotName
(def (poo-module-option-id slot-name)
  (if (symbol? slot-name)
    (symbol->string slot-name)
    slot-name))

;;; Boundary: schema specs default to String when the interface is concise.
;; OptionValueType <- PooModuleSchemaSpec
(def (poo-module-schema-spec-type schema-spec)
  (poo-module-object-ref/default schema-spec 'type 'String))

;;; Boundary: schema metadata is optional and never required for validation.
;; SchemaMetadata <- PooModuleSchemaSpec
(def (poo-module-schema-spec-metadata schema-spec)
  (poo-module-object-ref/default schema-spec 'metadata '()))

;;; Boundary: one schema spec records required/default/constant/optional rule.
;; PooModuleOptionSchema <- ModuleName OptionId PooModuleSchemaSpec
(def (poo-module-schema-from-spec module-id-value option-id-value schema-spec)
  (let ((value-type (poo-module-schema-spec-type schema-spec))
        (metadata-value (poo-module-schema-spec-metadata schema-spec)))
    (cond
     ((poo-module-object-has-slot? schema-spec 'merge)
      (make-poo-module-option-schema
       option-id-value
       module-id-value
       value-type
       (.ref schema-spec 'merge)
       (poo-module-object-ref/default schema-spec 'default #f)
       metadata-value))
     ((poo-module-object-has-slot? schema-spec 'constant)
      (make-poo-module-option-schema
       option-id-value
       module-id-value
       value-type
       'constant
       (.ref schema-spec 'constant)
       metadata-value))
     ((poo-module-object-has-slot? schema-spec 'default)
      (make-poo-module-option-schema
       option-id-value
       module-id-value
       value-type
       'default
       (.ref schema-spec 'default)
       metadata-value))
     ((poo-module-object-ref/default schema-spec 'optional? #f)
      (make-poo-module-option-schema
       option-id-value
       module-id-value
       value-type
       'optional
       #f
       metadata-value))
     (else
      (make-poo-module-option-schema
       option-id-value
       module-id-value
       value-type
       'required
       #f
       metadata-value)))))

;;; Boundary: config objects become option config receipts at projection time.
;; [PooModuleOptionConfig] <- PooModuleDescriptor
(def (poo-module-option-configs module)
  (let ((module-id-value (poo-module-name module))
        (option-object (poo-module-config module)))
    (cond
     ((object? option-object)
      (map (lambda (slot-name)
             (make-poo-module-option-config
              (poo-module-option-id slot-name)
              (.ref option-object slot-name)
              module-id-value
              '()))
           (.all-slots option-object)))
     (else
      (map (lambda (option-pair)
             (make-poo-module-option-config
              (poo-module-option-id (car option-pair))
              (cdr option-pair)
              module-id-value
              '()))
           (poo-module-options module))))))

;;; Boundary: option schemas are projected from interface schema slots.
;; [PooModuleOptionSchema] <- PooModuleDescriptor
(def (poo-module-option-schemas module)
  (let ((module-id-value (poo-module-name module))
        (schema-object (poo-module-schemas module)))
    (if (object? schema-object)
      (map (lambda (slot-name)
             (poo-module-schema-from-spec
              module-id-value
              (poo-module-option-id slot-name)
              (.ref schema-object slot-name)))
           (.all-slots schema-object))
      '())))

;;; Boundary: schema lookup matches projected option ids exactly.
;; MaybePooModuleOptionSchema <- [PooModuleOptionSchema] OptionId
(def (poo-module-find-schema schemas option-id-value)
  (find (lambda (schema)
          (poo-module-kind=? (poo-module-option-schema-id schema)
                             option-id-value))
        schemas))

;;; Boundary: missing-schema receipts keep validation non-throwing.
;; PooModuleOptionValidationReceipt <- PooModuleOptionConfig
(def (poo-module-missing-schema-receipt config)
  (make-poo-module-option-validation-receipt
   (poo-module-option-config-id config)
   (poo-module-option-config-source-module config)
   #f
   'missing-schema
   '("option schema is not declared")
   '()))

;;; Boundary: this slice validates constants and records other schema rules.
;; Boolean <- PooModuleOptionSchema PooModuleOptionConfig
(def (poo-module-option-schema-valid? schema config)
  (cond
   ((eq? (poo-module-option-schema-rule schema) 'constant)
    (equal? (poo-module-option-config-value config)
            (poo-module-option-schema-value schema)))
   (else #t)))

;;; Boundary: validation receipts carry outcome, not exceptions.
;; PooModuleOptionValidationReceipt <- PooModuleOptionSchema PooModuleOptionConfig
(def (poo-module-option-schema-validation-receipt schema config)
  (if (poo-module-option-schema-valid? schema config)
    (make-poo-module-option-validation-receipt
     (poo-module-option-config-id config)
     (poo-module-option-config-source-module config)
     #t
     'ok
     '()
     (poo-module-option-schema-metadata schema))
    (make-poo-module-option-validation-receipt
     (poo-module-option-config-id config)
     (poo-module-option-config-source-module config)
     #f
     'constant-mismatch
     '("option value does not match constant schema")
     (poo-module-option-schema-metadata schema))))

;;; Boundary: per-module receipts validate declared option configs only.
;; [PooModuleOptionValidationReceipt] <- PooModuleDescriptor
(def (poo-module-option-validation-receipts module)
  (let (schemas (poo-module-option-schemas module))
    (map (lambda (config)
           (let (schema
                 (poo-module-find-schema
                  schemas
                  (poo-module-option-config-id config)))
             (if schema
               (poo-module-option-schema-validation-receipt schema config)
               (poo-module-missing-schema-receipt config))))
         (poo-module-option-configs module))))

;;; Boundary: module validation stays recursive over inline import profiles.
;; [PooModuleOptionValidationReceipt] <- PooModuleDescriptor
(def (poo-module-validation-receipts module)
  (append
   (foldr append
          '()
          (map poo-module-validation-receipts
               (poo-module-import-configs (poo-module-imports module))))
   (poo-module-option-validation-receipts module)))

;;; Boundary: runtime imports unwrap structured imports but preserve payloads.
;; RuntimeImport <- ModuleImportValue
(def (poo-module-runtime-import import-value)
  (let (profile (poo-module-import-profile import-value))
    (cond
     ((poo-module-config? profile)
      (poo-module-apply profile))
     (else profile))))

;;; Boundary: apply creates an inspectable runtime-module value, not a handle.
;; POOObject <- PooModuleDescriptor
(def (poo-module-apply module)
  (.o kind: "poo-flow.modules.runtime-module.v1"
      id: (poo-module-name module)
      group: (poo-module-group module)
      flags: (poo-module-flags module)
      features: (poo-module-features module)
      depth: (poo-module-depth module)
      phase-files: (poo-module-phase-files module)
      hooks: (poo-module-hooks module)
      imports: (map poo-module-runtime-import (poo-module-imports module))
      extensions: (poo-module-extensions module)
      scripts: (poo-module-scripts module)
      options: (poo-module-option-configs module)
      metadata: (poo-module-metadata module)))

;;; Boundary: projection append preserves closure module order.
;; [ProjectionValue] <- [PooModuleDescriptor] (ProjectionValueList <- PooModuleDescriptor)
(def (poo-module-append-projection modules projector)
  (foldr append '() (map projector modules)))

;;; Boundary: evaluation folds the import closure into one receipt object.
;; POOObject <- PooModuleDescriptor
(def (poo-module-evaluate module)
  (let (closed-modules (poo-module-closure (list module)))
    (.o kind: "poo-flow.modules.runtime-evaluation.v1"
        module-ids: (poo-module-names closed-modules)
        init-module-ids:
        (poo-module-names (poo-module-phase-order closed-modules 'init))
        config-module-ids:
        (poo-module-names (poo-module-phase-order closed-modules 'config))
        hooks: (poo-module-append-projection closed-modules poo-module-hooks)
        extensions: (poo-module-append-projection closed-modules poo-module-extensions)
        scripts: (poo-module-append-projection closed-modules poo-module-scripts)
        options: (poo-module-append-projection closed-modules poo-module-option-configs)
        validation-receipts:
        (poo-module-append-projection
         closed-modules
         poo-module-option-validation-receipts))))

;;; Boundary: workflow groups root projections and validation receipts.
;; POOObject <- PooModuleDescriptor [AllowedHookId]
(def (poo-module-workflow module . maybe-allowed-hook-id-values)
  (let* ((allowed-hook-id-values
          (if (null? maybe-allowed-hook-id-values)
            '()
            (car maybe-allowed-hook-id-values)))
         (runtime-module-value (poo-module-apply module))
         (evaluation-value (poo-module-evaluate module)))
    (.o kind: poo-module-workflow-kind
        config: module
        runtime-module: runtime-module-value
        evaluation: evaluation-value
        allowed-hook-ids: allowed-hook-id-values
        root-options: (poo-module-option-configs module)
        option-schemas: (poo-module-option-schemas module)
        root-validation-receipts:
        (poo-module-option-validation-receipts module)
        validation-receipts:
        (.ref evaluation-value 'validation-receipts))))

;;; Boundary: value catalog is a user-facing catalog, separate from source catalog.
;; POOObject <- [PooModuleDescriptor]
(def (pooModuleCatalog . module-values)
  (.o kind: poo-module-value-catalog-kind
      modules: module-values))

;;; Boundary: value catalog lookup is by module id only.
;; MaybePooModuleDescriptor <- PooModuleValueCatalog ModuleName
(def (poo-module-value-catalog-find catalog module-id-value)
  (find (lambda (module)
          (equal? (poo-module-name module) module-id-value))
        (.ref catalog 'modules)))

;;; Boundary: catalog active checks make Doom's modulep behavior data-driven.
;; Boolean <- PooModuleValueCatalog ModuleName [ModuleFlag]
(def (poo-module-value-catalog-active? catalog module-id-value . required-flags)
  (let (module (poo-module-value-catalog-find catalog module-id-value))
    (and module
         (apply poo-module-active? module required-flags))))

;; Boolean <- PooModuleValueCatalog ModuleName [ModuleFlag]
(def (pooModuleActive? catalog module-id-value . required-flags)
  (apply poo-module-value-catalog-active?
         catalog
         module-id-value
         required-flags))

;;; Boundary: missing root id falls back to the first catalog module.
;; PooModuleDescriptor <- PooModuleValueCatalog MaybeModuleName
(def (poo-module-value-catalog-root catalog module-id-value)
  (cond
   (module-id-value
    (or (poo-module-value-catalog-find catalog module-id-value)
        (error "poo module root not found" module-id-value)))
   ((pair? (.ref catalog 'modules))
    (car (.ref catalog 'modules)))
   (else
    (error "poo module catalog is empty"))))

;;; Boundary: evalModules mirrors Marlin without entering runtime execution.
;; POOObject <- PooModuleValueCatalog [MaybeModuleName [AllowedHookId]]
(def (pooEvalModules catalog . eval-options)
  (let* ((root-module-id-value
          (if (null? eval-options) #f (car eval-options)))
         (allowed-hook-id-values
          (if (or (null? eval-options)
                  (null? (cdr eval-options)))
            '()
            (cadr eval-options)))
         (root-module
          (poo-module-value-catalog-root catalog root-module-id-value))
         (workflow
          (poo-module-workflow root-module allowed-hook-id-values))
         (evaluation-value (.ref workflow 'evaluation)))
    (.o kind: poo-eval-modules-result-kind
        catalog-kind: (.ref catalog 'kind)
        root-module-id: (poo-module-name root-module)
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
        scheme-owner: "gerbil-poo"
        runtime-owner: "poo-flow-runtime"
        replayable: #t)))

;;; Boundary: presentation is the debug/doctor scalar summary of evalModules.
;; POOObject <- PooModuleValueCatalog [MaybeModuleName [AllowedHookId]]
(def (pooModuleSystemPresentation catalog . eval-options)
  (let* ((root-module-id-value
          (if (null? eval-options) #f (car eval-options)))
         (allowed-hook-id-values
          (if (or (null? eval-options)
                  (null? (cdr eval-options)))
            '()
            (cadr eval-options)))
         (root-module
          (poo-module-value-catalog-root catalog root-module-id-value))
         (eval-result
          (cond
           ((null? eval-options)
            (pooEvalModules catalog))
           ((null? (cdr eval-options))
            (pooEvalModules catalog root-module-id-value))
           (else
            (pooEvalModules
             catalog
             root-module-id-value
             allowed-hook-id-values)))))
    (.o kind: poo-module-system-presentation-kind
        catalog-kind: (.ref catalog 'kind)
        catalog-module-count: (length (.ref catalog 'modules))
        root-module-id: (poo-module-name root-module)
        root-module-kind: (.@ root-module kind)
        root-import-count: (length (poo-module-imports root-module))
        root-flag-count: (length (poo-module-flags root-module))
        root-hook-count: (length (poo-module-hooks root-module))
        root-extension-count: (length (poo-module-extensions root-module))
        root-script-count: (length (poo-module-scripts root-module))
        allowed-hook-count: (length allowed-hook-id-values)
        user-entrypoints:
        '("pooModules"
          "pooModuleCatalog"
          "pooModuleActive?"
          "pooEvalModules"
          "pooModuleSystemPresentation")
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
        import-graph-owner: "poo-module-system"
        option-merge-owner: "gerbil-poo"
        extension-composition-owner: "gerbil-poo"
        scheme-owner: (.ref eval-result 'scheme-owner)
        runtime-owner: (.ref eval-result 'runtime-owner)
        runtime-lifecycle-owner: "poo-flow-runtime"
        runtime-parses-scheme-source: #f
        scheme-manufactures-runtime-handlers: #f
        replayable: (.ref eval-result 'replayable))))
