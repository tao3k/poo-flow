;;; -*- Gerbil -*-
;;; Boundary: module option/schema validation projection.
;;; Invariant: option projection returns inspectable Scheme values only.
;; | PooModuleOptionConfigCandidate = Value
;; | PooModuleOptionSchemaCandidate = Value
;; | PooModuleOptionValidationReceiptCandidate = Value

(import (only-in :clan/poo/object .all-slots .ref object?)
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/descriptor)

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
        poo-flow-module-validation-receipts)

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
