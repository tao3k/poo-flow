;;; -*- Gerbil -*-
;;; Boundary: Nix-style option merge projection for module configs.
;;; Invariant: merge receipts are data and never activate modules or runners.
;;; Intent: option composition stays inspectable before runtime execution.
;;; Parser policy should treat this file as the option merge semantics owner.

(import :modules/interface
        :modules/descriptor
        :modules/projection)

(export make-poo-module-option-merge-receipt
        poo-module-option-merge-receipt?
        poo-module-option-merge-receipt-id
        poo-module-option-merge-receipt-value
        poo-module-option-merge-receipt-rule
        poo-module-option-merge-receipt-source-modules
        poo-module-option-merge-receipt-valid?
        poo-module-option-merge-receipt-code
        poo-module-option-merge-receipt-messages
        poo-module-option-merge-receipt-metadata
        poo-module-option-merge-receipt->alist
        poo-module-option-merge-receipts
        poo-module-find-merge-receipt
        poo-module-merged-option-alist)

;; PooModuleOptionMergeReceipt <- OptionId Value MergeRule [ModuleName] Boolean Symbol [String] Alist
(defstruct poo-module-option-merge-receipt
  (id
   value
   rule
   source-modules
   valid?
   code
   messages
   metadata)
  transparent: #t)

;;; Boundary: these helpers normalize schema defaults and config values before policy dispatch.
;; [OptionAtom] <- OptionAtomOrList
(def (poo-module-merge-value->list value)
  (if (list? value) value (list value)))

;; [AppendDefaultAtom] <- MaybeAppendDefault
(def (poo-module-merge-default-list value)
  (if value
    (poo-module-merge-value->list value)
    '()))

;; [Value] <- [PooModuleOptionConfig]
(def (poo-module-merge-config-values configs)
  (if (null? configs)
    '()
    (cons (poo-module-option-config-value (car configs))
          (poo-module-merge-config-values (cdr configs)))))

;; [ModuleName] <- [PooModuleOptionConfig]
(def (poo-module-merge-config-sources configs)
  (if (null? configs)
    '()
    (cons (poo-module-option-config-source-module (car configs))
          (poo-module-merge-config-sources (cdr configs)))))

;; OptionValue <- [OptionValue] OptionDefaultValue
(def (poo-module-merge-last-value values default-value)
  (cond
   ((null? values) default-value)
   ((null? (cdr values)) (car values))
   (else
    (poo-module-merge-last-value (cdr values) default-value))))

;; Boolean <- OptionValue [OptionValue]
(def (poo-module-merge-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else
    (poo-module-merge-member? value (cdr values)))))

;; [OptionValue] <- [OptionValue]
(def (poo-module-merge-distinct-values values)
  (cond
   ((null? values) '())
   ((poo-module-merge-member? (car values) (cdr values))
    (poo-module-merge-distinct-values (cdr values)))
   (else
    (cons (car values)
          (poo-module-merge-distinct-values (cdr values))))))

;; [OptionValue] <- ConstantOptionValue [OptionValue]
(def (poo-module-merge-values-not-equal constant-value values)
  (cond
   ((null? values) '())
   ((equal? (car values) constant-value)
    (poo-module-merge-values-not-equal constant-value (cdr values)))
   (else
    (cons (car values)
          (poo-module-merge-values-not-equal constant-value (cdr values))))))

;; [AppendOptionAtom] <- [AppendOptionValue]
(def (poo-module-merge-append-values values)
  (if (null? values)
    '()
    (append (poo-module-merge-value->list (car values))
            (poo-module-merge-append-values (cdr values)))))

;; Boolean <- PooModuleOptionConfig OptionId
(def (poo-module-merge-config-id? config option-id-value)
  (poo-module-kind=? (poo-module-option-config-id config)
                     option-id-value))

;; Boolean <- PooModuleOptionSchema OptionId
(def (poo-module-merge-schema-id? schema option-id-value)
  (poo-module-kind=? (poo-module-option-schema-id schema)
                     option-id-value))

;; [PooModuleOptionConfig] <- [PooModuleOptionConfig] OptionId
(def (poo-module-merge-configs-for-id configs option-id-value)
  (cond
   ((null? configs) '())
   ((poo-module-merge-config-id? (car configs) option-id-value)
    (cons (car configs)
          (poo-module-merge-configs-for-id (cdr configs) option-id-value)))
   (else
    (poo-module-merge-configs-for-id (cdr configs) option-id-value))))

;;; Boundary: schema lookup is first-match after dependency ordering, so duplicate schemas must stay equivalent.
;; MaybePooModuleOptionSchema <- [PooModuleOptionSchema] OptionId
(def (poo-module-merge-schema-for-id schemas option-id-value)
  (find (lambda (schema)
          (poo-module-merge-schema-id? schema option-id-value))
        schemas))

;; [OptionId] <- [OptionId] OptionId
(def (poo-module-merge-cons-id option-ids option-id-value)
  (if (poo-module-merge-member? option-id-value option-ids)
    option-ids
    (append option-ids (list option-id-value))))

;; [OptionId] <- [OptionId] [OptionId]
(def (poo-module-merge-add-ids option-ids new-option-ids)
  (if (null? new-option-ids)
    option-ids
    (poo-module-merge-add-ids
     (poo-module-merge-cons-id option-ids (car new-option-ids))
     (cdr new-option-ids))))

;; [OptionId] <- [PooModuleOptionSchema]
(def (poo-module-merge-schema-ids schemas)
  (if (null? schemas)
    '()
    (cons (poo-module-option-schema-id (car schemas))
          (poo-module-merge-schema-ids (cdr schemas)))))

;; [OptionId] <- [PooModuleOptionConfig]
(def (poo-module-merge-config-ids configs)
  (if (null? configs)
    '()
    (cons (poo-module-option-config-id (car configs))
          (poo-module-merge-config-ids (cdr configs)))))

;; [OptionId] <- [PooModuleOptionSchema] [PooModuleOptionConfig]
(def (poo-module-merge-option-ids schemas configs)
  (poo-module-merge-add-ids
   (poo-module-merge-schema-ids schemas)
   (poo-module-merge-config-ids configs)))

;; [PooModuleOptionConfig] <- [PooModuleDescriptor]
(def (poo-module-merge-all-configs modules)
  (if (null? modules)
    '()
    (append (poo-module-option-configs (car modules))
            (poo-module-merge-all-configs (cdr modules)))))

;; [PooModuleOptionSchema] <- [PooModuleDescriptor]
(def (poo-module-merge-all-schemas modules)
  (if (null? modules)
    '()
    (append (poo-module-option-schemas (car modules))
            (poo-module-merge-all-schemas (cdr modules)))))

;;; Boundary: append merges default value first, then closure config values.
;; PooModuleOptionMergeReceipt <- OptionId PooModuleOptionSchema [PooModuleOptionConfig]
(def (poo-module-append-merge-receipt option-id-value schema configs)
  (let ((values
         (append (poo-module-merge-default-list
                  (poo-module-option-schema-value schema))
                 (poo-module-merge-config-values configs))))
    (make-poo-module-option-merge-receipt
     option-id-value
     (poo-module-merge-append-values values)
     'append
     (poo-module-merge-config-sources configs)
     #t
     'merged
     '()
     (poo-module-option-schema-metadata schema))))

;;; Boundary: override uses the last config value in closure order.
;; PooModuleOptionMergeReceipt <- OptionId PooModuleOptionSchema [PooModuleOptionConfig]
(def (poo-module-override-merge-receipt option-id-value schema configs)
  (let (values (poo-module-merge-config-values configs))
    (make-poo-module-option-merge-receipt
     option-id-value
     (poo-module-merge-last-value
      values
      (poo-module-option-schema-value schema))
     'override
     (poo-module-merge-config-sources configs)
     #t
     (if (null? values) 'default 'overridden)
     '()
     (poo-module-option-schema-metadata schema))))

;;; Boundary: conflict accepts identical values and reports divergent values.
;; PooModuleOptionMergeReceipt <- OptionId PooModuleOptionSchema [PooModuleOptionConfig]
(def (poo-module-conflict-merge-receipt option-id-value schema configs)
  (let* ((values (poo-module-merge-config-values configs))
         (distinct-values (poo-module-merge-distinct-values values)))
    (if (> (length distinct-values) 1)
      (make-poo-module-option-merge-receipt
       option-id-value
       distinct-values
       'conflict
       (poo-module-merge-config-sources configs)
       #f
       'conflict
       '("option values conflict")
       (poo-module-option-schema-metadata schema))
      (make-poo-module-option-merge-receipt
       option-id-value
       (poo-module-merge-last-value values #f)
       'conflict
       (poo-module-merge-config-sources configs)
       #t
       (if (null? values) 'absent 'merged)
       '()
       (poo-module-option-schema-metadata schema)))))

;;; Boundary: constant merge repeats validation at the final option surface.
;; PooModuleOptionMergeReceipt <- OptionId PooModuleOptionSchema [PooModuleOptionConfig]
(def (poo-module-constant-merge-receipt option-id-value schema configs)
  (let* ((constant-value (poo-module-option-schema-value schema))
         (values (poo-module-merge-config-values configs))
         (bad-values
          (poo-module-merge-values-not-equal constant-value values)))
    (make-poo-module-option-merge-receipt
     option-id-value
     constant-value
     'constant
     (poo-module-merge-config-sources configs)
     (null? bad-values)
     (if (null? bad-values) 'merged 'constant-mismatch)
     (if (null? bad-values)
       '()
       '("option value does not match constant schema"))
     (poo-module-option-schema-metadata schema))))

;;; Boundary: default-like rules use the last config or the schema value.
;; PooModuleOptionMergeReceipt <- OptionId PooModuleOptionSchema [PooModuleOptionConfig] Symbol
(def (poo-module-default-merge-receipt option-id-value schema configs rule)
  (let (values (poo-module-merge-config-values configs))
    (make-poo-module-option-merge-receipt
     option-id-value
     (poo-module-merge-last-value values
                                  (poo-module-option-schema-value schema))
     rule
     (poo-module-merge-config-sources configs)
     #t
     (if (null? values) 'default 'merged)
     '()
     (poo-module-option-schema-metadata schema))))

;;; Boundary: required options fail visibly when no module supplies a value.
;; PooModuleOptionMergeReceipt <- OptionId PooModuleOptionSchema [PooModuleOptionConfig]
(def (poo-module-required-merge-receipt option-id-value schema configs)
  (if (null? configs)
    (make-poo-module-option-merge-receipt
     option-id-value
     #f
     'required
     '()
     #f
     'missing-required
     '("required option is not configured")
     (poo-module-option-schema-metadata schema))
    (poo-module-default-merge-receipt option-id-value schema configs 'required)))

;;; Boundary: missing schemas remain data findings instead of exceptions.
;; PooModuleOptionMergeReceipt <- OptionId [PooModuleOptionConfig]
(def (poo-module-missing-merge-schema-receipt option-id-value configs)
  (make-poo-module-option-merge-receipt
   option-id-value
   (poo-module-merge-last-value
    (poo-module-merge-config-values configs)
    #f)
   'missing-schema
   (poo-module-merge-config-sources configs)
   #f
   'missing-schema
   '("option schema is not declared")
   '()))

;;; Boundary: one option id lowers to exactly one merge receipt.
;; PooModuleOptionMergeReceipt <- OptionId [PooModuleOptionSchema] [PooModuleOptionConfig]
(def (poo-module-option-merge-receipt-for option-id-value schemas configs)
  (let ((schema (poo-module-merge-schema-for-id schemas option-id-value))
        (matched-configs
         (poo-module-merge-configs-for-id configs option-id-value)))
    (cond
     ((not schema)
      (poo-module-missing-merge-schema-receipt option-id-value matched-configs))
     ((eq? (poo-module-option-schema-rule schema) 'append)
      (poo-module-append-merge-receipt option-id-value schema matched-configs))
     ((eq? (poo-module-option-schema-rule schema) 'override)
      (poo-module-override-merge-receipt option-id-value schema matched-configs))
     ((eq? (poo-module-option-schema-rule schema) 'conflict)
      (poo-module-conflict-merge-receipt option-id-value schema matched-configs))
     ((eq? (poo-module-option-schema-rule schema) 'constant)
      (poo-module-constant-merge-receipt option-id-value schema matched-configs))
     ((eq? (poo-module-option-schema-rule schema) 'required)
      (poo-module-required-merge-receipt option-id-value schema matched-configs))
     (else
      (poo-module-default-merge-receipt
       option-id-value
       schema
       matched-configs
       (poo-module-option-schema-rule schema))))))

;; [PooModuleOptionMergeReceipt] <- [OptionId] [PooModuleOptionSchema] [PooModuleOptionConfig]
(def (poo-module-option-merge-receipts-for-ids option-ids schemas configs)
  (if (null? option-ids)
    '()
    (cons (poo-module-option-merge-receipt-for
           (car option-ids)
           schemas
           configs)
          (poo-module-option-merge-receipts-for-ids
           (cdr option-ids)
           schemas
           configs))))

;;; Boundary: public merge receipts evaluate dependencies before the root module.
;; [PooModuleOptionMergeReceipt] <- PooModuleDescriptor
(def (poo-module-option-merge-receipts module)
  (let* ((closed-modules (reverse (poo-module-closure (list module))))
         (schemas (poo-module-merge-all-schemas closed-modules))
         (configs (poo-module-merge-all-configs closed-modules)))
    (poo-module-option-merge-receipts-for-ids
     (poo-module-merge-option-ids schemas configs)
     schemas
     configs)))

;;; Boundary: public lookup keeps callers on receipts instead of peeking into merge internals.
;; MaybePooModuleOptionMergeReceipt <- [PooModuleOptionMergeReceipt] OptionId
(def (poo-module-find-merge-receipt receipts option-id-value)
  (find (lambda (receipt)
          (poo-module-kind=?
           (poo-module-option-merge-receipt-id receipt)
           option-id-value))
        receipts))

;;; Boundary: invalid merge receipts stay visible in receipts but do not enter final config.
;;; Boundary: alist projection is the stable doctor/presentation edge for merge data.
;; Alist <- PooModuleOptionMergeReceipt
(def (poo-module-option-merge-receipt->alist receipt)
  (list (cons 'id (poo-module-option-merge-receipt-id receipt))
        (cons 'value (poo-module-option-merge-receipt-value receipt))
        (cons 'rule (poo-module-option-merge-receipt-rule receipt))
        (cons 'source-modules
              (poo-module-option-merge-receipt-source-modules receipt))
        (cons 'valid? (poo-module-option-merge-receipt-valid? receipt))
        (cons 'code (poo-module-option-merge-receipt-code receipt))
        (cons 'messages (poo-module-option-merge-receipt-messages receipt))
        (cons 'metadata (poo-module-option-merge-receipt-metadata receipt))))

;;; Boundary: invalid merge receipts stay visible in receipts but do not enter final config.
;; Alist <- [PooModuleOptionMergeReceipt]
(def (poo-module-merged-option-alist-from receipts)
  (cond
   ((null? receipts) '())
   ((poo-module-option-merge-receipt-valid? (car receipts))
    (cons (cons (poo-module-option-merge-receipt-id (car receipts))
                (poo-module-option-merge-receipt-value (car receipts)))
          (poo-module-merged-option-alist-from (cdr receipts))))
   (else
    (poo-module-merged-option-alist-from (cdr receipts)))))

;;; Boundary: merged option alist includes only valid final option receipts.
;; Alist <- PooModuleDescriptor
(def (poo-module-merged-option-alist module)
  (poo-module-merged-option-alist-from
   (poo-module-option-merge-receipts module)))
