;;; -*- Gerbil -*-
;;; Contract: validate values through generated JSON Schema object contracts.
;;; Invariant: this owner checks emitted POO Flow contracts only. It is not a
;;; full JSON Schema evaluator and does not fetch schemas or run workflows.

(import (only-in :clan/poo/object
                 object?)
        (only-in "../utilities/contracts.ss"
                 poo-flow-object-type-contract-key
                 poo-flow-object-type-contract-slots
                 poo-flow-slot-contract-slot
                 poo-flow-slot-contract-predicate
                 poo-flow-slot-contract-required?
                 poo-flow-slot-contract->alist)
        (only-in "./functional.ss"
                 poo-flow-contract-any?
                 poo-flow-contract-append-map
                 poo-flow-contract-json-object?
                 poo-flow-contract-project-list
                 poo-flow-contract-filter-map
                 poo-flow-contract-member?)
        (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-node?
                 poo-flow-json-schema-node-kind
                 poo-flow-json-schema-node-value
                 poo-flow-json-schema-node->alist
                 poo-flow-json-schema-property-name
                 poo-flow-json-schema-property-schema
                 poo-flow-json-schema-property-required?
                 poo-flow-json-schema-property->alist
                 poo-flow-json-schema-object-properties
                 poo-flow-json-schema-object-additional-properties
                 poo-flow-json-schema-object-pattern-properties
                 poo-flow-json-schema-pattern-property-schema
                 poo-flow-json-schema-normalization-schema)
        (only-in "./json-schema-emit.ss"
                 poo-flow-json-schema-null?
                 poo-flow-json-schema-node-predicate)
        (only-in "./json-schema-receipt.ss"
                 poo-flow-json-schema-contract-artifact-normalization
                 poo-flow-json-schema-contract-artifact-object-contract)
        (only-in "./json-schema-validation-core.ss"
                 +poo-flow-json-schema-validation-missing+
                 poo-flow-json-schema-candidate-slot
                 poo-flow-json-schema-candidate-rows
                 poo-flow-json-schema-path->symbol
                 poo-flow-json-schema-path-append
                 poo-flow-json-schema-schema-guided-array-values
                 poo-flow-json-schema-array-node-shape-valid?
                 poo-flow-json-schema-object-node-shape-valid?
                 poo-flow-json-schema-row-key-symbol
                 poo-flow-json-schema-row-key-string
                 poo-flow-json-schema-matching-pattern-properties)
        (only-in "./json-schema-valid.ss"
                 poo-flow-json-schema-node-valid?
                 poo-flow-json-schema-contract-artifact-value-valid?)
        (only-in :std/srfi/1
                 iota
                 map))

(export make-poo-flow-json-schema-validation-diagnostic
        poo-flow-json-schema-validation-diagnostic?
        poo-flow-json-schema-validation-diagnostic-severity
        poo-flow-json-schema-validation-diagnostic-reason
        poo-flow-json-schema-validation-diagnostic-message
        poo-flow-json-schema-validation-diagnostic-slot
        poo-flow-json-schema-validation-diagnostic-value
        poo-flow-json-schema-validation-diagnostic-contract
        poo-flow-json-schema-validation-diagnostic-metadata
        poo-flow-json-schema-validation-diagnostic->alist
        make-poo-flow-json-schema-object-contract-validation
        poo-flow-json-schema-object-contract-validation?
        poo-flow-json-schema-object-contract-validation-kind
        poo-flow-json-schema-object-contract-validation-schema
        poo-flow-json-schema-object-contract-validation-object-key
        poo-flow-json-schema-object-contract-validation-valid?
        poo-flow-json-schema-object-contract-validation-diagnostics
        poo-flow-json-schema-object-contract-validation-checked-slots
        poo-flow-json-schema-object-contract-validation-missing-required
        poo-flow-json-schema-object-contract-validation-invalid-slots
        poo-flow-json-schema-object-contract-validation-runtime-executed
        poo-flow-json-schema-object-contract-validation->alist
        poo-flow-json-schema-node-validate
        poo-flow-json-schema-node-valid?
        poo-flow-json-schema-contract-artifact-value-valid?
        poo-flow-json-schema-contract-artifact-validate
        poo-flow-json-schema-object-contract-validate)

;;; Boundary: diagnostic rows stay fixed internally and project to bounded
;;; alists for validation receipts.
;; : (-> Symbol Symbol String MaybeSymbol Value Alist Alist PooFlowJsonSchemaValidationDiagnostic)
(defstruct poo-flow-json-schema-validation-diagnostic
  (severity reason message slot value contract metadata)
  transparent: #t)

;; : (-> PooFlowJsonSchemaValidationDiagnostic Alist)
(def (poo-flow-json-schema-validation-diagnostic->alist diagnostic)
  (list
   (cons 'severity
         (poo-flow-json-schema-validation-diagnostic-severity diagnostic))
   (cons 'reason
         (poo-flow-json-schema-validation-diagnostic-reason diagnostic))
   (cons 'message
         (poo-flow-json-schema-validation-diagnostic-message diagnostic))
   (cons 'slot
         (poo-flow-json-schema-validation-diagnostic-slot diagnostic))
   (cons 'value
         (poo-flow-json-schema-validation-diagnostic-value diagnostic))
   (cons 'contract
         (poo-flow-json-schema-validation-diagnostic-contract diagnostic))
   (cons 'metadata
         (poo-flow-json-schema-validation-diagnostic-metadata diagnostic))))

;;; Boundary: validation receipts store typed diagnostics internally and
;;; project to bounded alists at the handoff boundary.
;; : (-> Symbol String Symbol Boolean [Diagnostic] [Symbol] [Symbol] [Symbol] Boolean PooFlowJsonSchemaObjectContractValidation)
(defstruct poo-flow-json-schema-object-contract-validation
  (kind
   schema
   object-key
   valid?
   diagnostics
   checked-slots
   missing-required
   invalid-slots
   runtime-executed)
  transparent: #t)

;; : (-> PooFlowSlotContract JsonSchemaCandidateObject PooFlowJsonSchemaValidationDiagnostic)
(def (poo-flow-json-schema-missing-required-diagnostic slot-contract candidate)
  (make-poo-flow-json-schema-validation-diagnostic
   'error
   'missing-required-slot
   "Required JSON Schema contract slot is missing"
   (poo-flow-slot-contract-slot slot-contract)
   candidate
   (poo-flow-slot-contract->alist slot-contract)
   '((owner . json-schema-validate))))

;; : (-> JsonSchemaValidationPath JsonSchemaCandidateSlotValue JsonSchemaContractAlist PooFlowJsonSchemaValidationDiagnostic)
(def (poo-flow-json-schema-missing-path-diagnostic path value contract)
  (make-poo-flow-json-schema-validation-diagnostic
   'error
   'missing-required-slot
   "Required JSON Schema contract path is missing"
   (poo-flow-json-schema-path->symbol path)
   value
   contract
   `((owner . json-schema-validate)
     (path . ,path))))

;; : (-> PooFlowSlotContract JsonSchemaCandidateSlotValue PooFlowJsonSchemaValidationDiagnostic)
(def (poo-flow-json-schema-invalid-slot-diagnostic slot-contract value)
  (make-poo-flow-json-schema-validation-diagnostic
   'error
   'invalid-slot-value
   "JSON Schema contract slot predicate rejected the value"
   (poo-flow-slot-contract-slot slot-contract)
   value
   (poo-flow-slot-contract->alist slot-contract)
   '((owner . json-schema-validate))))

;; : (-> Symbol String JsonSchemaValidationPath JsonSchemaCandidateSlotValue JsonSchemaContractAlist PooFlowJsonSchemaValidationDiagnostic)
(def (poo-flow-json-schema-invalid-path-diagnostic reason message path value
                                                   contract)
  (make-poo-flow-json-schema-validation-diagnostic
   'error
   reason
   message
   (poo-flow-json-schema-path->symbol path)
   value
   contract
   `((owner . json-schema-validate)
     (path . ,path))))

;; : (-> JsonSchemaCandidateObject PooFlowJsonSchemaValidationDiagnostic)
(def (poo-flow-json-schema-invalid-object-diagnostic candidate)
  (make-poo-flow-json-schema-validation-diagnostic
   'error
   'invalid-object-shape
   "JSON Schema object-contract validation requires a POO object or alist"
   #f
   candidate
   '()
   '((owner . json-schema-validate))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaCandidateSlotValue JsonSchemaValidationPath [Diagnostic])
(def (poo-flow-json-schema-node-validate node value path)
  (let (kind (poo-flow-json-schema-node-kind node))
    (cond
     ((and (eq? kind 'array)
           (not (poo-flow-json-schema-array-node-shape-valid? node value)))
      (list
       (poo-flow-json-schema-invalid-path-diagnostic
        'invalid-node-value
        "JSON Schema recursive array predicate rejected the value"
        path
        value
        (poo-flow-json-schema-node->alist node))))
     ((and (eq? kind 'object)
           (not (poo-flow-json-schema-object-node-shape-valid? node value)))
      (list
       (poo-flow-json-schema-invalid-path-diagnostic
        'invalid-node-value
        "JSON Schema recursive object predicate rejected the value"
        path
        value
        (poo-flow-json-schema-node->alist node))))
     ((and (eq? kind 'one-of)
           (= (length (poo-flow-json-schema-node-value node)) 1))
      (poo-flow-json-schema-node-validate
       (car (poo-flow-json-schema-node-value node))
       value
       path))
     ((and (not (eq? kind 'array))
           (not (eq? kind 'object))
           (not ((poo-flow-json-schema-node-predicate node) value)))
      (list
       (poo-flow-json-schema-invalid-path-diagnostic
        'invalid-node-value
        "JSON Schema recursive node predicate rejected the value"
        path
        value
        (poo-flow-json-schema-node->alist node))))
     (else
      (cond
       ((eq? kind 'object)
        (poo-flow-json-schema-object-node-validate node value path))
       ((eq? kind 'array)
        (poo-flow-json-schema-array-node-validate node value path))
       ((and (eq? kind 'nullable)
             (not (poo-flow-json-schema-null? value)))
        (poo-flow-json-schema-node-validate
         (poo-flow-json-schema-node-value node)
         value
         path))
       (else '()))))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaArrayCandidate JsonSchemaValidationPath [Diagnostic])
(def (poo-flow-json-schema-array-node-validate node value path)
  (let ((item-node (poo-flow-json-schema-node-value node))
        (items (poo-flow-json-schema-schema-guided-array-values value)))
    (poo-flow-contract-append-map
     (lambda (indexed-item)
       (poo-flow-json-schema-node-validate
        item-node
        (car indexed-item)
        (poo-flow-json-schema-path-append path (cdr indexed-item))))
     (map cons items (iota (length items))))))

;; : (-> PooFlowJsonSchemaProperty JsonSchemaCandidateObject JsonSchemaValidationPath [Diagnostic])
(def (poo-flow-json-schema-property-validate property candidate path)
  (let* ((slot
          (poo-flow-json-schema-property-name property))
         (value
          (poo-flow-json-schema-candidate-slot candidate slot))
         (slot-path
          (poo-flow-json-schema-path-append path slot)))
    (cond
     ((eq? value +poo-flow-json-schema-validation-missing+)
      (if (poo-flow-json-schema-property-required? property)
        (list
         (poo-flow-json-schema-missing-path-diagnostic
          slot-path
          candidate
          (poo-flow-json-schema-property->alist property)))
        '()))
     (else
      (poo-flow-json-schema-node-validate
       (poo-flow-json-schema-property-schema property)
       value
       slot-path)))))

;; : (-> PooFlowJsonSchemaPatternProperty JsonSchemaObjectRow JsonSchemaValidationPath [Diagnostic])
(def (poo-flow-json-schema-validation-row-value object-row)
  (let (tail (cdr object-row))
    (if (and (pair? tail)
             (null? (cdr tail))
             (not (poo-flow-contract-json-object? tail))
             (poo-flow-contract-json-object? (car tail)))
      (car tail)
      tail)))

(def (poo-flow-json-schema-pattern-row-validate pattern-property object-row path)
  (poo-flow-json-schema-node-validate
   (poo-flow-json-schema-pattern-property-schema pattern-property)
   (poo-flow-json-schema-validation-row-value object-row)
   (poo-flow-json-schema-path-append
    path
    (poo-flow-json-schema-row-key-symbol object-row))))

;; : (-> JsonSchemaMapValueSchema JsonSchemaObjectRow JsonSchemaValidationPath [Diagnostic])
(def (poo-flow-json-schema-additional-property-validate additional object-row
                                                        path)
  (let ((row-path
         (poo-flow-json-schema-path-append
          path
          (poo-flow-json-schema-row-key-symbol object-row))))
    (cond
     ((eq? additional 'unspecified) '())
     ((eq? additional #t) [])
     ((eq? additional #f)
      (list
       (poo-flow-json-schema-invalid-path-diagnostic
        'additional-property-not-allowed
        "JSON Schema additionalProperties rejected object key"
        row-path
        (poo-flow-json-schema-validation-row-value object-row)
        additional)))
     ((and (poo-flow-json-schema-node? additional)
           (eq? (poo-flow-json-schema-node-kind additional) 'never))
      (list
       (poo-flow-json-schema-invalid-path-diagnostic
        'additional-property-not-allowed
        "JSON Schema additionalProperties rejected the object key"
        row-path
     (poo-flow-json-schema-validation-row-value object-row)
        (poo-flow-json-schema-node->alist additional))))
     ((poo-flow-json-schema-node? additional)
    (poo-flow-json-schema-node-validate
     additional
     (poo-flow-json-schema-validation-row-value object-row)
     row-path))
     (else '()))))

;; : (-> PooFlowJsonSchemaObject JsonSchemaObjectRow [Symbol] JsonSchemaValidationPath [Diagnostic])
(def (poo-flow-json-schema-object-row-validate object object-row declared
                                               path)
  (let* ((row-key
          (poo-flow-json-schema-row-key-symbol object-row))
         (row-key-string
          (poo-flow-json-schema-row-key-string object-row))
         (pattern-matches
          (poo-flow-json-schema-matching-pattern-properties
           (poo-flow-json-schema-object-pattern-properties object)
           row-key-string))
         (pattern-diagnostics
          (poo-flow-contract-append-map
           (lambda (pattern-row)
             (poo-flow-json-schema-pattern-row-validate
              pattern-row
              object-row
              path))
           pattern-matches)))
    (append
     pattern-diagnostics
     (if (or (poo-flow-contract-member? row-key declared)
             (not (null? pattern-matches)))
       '()
       (poo-flow-json-schema-additional-property-validate
        (poo-flow-json-schema-object-additional-properties object)
        object-row
        path)))))

;; : (-> PooFlowJsonSchemaNode JsonSchemaCandidateObject JsonSchemaValidationPath [Diagnostic])
(def (poo-flow-json-schema-object-node-validate node candidate path)
  (let* ((object
          (poo-flow-json-schema-node-value node))
         (properties
          (poo-flow-json-schema-object-properties object))
         (declared
          (poo-flow-contract-project-list
           poo-flow-json-schema-property-name
           properties))
         (property-diagnostics
          (poo-flow-contract-append-map
           (lambda (property)
             (poo-flow-json-schema-property-validate
              property
              candidate
              path))
           properties))
         (map-diagnostics
          (poo-flow-contract-append-map
           (lambda (row)
             (poo-flow-json-schema-object-row-validate
              object
              row
              declared
              path))
           (poo-flow-json-schema-candidate-rows candidate))))
    (append property-diagnostics map-diagnostics)))

;; : (-> PooFlowSlotContract JsonSchemaCandidateObject MaybeDiagnostic)
(def (poo-flow-json-schema-validate-slot slot-contract candidate)
  (let (value
        (poo-flow-json-schema-candidate-slot
         candidate
         (poo-flow-slot-contract-slot slot-contract)))
    (cond
     ((eq? value +poo-flow-json-schema-validation-missing+)
      (and (poo-flow-slot-contract-required? slot-contract)
           (poo-flow-json-schema-missing-required-diagnostic
            slot-contract
            candidate)))
     (((poo-flow-slot-contract-predicate slot-contract) value)
      #f)
     (else
      (poo-flow-json-schema-invalid-slot-diagnostic
       slot-contract
       value)))))

;; : (-> [PooFlowJsonSchemaValidationDiagnostic] Symbol [Symbol])
(def (poo-flow-json-schema-validation-slots-by-reason diagnostics reason)
  (poo-flow-contract-filter-map
   (lambda (diagnostic)
     (and (eq? (poo-flow-json-schema-validation-diagnostic-reason diagnostic)
               reason)
          (poo-flow-json-schema-validation-diagnostic-slot diagnostic)))
   diagnostics))

;; : (-> PooFlowJsonSchemaValidationDiagnostic Boolean)
(def (poo-flow-json-schema-validation-fatal? diagnostic)
  (let (severity
        (poo-flow-json-schema-validation-diagnostic-severity diagnostic))
    (or (eq? severity 'error)
        (eq? severity 'fatal))))

;; : (-> [PooFlowJsonSchemaValidationDiagnostic] Boolean)
(def (poo-flow-json-schema-validation-diagnostics-valid? diagnostics)
  (not
   (poo-flow-contract-any?
    poo-flow-json-schema-validation-fatal?
    diagnostics)))

;; : (-> PooFlowJsonSchemaObjectContractValidation Alist)
(def (poo-flow-json-schema-object-contract-validation->alist validation)
  (list
   (cons 'kind
         (poo-flow-json-schema-object-contract-validation-kind validation))
   (cons 'schema
         (poo-flow-json-schema-object-contract-validation-schema validation))
   (cons 'object-key
         (poo-flow-json-schema-object-contract-validation-object-key validation))
   (cons 'valid?
         (poo-flow-json-schema-object-contract-validation-valid? validation))
   (cons 'diagnostics
         (poo-flow-contract-project-list
          poo-flow-json-schema-validation-diagnostic->alist
          (poo-flow-json-schema-object-contract-validation-diagnostics validation)))
   (cons 'diagnostic-count
         (length
          (poo-flow-json-schema-object-contract-validation-diagnostics
           validation)))
   (cons 'checked-slots
         (poo-flow-json-schema-object-contract-validation-checked-slots
          validation))
   (cons 'missing-required
         (poo-flow-json-schema-object-contract-validation-missing-required
          validation))
   (cons 'invalid-slots
         (poo-flow-json-schema-object-contract-validation-invalid-slots
          validation))
   (cons 'runtime-executed
         (poo-flow-json-schema-object-contract-validation-runtime-executed
          validation))))

;; : (-> PooFlowObjectTypeContract [Diagnostic] PooFlowJsonSchemaObjectContractValidation)
(def (poo-flow-json-schema-validation-receipt object-contract diagnostics)
  (let (slots (poo-flow-object-type-contract-slots object-contract))
    (make-poo-flow-json-schema-object-contract-validation
     'json-schema-object-contract-validation
     "poo-flow-json-schema-object-contract-validation/v1"
     (poo-flow-object-type-contract-key object-contract)
     (poo-flow-json-schema-validation-diagnostics-valid? diagnostics)
     diagnostics
     (poo-flow-contract-project-list
      poo-flow-slot-contract-slot
      slots)
     (poo-flow-json-schema-validation-slots-by-reason
      diagnostics
      'missing-required-slot)
     (append
      (poo-flow-json-schema-validation-slots-by-reason
       diagnostics
       'invalid-slot-value)
      (poo-flow-json-schema-validation-slots-by-reason
       diagnostics
       'invalid-node-value)
      (poo-flow-json-schema-validation-slots-by-reason
       diagnostics
       'additional-property-not-allowed))
     #f)))

;; : (-> PooFlowObjectTypeContract JsonSchemaCandidateObject PooFlowJsonSchemaObjectContractValidation)
(def (poo-flow-json-schema-object-contract-validate object-contract candidate)
  (let* ((slots
          (poo-flow-object-type-contract-slots object-contract))
         (shape-diagnostics
          (if (or (poo-flow-contract-json-object? candidate)
                  (object? candidate))
            '()
            (list
             (poo-flow-json-schema-invalid-object-diagnostic candidate))))
         (slot-diagnostics
          (if (null? shape-diagnostics)
            (poo-flow-contract-filter-map
             (lambda (slot-contract)
               (poo-flow-json-schema-validate-slot
                slot-contract
                candidate))
             slots)
            '()))
         (diagnostics
          (append shape-diagnostics slot-diagnostics)))
    (poo-flow-json-schema-validation-receipt object-contract diagnostics)))

;; : (-> PooFlowJsonSchemaContractArtifact JsonSchemaCandidateObject PooFlowJsonSchemaObjectContractValidation)
(def (poo-flow-json-schema-contract-artifact-validate artifact candidate)
  (let* ((object-contract
          (poo-flow-json-schema-contract-artifact-object-contract artifact))
         (root-node
         (poo-flow-json-schema-normalization-schema
          (poo-flow-json-schema-contract-artifact-normalization artifact)))
        (shape-diagnostics
          (if (or (poo-flow-contract-json-object? candidate)
                  (object? candidate))
            '()
            (list
             (poo-flow-json-schema-invalid-object-diagnostic candidate))))
         (diagnostics
          (if (null? shape-diagnostics)
            (if (poo-flow-json-schema-node-valid? root-node candidate)
              '()
              (poo-flow-json-schema-node-validate root-node candidate '()))
            shape-diagnostics)))
    (poo-flow-json-schema-validation-receipt
     object-contract
     diagnostics)))
