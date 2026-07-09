;;; -*- Gerbil -*-
;;; Boundary: POO-native memory store specs, catalogs, and handoff receipts.
;;; Invariant: this module describes memory backends and validates intent refs;
;;; it never recalls, commits, persists, or starts a runtime backend.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/module-system/projection-syntax
        :poo-flow/src/module-system/durable-policy
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/transform)

(export +poo-flow-memory-core-store-spec-kind+
        +poo-flow-memory-core-catalog-kind+
        +poo-flow-memory-core-handoff-manifest-kind+
        +poo-flow-memory-core-policy-validation-receipt-kind+
        +poo-flow-memory-core-durable-job-receipt-kind+
        +poo-flow-memory-durable-job-kinds+
        +poo-flow-memory-durable-job-states+
        poo-flow-memory-store-spec
        poo-flow-memory-store-spec?
        poo-flow-memory-store-spec-ref
        poo-flow-memory-store-spec-scopes
        poo-flow-memory-store-spec-commit-policies
        poo-flow-memory-store-spec-recall-policies
        poo-flow-memory-store-spec->alist
        poo-flow-memory-handoff-manifest
        poo-flow-memory-handoff-manifest?
        poo-flow-memory-handoff-manifest->alist
        poo-flow-memory-catalog
        poo-flow-memory-catalog?
        poo-flow-memory-catalog-ref
        poo-flow-memory-catalog-store-refs
        poo-flow-memory-catalog-store-count
        poo-flow-memory-catalog-find
        poo-flow-memory-catalog->alist
        poo-flow-memory-policy-catalog-validation-receipt
        poo-flow-memory-policy-catalog-validation-receipt?
        poo-flow-memory-policy-catalog-validation-receipt-valid?
        poo-flow-memory-policy-catalog-validation-receipt-diagnostics
        poo-flow-memory-policy-catalog-validation-receipt->alist
        make-poo-flow-memory-durable-job-receipt
        poo-flow-memory-durable-job-receipt?
        poo-flow-memory-durable-job-receipt-job-id
        poo-flow-memory-durable-job-receipt-job-kind
        poo-flow-memory-durable-job-receipt-job-state
        poo-flow-memory-durable-job-receipt-project-id
        poo-flow-memory-durable-job-receipt-root-session-id
        poo-flow-memory-durable-job-receipt-session-id
        poo-flow-memory-durable-job-receipt-agent-id
        poo-flow-memory-durable-job-receipt-store-ref
        poo-flow-memory-durable-job-receipt-durable-policy-ref
        poo-flow-memory-durable-job-receipt-job-store-ref
        poo-flow-memory-durable-job-receipt-checkpoint-store-ref
        poo-flow-memory-durable-job-receipt-source-ref
        poo-flow-memory-durable-job-receipt-source-watermark
        poo-flow-memory-durable-job-receipt-target-watermark
        poo-flow-memory-durable-job-receipt-stale-source?
        poo-flow-memory-durable-job-receipt-retry-policy
        poo-flow-memory-durable-job-receipt-retention-policy
        poo-flow-memory-durable-job-receipt-usage-counter
        poo-flow-memory-durable-job-receipt-scope
        poo-flow-memory-durable-job-receipt-recall
        poo-flow-memory-durable-job-receipt-commit-policy
        poo-flow-memory-durable-job-receipt-valid?
        poo-flow-memory-durable-job-receipt-diagnostics
        poo-flow-memory-durable-job-receipt-metadata
        poo-flow-memory-durable-job-receipt-from-intent
        poo-flow-memory-recall-job-receipt
        poo-flow-memory-write-job-receipt
        poo-flow-memory-consolidation-job-receipt
        poo-flow-memory-stale-source-job-receipt
        poo-flow-memory-repair-job-receipt
        poo-flow-memory-durable-job-receipt->alist
        poo-flow-memory-durable-job-receipts->alists
        poo-flow-memory-core-local-session-store
        poo-flow-memory-core-durable-project-store
        poo-flow-memory-core-default-catalog)

;;; Boundary: memory field rows preserve object slot names that durable session
;;; and artifact policy projections consume.
;; poo-flow-memory-field-rows
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expands memory object field clauses into stable projection rows for durable
;;   memory receipts.
;;   # Examples
;;   ```scheme
;;   (poo-flow-memory-field-rows (store 'local))
;;   ;; => ((store . local))
;;   ```
(defrules poo-flow-memory-field-rows ()
  ((_ (field value) ...)
   (list (cons 'field value) ...)))

;; : PooMemoryHandoffManifestReceiptStruct
(defstruct poo-flow-memory-handoff-manifest-receipt
  (kind
   schema
   request-id
   store-ref
   store-kind
   namespace
   scopes
   recall-policies
   commit-policies
   operation
   runtime-owner
   runtime-backend
   durable?
   handoff-ready?
   diagnostic-count
   diagnostics
   runtime-executed
   metadata)
  transparent: #t)

;; : PooMemoryPolicyValidationReceiptRecordStruct
(defstruct poo-flow-memory-policy-validation-receipt-record
  (kind
   schema
   validation-id
   catalog-ref
   catalog-store-count
   catalog-store-refs
   intent-count
   intent-store-refs
   resolved-store-refs
   unresolved-store-refs
   valid?
   diagnostic-count
   diagnostics
   runtime-owner
   runtime-executed
   metadata)
  transparent: #t)

;;; Runtime receipts use fixed structs first; this helper is the narrow POO ABI
;;; projection used at downstream `.ref` boundaries.
;; : (-> Alist POOObject)
(def (poo-flow-memory-runtime-object fields)
  (object<-alist fields))

;; : Symbol
(def +poo-flow-memory-core-store-spec-kind+
  'poo-flow.memory-core.store-spec)

;; : Symbol
(def +poo-flow-memory-core-catalog-kind+
  'poo-flow.memory-core.catalog)

;; : Symbol
(def +poo-flow-memory-core-handoff-manifest-kind+
  'poo-flow.memory-core.handoff-manifest)

;; : Symbol
(def +poo-flow-memory-core-policy-validation-receipt-kind+
  'poo-flow.memory-core.policy-catalog-validation-receipt)

;; : Symbol
(def +poo-flow-memory-core-durable-job-receipt-kind+
  'poo-flow.memory-core.durable-job-receipt)

;; : [Symbol]
(def +poo-flow-memory-durable-job-kinds+
  '(recall write consolidation stale-source repair))

;; : [Symbol]
(def +poo-flow-memory-durable-job-states+
  '(planned claimable claimed completed failed stale repair-required))

;; : (-> POOObject Symbol Object Object)
(def (poo-flow-memory-slot object key default-value)
  (with-catch
   (lambda (_failure) default-value)
   (lambda ()
     (.ref object key))))

;; : (-> Alist Symbol Object Object)
(def (poo-flow-memory-option options key default-value)
  (let (entry (assoc key options))
    (if entry (cdr entry) default-value)))

;; : (-> Object Boolean)
(def (poo-flow-memory-symbol-list? values)
  (and (list? values)
       (poo-flow-session-every? symbol? values)))

;; : (-> Object Boolean)
(def (poo-flow-memory-alist? value)
  (list? value))

;; : (-> Symbol Symbol Symbol [Symbol] [Symbol] [Symbol] String Symbol Boolean Symbol [Alist] PooMemoryStoreSpec)
(def (poo-flow-memory-store-spec store-ref
                                 store-kind
                                 namespace
                                 scopes
                                 recall-policies
                                 commit-policies
                                 runtime-owner
                                 handoff-operation
                                 durable?
                                 runtime-backend
                                 . maybe-metadata)
  (poo-flow-session-require "memory store ref must be a symbol"
                            (symbol? store-ref)
                            store-ref)
  (poo-flow-session-require "memory store kind must be a symbol"
                            (symbol? store-kind)
                            store-kind)
  (poo-flow-session-require "memory namespace must be a symbol"
                            (symbol? namespace)
                            namespace)
  (poo-flow-session-require "memory scopes must be symbols"
                            (poo-flow-memory-symbol-list? scopes)
                            scopes)
  (poo-flow-session-require "memory recall policies must be symbols"
                            (poo-flow-memory-symbol-list? recall-policies)
                            recall-policies)
  (poo-flow-session-require "memory commit policies must be symbols"
                            (poo-flow-memory-symbol-list? commit-policies)
                            commit-policies)
  (poo-flow-session-require "memory runtime owner must be a string"
                            (string? runtime-owner)
                            runtime-owner)
  (poo-flow-session-require "memory handoff operation must be a symbol"
                            (symbol? handoff-operation)
                            handoff-operation)
  (poo-flow-session-require "memory durable? must be boolean"
                            (boolean? durable?)
                            durable?)
  (poo-flow-session-require "memory runtime backend must be a symbol"
                            (symbol? runtime-backend)
                            runtime-backend)
  (object<-alist
   (list
    (cons 'kind +poo-flow-memory-core-store-spec-kind+)
    (cons 'schema 'poo-flow.modules.memory-core.store-spec.v1)
    (cons 'store-ref store-ref)
    (cons 'store-kind store-kind)
    (cons 'namespace namespace)
    (cons 'scopes scopes)
    (cons 'recall-policies recall-policies)
    (cons 'commit-policies commit-policies)
    (cons 'runtime-owner runtime-owner)
    (cons 'handoff-operation handoff-operation)
    (cons 'durable? durable?)
    (cons 'runtime-backend runtime-backend)
    (cons 'runtime-executed #f)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata))))))

;; : (-> POOObject Boolean)
(def (poo-flow-memory-store-spec? value)
  (and (object? value)
       (eq? (poo-flow-memory-slot value 'kind #f)
            +poo-flow-memory-core-store-spec-kind+)))

;; : (-> PooMemoryStoreSpec Symbol)
(def (poo-flow-memory-store-spec-ref spec)
  (.ref spec 'store-ref))

;; : (-> PooMemoryStoreSpec [Symbol])
(def (poo-flow-memory-store-spec-scopes spec)
  (.ref spec 'scopes))

;; : (-> PooMemoryStoreSpec [Symbol])
(def (poo-flow-memory-store-spec-commit-policies spec)
  (.ref spec 'commit-policies))

;; : (-> PooMemoryStoreSpec [Symbol])
(def (poo-flow-memory-store-spec-recall-policies spec)
  (.ref spec 'recall-policies))

;; : (-> PooMemoryStoreSpec Alist)
(defpoo-module-final-projection
  poo-flow-memory-store-spec->alist (spec)
  (bindings ((checked-spec
              (poo-flow-session-require
               "memory store projection requires a memory store spec"
               (poo-flow-memory-store-spec? spec)
               spec))))
  (fields ((kind (.ref checked-spec 'kind))
           (schema (.ref checked-spec 'schema))
           (store-ref (.ref checked-spec 'store-ref))
           (store-kind (.ref checked-spec 'store-kind))
           (namespace (.ref checked-spec 'namespace))
           (scopes (.ref checked-spec 'scopes))
           (recall-policies (.ref checked-spec 'recall-policies))
           (commit-policies (.ref checked-spec 'commit-policies))
           (runtime-owner (.ref checked-spec 'runtime-owner))
           (handoff-operation (.ref checked-spec 'handoff-operation))
           (durable? (.ref checked-spec 'durable?))
           (runtime-backend (.ref checked-spec 'runtime-backend))
           (runtime-executed (.ref checked-spec 'runtime-executed))
           (metadata (.ref checked-spec 'metadata)))))

;; : (-> [PooMemoryStoreSpec] [Alist])
(defpoo-module-final-projection-batch
  poo-flow-memory-store-specs->alists (specs)
  (projector poo-flow-memory-store-spec->alist)
  (error-message "memory store serialization requires a list"))

;; : (-> Symbol PooMemoryStoreSpec [Alist] PooMemoryHandoffManifest)
(def (poo-flow-memory-handoff-manifest request-id spec . maybe-metadata)
  (poo-flow-session-require "memory handoff request id must be a symbol"
                            (symbol? request-id)
                            request-id)
  (poo-flow-session-require "memory handoff requires a store spec"
                            (poo-flow-memory-store-spec? spec)
                            spec)
  (poo-flow-memory-runtime-object
   (list
    (cons 'kind +poo-flow-memory-core-handoff-manifest-kind+)
    (cons 'schema 'poo-flow.modules.memory-core.handoff-manifest.v1)
    (cons 'request-id request-id)
    (cons 'store-ref (poo-flow-memory-store-spec-ref spec))
    (cons 'store-kind (.ref spec 'store-kind))
    (cons 'namespace (.ref spec 'namespace))
    (cons 'scopes (.ref spec 'scopes))
    (cons 'recall-policies (.ref spec 'recall-policies))
    (cons 'commit-policies (.ref spec 'commit-policies))
    (cons 'operation (.ref spec 'handoff-operation))
    (cons 'runtime-owner (.ref spec 'runtime-owner))
    (cons 'runtime-backend (.ref spec 'runtime-backend))
    (cons 'durable? (.ref spec 'durable?))
    (cons 'handoff-ready? #t)
    (cons 'diagnostic-count 0)
    (cons 'diagnostics '())
    (cons 'runtime-executed #f)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata))))))

;; : (-> POOObject Boolean)
(def (poo-flow-memory-handoff-manifest? value)
  (or (poo-flow-memory-handoff-manifest-receipt? value)
      (and (object? value)
           (eq? (poo-flow-memory-slot value 'kind #f)
                +poo-flow-memory-core-handoff-manifest-kind+))))

;;; Boundary: handoff manifest serialization is the bounded ABI between memory
;;; policy objects and Marlin/runtime transfer.
;; : (-> PooMemoryHandoffManifest Alist)
(def (poo-flow-memory-handoff-manifest->alist manifest)
  (let (checked-manifest
        (poo-flow-session-require
         "memory handoff projection requires a memory handoff manifest"
         (poo-flow-memory-handoff-manifest? manifest)
         manifest))
    (if (poo-flow-memory-handoff-manifest-receipt? checked-manifest)
      (list
       (cons 'kind
             (poo-flow-memory-handoff-manifest-receipt-kind checked-manifest))
       (cons 'schema
             (poo-flow-memory-handoff-manifest-receipt-schema checked-manifest))
       (cons 'request-id
             (poo-flow-memory-handoff-manifest-receipt-request-id checked-manifest))
       (cons 'store-ref
             (poo-flow-memory-handoff-manifest-receipt-store-ref checked-manifest))
       (cons 'store-kind
             (poo-flow-memory-handoff-manifest-receipt-store-kind checked-manifest))
       (cons 'namespace
             (poo-flow-memory-handoff-manifest-receipt-namespace checked-manifest))
       (cons 'scopes
             (poo-flow-memory-handoff-manifest-receipt-scopes checked-manifest))
       (cons 'recall-policies
             (poo-flow-memory-handoff-manifest-receipt-recall-policies checked-manifest))
       (cons 'commit-policies
             (poo-flow-memory-handoff-manifest-receipt-commit-policies checked-manifest))
       (cons 'operation
             (poo-flow-memory-handoff-manifest-receipt-operation checked-manifest))
       (cons 'runtime-owner
             (poo-flow-memory-handoff-manifest-receipt-runtime-owner checked-manifest))
       (cons 'runtime-backend
             (poo-flow-memory-handoff-manifest-receipt-runtime-backend checked-manifest))
       (cons 'durable?
             (poo-flow-memory-handoff-manifest-receipt-durable? checked-manifest))
       (cons 'handoff-ready?
             (poo-flow-memory-handoff-manifest-receipt-handoff-ready? checked-manifest))
       (cons 'diagnostic-count
             (poo-flow-memory-handoff-manifest-receipt-diagnostic-count checked-manifest))
       (cons 'diagnostics
             (poo-flow-memory-handoff-manifest-receipt-diagnostics checked-manifest))
       (cons 'runtime-executed
             (poo-flow-memory-handoff-manifest-receipt-runtime-executed checked-manifest))
       (cons 'metadata
             (poo-flow-memory-handoff-manifest-receipt-metadata checked-manifest)))
      (list
       (cons 'kind (.ref checked-manifest 'kind))
       (cons 'schema (.ref checked-manifest 'schema))
       (cons 'request-id (.ref checked-manifest 'request-id))
       (cons 'store-ref (.ref checked-manifest 'store-ref))
       (cons 'store-kind (.ref checked-manifest 'store-kind))
       (cons 'namespace (.ref checked-manifest 'namespace))
       (cons 'scopes (.ref checked-manifest 'scopes))
       (cons 'recall-policies (.ref checked-manifest 'recall-policies))
       (cons 'commit-policies (.ref checked-manifest 'commit-policies))
       (cons 'operation (.ref checked-manifest 'operation))
       (cons 'runtime-owner (.ref checked-manifest 'runtime-owner))
       (cons 'runtime-backend (.ref checked-manifest 'runtime-backend))
       (cons 'durable? (.ref checked-manifest 'durable?))
       (cons 'handoff-ready? (.ref checked-manifest 'handoff-ready?))
       (cons 'diagnostic-count (.ref checked-manifest 'diagnostic-count))
       (cons 'diagnostics (.ref checked-manifest 'diagnostics))
       (cons 'runtime-executed (.ref checked-manifest 'runtime-executed))
       (cons 'metadata (.ref checked-manifest 'metadata))))))

;; : (-> [PooMemoryStoreSpec] (Cons [Symbol] Integer))
(def (poo-flow-memory-catalog-summary stores)
  (cons (map poo-flow-memory-store-spec-ref stores)
        (length stores)))

;; : (-> Symbol [PooMemoryStoreSpec] [Alist] PooMemoryCatalog)
(def (poo-flow-memory-catalog catalog-ref stores . maybe-metadata)
  (poo-flow-session-require "memory catalog ref must be a symbol"
                            (symbol? catalog-ref)
                            catalog-ref)
  (poo-flow-session-require "memory catalog stores must be specs"
                            (poo-flow-session-every? poo-flow-memory-store-spec?
                                                     stores)
                            stores)
  (let* ((catalog-summary (poo-flow-memory-catalog-summary stores))
         (store-refs (car catalog-summary))
         (store-count (cdr catalog-summary)))
    (object<-alist
     (list
      (cons 'kind +poo-flow-memory-core-catalog-kind+)
      (cons 'schema 'poo-flow.modules.memory-core.catalog.v1)
      (cons 'catalog-ref catalog-ref)
      (cons 'stores stores)
      (cons 'store-refs store-refs)
      (cons 'store-count store-count)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f)
      (cons 'metadata (if (null? maybe-metadata)
                        '()
                        (car maybe-metadata)))))))

;; : (-> POOObject Boolean)
(def (poo-flow-memory-catalog? value)
  (and (object? value)
       (eq? (poo-flow-memory-slot value 'kind #f)
            +poo-flow-memory-core-catalog-kind+)))

;; : (-> PooMemoryCatalog Symbol)
(def (poo-flow-memory-catalog-ref catalog)
  (.ref catalog 'catalog-ref))

;; : (-> PooMemoryCatalog [Symbol])
(def (poo-flow-memory-catalog-store-refs catalog)
  (.ref catalog 'store-refs))

;; : (-> PooMemoryCatalog Integer)
(def (poo-flow-memory-catalog-store-count catalog)
  (.ref catalog 'store-count))

;; : (-> [PooMemoryStoreSpec] Symbol MaybePooMemoryStoreSpec)
(def (poo-flow-memory-store-spec-find stores store-ref)
  (cond
   ((null? stores) #f)
   ((eq? (poo-flow-memory-store-spec-ref (car stores)) store-ref) (car stores))
   (else
    (poo-flow-memory-store-spec-find (cdr stores) store-ref))))

;; : (-> PooMemoryCatalog Symbol MaybePooMemoryStoreSpec)
(def (poo-flow-memory-catalog-find catalog store-ref)
  (poo-flow-memory-store-spec-find (.ref catalog 'stores) store-ref))

;; : (-> PooMemoryCatalog Alist)
(defpoo-module-final-projection
  poo-flow-memory-catalog->alist (catalog)
  (bindings ((checked-catalog
              (poo-flow-session-require
               "memory catalog projection requires a catalog"
               (poo-flow-memory-catalog? catalog)
               catalog))))
  (fields ((kind (.ref checked-catalog 'kind))
           (schema (.ref checked-catalog 'schema))
           (catalog-ref (.ref checked-catalog 'catalog-ref))
           (store-count (.ref checked-catalog 'store-count))
           (store-refs (.ref checked-catalog 'store-refs))
           (stores
            (poo-flow-memory-store-specs->alists
             (.ref checked-catalog 'stores)))
           (runtime-owner (.ref checked-catalog 'runtime-owner))
           (runtime-executed (.ref checked-catalog 'runtime-executed))
           (metadata (.ref checked-catalog 'metadata)))))

;; : (-> [MemoryProjectionValue] [MemoryProjectionValue] [MemoryProjectionValue])
(def (poo-flow-memory-reverse-onto values tail)
  (if (null? values)
    tail
    (poo-flow-memory-reverse-onto
     (cdr values)
     (cons (car values) tail))))

;; : (-> Symbol PooSessionMemoryIntent Alist)
(def (poo-flow-memory-diagnostic code intent)
  (poo-flow-memory-field-rows
   (kind 'poo-flow.memory-core.diagnostic)
   (schema 'poo-flow.modules.memory-core.diagnostic.v1)
   (code code)
   (intent-name (poo-flow-session-memory-intent-name intent))
   (store-ref (poo-flow-session-memory-intent-store-ref intent))
   (scope (poo-flow-session-memory-intent-scope intent))
   (commit-policy (poo-flow-session-memory-intent-commit-policy intent))
   (severity 'error)
   (runtime-executed #f)))

;; : (-> PooMemoryStoreSpec PooSessionMemoryIntent [Alist] [Alist])
(def (poo-flow-memory-store-intent-diagnostics/tail spec intent tail)
  (let ((scope (poo-flow-session-memory-intent-scope intent))
        (commit-policy
         (poo-flow-session-memory-intent-commit-policy intent))
        (recall-keys (poo-flow-session-memory-intent-recall intent)))
    (let* ((recall-tail
            (if (or (null? recall-keys)
                    (not (null? (poo-flow-memory-store-spec-recall-policies
                                 spec))))
              tail
              (cons (poo-flow-memory-diagnostic
                     'memory-store-recall-disabled
                     intent)
                    tail)))
           (commit-tail
            (if (member commit-policy
                        (poo-flow-memory-store-spec-commit-policies spec))
              recall-tail
              (cons (poo-flow-memory-diagnostic
                     'memory-intent-commit-denied
                     intent)
                    recall-tail))))
      (if (member scope (poo-flow-memory-store-spec-scopes spec))
        commit-tail
        (cons (poo-flow-memory-diagnostic 'memory-intent-scope-denied
                                          intent)
              commit-tail)))))

;; : (-> PooMemoryStoreSpec PooSessionMemoryIntent [Alist])
(def (poo-flow-memory-store-intent-diagnostics spec intent)
  (poo-flow-memory-store-intent-diagnostics/tail spec intent '()))

;; : (-> PooMemoryCatalog [PooSessionMemoryIntent] [Symbol] Integer [Symbol] [Symbol] [Symbol] [Alist] Alist)
(def (poo-flow-memory-policy-catalog-validation-summary-finish
      intent-count
      intent-store-refs-rev
      resolved-store-refs-rev
      unresolved-store-refs-rev
      diagnostics-rev)
  (list
   (cons 'intent-count intent-count)
   (cons 'intent-store-refs (reverse intent-store-refs-rev))
   (cons 'resolved-store-refs (reverse resolved-store-refs-rev))
   (cons 'unresolved-store-refs (reverse unresolved-store-refs-rev))
   (cons 'diagnostics (reverse diagnostics-rev))))

;; : (-> Object PooSessionMemoryIntent [Alist])
(def (poo-flow-memory-policy-catalog-intent-diagnostics spec intent)
  (if spec
    (poo-flow-memory-store-intent-diagnostics spec intent)
    (list (poo-flow-memory-diagnostic
           'memory-store-not-in-catalog
           intent))))

;; : (-> Boolean Symbol [Symbol] [Symbol])
(def (poo-flow-memory-policy-catalog-seen-store-refs already-seen?
                                                            store-ref
                                                            seen-store-refs)
  (if already-seen?
    seen-store-refs
    (cons store-ref seen-store-refs)))

;; : (-> Boolean Symbol [Symbol] [Symbol])
(def (poo-flow-memory-policy-catalog-intent-store-refs/rev already-seen?
                                                                  store-ref
                                                                  refs-rev)
  (if already-seen?
    refs-rev
    (cons store-ref refs-rev)))

;; : (-> Boolean Object Symbol [Symbol] [Symbol])
(def (poo-flow-memory-policy-catalog-resolved-store-refs/rev already-seen?
                                                                    spec
                                                                    store-ref
                                                                    refs-rev)
  (if (and (not already-seen?) spec)
    (cons store-ref refs-rev)
    refs-rev))

;; : (-> Boolean Object Symbol [Symbol] [Symbol])
(def (poo-flow-memory-policy-catalog-unresolved-store-refs/rev already-seen?
                                                                      spec
                                                                      store-ref
                                                                      refs-rev)
  (if (and (not already-seen?) (not spec))
    (cons store-ref refs-rev)
    refs-rev))

;; poo-flow-memory-policy-catalog-validation-summary/rev
;;   : (-> PooMemoryCatalog [PooSessionMemoryIntent] [Symbol] Integer [Symbol] [Symbol] [Symbol] [Alist] Alist)
;;   | doc m%
;;       Fold session memory intents against a memory catalog while preserving
;;       declaration order and diagnostic provenance. This helper owns the
;;       accumulator state for catalog validation; runtime recall, commit, and
;;       persistence stay outside Scheme.
;;       # Examples
;;       ```scheme
;;       (poo-flow-memory-policy-catalog-validation-summary/rev
;;        catalog intents '() 0 '() '() '() '())
;;       ```
;;       # Result
;;       A validation summary alist with intent, resolved-store, unresolved-store,
;;       and diagnostic rows.
;;     %
(def (poo-flow-memory-policy-catalog-validation-summary/rev catalog
                                                            memory-intents
                                                            seen-store-refs
                                                            intent-count
                                                            intent-store-refs-rev
                                                            resolved-store-refs-rev
                                                            unresolved-store-refs-rev
                                                            diagnostics-rev)
  (let loop ((remaining-intents memory-intents)
             (seen-store-refs seen-store-refs)
             (intent-count intent-count)
             (intent-store-refs-rev intent-store-refs-rev)
             (resolved-store-refs-rev resolved-store-refs-rev)
             (unresolved-store-refs-rev unresolved-store-refs-rev)
             (diagnostics-rev diagnostics-rev))
    (cond
     ((null? remaining-intents)
      (poo-flow-memory-policy-catalog-validation-summary-finish
       intent-count
       intent-store-refs-rev
       resolved-store-refs-rev
       unresolved-store-refs-rev
       diagnostics-rev))
     (else
      (let* ((intent (car remaining-intents))
             (store-ref
              (poo-flow-session-memory-intent-store-ref intent))
             (already-seen? (member store-ref seen-store-refs))
             (spec (poo-flow-memory-catalog-find catalog store-ref))
             (intent-diagnostics
              (poo-flow-memory-policy-catalog-intent-diagnostics
               spec
               intent)))
        (loop
         (cdr remaining-intents)
         (poo-flow-memory-policy-catalog-seen-store-refs
          already-seen?
          store-ref
          seen-store-refs)
         (+ intent-count 1)
         (poo-flow-memory-policy-catalog-intent-store-refs/rev
          already-seen?
          store-ref
          intent-store-refs-rev)
         (poo-flow-memory-policy-catalog-resolved-store-refs/rev
          already-seen?
          spec
          store-ref
          resolved-store-refs-rev)
         (poo-flow-memory-policy-catalog-unresolved-store-refs/rev
          already-seen?
          spec
          store-ref
          unresolved-store-refs-rev)
         (poo-flow-memory-reverse-onto intent-diagnostics
                                       diagnostics-rev)))))))

;; : (-> PooMemoryCatalog [PooSessionMemoryIntent] Alist)
(def (poo-flow-memory-policy-catalog-validation-summary catalog memory-intents)
  (poo-flow-memory-policy-catalog-validation-summary/rev
   catalog
   memory-intents
   '()
   0
   '()
   '()
   '()
   '()))

;; : (-> Symbol PooMemoryCatalog [PooSessionMemoryIntent] [Alist] PooMemoryPolicyCatalogValidationReceipt)
(def (poo-flow-memory-policy-catalog-validation-receipt validation-id
                                                        catalog
                                                        memory-intents
                                                        . maybe-metadata)
  (poo-flow-session-require "memory validation id must be a symbol"
                            (symbol? validation-id)
                            validation-id)
  (poo-flow-session-require "memory validation requires a catalog"
                            (poo-flow-memory-catalog? catalog)
                            catalog)
  (poo-flow-session-require "memory validation intents must be memory intents"
                            (poo-flow-session-every?
                             poo-flow-session-memory-intent?
                             memory-intents)
                            memory-intents)
  (let* ((validation-summary
          (poo-flow-memory-policy-catalog-validation-summary
           catalog
           memory-intents))
         (intent-count-value
          (poo-flow-session-alist-ref validation-summary 'intent-count 0))
         (intent-store-refs
          (poo-flow-session-alist-ref validation-summary
                                      'intent-store-refs
                                      '()))
         (resolved-store-refs
          (poo-flow-session-alist-ref validation-summary
                                      'resolved-store-refs
                                      '()))
         (unresolved-store-refs
          (poo-flow-session-alist-ref validation-summary
                                      'unresolved-store-refs
                                      '()))
         (diagnostics
          (poo-flow-session-alist-ref validation-summary 'diagnostics '())))
    (poo-flow-memory-runtime-object
     (poo-flow-memory-policy-catalog-validation-receipt->alist
      (make-poo-flow-memory-policy-validation-receipt-record
       +poo-flow-memory-core-policy-validation-receipt-kind+
       'poo-flow.modules.memory-core.policy-catalog-validation.v1
       validation-id
       (poo-flow-memory-catalog-ref catalog)
       (poo-flow-memory-catalog-store-count catalog)
       (poo-flow-memory-catalog-store-refs catalog)
       intent-count-value
       intent-store-refs
       resolved-store-refs
       unresolved-store-refs
       (null? diagnostics)
       (length diagnostics)
       diagnostics
       "marlin-agent-core"
       #f
       (if (null? maybe-metadata)
         '()
         (car maybe-metadata)))))))

;; : (-> POOObject Boolean)
(def (poo-flow-memory-policy-catalog-validation-receipt? value)
  (or (poo-flow-memory-policy-validation-receipt-record? value)
      (and (object? value)
           (eq? (poo-flow-memory-slot value 'kind #f)
                +poo-flow-memory-core-policy-validation-receipt-kind+))))

;; : (-> PooMemoryPolicyCatalogValidationReceipt Boolean)
(def (poo-flow-memory-policy-catalog-validation-receipt-valid? receipt)
  (if (poo-flow-memory-policy-validation-receipt-record? receipt)
    (poo-flow-memory-policy-validation-receipt-record-valid? receipt)
    (.ref receipt 'valid?)))

;; : (-> PooMemoryPolicyCatalogValidationReceipt [Alist])
(def (poo-flow-memory-policy-catalog-validation-receipt-diagnostics receipt)
  (if (poo-flow-memory-policy-validation-receipt-record? receipt)
    (poo-flow-memory-policy-validation-receipt-record-diagnostics receipt)
    (.ref receipt 'diagnostics)))

;; : (-> PooMemoryPolicyCatalogValidationReceipt Alist)
(def (poo-flow-memory-policy-catalog-validation-receipt->alist receipt)
  (let (checked-receipt
        (poo-flow-session-require
         "memory policy validation projection requires a validation receipt"
         (poo-flow-memory-policy-catalog-validation-receipt? receipt)
         receipt))
    (if (poo-flow-memory-policy-validation-receipt-record? checked-receipt)
      (list
       (cons 'kind
             (poo-flow-memory-policy-validation-receipt-record-kind checked-receipt))
       (cons 'schema
             (poo-flow-memory-policy-validation-receipt-record-schema checked-receipt))
       (cons 'validation-id
             (poo-flow-memory-policy-validation-receipt-record-validation-id checked-receipt))
       (cons 'catalog-ref
             (poo-flow-memory-policy-validation-receipt-record-catalog-ref checked-receipt))
       (cons 'catalog-store-count
             (poo-flow-memory-policy-validation-receipt-record-catalog-store-count checked-receipt))
       (cons 'catalog-store-refs
             (poo-flow-memory-policy-validation-receipt-record-catalog-store-refs checked-receipt))
       (cons 'intent-count
             (poo-flow-memory-policy-validation-receipt-record-intent-count checked-receipt))
       (cons 'intent-store-refs
             (poo-flow-memory-policy-validation-receipt-record-intent-store-refs checked-receipt))
       (cons 'resolved-store-refs
             (poo-flow-memory-policy-validation-receipt-record-resolved-store-refs checked-receipt))
       (cons 'unresolved-store-refs
             (poo-flow-memory-policy-validation-receipt-record-unresolved-store-refs checked-receipt))
       (cons 'valid?
             (poo-flow-memory-policy-validation-receipt-record-valid? checked-receipt))
       (cons 'diagnostic-count
             (poo-flow-memory-policy-validation-receipt-record-diagnostic-count checked-receipt))
       (cons 'diagnostics
             (poo-flow-memory-policy-validation-receipt-record-diagnostics checked-receipt))
       (cons 'runtime-owner
             (poo-flow-memory-policy-validation-receipt-record-runtime-owner checked-receipt))
       (cons 'runtime-executed
             (poo-flow-memory-policy-validation-receipt-record-runtime-executed checked-receipt))
       (cons 'metadata
             (poo-flow-memory-policy-validation-receipt-record-metadata checked-receipt)))
      (list
       (cons 'kind (.ref checked-receipt 'kind))
       (cons 'schema (.ref checked-receipt 'schema))
       (cons 'validation-id (.ref checked-receipt 'validation-id))
       (cons 'catalog-ref (.ref checked-receipt 'catalog-ref))
       (cons 'catalog-store-count (.ref checked-receipt 'catalog-store-count))
       (cons 'catalog-store-refs (.ref checked-receipt 'catalog-store-refs))
       (cons 'intent-count (.ref checked-receipt 'intent-count))
       (cons 'intent-store-refs (.ref checked-receipt 'intent-store-refs))
       (cons 'resolved-store-refs (.ref checked-receipt 'resolved-store-refs))
       (cons 'unresolved-store-refs
             (.ref checked-receipt 'unresolved-store-refs))
       (cons 'valid? (.ref checked-receipt 'valid?))
       (cons 'diagnostic-count (.ref checked-receipt 'diagnostic-count))
       (cons 'diagnostics (.ref checked-receipt 'diagnostics))
       (cons 'runtime-owner (.ref checked-receipt 'runtime-owner))
       (cons 'runtime-executed (.ref checked-receipt 'runtime-executed))
       (cons 'metadata (.ref checked-receipt 'metadata))))))

;; : (-> Symbol Boolean)
(def (poo-flow-memory-durable-job-kind? value)
  (and (symbol? value)
       (if (member value +poo-flow-memory-durable-job-kinds+) #t #f)))

;; : (-> Symbol Boolean)
(def (poo-flow-memory-durable-job-state? value)
  (and (symbol? value)
       (if (member value +poo-flow-memory-durable-job-states+) #t #f)))

;; : (-> Symbol Symbol Value Alist)
(def (poo-flow-memory-durable-job-diagnostic code slot value)
  (list (cons 'kind 'poo-flow.memory-core.durable-job.diagnostic)
        (cons 'schema 'poo-flow.modules.memory-core.durable-job.diagnostic.v1)
        (cons 'code code)
        (cons 'phase 'memory-durable-job)
        (cons 'slot slot)
        (cons 'value value)
        (cons 'severity 'error)
        (cons 'recoverable? #t)
        (cons 'runtime-executed #f)))

(def (poo-flow-memory-durable-job-diagnostic-prepend tail ok? code slot value)
  (if ok?
    tail
    (cons (poo-flow-memory-durable-job-diagnostic code slot value)
          tail)))

;; : (-> Symbol Symbol Value [Alist])
(def (poo-flow-memory-required-symbol-diagnostics/tail code slot value tail)
  (if (symbol? value)
    tail
    (cons (poo-flow-memory-durable-job-diagnostic code slot value)
          tail)))

;; : (-> Symbol Symbol Value [Alist])
(def (poo-flow-memory-required-symbol-diagnostics code slot value)
  (poo-flow-memory-required-symbol-diagnostics/tail code slot value '()))

;; : (-> Symbol [Alist] MaybeSymbol)
(def (poo-flow-memory-durable-policy-ref-from-options options)
  (let (durable-policy (poo-flow-memory-option options 'durable-policy #f))
    (cond
     ((poo-flow-durable-policy? durable-policy)
      (poo-flow-durable-policy-receipt-policy-id
       (poo-flow-durable-policy->receipt durable-policy)))
     (else
      (poo-flow-memory-option options 'durable-policy-ref #f)))))

;; : (-> PooMemoryStoreSpec PooSessionMemoryIntent [Alist])
(def (poo-flow-memory-durable-store-diagnostics spec intent)
  (poo-flow-memory-store-intent-diagnostics/tail
   spec
   intent
   (if (poo-flow-memory-slot spec 'durable? #f)
     '()
     (list (poo-flow-memory-diagnostic 'memory-store-not-durable
                                       intent)))))

;; : (-> PooMemoryCatalog PooSessionMemoryIntent [Alist])
(def (poo-flow-memory-durable-intent-diagnostics catalog intent)
  (let (spec
        (poo-flow-memory-catalog-find
         catalog
         (poo-flow-session-memory-intent-store-ref intent)))
    (if spec
      (poo-flow-memory-durable-store-diagnostics spec intent)
      (list (poo-flow-memory-diagnostic 'memory-store-not-in-catalog
                                        intent)))))

;;; Boundary: durable job diagnostics validate session memory intent and catalog
;;; evidence before any durable store operation is scheduled.
;; : (-> Symbol Symbol Symbol Symbol Symbol MaybeSymbol PooMemoryCatalog PooSessionMemoryIntent Alist [Alist])
(def (poo-flow-memory-durable-job-diagnostics job-kind
                                              job-state
                                              project-id
                                              root-session-id
                                              session-id
                                              agent-id
                                              catalog
                                              intent
                                              options)
  (let ((durable-policy-ref
         (poo-flow-memory-durable-policy-ref-from-options options))
        (job-store-ref
         (poo-flow-memory-option options 'job-store-ref 'runtime/job-store))
        (checkpoint-store-ref
         (poo-flow-memory-option options
                                 'checkpoint-store-ref
                                 'runtime/checkpoint-store))
        (usage-counter
         (poo-flow-memory-option options 'usage-counter 0)))
    (let* ((intent-tail
            (poo-flow-memory-durable-intent-diagnostics catalog intent))
           (usage-tail
            (poo-flow-memory-durable-job-diagnostic-prepend
             intent-tail
             (and (integer? usage-counter) (>= usage-counter 0))
             'invalid-usage-counter
             'usage-counter
             usage-counter))
           (checkpoint-tail
            (poo-flow-memory-required-symbol-diagnostics/tail
             'missing-checkpoint-store-ref
             'checkpoint-store-ref
             checkpoint-store-ref
             usage-tail))
           (job-store-tail
            (poo-flow-memory-required-symbol-diagnostics/tail
             'missing-job-store-ref
             'job-store-ref
             job-store-ref
             checkpoint-tail))
           (durable-policy-tail
            (poo-flow-memory-required-symbol-diagnostics/tail
             'missing-durable-policy-ref
             'durable-policy-ref
             durable-policy-ref
             job-store-tail))
           (agent-tail
            (poo-flow-memory-durable-job-diagnostic-prepend
             durable-policy-tail
             (or (symbol? agent-id) (not agent-id))
             'invalid-agent-id
             'agent-id
             agent-id))
           (session-tail
            (poo-flow-memory-required-symbol-diagnostics/tail
             'missing-session-id
             'session-id
             session-id
             agent-tail))
           (root-tail
            (poo-flow-memory-required-symbol-diagnostics/tail
             'missing-root-session-id
             'root-session-id
             root-session-id
             session-tail))
           (project-tail
            (poo-flow-memory-required-symbol-diagnostics/tail
             'missing-project-id
             'project-id
             project-id
             root-tail))
           (job-state-tail
            (poo-flow-memory-durable-job-diagnostic-prepend
             project-tail
             (poo-flow-memory-durable-job-state? job-state)
             'unsupported-memory-job-state
             'job-state
             job-state)))
      (poo-flow-memory-durable-job-diagnostic-prepend
       job-state-tail
       (poo-flow-memory-durable-job-kind? job-kind)
       'unsupported-memory-job-kind
       'job-kind
       job-kind))))

;; : PooMemoryDurableJobReceipt
(defstruct poo-flow-memory-durable-job-receipt
  (job-id
   job-kind
   job-state
   project-id
   root-session-id
   session-id
   agent-id
   store-ref
   durable-policy-ref
   job-store-ref
   checkpoint-store-ref
   source-ref
   source-watermark
   target-watermark
   stale-source?
   retry-policy
   retention-policy
   usage-counter
   scope
   recall
   commit-policy
   valid?
   diagnostics
   metadata
   runtime-owner
   handoff-required
   runtime-executed)
  transparent: #t)

;;; Boundary: durable job receipts materialize memory checkpoint intent as a
;;; policy-visible value without executing provider storage.
;; : (-> Symbol Symbol Symbol Symbol Symbol MaybeSymbol PooMemoryCatalog PooSessionMemoryIntent [Alist] PooMemoryDurableJobReceipt)
(def (poo-flow-memory-durable-job-receipt-from-intent job-id
                                                       job-kind
                                                       project-id
                                                       root-session-id
                                                       session-id
                                                       agent-id
                                                       catalog
                                                       intent
                                                       . maybe-options)
  (poo-flow-session-require "memory durable job id must be a symbol"
                            (symbol? job-id)
                            job-id)
  (poo-flow-session-require "memory durable job requires a catalog"
                            (poo-flow-memory-catalog? catalog)
                            catalog)
  (poo-flow-session-require "memory durable job requires a memory intent"
                            (poo-flow-session-memory-intent? intent)
                            intent)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (job-state (poo-flow-memory-option options 'job-state 'planned))
         (durable-policy-ref
          (poo-flow-memory-durable-policy-ref-from-options options))
         (job-store-ref
          (poo-flow-memory-option options 'job-store-ref 'runtime/job-store))
         (checkpoint-store-ref
          (poo-flow-memory-option options
                                  'checkpoint-store-ref
                                  'runtime/checkpoint-store))
         (source-ref
          (poo-flow-memory-option
           options
           'source-ref
           (poo-flow-session-memory-intent-name intent)))
         (source-watermark
          (poo-flow-memory-option options 'source-watermark #f))
         (target-watermark
          (poo-flow-memory-option options 'target-watermark #f))
         (stale-source?
          (poo-flow-memory-option options 'stale-source? #f))
         (retry-policy
          (poo-flow-memory-option options 'retry-policy 'retry/bounded))
         (retention-policy
          (poo-flow-memory-option options 'retention-policy 'retain/project))
         (usage-counter
          (poo-flow-memory-option options 'usage-counter 0))
         (metadata
          (poo-flow-memory-option options 'metadata '()))
         (diagnostics
          (poo-flow-memory-durable-job-diagnostics
           job-kind
           job-state
           project-id
           root-session-id
           session-id
           agent-id
           catalog
           intent
           options)))
    (make-poo-flow-memory-durable-job-receipt
     job-id
     job-kind
     job-state
     project-id
     root-session-id
     session-id
     agent-id
     (poo-flow-session-memory-intent-store-ref intent)
     durable-policy-ref
     job-store-ref
     checkpoint-store-ref
     source-ref
     source-watermark
     target-watermark
     stale-source?
     retry-policy
     retention-policy
     usage-counter
     (poo-flow-session-memory-intent-scope intent)
     (poo-flow-session-memory-intent-recall intent)
     (poo-flow-session-memory-intent-commit-policy intent)
     (null? diagnostics)
     diagnostics
     metadata
     "marlin-agent-core"
     #t
     #f)))

;; : (-> Symbol Symbol Symbol Symbol MaybeSymbol PooMemoryCatalog PooSessionMemoryIntent [Alist] PooMemoryDurableJobReceipt)
(def (poo-flow-memory-recall-job-receipt job-id
                                         project-id
                                         root-session-id
                                         session-id
                                         agent-id
                                         catalog
                                         intent
                                         . maybe-options)
  (apply poo-flow-memory-durable-job-receipt-from-intent
         job-id
         'recall
         project-id
         root-session-id
         session-id
         agent-id
         catalog
         intent
         maybe-options))

(def (poo-flow-memory-write-job-receipt job-id
                                        project-id
                                        root-session-id
                                        session-id
                                        agent-id
                                        catalog
                                        intent
                                        . maybe-options)
  (apply poo-flow-memory-durable-job-receipt-from-intent
         job-id
         'write
         project-id
         root-session-id
         session-id
         agent-id
         catalog
         intent
         maybe-options))

(def (poo-flow-memory-consolidation-job-receipt job-id
                                                project-id
                                                root-session-id
                                                session-id
                                                agent-id
                                                catalog
                                                intent
                                                . maybe-options)
  (apply poo-flow-memory-durable-job-receipt-from-intent
         job-id
         'consolidation
         project-id
         root-session-id
         session-id
         agent-id
         catalog
         intent
         maybe-options))

(def (poo-flow-memory-stale-source-job-receipt job-id
                                               project-id
                                               root-session-id
                                               session-id
                                               agent-id
                                               catalog
                                               intent
                                               . maybe-options)
  (apply poo-flow-memory-durable-job-receipt-from-intent
         job-id
         'stale-source
         project-id
         root-session-id
         session-id
         agent-id
         catalog
         intent
         maybe-options))

(def (poo-flow-memory-repair-job-receipt job-id
                                         project-id
                                         root-session-id
                                         session-id
                                         agent-id
                                         catalog
                                         intent
                                         . maybe-options)
  (apply poo-flow-memory-durable-job-receipt-from-intent
         job-id
         'repair
         project-id
         root-session-id
         session-id
         agent-id
         catalog
         intent
         maybe-options))

;; : (-> PooMemoryDurableJobReceipt Alist)
(defpoo-module-final-projection
  poo-flow-memory-durable-job-receipt->alist (receipt)
  (bindings ((checked-receipt
              (poo-flow-session-require
               "memory durable job projection requires a durable job receipt"
               (poo-flow-memory-durable-job-receipt? receipt)
               receipt))
             (diagnostics
              (poo-flow-memory-durable-job-receipt-diagnostics
               checked-receipt))))
  (fields ((kind +poo-flow-memory-core-durable-job-receipt-kind+)
           (schema 'poo-flow.modules.memory-core.durable-job-receipt.v1)
           (job-id
            (poo-flow-memory-durable-job-receipt-job-id checked-receipt))
           (job-kind
            (poo-flow-memory-durable-job-receipt-job-kind checked-receipt))
           (job-state
            (poo-flow-memory-durable-job-receipt-job-state checked-receipt))
           (project-id
            (poo-flow-memory-durable-job-receipt-project-id checked-receipt))
           (root-session-id
            (poo-flow-memory-durable-job-receipt-root-session-id
             checked-receipt))
           (session-id
            (poo-flow-memory-durable-job-receipt-session-id checked-receipt))
           (agent-id
            (poo-flow-memory-durable-job-receipt-agent-id checked-receipt))
           (store-ref
            (poo-flow-memory-durable-job-receipt-store-ref checked-receipt))
           (durable-policy-ref
            (poo-flow-memory-durable-job-receipt-durable-policy-ref
             checked-receipt))
           (job-store-ref
            (poo-flow-memory-durable-job-receipt-job-store-ref
             checked-receipt))
           (checkpoint-store-ref
            (poo-flow-memory-durable-job-receipt-checkpoint-store-ref
             checked-receipt))
           (source-ref
            (poo-flow-memory-durable-job-receipt-source-ref checked-receipt))
           (source-watermark
            (poo-flow-memory-durable-job-receipt-source-watermark
             checked-receipt))
           (target-watermark
            (poo-flow-memory-durable-job-receipt-target-watermark
             checked-receipt))
           (stale-source?
            (poo-flow-memory-durable-job-receipt-stale-source?
             checked-receipt))
           (retry-policy
            (poo-flow-memory-durable-job-receipt-retry-policy
             checked-receipt))
           (retention-policy
            (poo-flow-memory-durable-job-receipt-retention-policy
             checked-receipt))
           (usage-counter
            (poo-flow-memory-durable-job-receipt-usage-counter
             checked-receipt))
           (scope
            (poo-flow-memory-durable-job-receipt-scope checked-receipt))
           (recall
            (poo-flow-memory-durable-job-receipt-recall checked-receipt))
           (commit-policy
            (poo-flow-memory-durable-job-receipt-commit-policy
             checked-receipt))
           (valid?
            (poo-flow-memory-durable-job-receipt-valid? checked-receipt))
           (diagnostics diagnostics)
           (diagnostic-count (length diagnostics))
           (metadata
            (poo-flow-memory-durable-job-receipt-metadata checked-receipt))
           (runtime-owner
            (poo-flow-memory-durable-job-receipt-runtime-owner
             checked-receipt))
           (handoff-required
            (poo-flow-memory-durable-job-receipt-handoff-required
             checked-receipt))
           (runtime-executed
            (poo-flow-memory-durable-job-receipt-runtime-executed
             checked-receipt)))))

;; : (-> [PooMemoryDurableJobReceipt] [Alist])
(defpoo-module-final-projection-batch
  poo-flow-memory-durable-job-receipts->alists (receipts)
  (projector poo-flow-memory-durable-job-receipt->alist)
  (error-message "memory durable job receipt serialization requires a list"))

(def poo-flow-memory-core-local-session-store
  (poo-flow-memory-store-spec
   'memory/local-session
   'local-session
   'session
   '(current-session parent-summary)
   '(read-latest read-summary)
   '(none ephemeral)
   "marlin-agent-core"
   'memory/local-session-handoff
   #f
   'marlin-memory-adapter
   '((builtin . #t))))

(def poo-flow-memory-core-durable-project-store
  (poo-flow-memory-store-spec
   'memory/durable-project
   'durable-project
   'project
   '(current-session parent-summary project)
   '(semantic-search exact-key read-summary)
   '(append review-only)
   "marlin-agent-core"
   'memory/durable-project-handoff
   #t
   'marlin-memory-adapter
   '((builtin . #t))))

(def poo-flow-memory-core-default-catalog
  (poo-flow-memory-catalog
   'memory-core/default
   (list poo-flow-memory-core-local-session-store
         poo-flow-memory-core-durable-project-store)
   '((source . poo-flow-memory-core)
     (runtime-executed . #f))))
