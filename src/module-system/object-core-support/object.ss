;;; -*- Gerbil -*-
;;; Boundary: module object schema, slot defaults, and object catalog merge.

(import :gerbil/gambit
        (only-in :clan/poo/object
                 .ref
                 object?
                 object-slots
                 make-object
                 $constant-slot-spec
                 $constant-slot-spec?
                 $constant-slot-spec-value
                 $computed-slot-spec)
        (only-in :std/sugar foldl)
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/object-core-support/contracts
        :poo-flow/src/module-system/object-core-support/merge)

(export poo-flow-module-object
        poo-flow-module-object?
        poo-flow-module-object-identity
        poo-flow-module-object-inherits
        poo-flow-module-object-fields
        poo-flow-module-object-metadata
        poo-flow-module-object-inheritance-chain-cache
        poo-flow-module-object-constant-slot
        poo-flow-module-object-fields-slot
        poo-flow-module-object-constant-slot-ref
        poo-flow-module-object-constant-slot-ref/default
        poo-flow-module-object-field-identity
        poo-flow-module-object-field-index
        poo-flow-module-object-identity-hash-ref
        poo-flow-module-object-field-set
        poo-flow-module-object-fields-merge
        poo-flow-module-object-inherited-fields
        poo-flow-module-object-resolved-fields
        poo-flow-module-object-resolved-field-index
        poo-flow-module-object-field/index
        poo-flow-module-object-field/in-fields
        poo-flow-module-object-field
        poo-flow-module-object-default-slots
        poo-flow-module-object-alist-set
        poo-flow-module-object-slots-merge
        poo-flow-module-object-node/default-slots
        poo-flow-module-object-node
        poo-flow-module-object-contribution
        poo-flow-module-object-contribution/index
        poo-flow-module-object-contributions
        poo-flow-module-objects-node
        poo-flow-module-objects-index
        poo-flow-module-objects-ref/index
        poo-flow-module-objects-ref
        poo-flow-module-objects-contributions-by-target
        poo-flow-module-objects-fast-extension-child-state
        poo-flow-module-objects-fast-extension-result
        poo-flow-module-objects-mk-merge/node
        poo-flow-module-objects-mk-merge)

;;; Module objects are POO-side schemas. They can inherit fields, but they do
;;; not instantiate modules or evaluate user config.
;; : (-> Symbol [PooModuleObject] [PooModuleFieldContract] PooModuleObjectMetadata PooModuleObject)
(def (poo-flow-module-object identity inherits fields metadata)
  (let ((identity-value identity)
        (inherits-value inherits)
        (fields-value fields)
        (metadata-value metadata))
    (make-object
     supers: '()
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
             (poo-flow-module-object-fields-slot inherits-value fields-value)
             (poo-flow-module-object-constant-slot
              'metadata
              metadata-value)
             (poo-flow-module-object-constant-slot
              'inheritance-chain-cache
              (vector #f '()))))))

;; : (-> PooModuleObjectCandidate Boolean)
(def (poo-flow-module-object? value)
  (and (object? value)
       (let (kind (poo-flow-module-object-constant-slot-ref/default
                   value
                   'kind
                   +poo-flow-module-object-slot-missing+))
         (if (eq? kind +poo-flow-module-object-slot-missing+)
           (poo-flow-module-object-kind? value poo-flow-module-object-kind)
           (equal? kind poo-flow-module-object-kind)))))

;; : (-> PooModuleObject Symbol)
(def (poo-flow-module-object-identity object)
  (poo-flow-module-object-constant-slot-ref object 'identity))
;; : (-> PooModuleObject [PooModuleObject])
(def (poo-flow-module-object-inherits object)
  (poo-flow-module-object-constant-slot-ref object 'inherits))
;; : (-> PooModuleObject [PooModuleFieldContract])
(def (poo-flow-module-object-fields object)
  (poo-flow-module-object-constant-slot-ref object 'direct-fields))
;; : (-> PooModuleObject PooModuleObjectMetadata)
(def (poo-flow-module-object-metadata object)
  (poo-flow-module-object-constant-slot-ref object 'metadata))

(def (poo-flow-module-object-inheritance-chain-cache object)
  (poo-flow-module-object-constant-slot-ref object 'inheritance-chain-cache))

;; : (-> Symbol Value PooModuleObjectSlotSpec)
(def (poo-flow-module-object-constant-slot key value)
  (cons key ($constant-slot-spec value)))

(def +poo-flow-module-object-slot-missing+
  (list 'poo-flow-module-object-slot-missing))

;;; Descriptor slots are plain POO constant slot specs. Read them from the POO
;;; object's slot table so metadata projections do not instantiate every object.
;; : (-> PooModuleObject Symbol Value Value)
(def (poo-flow-module-object-constant-slot-ref/default object key default)
  (let loop ((slots (object-slots object)))
    (cond
     ((null? slots) default)
     ((eq? (caar slots) key)
      (let (spec (cdar slots))
        (if ($constant-slot-spec? spec)
          ($constant-slot-spec-value spec)
          default)))
     (else (loop (cdr slots))))))

;; : (-> PooModuleObject Symbol Value)
(def (poo-flow-module-object-constant-slot-ref object key)
  (let (value (poo-flow-module-object-constant-slot-ref/default
               object
               key
               +poo-flow-module-object-slot-missing+))
    (if (eq? value +poo-flow-module-object-slot-missing+)
      (.ref object key)
      value)))

;;; Field slots are computed from the superclass chain, letting child objects
;;; override or add fields without duplicating inherited object metadata.
;; : (-> [PooModuleFieldContract] PooModuleObjectSlotSpec)
(def (poo-flow-module-object-fields-slot inherits fields)
  (cons 'fields
        ($computed-slot-spec
         (lambda (_self _superfun)
           (poo-flow-module-object-fields-merge
            (poo-flow-module-object-inherited-fields inherits)
            fields)))))

;;; Field identity accepts contracts and raw symbols so lookup paths share one
;;; boundary between parsed field contracts and caller-provided keys.
;; : (-> (U PooModuleFieldContract Symbol) Symbol)
(def (poo-flow-module-object-field-identity field)
  (if (poo-flow-module-field-contract? field)
    (poo-flow-module-field-contract-identity field)
    field))

;;; Field indexes keep the first declaration authoritative for lookup while
;;; ordered merge code handles replacement and append materialization.
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

;;; Field set is the small-list replacement path used before hash indexes are
;;; worth materializing, preserving inherited field order.
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
    (def (finish new-identities)
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
            (reverse new-identities))))
    (let loop ((fields extra) (new-identities '()))
      (if (null? fields)
        (finish new-identities)
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

;;; Inherited field resolution builds a synthetic object so direct and inherited
;;; schemas both pass through the same computed-slot semantics.
;; : (-> [PooModuleObject] [PooModuleFieldContract])
(def (poo-flow-module-object-inherited-fields inherits)
  (if (null? inherits)
    '()
    (let loop ((rest inherits) (fields '()))
      (if (null? rest)
        fields
        (loop (cdr rest)
              (poo-flow-module-object-fields-merge
               fields
               (poo-flow-module-object-resolved-fields (car rest))))))))

;;; Resolved fields avoid POO slot evaluation for leaf objects and only consult
;;; computed inheritance state when the object has parents.
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

;;; Linear field lookup is retained for one-off access; repeated contribution
;;; mapping should use the indexed lookup path.
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

;;; Slot alist replacement preserves the first key position and updates only
;;; the matching row, matching extension slot merge order.
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
    (def (finish new-keys)
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
            (reverse new-keys))))
    (let loop ((entries extra) (new-keys '()))
      (if (null? entries)
        (finish new-keys)
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

;;; Object contribution converts one user slot row into a typed field
;;; contribution and fails loudly when the object schema has no such field.
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

;;; Indexed contribution conversion keeps large object updates from rescanning
;;; resolved fields for every user-provided row.
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

;;; Object indexes materialize the catalog identity boundary once so inherit and
;;; merge callers can resolve child nodes without repeated child scans.
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

;;; Fast child state updates only children that have grouped contributions while
;;; preserving untouched child nodes and tracking whether any merge changed.
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

;;; Fast extension result is valid only for the objects root; other roots fall
;;; back to the generic fixed-point merge contract.
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

;;; Merge-node entrypoint prefers the objects-root fast path and delegates to
;;; the generic extension merge when the shape is outside that proven boundary.
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
