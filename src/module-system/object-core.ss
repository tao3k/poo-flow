;;; -*- Gerbil -*-
;;; Boundary: POO module object core contracts and object-aware wrappers.

(import :gerbil/gambit
        (only-in :clan/poo/object
                 .o
                 .ref
                 object?
                 make-object
                 $constant-slot-spec
                 $computed-slot-spec)
        (only-in :std/sugar foldl)
        :poo-flow/src/module-system/extension)

(export poo-flow-module-object-kind
        poo-flow-module-field-contract-kind
        poo-flow-module-field-contribution-kind
        poo-flow-module-transformer-contract-kind
        poo-flow-module-config-merge-result-kind
        poo-flow-module-objects-root-identity
        poo-flow-module-value-kind-accepts?
        poo-flow-module-field-contract
        poo-flow-module-field-contract?
        poo-flow-module-field-contract-identity
        poo-flow-module-field-contract-value-kind
        poo-flow-module-field-contract-merge
        poo-flow-module-field-contract-default
        poo-flow-module-field-contract-metadata
        poo-flow-module-field-contract-accepts?
        poo-flow-module-field-contract-with-merge
        poo-flow-module-field-contribution
        poo-flow-module-field-contribution?
        poo-flow-module-field-contribution-target
        poo-flow-module-field-contribution-field
        poo-flow-module-field-contribution-value
        poo-flow-module-field-contribution-merge
        poo-flow-module-field-contribution->extension
        poo-flow-module-field-contributions->extensions
        poo-flow-module-transformer-contract
        poo-flow-module-transformer-contract?
        poo-flow-module-transformer-contract-identity
        poo-flow-module-transformer-contract-merge
        poo-flow-module-transformer-contract-input-kind
        poo-flow-module-transformer-contract-argument-kind
        poo-flow-module-transformer-contract-output-kind
        poo-flow-module-transformer-contract-idempotent?
        poo-flow-module-transformer-contract-identity-key
        poo-flow-module-transformer-contract-metadata
        poo-flow-module-transformer-list-append-contract
        poo-flow-module-transformer-list-remove-contract
        poo-flow-module-transformer-map-set-contract
        poo-flow-module-transformer-contract-diagnostics
        poo-flow-module-transformer-contract-valid?
        poo-flow-module-transformer-field-contribution
        poo-flow-module-config-mk-merge
        poo-flow-module-config-merge-result?
        poo-flow-module-config-merge-result-extension-result
        poo-flow-module-config-merge-result-contributions
        poo-flow-module-config-merge-result-root
        poo-flow-module-config-merge-result-iterations
        poo-flow-module-config-merge-result-stable?
        poo-flow-module-object
        poo-flow-module-object?
        poo-flow-module-object-identity
        poo-flow-module-object-inherits
        poo-flow-module-object-fields
        poo-flow-module-object-metadata
        poo-flow-module-object-resolved-fields
        poo-flow-module-object-field
        poo-flow-module-object-default-slots
        poo-flow-module-object-node/default-slots
        poo-flow-module-object-node
        poo-flow-module-object-contributions
        poo-flow-module-objects-node
        poo-flow-module-objects-index
        poo-flow-module-objects-ref/index
        poo-flow-module-objects-ref
        poo-flow-module-objects-mk-merge/node
        poo-flow-module-objects-mk-merge)

;; : PooModuleObjectKindId
;; | PooModuleObjectKindId = String
(def poo-flow-module-object-kind "poo-flow.modules.object.v1")
;; : PooModuleFieldContractKindId
;; | PooModuleFieldContractKindId = String
(def poo-flow-module-field-contract-kind "poo-flow.modules.field-contract.v1")
;; : PooModuleFieldContributionKindId
;; | PooModuleFieldContributionKindId = String
(def poo-flow-module-field-contribution-kind "poo-flow.modules.field-contribution.v1")
;; : PooModuleTransformerContractKindId
;; | PooModuleTransformerContractKindId = String
(def poo-flow-module-transformer-contract-kind "poo-flow.modules.transformer-contract.v1")
;; : PooModuleConfigMergeResultKindId
;; | PooModuleConfigMergeResultKindId = String
(def poo-flow-module-config-merge-result-kind "poo-flow.modules.config-merge-result.v1")
;; : PooModuleObjectsRootIdentity
;; | PooModuleObjectsRootIdentity = Symbol
(def poo-flow-module-objects-root-identity 'objects)

;; : (-> PooModuleValueCandidate PooModuleKindId Boolean)
(def (poo-flow-module-object-kind? value kind)
  (and (object? value) (equal? (.ref value 'kind) kind)))

;; | PooModuleAlistCandidate = (U Null Pair)
;; : (-> PooModuleAlistCandidate Boolean)
(def (poo-flow-module-alist? value)
  (cond ((null? value) #t)
        ((and (pair? value) (pair? (car value)))
         (poo-flow-module-alist? (cdr value)))
        (else #f)))

;; : (-> PooModuleKindId PooModuleFieldValueCandidate Boolean)
(def (poo-flow-module-value-kind-accepts? value-kind value)
  (cond ((eq? value-kind 'Any) #t)
        ((eq? value-kind 'List) (list? value))
        ((eq? value-kind 'Map) (poo-flow-module-alist? value))
        ((eq? value-kind 'Alist) (poo-flow-module-alist? value))
        ((eq? value-kind 'Symbol) (symbol? value))
        ((eq? value-kind 'String) (string? value))
        ((eq? value-kind 'Boolean) (boolean? value))
        ((eq? value-kind 'Object) (object? value))
        ((eq? value-kind 'Node) (poo-flow-module-extension-node? value))
        (else #t)))

;;; Field contracts translate object-level C3 inheritance into merge operations
;;; without hardcoding backend-specific fields in the module system.
;; : (-> Symbol Symbol Symbol PooModuleFieldDefault PooModuleFieldMetadata PooModuleFieldContract)
(def (poo-flow-module-field-contract identity value-kind merge default metadata)
  (let ((identity-value identity)
        (value-kind-value value-kind)
        (merge-value merge)
        (default-value default)
        (metadata-value metadata))
    (.o kind: poo-flow-module-field-contract-kind
        identity: identity-value
        value-kind: value-kind-value
        merge: merge-value
        default: default-value
        metadata: metadata-value)))

;; : (-> PooModuleFieldContractCandidate Boolean)
(def (poo-flow-module-field-contract? value)
  (poo-flow-module-object-kind? value poo-flow-module-field-contract-kind))

;; : (-> PooModuleFieldContract Symbol)
(def (poo-flow-module-field-contract-identity field) (.ref field 'identity))
;; : (-> PooModuleFieldContract Symbol)
(def (poo-flow-module-field-contract-value-kind field) (.ref field 'value-kind))
;; : (-> PooModuleFieldContract Symbol)
(def (poo-flow-module-field-contract-merge field) (.ref field 'merge))
;; : (-> PooModuleFieldContract PooModuleFieldDefault)
(def (poo-flow-module-field-contract-default field) (.ref field 'default))
;; : (-> PooModuleFieldContract PooModuleFieldMetadata)
(def (poo-flow-module-field-contract-metadata field) (.ref field 'metadata))

;;; Value-kind checks are intentionally shallow; object-specific transformer
;;; contracts can refine this before an extension operation is projected.
;; : (-> PooModuleFieldContract PooModuleFieldValueCandidate Boolean)
(def (poo-flow-module-field-contract-accepts? field value)
  (poo-flow-module-value-kind-accepts?
   (poo-flow-module-field-contract-value-kind field)
   value))

;; : (-> PooModuleFieldContract Symbol PooModuleFieldContract)
(def (poo-flow-module-field-contract-with-merge field merge)
  (poo-flow-module-field-contract
   (poo-flow-module-field-contract-identity field)
   (poo-flow-module-field-contract-value-kind field)
   merge
   (poo-flow-module-field-contract-default field)
   (poo-flow-module-field-contract-metadata field)))

;;; Field contributions are object-aware extension requests: the field decides
;;; merge behavior while the contribution carries target and value.
;; : (-> Symbol PooModuleFieldContract PooModuleFieldValue PooModuleFieldContribution)
(def (poo-flow-module-field-contribution target field value)
  (let* ((target-value target)
         (field-value field)
         (value-value value)
         (field-contract? (poo-flow-module-field-contract? field-value))
         (field-identity-value
          (if field-contract?
            (poo-flow-module-field-contract-identity field-value)
            field-value))
         (field-merge-value
          (if field-contract?
            (poo-flow-module-field-contract-merge field-value)
            'override))
         (field-value-kind-value
          (if field-contract?
            (poo-flow-module-field-contract-value-kind field-value)
            'Any)))
    (vector poo-flow-module-field-contribution-kind
            target-value
            field-value
            value-value
            field-identity-value
            field-merge-value
            field-value-kind-value
            field-contract?)))

;; : (-> PooModuleFieldContributionCandidate Boolean)
(def (poo-flow-module-field-contribution-vector? value)
  (and (vector? value)
       (= (vector-length value) 8)
       (equal? (vector-ref value 0)
               poo-flow-module-field-contribution-kind)))

;; : (-> PooModuleFieldContributionCandidate Boolean)
(def (poo-flow-module-field-contribution? value)
  (or (poo-flow-module-field-contribution-vector? value)
      (poo-flow-module-object-kind? value poo-flow-module-field-contribution-kind)))

;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-target contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 1)
    (.ref contribution 'target)))
;; : (-> PooModuleFieldContribution PooModuleFieldContract)
(def (poo-flow-module-field-contribution-field contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 2)
    (.ref contribution 'field)))
;; : (-> PooModuleFieldContribution PooModuleFieldValue)
(def (poo-flow-module-field-contribution-value contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 3)
    (.ref contribution 'value)))
;; : (-> PooModuleFieldContribution Boolean)
(def (poo-flow-module-field-contribution-field-contract? contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 7)
    (.ref contribution 'field-contract-p)))
;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-field-value-kind contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 6)
    (.ref contribution 'field-value-kind)))

;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-field-identity contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 4)
    (.ref contribution 'field-identity)))

;; : (-> PooModuleFieldContribution Symbol)
(def (poo-flow-module-field-contribution-merge contribution)
  (if (poo-flow-module-field-contribution-vector? contribution)
    (vector-ref contribution 5)
    (.ref contribution 'field-merge)))

;; : (-> PooModuleFieldContribution Boolean)
(def (poo-flow-module-field-contribution-valid? contribution)
  (or (not (poo-flow-module-field-contribution-field-contract? contribution))
      (poo-flow-module-value-kind-accepts?
       (poo-flow-module-field-contribution-field-value-kind contribution)
       (poo-flow-module-field-contribution-value contribution))))

;;; Contribution conversion is the only place field merge names become graph
;;; operations, keeping custom objects independent from merge internals.
;; : (-> PooModuleFieldContribution PooModuleExtensionOperation)
(def (poo-flow-module-field-contribution-operation contribution)
  (let* ((field-identity
          (poo-flow-module-field-contribution-field-identity contribution))
         (value
          (poo-flow-module-field-contribution-value contribution))
         (merge
          (poo-flow-module-field-contribution-merge contribution)))
    (cond
     ((eq? merge 'override)
      (poo-flow-module-extension-slot-override field-identity value))
     ((eq? merge 'append)
      (poo-flow-module-extension-slot-append field-identity value))
     ((eq? merge 'prepend)
      (poo-flow-module-extension-slot-prepend field-identity value))
     ((eq? merge 'remove)
      (poo-flow-module-extension-slot-remove field-identity value))
     ((eq? merge 'node-extend)
      (poo-flow-module-extension-node-extend value))
     ((eq? merge 'node-remove)
      (poo-flow-module-extension-node-remove value))
     (else
      (poo-flow-module-extension-slot-override field-identity value)))))

;; : (-> PooModuleFieldContribution PooModuleExtensionContribution)
(def (poo-flow-module-field-contribution->extension contribution)
  (let* ((target
          (poo-flow-module-field-contribution-target contribution))
         (value
          (poo-flow-module-field-contribution-value contribution))
         (field-contract?
          (poo-flow-module-field-contribution-field-contract? contribution))
         (valid?
          (or (not field-contract?)
              (poo-flow-module-value-kind-accepts?
               (poo-flow-module-field-contribution-field-value-kind
                contribution)
               value)))
         (field-identity
          (poo-flow-module-field-contribution-field-identity contribution))
         (merge
          (poo-flow-module-field-contribution-merge contribution))
         (operation
          (cond
           ((eq? merge 'override)
            (poo-flow-module-extension-slot-override field-identity value))
           ((eq? merge 'append)
            (poo-flow-module-extension-slot-append field-identity value))
           ((eq? merge 'prepend)
            (poo-flow-module-extension-slot-prepend field-identity value))
           ((eq? merge 'remove)
            (poo-flow-module-extension-slot-remove field-identity value))
           ((eq? merge 'node-extend)
            (poo-flow-module-extension-node-extend value))
           ((eq? merge 'node-remove)
            (poo-flow-module-extension-node-remove value))
           (else
            (poo-flow-module-extension-slot-override field-identity value)))))
    (if valid?
      (poo-flow-module-extension-contribution target (list operation))
      (error "poo-flow module field contribution violates its POO contract"
             contribution))))

;;; Field contribution projection is a map because validation happens at each
;;; contribution boundary before the generic extension graph sees operations.
;; : (-> [PooModuleFieldContribution] [PooModuleExtensionContribution])
(def (poo-flow-module-field-contributions->extensions contributions)
  (map poo-flow-module-field-contribution->extension contributions))

;;; Transformer contracts are object-owned wrappers around standard
;;; list/map-shaped operations. They validate user or agent repair payloads
;;; before those payloads become ordinary field contributions.
;; : (-> Symbol Symbol Symbol Symbol Symbol Boolean MaybeSymbol Alist PooModuleTransformerContract)
(def (poo-flow-module-transformer-contract identity
                                           merge
                                           input-kind
                                           argument-kind
                                           output-kind
                                           idempotent?
                                           identity-key
                                           metadata)
  (let ((identity-value identity)
        (merge-value merge)
        (input-kind-value input-kind)
        (argument-kind-value argument-kind)
        (output-kind-value output-kind)
        (idempotent-value idempotent?)
        (identity-key-value identity-key)
        (metadata-value metadata))
    (.o kind: poo-flow-module-transformer-contract-kind
        identity: identity-value
        merge: merge-value
        input-kind: input-kind-value
        argument-kind: argument-kind-value
        output-kind: output-kind-value
        idempotent?: idempotent-value
        identity-key: identity-key-value
        metadata: metadata-value)))

;; : (-> PooModuleTransformerContractCandidate Boolean)
(def (poo-flow-module-transformer-contract? value)
  (poo-flow-module-object-kind? value poo-flow-module-transformer-contract-kind))

;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-identity transformer)
  (.ref transformer 'identity))
;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-merge transformer)
  (.ref transformer 'merge))
;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-input-kind transformer)
  (.ref transformer 'input-kind))
;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-argument-kind transformer)
  (.ref transformer 'argument-kind))
;; : (-> PooModuleTransformerContract Symbol)
(def (poo-flow-module-transformer-contract-output-kind transformer)
  (.ref transformer 'output-kind))
;; : (-> PooModuleTransformerContract Boolean)
(def (poo-flow-module-transformer-contract-idempotent? transformer)
  (.ref transformer 'idempotent?))
;; : (-> PooModuleTransformerContract MaybeSymbol)
(def (poo-flow-module-transformer-contract-identity-key transformer)
  (.ref transformer 'identity-key))
;; : (-> PooModuleTransformerContract Alist)
(def (poo-flow-module-transformer-contract-metadata transformer)
  (.ref transformer 'metadata))

;; : PooModuleTransformerContract
(def poo-flow-module-transformer-list-append-contract
  (poo-flow-module-transformer-contract
   'list.append
   'append
   'List
   'List
   'List
   #t
   #f
   '((scope . object-core) (standard-library-shape . list.append))))

;; : PooModuleTransformerContract
(def poo-flow-module-transformer-list-remove-contract
  (poo-flow-module-transformer-contract
   'list.remove
   'remove
   'List
   'List
   'List
   #t
   #f
   '((scope . object-core) (standard-library-shape . list.remove))))

;; : PooModuleTransformerContract
(def poo-flow-module-transformer-map-set-contract
  (poo-flow-module-transformer-contract
   'map.set
   'override
   'Map
   'Map
   'Map
   #t
   #f
   '((scope . object-core) (standard-library-shape . map.set))))

;; : (-> Symbol Symbol Boolean)
(def (poo-flow-module-transformer-kind-compatible? expected actual)
  (or (eq? expected 'Any)
      (eq? actual 'Any)
      (eq? expected actual)
      (and (eq? expected 'Map) (eq? actual 'Alist))
      (and (eq? expected 'Alist) (eq? actual 'Map))))

;; : (-> Symbol PooModuleTransformerContract String)
(def (poo-flow-module-transformer-diagnostic code transformer)
  (string-append
   "transformer:"
   (symbol->string (poo-flow-module-transformer-contract-identity transformer))
   ":"
   (symbol->string code)))

;; : (-> PooModuleTransformerContract PooModuleFieldContract PooModuleFieldValue [String])
(def (poo-flow-module-transformer-contract-diagnostics transformer field value)
  (append
   (if (poo-flow-module-transformer-kind-compatible?
        (poo-flow-module-transformer-contract-input-kind transformer)
        (poo-flow-module-field-contract-value-kind field))
     '()
     (list (poo-flow-module-transformer-diagnostic
            'field-kind-mismatch
            transformer)))
   (if (poo-flow-module-value-kind-accepts?
        (poo-flow-module-transformer-contract-argument-kind transformer)
        value)
     '()
     (list (poo-flow-module-transformer-diagnostic
            'argument-kind-mismatch
            transformer)))))

;; : (-> PooModuleTransformerContract PooModuleFieldContract PooModuleFieldValue Boolean)
(def (poo-flow-module-transformer-contract-valid? transformer field value)
  (null? (poo-flow-module-transformer-contract-diagnostics
          transformer
          field
          value)))

;; : (-> Symbol PooModuleFieldContract PooModuleTransformerContract PooModuleFieldValue PooModuleFieldContribution)
(def (poo-flow-module-transformer-field-contribution target field transformer value)
  (if (poo-flow-module-transformer-contract-valid? transformer field value)
    (poo-flow-module-field-contribution
     target
     (poo-flow-module-field-contract-with-merge
      field
      (poo-flow-module-transformer-contract-merge transformer))
     value)
    (error "poo-flow module transformer violates its POO contract"
           (poo-flow-module-transformer-contract-diagnostics
            transformer
            field
            value))))

;;; Config merge results preserve the original contributions so diagnostics can
;;; explain both the final graph and the inputs that produced it.
;; : (-> PooModuleExtensionResult [PooModuleFieldContribution] PooModuleConfigMergeResult)
(def (poo-flow-module-config-merge-result extension-result contributions)
  (let ((extension-result-value extension-result)
        (contributions-value contributions))
    (.o kind: poo-flow-module-config-merge-result-kind
        extension-result: extension-result-value
        contributions: contributions-value)))

;; : (-> PooModuleConfigMergeResultCandidate Boolean)
(def (poo-flow-module-config-merge-result? value)
  (poo-flow-module-object-kind? value poo-flow-module-config-merge-result-kind))

;; : (-> PooModuleConfigMergeResult PooModuleExtensionResult)
(def (poo-flow-module-config-merge-result-extension-result result)
  (.ref result 'extension-result))
;; : (-> PooModuleConfigMergeResult [PooModuleFieldContribution])
(def (poo-flow-module-config-merge-result-contributions result)
  (.ref result 'contributions))
;; : (-> PooModuleConfigMergeResult PooModuleExtensionNode)
(def (poo-flow-module-config-merge-result-root result)
  (poo-flow-module-extension-result-root
   (poo-flow-module-config-merge-result-extension-result result)))
;; : (-> PooModuleConfigMergeResult Integer)
(def (poo-flow-module-config-merge-result-iterations result)
  (poo-flow-module-extension-result-iterations
   (poo-flow-module-config-merge-result-extension-result result)))
;; : (-> PooModuleConfigMergeResult Boolean)
(def (poo-flow-module-config-merge-result-stable? result)
  (poo-flow-module-extension-result-stable?
   (poo-flow-module-config-merge-result-extension-result result)))

;; : (-> PooModuleSlotValue [PooModuleSlotValue] Boolean)
(def (poo-flow-module-config-member? value values)
  (and (member value values) #t))

;; : (-> [PooModuleSlotValue] HashTable)
(def (poo-flow-module-config-value-index values)
  (let (index (make-hash-table))
    (for-each
     (lambda (value)
       (hash-put! index value #t))
     values)
    index))

;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-config-append-distinct base extra)
  (if (null? extra)
    base
    (poo-flow-module-config-append-distinct/indexed
     base
     extra
     (poo-flow-module-config-value-index base))))

;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] HashTable [PooModuleSlotValue])
(def (poo-flow-module-config-append-distinct/indexed base extra seen)
  (let (added
        (foldl (lambda (value result)
                 (if (hash-get seen value)
                   result
                   (begin
                     (hash-put! seen value #t)
                     (cons value result))))
               '()
               extra))
    (if (null? added)
      base
      (append base (reverse added)))))

;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-config-remove-elements values removed)
  (if (null? removed)
    values
    (let (removed-index (poo-flow-module-config-value-index removed))
      (reverse
       (foldl (lambda (value kept)
                (if (hash-get removed-index value)
                  kept
                  (cons value kept)))
              '()
              values)))))

;; : (-> PooModuleSlotValue [PooModuleSlotValue])
(def (poo-flow-module-config-list-value value)
  (cond ((null? value) '())
        ((list? value) value)
        (else (list value))))

;; : (-> Symbol Boolean)
(def (poo-flow-module-config-slot-merge-action? merge)
  (or (eq? merge 'override)
      (eq? merge 'append)
      (eq? merge 'prepend)
      (eq? merge 'remove)))

;; : (-> Symbol PooModuleSlotValue PooModuleSlotValue PooModuleSlotValue)
(def (poo-flow-module-config-merged-slot-value merge current value)
  (cond
   ((eq? merge 'override) value)
   ((eq? merge 'append)
    (poo-flow-module-config-append-distinct
     (poo-flow-module-config-list-value current)
     (poo-flow-module-config-list-value value)))
   ((eq? merge 'prepend)
    (poo-flow-module-config-append-distinct
     (poo-flow-module-config-list-value value)
     (poo-flow-module-config-list-value current)))
   ((eq? merge 'remove)
    (poo-flow-module-config-remove-elements
     (poo-flow-module-config-list-value current)
     (poo-flow-module-config-list-value value)))
   (else current)))

;; poo-flow-module-config-fast-slot-merge/in-order
;;   : (-> Symbol PooModuleSlotMap [PooModuleFieldContribution] MaybePooModuleSlotMap)
;;   | doc m%
;;       `poo-flow-module-config-fast-slot-merge/in-order` applies field
;;       contributions while preserving slot order and allocating only when a
;;       value actually changes.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-config-fast-slot-merge/in-order node slots fields)
;;       ;; => maybe-updated-slots
;;       ```
;;     %
(def (poo-flow-module-config-fast-slot-merge/in-order node-identity slots contributions)
  (let ((head '())
        (tail #f)
        (seen (make-hash-table)))
    (def (append-entry! entry)
      (let (cell (cons entry '()))
        (if tail
          (begin
            (set-cdr! tail cell)
            (set! tail cell))
          (begin
            (set! head cell)
            (set! tail cell)))))
    (def (copy-prefix! stop)
      (let copy ((remaining slots))
        (when (not (eq? remaining stop))
          (append-entry! (car remaining))
          (copy (cdr remaining)))))
    (let loop ((remaining-slots slots)
               (remaining-contributions contributions)
               (changed? #f))
      (cond
       ((null? remaining-slots)
        (if (null? remaining-contributions)
          (if changed?
            head
            slots)
          #f))
       ((null? remaining-contributions) #f)
       (else
        (let ((entry (car remaining-slots))
              (contribution (car remaining-contributions)))
          (if (not (poo-flow-module-field-contribution-vector? contribution))
            #f
            (let* ((target (vector-ref contribution 1))
                   (value (vector-ref contribution 3))
                   (key (vector-ref contribution 4))
                   (slot-key (car entry))
                   (merge (vector-ref contribution 5))
                   (value-kind (vector-ref contribution 6))
                   (field-contract? (vector-ref contribution 7))
                   (valid?
                    (or (not field-contract?)
                        (poo-flow-module-value-kind-accepts?
                         value-kind
                         value))))
              (if (and (equal? target node-identity)
                       valid?
                       (poo-flow-module-config-slot-merge-action? merge)
                       (equal? key slot-key))
                (if (hash-get seen slot-key)
                  #f
                  (begin
                    (hash-put! seen slot-key #t)
                    (let* ((current (cdr entry))
                           (next-value
                            (poo-flow-module-config-merged-slot-value
                             merge
                             current
                             value))
                           (value-changed?
                            (not (or (eq? next-value current)
                                     (equal? next-value current)))))
                      (when (and value-changed? (not changed?))
                        (copy-prefix! remaining-slots))
                      (when (or changed? value-changed?)
                        (append-entry! (if value-changed?
                                         (cons key next-value)
                                         entry)))
                      (loop (cdr remaining-slots)
                            (cdr remaining-contributions)
                            (or changed? value-changed?)))))
                #f)))))))))

;; : (-> HashTable Symbol Value)
(def (poo-flow-module-config-slot-key-hash-ref table key)
  (hash-get table key))

;; poo-flow-module-config-fast-slot-merge/sparse
;;   : (-> Symbol PooModuleSlotMap [PooModuleFieldContribution] MaybePooModuleSlotMap)
;;   | doc m%
;;       `poo-flow-module-config-fast-slot-merge/sparse` handles sparse or
;;       repeated slot updates with hash-indexed state while keeping append and
;;       remove semantics equivalent to the ordered merge path.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-config-fast-slot-merge/sparse node slots fields)
;;       ;; => maybe-updated-slots
;;       ```
;;     %
(def (poo-flow-module-config-fast-slot-merge/sparse node-identity slots contributions)
  (let ((seen (make-hash-table))
        (updated (make-hash-table))
        (updates (make-hash-table))
        (value-indexes (make-hash-table))
        (append-active (make-hash-table))
        (append-bases (make-hash-table))
        (append-additions (make-hash-table)))
    (def (slot-value-index key current)
      (let (index (poo-flow-module-config-slot-key-hash-ref value-indexes key))
        (if index
          index
          (let (next-index
                (poo-flow-module-config-value-index
                 (poo-flow-module-config-list-value current)))
            (hash-put! value-indexes key next-index)
            next-index))))
    (def (record-slot-value-index! key value)
      (hash-put! value-indexes
                 key
                 (poo-flow-module-config-value-index
                  (poo-flow-module-config-list-value value))))
    (def (materialize-append-state key)
      (let ((base (poo-flow-module-config-slot-key-hash-ref
                   append-bases
                   key))
            (additions (poo-flow-module-config-slot-key-hash-ref
                        append-additions
                        key)))
        (if (null? additions)
          base
          (append base (reverse additions)))))
    (def (flush-append-state! key)
      (if (poo-flow-module-config-slot-key-hash-ref append-active key)
        (let (value (materialize-append-state key))
          (hash-put! updates key value)
          (hash-put! append-active key #f)
          (record-slot-value-index! key value)
          value)
        (poo-flow-module-config-slot-key-hash-ref updates key)))
    (def (resolved-slot-update key)
      (if (poo-flow-module-config-slot-key-hash-ref append-active key)
        (flush-append-state! key)
        (poo-flow-module-config-slot-key-hash-ref updates key)))
    (def (append-slot-value! key current value)
      (let ((current-list (poo-flow-module-config-list-value current))
            (extra (poo-flow-module-config-list-value value))
            (active? (poo-flow-module-config-slot-key-hash-ref
                      append-active
                      key)))
        (when (not active?)
          (hash-put! append-active key #t)
          (hash-put! append-bases key current-list)
          (hash-put! append-additions key '())
          (hash-put! updates key current-list))
        (let (seen-values (slot-value-index key current-list))
          (let loop ((remaining extra)
                     (additions
                      (poo-flow-module-config-slot-key-hash-ref
                       append-additions
                       key))
                     (changed? #f))
            (cond
             ((null? remaining)
              (hash-put! append-additions key additions)
              changed?)
             ((hash-get seen-values (car remaining))
              (loop (cdr remaining) additions changed?))
             (else
              (hash-put! seen-values (car remaining) #t)
              (loop (cdr remaining)
                    (cons (car remaining) additions)
                    #t)))))))
    (let init ((remaining slots))
      (cond
       ((null? remaining)
        (let apply-contributions ((rest contributions)
                                  (new-order '())
                                  (changed? #f))
          (if (null? rest)
            (if (and (not changed?) (null? new-order))
              slots
              (append
               (map (lambda (entry)
                      (let (key (car entry))
                        (if (poo-flow-module-config-slot-key-hash-ref
                             updated
                             key)
                          (cons key (resolved-slot-update key))
                          entry)))
                    slots)
               (map (lambda (key)
                      (cons key (resolved-slot-update key)))
                    (reverse new-order))))
            (let* ((contribution (car rest))
                   (vector-contribution?
                    (poo-flow-module-field-contribution-vector? contribution))
                   (target
                    (if vector-contribution?
                      (vector-ref contribution 1)
                      (poo-flow-module-field-contribution-target
                       contribution)))
                   (value
                    (if vector-contribution?
                      (vector-ref contribution 3)
                      (poo-flow-module-field-contribution-value
                       contribution)))
                   (field-contract?
                    (if vector-contribution?
                      (vector-ref contribution 7)
                      (poo-flow-module-field-contribution-field-contract?
                       contribution)))
                   (valid?
                    (or (not field-contract?)
                        (poo-flow-module-value-kind-accepts?
                         (if vector-contribution?
                           (vector-ref contribution 6)
                           (poo-flow-module-field-contribution-field-value-kind
                            contribution))
                         value)))
                   (key
                    (if vector-contribution?
                      (vector-ref contribution 4)
                      (poo-flow-module-field-contribution-field-identity
                       contribution)))
                   (merge
                    (if vector-contribution?
                      (vector-ref contribution 5)
                      (poo-flow-module-field-contribution-merge
                       contribution))))
              (if (and (equal? target node-identity)
                       valid?
                       (poo-flow-module-config-slot-merge-action? merge))
                (let* ((entry (poo-flow-module-config-slot-key-hash-ref
                               seen
                               key))
                       (known? (and entry #t))
                       (next-new-order
                        (if known?
                          new-order
                          (begin
                            (hash-put! seen key (cons key #f))
                            (cons key new-order))))
                       (current
                        (cond
                         ((poo-flow-module-config-slot-key-hash-ref
                           updated
                           key)
                          (if (and (not (eq? merge 'append))
                                   (poo-flow-module-config-slot-key-hash-ref
                                    append-active
                                    key))
                            (flush-append-state! key)
                            (poo-flow-module-config-slot-key-hash-ref
                             updates
                             key)))
                         (known? (cdr entry))
                         (else '())))
                       (append-merge? (eq? merge 'append)))
                  (if append-merge?
                    (let* ((value-changed?
                            (append-slot-value! key current value))
                           (next-changed?
                            (or changed?
                                (not known?)
                                value-changed?)))
                      (when (or (not known?) value-changed?)
                        (hash-put! updated key #t))
                      (apply-contributions (cdr rest)
                                           next-new-order
                                           next-changed?))
                    (let* ((next-value
                            (poo-flow-module-config-merged-slot-value
                             merge
                             current
                             value))
                           (value-changed?
                            (not (or (eq? next-value current)
                                     (equal? next-value current))))
                           (next-changed?
                            (or changed?
                                (not known?)
                                value-changed?)))
                      (when (or (not known?) value-changed?)
                        (hash-put! updated key #t)
                        (hash-put! updates key next-value)
                        (record-slot-value-index! key next-value))
                      (apply-contributions (cdr rest)
                                           next-new-order
                                           next-changed?))))
                #f)))))
       ((hash-get seen (caar remaining)) #f)
       (else
       (hash-put! seen (caar remaining) (car remaining))
       (init (cdr remaining)))))))

;; : (-> PooModuleSlotMap [PooModuleFieldContribution] MaybePooModuleSlotMap)
(def (poo-flow-module-config-fast-slot-merge node-identity slots contributions)
  (or (poo-flow-module-config-fast-slot-merge/in-order
       node-identity
       slots
       contributions)
      (poo-flow-module-config-fast-slot-merge/sparse
       node-identity
       slots
       contributions)))

;; : (-> PooModuleExtensionNode [PooModuleFieldContribution] MaybePooModuleExtensionResult)
(def (poo-flow-module-config-fast-extension-result base contributions)
  (let ((children (poo-flow-module-extension-node-children base))
        (node-identity (poo-flow-module-extension-node-identity base))
        (slots (poo-flow-module-extension-node-slots base)))
    (if (null? children)
      (let (merged-slots
            (poo-flow-module-config-fast-slot-merge
             node-identity
             slots
             contributions))
        (if merged-slots
          (poo-flow-module-extension-result
           (poo-flow-module-extension-node node-identity merged-slots '())
           (if (equal? merged-slots slots) 0 1)
           #t)
          #f))
      #f)))

;; : (-> PooModuleExtensionNode [PooModuleFieldContribution] PooModuleConfigMergeResult)
(def (poo-flow-module-config-mk-merge base contributions)
  (poo-flow-module-config-merge-result
   (or (poo-flow-module-config-fast-extension-result base contributions)
       (poo-flow-module-extension-fixed-point
        base
        (poo-flow-module-field-contributions->extensions contributions)))
   contributions))

;;; Module objects are POO-side schemas. They can inherit fields, but they do
;;; not instantiate modules or evaluate user config.
;; : (-> Symbol [PooModuleObject] [PooModuleFieldContract] PooModuleObjectMetadata PooModuleObject)
(def (poo-flow-module-object identity inherits fields metadata)
  (let ((identity-value identity)
        (inherits-value inherits)
        (fields-value fields)
        (metadata-value metadata))
    (make-object
     supers: inherits-value
     defaults: '((fields . ()))
     slots: (list
             (poo-flow-module-object-constant-slot
              'kind
              poo-flow-module-object-kind)
             (poo-flow-module-object-constant-slot
              'identity
              identity-value)
             (poo-flow-module-object-constant-slot
              'inherits
              inherits-value)
             (poo-flow-module-object-constant-slot
              'direct-fields
              fields-value)
             (poo-flow-module-object-fields-slot fields-value)
             (poo-flow-module-object-constant-slot
              'metadata
              metadata-value)))))

;; : (-> PooModuleObjectCandidate Boolean)
(def (poo-flow-module-object? value)
  (poo-flow-module-object-kind? value poo-flow-module-object-kind))

;; : (-> PooModuleObject Symbol)
(def (poo-flow-module-object-identity object) (.ref object 'identity))
;; : (-> PooModuleObject [PooModuleObject])
(def (poo-flow-module-object-inherits object) (.ref object 'inherits))
;; : (-> PooModuleObject [PooModuleFieldContract])
(def (poo-flow-module-object-fields object) (.ref object 'direct-fields))
;; : (-> PooModuleObject PooModuleObjectMetadata)
(def (poo-flow-module-object-metadata object) (.ref object 'metadata))

;; : (-> Symbol Value PooModuleObjectSlotSpec)
(def (poo-flow-module-object-constant-slot key value)
  (cons key ($constant-slot-spec value)))

;;; Field slots are computed from the superclass chain, letting child objects
;;; override or add fields without duplicating inherited object metadata.
;; : (-> [PooModuleFieldContract] PooModuleObjectSlotSpec)
(def (poo-flow-module-object-fields-slot fields)
  (cons 'fields
        ($computed-slot-spec
         (lambda (_self superfun)
           (poo-flow-module-object-fields-merge (superfun) fields)))))

;; : (-> (U PooModuleFieldContract Symbol) Symbol)
(def (poo-flow-module-object-field-identity field)
  (if (poo-flow-module-field-contract? field)
    (poo-flow-module-field-contract-identity field)
    field))

;; : (-> [PooModuleFieldContract] HashTable)
(def (poo-flow-module-object-field-index fields)
  (let (index (make-hash-table))
    (for-each
     (lambda (field)
       (let (identity (poo-flow-module-object-field-identity field))
         (if (poo-flow-module-object-identity-hash-ref index identity)
           index
           (hash-put! index identity field))))
     fields)
    index))

;; : (-> HashTable Symbol Value)
(def (poo-flow-module-object-identity-hash-ref table identity)
  (hash-get table identity))

;; : (-> [PooModuleFieldContract] PooModuleFieldContract [PooModuleFieldContract])
(def (poo-flow-module-object-field-set fields field)
  (let (field-identity (poo-flow-module-object-field-identity field))
    (cond ((null? fields) (list field))
          ((equal? (poo-flow-module-object-field-identity (car fields))
                   field-identity)
           (cons field (cdr fields)))
          (else
           (cons (car fields)
                 (poo-flow-module-object-field-set (cdr fields) field))))))

;; poo-flow-module-object-fields-merge
;;   : (-> [PooModuleFieldContract] [PooModuleFieldContract] [PooModuleFieldContract])
;;   | doc m%
;;       `poo-flow-module-object-fields-merge` folds extra contracts through
;;       field identity replacement so inheritance and explicit field override
;;       use the same ordering rule.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-object-fields-merge base-fields extra-fields)
;;       ;; => merged-fields
;;       ```
;;     %
(def (poo-flow-module-object-fields-merge base extra)
  (let ((base-seen (make-hash-table))
        (override-seen (make-hash-table))
        (overrides (make-hash-table))
        (new-seen (make-hash-table))
        (replacement-used (make-hash-table)))
    (for-each
     (lambda (field)
       (hash-put! base-seen
                  (poo-flow-module-object-field-identity field)
                  #t))
     base)
    (let loop ((fields extra) (new-identities '()))
      (if (null? fields)
        (append
         (map (lambda (field)
                (let (identity
                      (poo-flow-module-object-field-identity field))
                  (if (and (poo-flow-module-object-identity-hash-ref
                            override-seen
                            identity)
                           (not (poo-flow-module-object-identity-hash-ref
                                 replacement-used
                                 identity)))
                    (begin
                      (hash-put! replacement-used identity #t)
                      (poo-flow-module-object-identity-hash-ref
                       overrides
                       identity))
                    field)))
              base)
         (map (lambda (identity)
                (poo-flow-module-object-identity-hash-ref overrides identity))
              (reverse new-identities)))
        (let* ((field (car fields))
               (identity
                (poo-flow-module-object-field-identity field))
               (next-new-identities
                (if (or (poo-flow-module-object-identity-hash-ref
                         base-seen
                         identity)
                        (poo-flow-module-object-identity-hash-ref
                         new-seen
                         identity))
                  new-identities
                  (begin
                    (hash-put! new-seen identity #t)
                    (cons identity new-identities)))))
          (hash-put! override-seen identity #t)
          (hash-put! overrides identity field)
          (loop (cdr fields) next-new-identities))))))

;; : (-> [PooModuleObject] [PooModuleFieldContract])
(def (poo-flow-module-object-inherited-fields inherits)
  (if (null? inherits)
    '()
    (poo-flow-module-object-resolved-fields
     (poo-flow-module-object 'objects.inherited.fields inherits '() '()))))

;; : (-> PooModuleObject [PooModuleFieldContract])
(def (poo-flow-module-object-resolved-fields object)
  (if (null? (poo-flow-module-object-inherits object))
    (poo-flow-module-object-fields object)
    (.ref object 'fields)))

;; : (-> PooModuleObject HashTable)
(def (poo-flow-module-object-resolved-field-index object)
  (poo-flow-module-object-field-index
   (poo-flow-module-object-resolved-fields object)))

;; : (-> HashTable Symbol MaybePooModuleFieldContract)
(def (poo-flow-module-object-field/index field-index identity)
  (poo-flow-module-object-identity-hash-ref field-index identity))

;; : (-> [PooModuleFieldContract] Symbol MaybePooModuleFieldContract)
(def (poo-flow-module-object-field/in-fields fields identity)
  (cond
   ((null? fields) #f)
   ((equal? (poo-flow-module-object-field-identity (car fields))
            identity)
    (car fields))
   (else
    (poo-flow-module-object-field/in-fields (cdr fields) identity))))

;; poo-flow-module-object-field
;;   : (-> PooModuleObject Symbol MaybePooModuleFieldContract)
;;   | contract: resolves inherited fields before selecting by identity
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-object-field object 'backend)
;;       ;; => field contract or #f
;;       ```
;;     %
(def (poo-flow-module-object-field object identity)
  (poo-flow-module-object-field/in-fields
   (poo-flow-module-object-resolved-fields object)
   identity))

;;; Default slot materialization maps field contracts to slot values; override
;;; rows only merge after every field identity has a contract-owned default.
;; : (-> PooModuleObject PooModuleSlotMap)
(def (poo-flow-module-object-default-slots object)
  (map (lambda (field)
         (cons (poo-flow-module-field-contract-identity field)
               (poo-flow-module-field-contract-default field)))
       (poo-flow-module-object-resolved-fields object)))

;; : (-> PooModuleSlotMap Symbol PooModuleSlotValue PooModuleSlotMap)
(def (poo-flow-module-object-alist-set entries key value)
  (cond ((null? entries) (list (cons key value)))
        ((equal? (caar entries) key) (cons (cons key value) (cdr entries)))
        (else (cons (car entries)
                    (poo-flow-module-object-alist-set
                     (cdr entries)
                     key
                     value)))))

;; poo-flow-module-object-slots-merge
;;   : (-> PooModuleSlotMap PooModuleSlotMap PooModuleSlotMap)
;;   | doc m%
;;       `poo-flow-module-object-slots-merge` folds object rows through the
;;       alist setter, preserving first declaration order while allowing later
;;       rows to override by key.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-object-slots-merge base-slots extra-slots)
;;       ;; => merged-slots
;;       ```
;;     %
(def (poo-flow-module-object-slots-merge base extra)
  (let ((base-seen (make-hash-table))
        (override-seen (make-hash-table))
        (overrides (make-hash-table))
        (new-seen (make-hash-table))
        (replacement-used (make-hash-table)))
    (for-each
     (lambda (entry)
       (hash-put! base-seen (car entry) #t))
     base)
    (let loop ((entries extra) (new-keys '()))
      (if (null? entries)
        (append
         (map (lambda (entry)
                (let (key (car entry))
                  (if (and (poo-flow-module-config-slot-key-hash-ref
                            override-seen
                            key)
                           (not (poo-flow-module-config-slot-key-hash-ref
                                 replacement-used
                                 key)))
                    (begin
                      (hash-put! replacement-used key #t)
                      (cons key
                            (poo-flow-module-config-slot-key-hash-ref
                             overrides
                             key)))
                    entry)))
              base)
         (map (lambda (key)
                (cons key
                      (poo-flow-module-config-slot-key-hash-ref
                       overrides
                       key)))
              (reverse new-keys)))
        (let* ((entry (car entries))
               (key (car entry))
               (next-new-keys
                (if (or (poo-flow-module-config-slot-key-hash-ref
                         base-seen
                         key)
                        (poo-flow-module-config-slot-key-hash-ref
                         new-seen
                         key))
                  new-keys
                  (begin
                    (hash-put! new-seen key #t)
                    (cons key new-keys)))))
          (hash-put! override-seen key #t)
          (hash-put! overrides key (cdr entry))
          (loop (cdr entries) next-new-keys))))))

;;; Object nodes are extension nodes seeded with field defaults; downstream
;;; contributions only need to provide changed slots.
;; : (-> PooModuleObject PooModuleSlotMap [PooModuleExtensionNode] PooModuleExtensionNode)
(def (poo-flow-module-object-node/default-slots object default-slots slots children)
  (poo-flow-module-extension-node
   (poo-flow-module-object-identity object)
   (poo-flow-module-object-slots-merge
    default-slots
    slots)
   children))

;; : (-> PooModuleObject PooModuleSlotMap [PooModuleExtensionNode] PooModuleExtensionNode)
(def (poo-flow-module-object-node object slots children)
  (poo-flow-module-object-node/default-slots
   object
   (poo-flow-module-object-default-slots object)
   slots
   children))

;; : (-> PooModuleObject Pair PooModuleFieldContribution)
(def (poo-flow-module-object-contribution object entry)
  (let (field (poo-flow-module-object-field object (car entry)))
    (if field
      (poo-flow-module-field-contribution
       (poo-flow-module-object-identity object)
       field
       (cdr entry))
      (error "unknown poo-flow module object field"
             (poo-flow-module-object-identity object)
             (car entry)))))

;; : (-> PooModuleObject HashTable Pair PooModuleFieldContribution)
(def (poo-flow-module-object-contribution/index object field-index entry)
  (let (field (hash-get field-index (car entry)))
    (if field
      (poo-flow-module-field-contribution
       (poo-flow-module-object-identity object)
       field
       (cdr entry))
      (error "unknown poo-flow module object field"
             (poo-flow-module-object-identity object)
             (car entry)))))

;;; Object contribution mapping preserves one field-contract lookup per user
;;; row, keeping unknown fields as validation failures instead of silent slots.
;; : (-> PooModuleObject PooModuleObjectContributionEntries [PooModuleFieldContribution])
(def (poo-flow-module-object-contributions object entries)
  (let (field-index
        (poo-flow-module-object-resolved-field-index object))
    (map (lambda (entry)
           (poo-flow-module-object-contribution/index object
                                                      field-index
                                                      entry))
         entries)))

;;; The object namespace is a regular extension graph root, so object removal
;;; and extension use the same fixed-point merge path as runtime modules.
;; : (-> [PooModuleObject] PooModuleExtensionNode)
(def (poo-flow-module-objects-node objects)
  (poo-flow-module-extension-node
   poo-flow-module-objects-root-identity
   '((namespace . objects))
   (map (lambda (object)
          (poo-flow-module-object-node object '() '()))
        objects)))

;; : (-> PooModuleExtensionNode HashTable)
(def (poo-flow-module-objects-index objects-node)
  (let (index (make-hash-table))
    (for-each
     (lambda (child)
       (hash-put! index
                  (poo-flow-module-extension-node-identity child)
                  child))
     (poo-flow-module-extension-node-children objects-node))
    index))

;; : (-> HashTable Symbol MaybePooModuleExtensionNode)
(def (poo-flow-module-objects-ref/index objects-index identity)
  (poo-flow-module-object-identity-hash-ref objects-index identity))

;; : (-> PooModuleExtensionNode Symbol MaybePooModuleExtensionNode)
(def (poo-flow-module-objects-ref objects-node identity)
  (poo-flow-module-extension-child-ref
   (poo-flow-module-extension-node-children objects-node)
   identity))

;; poo-flow-module-objects-contributions-by-target
;;   : (-> [PooModuleFieldContribution] HashTable)
;;   | doc m%
;;       `poo-flow-module-objects-contributions-by-target` groups field
;;       contributions by target identity so extension children can be updated
;;       without repeatedly scanning the full contribution list.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-objects-contributions-by-target contributions)
;;       ;; => target-contribution-table
;;       ```
;;     %
(def (poo-flow-module-objects-contributions-by-target contributions)
  (let (groups (make-hash-table))
    (let loop ((remaining contributions))
      (if (null? remaining)
        groups
        (let* ((contribution (car remaining))
               (target
                (poo-flow-module-field-contribution-target contribution))
               (group (hash-get groups target)))
          (hash-put! groups
                     target
                     (if group
                       (cons contribution group)
                       (list contribution)))
          (loop (cdr remaining)))))))

;; : (-> HashTable MaybeFastExtensionChildState PooModuleExtensionNode MaybeFastExtensionChildState)
(def (poo-flow-module-objects-fast-extension-child-state groups state child)
  (and state
       (let* ((next-children (car state))
              (changed? (cdr state))
              (target (poo-flow-module-extension-node-identity child))
              (target-contributions (hash-get groups target)))
         (if target-contributions
           (let (child-result
                 (poo-flow-module-config-fast-extension-result
                  child
                  (reverse target-contributions)))
             (and child-result
                  (let ((next-child
                         (poo-flow-module-extension-result-root child-result))
                        (child-changed?
                         (> (poo-flow-module-extension-result-iterations
                             child-result)
                            0)))
                    (cons (cons next-child next-children)
                          (or changed? child-changed?)))))
           (cons (cons child next-children) changed?)))))

;; : (-> PooModuleExtensionNode [PooModuleFieldContribution] MaybePooModuleExtensionResult)
(def (poo-flow-module-objects-fast-extension-result objects-node contributions)
  (and (equal? (poo-flow-module-extension-node-identity objects-node)
               poo-flow-module-objects-root-identity)
       (let* ((groups
               (poo-flow-module-objects-contributions-by-target contributions))
              (slots
               (poo-flow-module-extension-node-slots objects-node))
              (state
               (foldl (lambda (child state)
                        (poo-flow-module-objects-fast-extension-child-state
                         groups
                         state
                         child))
                      (cons '() #f)
                      (poo-flow-module-extension-node-children objects-node))))
         (and state
              (poo-flow-module-extension-result
               (poo-flow-module-extension-node
                poo-flow-module-objects-root-identity
                slots
                (reverse (car state)))
               (if (cdr state) 1 0)
               #t)))))

;; : (-> PooModuleExtensionNode [PooModuleFieldContribution] PooModuleConfigMergeResult)
(def (poo-flow-module-objects-mk-merge/node objects-node contributions)
  (let (fast-result
        (poo-flow-module-objects-fast-extension-result objects-node
                                                       contributions))
    (if fast-result
      (poo-flow-module-config-merge-result fast-result contributions)
      (poo-flow-module-config-mk-merge objects-node contributions))))

;; : (-> [PooModuleObject] [PooModuleFieldContribution] PooModuleConfigMergeResult)
(def (poo-flow-module-objects-mk-merge objects contributions)
  (poo-flow-module-objects-mk-merge/node
   (poo-flow-module-objects-node objects)
   contributions))
