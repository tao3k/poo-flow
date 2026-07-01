;;; -*- Gerbil -*-
;;; Boundary: report-only session transform objects.
;;; Invariant: transforms derive session values and handoff receipts; they never
;;; execute providers, tools, memory stores, selectors, or sandbox runtimes.

(import (only-in :gerbil/gambit fx+)
        (only-in :clan/poo/object .o .ref object? object<-alist)
        (only-in :std/sugar foldl)
        :poo-flow/src/modules/session/objects)

(export poo-flow-session-transform
        poo-flow-session-transform?
        poo-flow-session-transform-name
        poo-flow-session-transform-intent
        poo-flow-session-transform-description
        poo-flow-session-transform-capabilities
        poo-flow-session-transform-runtime-owner
        poo-flow-session-transform-metadata
        poo-flow-session-transform-memory-intents
        poo-flow-session-memory-intent
        poo-flow-session-memory-intent?
        poo-flow-session-memory-intent-name
        poo-flow-session-memory-intent-store-ref
        poo-flow-session-memory-intent-scope
        poo-flow-session-memory-intent-recall
        poo-flow-session-memory-intent-commit-policy
        poo-flow-session-memory-intent-runtime-owner
        poo-flow-session-memory-intent-metadata
        poo-flow-session-transform-apply
        poo-flow-session-transform-receipt?
        poo-flow-session-transform-receipt-derived-session
        poo-flow-session-transform-receipt-handoff-intent
        poo-flow-session-transform-receipt-memory-receipts
        poo-flow-session-memory-receipt?
        poo-flow-session-memory-receipt-name)

;; : (-> SessionMemoryKeyCandidate Boolean)
;; | type SessionMemoryKeyCandidate = (U Symbol String)
(def (poo-flow-session-memory-key? value)
  (or (symbol? value) (string? value)))

;; : (-> Symbol Alist Alist)
(def (poo-flow-session-transform-declaration-metadata/tail declared-by tail)
  (cons (cons 'declared-by declared-by)
        (cons (cons 'runtime-executed #f) tail)))

;; : (-> Symbol Alist Alist)
(def (poo-flow-session-transform-lineage-metadata/tail transform-name tail)
  (cons (cons 'transform-name transform-name)
        tail))

;; : (-> Symbol Symbol Fixnum Alist Alist)
(def (poo-flow-session-transform-derived-metadata/tail transform-name
                                                        source-session-id
                                                        memory-intent-count
                                                        tail)
  (cons (cons 'derived-by 'poo-flow-session-transform)
        (cons (cons 'transform-name transform-name)
              (cons (cons 'source-session-id source-session-id)
                    (cons (cons 'memory-intent-count memory-intent-count)
                          tail)))))

;;; A memory intent is a report-only request for a runtime memory backend. It is
;;; attached to session transforms but never recalls or commits data in Scheme.
;; : (-> Symbol Symbol Symbol [Symbol/String] Symbol [Alist] PooSessionMemoryIntent)
(def (poo-flow-session-memory-intent intent-name
                                     store-ref
                                     scope
                                     recall
                                     commit-policy
                                     . maybe-metadata)
  (poo-flow-session-require "session memory intent name must be a symbol"
                            (symbol? intent-name)
                            intent-name)
  (poo-flow-session-require "session memory store ref must be a symbol"
                            (symbol? store-ref)
                            store-ref)
  (poo-flow-session-require "session memory scope must be a symbol"
                            (symbol? scope)
                            scope)
  (poo-flow-session-require "session memory recall keys must be a list"
                            (list? recall)
                            recall)
  (poo-flow-session-require
   "session memory recall keys must be symbols or strings"
   (poo-flow-session-every? poo-flow-session-memory-key? recall)
   recall)
  (poo-flow-session-require "session memory commit policy must be a symbol"
                            (symbol? commit-policy)
                            commit-policy)
  (let ((metadata-value
         (poo-flow-session-transform-declaration-metadata/tail
          'poo-flow-session-memory-intent
          (if (null? maybe-metadata) '() (car maybe-metadata)))))
    (poo-flow-session-require "session memory metadata must be a list"
                              (list? metadata-value)
                              metadata-value)
    (list (cons 'kind 'poo-flow.session.memory-intent)
          (cons 'schema 'poo-flow.modules.session.memory-intent.v1)
          (cons 'intent-name intent-name)
          (cons 'store-ref store-ref)
          (cons 'scope scope)
          (cons 'recall recall)
          (cons 'commit-policy commit-policy)
          (cons 'runtime-owner "marlin-agent-core")
          (cons 'handoff-required #t)
          (cons 'descriptor-realized? #f)
          (cons 'runtime-executed #f)
          (cons 'metadata metadata-value))))

;;; Boundary: session memory intent ref is the policy-visible edge for policy
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> PooSessionMemoryIntent Symbol Value Value)
(def (poo-flow-session-memory-intent-ref intent key default)
  (if (object? intent)
    (.ref intent key)
    (poo-flow-session-alist-ref intent key default)))

;; : (-> SessionMemoryIntentCandidate Boolean)
;; | type SessionMemoryIntentCandidate = (U PooSessionMemoryIntent Alist POOObject)
(def (poo-flow-session-memory-intent? value)
  (or (and (object? value)
           (eq? (.ref value 'kind) 'poo-flow.session.memory-intent))
      (and (list? value)
           (eq? (poo-flow-session-alist-ref value 'kind #f)
                'poo-flow.session.memory-intent))))

;; : (-> PooSessionMemoryIntent Symbol)
(def (poo-flow-session-memory-intent-name intent)
  (poo-flow-session-memory-intent-ref intent 'intent-name #f))

;; : (-> PooSessionMemoryIntent Symbol)
(def (poo-flow-session-memory-intent-store-ref intent)
  (poo-flow-session-memory-intent-ref intent 'store-ref #f))

;; : (-> PooSessionMemoryIntent Symbol)
(def (poo-flow-session-memory-intent-scope intent)
  (poo-flow-session-memory-intent-ref intent 'scope #f))

;; : (-> PooSessionMemoryIntent [Symbol/String])
(def (poo-flow-session-memory-intent-recall intent)
  (poo-flow-session-memory-intent-ref intent 'recall '()))

;; : (-> PooSessionMemoryIntent Symbol)
(def (poo-flow-session-memory-intent-commit-policy intent)
  (poo-flow-session-memory-intent-ref intent 'commit-policy #f))

;; : (-> PooSessionMemoryIntent String)
(def (poo-flow-session-memory-intent-runtime-owner intent)
  (poo-flow-session-memory-intent-ref intent 'runtime-owner "marlin-agent-core"))

;; : (-> PooSessionMemoryIntent Alist)
(def (poo-flow-session-memory-intent-metadata intent)
  (poo-flow-session-memory-intent-ref intent 'metadata '()))

;; : (-> PooSessionMemoryIntent Alist)
(def (poo-flow-session-memory-intent-handoff intent)
  (list
   (cons 'kind 'poo-flow.session.memory-intent.handoff)
   (cons 'schema 'poo-flow.modules.session.memory-intent.handoff.v1)
   (cons 'intent-name (poo-flow-session-memory-intent-name intent))
   (cons 'store-ref (poo-flow-session-memory-intent-store-ref intent))
   (cons 'scope (poo-flow-session-memory-intent-scope intent))
   (cons 'recall (poo-flow-session-memory-intent-recall intent))
   (cons 'commit-policy
         (poo-flow-session-memory-intent-commit-policy intent))
   (cons 'runtime-owner
         (poo-flow-session-memory-intent-runtime-owner intent))
   (cons 'handoff-required #t)
   (cons 'descriptor-realized? #f)
   (cons 'runtime-executed #f)))

;; poo-flow-session-memory-intent-handoff-bundle
;;   : (-> [PooSessionMemoryIntent] (Cons [Alist] Fixnum))
;;   | doc m%
;;       Project memory intents into report-only handoff rows while returning
;;       the row count in the same public bundle protocol.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-session-memory-intent-handoff-bundle intents)
;;       ;; => (handoff-rows . count)
;;       ```
;;     %
;; : (-> [PooSessionMemoryIntent] (Cons [Alist] Fixnum))
(def (poo-flow-session-memory-intent-handoff-bundle memory-intents)
  (let (bundle
        (foldl (lambda (intent result)
                 (cons (cons (poo-flow-session-memory-intent-handoff intent)
                             (car result))
                       (fx+ (cdr result) 1)))
               (cons '() 0)
               memory-intents))
    (cons (reverse (car bundle)) (cdr bundle))))

;; poo-flow-session-memory-intent-count
;;   : (-> [PooSessionMemoryIntent] Fixnum)
;;   | doc m%
;;       Return the cardinality of memory intents when callers do not need to
;;       allocate handoff rows.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-session-memory-intent-count intents)
;;       ;; => count
;;       ```
;;     %
;; : (-> [PooSessionMemoryIntent] Fixnum)
(def (poo-flow-session-memory-intent-count memory-intents)
  (length memory-intents))

;; : (-> [PooSessionTransformOption] (Cons Alist [PooSessionMemoryIntent]))
;; | type PooSessionTransformOption = (U Alist PooSessionMemoryIntent)
(def (poo-flow-session-transform-options options)
  (cond
   ((null? options)
    (cons '() '()))
   ((null? (cdr options))
    (let ((option (car options)))
      (if (and (list? option)
               (poo-flow-session-every? poo-flow-session-memory-intent?
                                         option))
          (cons '() option)
          (cons option '()))))
   ((null? (cddr options))
    (cons (car options) (cadr options)))
   (else
    (poo-flow-session-require
     "session transform accepts at most metadata and memory intents"
     #f
     options))))

;;; A transform is an agent-flow layer spec. It is intentionally inert: provider
;;; prompts and runtime calls become handoff intent, not Scheme execution.
;; : (-> Symbol Symbol String [Symbol] [Alist] PooSessionTransform)
(def (poo-flow-session-transform transform-name
                                 intent
                                 description
                                 capabilities
                                 . options)
  (poo-flow-session-require "session transform name must be a symbol"
                            (symbol? transform-name)
                            transform-name)
  (poo-flow-session-require "session transform intent must be a symbol"
                            (symbol? intent)
                            intent)
  (poo-flow-session-require "session transform description must be a string"
                            (string? description)
                            description)
  (poo-flow-session-require "session transform capabilities must be a list"
                            (list? capabilities)
                            capabilities)
  (poo-flow-session-require
   "session transform capabilities must contain only symbols"
   (poo-flow-session-every? symbol? capabilities)
   capabilities)
  (let* ((split-options (poo-flow-session-transform-options options))
         (transform-name-value transform-name)
         (intent-value intent)
         (description-value description)
         (capability-values capabilities)
         (metadata-value
          (poo-flow-session-transform-declaration-metadata/tail
           'poo-flow-session-transform
           (car split-options)))
         (memory-intents-value (cdr split-options)))
    (poo-flow-session-require "session transform metadata must be a list"
                              (list? metadata-value)
                              metadata-value)
    (poo-flow-session-require "session transform memory intents must be a list"
                              (list? memory-intents-value)
                              memory-intents-value)
    (poo-flow-session-require
     "session transform memory intents must contain only memory intents"
     (poo-flow-session-every? poo-flow-session-memory-intent?
                              memory-intents-value)
     memory-intents-value)
    (object<-alist
     (list
      (cons 'kind 'poo-flow.session.transform)
      (cons 'schema 'poo-flow.modules.session.transform.v1)
      (cons 'transform-name transform-name-value)
      (cons 'intent intent-value)
      (cons 'description description-value)
      (cons 'capabilities capability-values)
      (cons 'memory-intents memory-intents-value)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'handoff-required #t)
      (cons 'descriptor-realized? #f)
      (cons 'runtime-executed #f)
      (cons 'metadata metadata-value)))))

;; : (-> POOObject Boolean)
(def (poo-flow-session-transform? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.session.transform)))

;; : (-> PooSessionTransform Symbol)
(def (poo-flow-session-transform-name transform)
  (.ref transform 'transform-name))

;; : (-> PooSessionTransform Symbol)
(def (poo-flow-session-transform-intent transform)
  (.ref transform 'intent))

;; : (-> PooSessionTransform String)
(def (poo-flow-session-transform-description transform)
  (.ref transform 'description))

;; : (-> PooSessionTransform [Symbol])
(def (poo-flow-session-transform-capabilities transform)
  (.ref transform 'capabilities))

;; : (-> PooSessionTransform String)
(def (poo-flow-session-transform-runtime-owner transform)
  (.ref transform 'runtime-owner))

;; : (-> PooSessionTransform Alist)
(def (poo-flow-session-transform-metadata transform)
  (.ref transform 'metadata))

;; : (-> PooSessionTransform [PooSessionMemoryIntent])
(def (poo-flow-session-transform-memory-intents transform)
  (.ref transform 'memory-intents))

;;; Handoff intent is the runtime-facing summary. It is plain data so Marlin can
;;; consume it without traversing nested POO objects.
;; : (-> PooSessionTransform PooSession PooSession Alist)
(def (poo-flow-session-transform-handoff-intent transform
                                                source-session
                                                derived-session)
  (let* ((memory-intents-value
          (poo-flow-session-transform-memory-intents transform))
         (memory-handoff-bundle
          (poo-flow-session-memory-intent-handoff-bundle
           memory-intents-value))
         (derived-placement-value
          (poo-flow-session-value-placement derived-session)))
    (list
     (cons 'kind 'poo-flow.session.transform.handoff-intent)
     (cons 'schema 'poo-flow.modules.session.transform.handoff-intent.v1)
     (cons 'transform-name (poo-flow-session-transform-name transform))
     (cons 'intent (poo-flow-session-transform-intent transform))
     (cons 'source-session-id (poo-flow-session-id source-session))
     (cons 'derived-session-id (poo-flow-session-id derived-session))
     (cons 'capabilities (poo-flow-session-transform-capabilities transform))
     (cons 'memory-intents (car memory-handoff-bundle))
     (cons 'memory-intent-count (cdr memory-handoff-bundle))
     (cons 'placement-profile-ref
           (poo-flow-session-placement-profile-ref
            derived-placement-value))
     (cons 'placement-resolved?
           (poo-flow-session-placement-resolved?
            derived-placement-value))
     (cons 'runtime-owner (poo-flow-session-transform-runtime-owner transform))
     (cons 'handoff-required #t)
     (cons 'descriptor-realized? #f)
     (cons 'runtime-executed #f))))

;;; Runtime memory effects stay behind the handoff. The receipt records what
;;; would be recalled or committed by the runtime owner.
;; : (-> PooSessionMemoryIntent PooSessionTransform PooSession PooSession PooSessionMemoryReceipt)
(def (poo-flow-session-memory-receipt-row memory-intent
                                          transform
                                          source-session
                                          derived-session)
  (list
   (cons 'kind 'poo-flow.session.memory.receipt)
   (cons 'schema 'poo-flow.modules.session.memory.receipt.v1)
   (cons 'intent-name (poo-flow-session-memory-intent-name memory-intent))
   (cons 'store-ref (poo-flow-session-memory-intent-store-ref memory-intent))
   (cons 'scope (poo-flow-session-memory-intent-scope memory-intent))
   (cons 'recall (poo-flow-session-memory-intent-recall memory-intent))
   (cons 'commit-policy (poo-flow-session-memory-intent-commit-policy
                         memory-intent))
   (cons 'transform-name (poo-flow-session-transform-name transform))
   (cons 'source-session-id (poo-flow-session-id source-session))
   (cons 'derived-session-id (poo-flow-session-id derived-session))
   (cons 'runtime-owner (poo-flow-session-memory-intent-runtime-owner
                         memory-intent))
   (cons 'handoff-required #t)
   (cons 'descriptor-realized? #f)
   (cons 'runtime-executed #f)
   (cons 'metadata (poo-flow-session-memory-intent-metadata memory-intent))))

;; poo-flow-session-memory-receipt-row-bundle
;;   : (-> [PooSessionMemoryIntent] PooSessionTransform PooSession PooSession (Cons [Alist] Fixnum))
;;   | doc m%
;;       Project memory intents into receipt rows for a derived session and
;;       return the row count with the same bundle protocol.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-session-memory-receipt-row-bundle intents transform source derived)
;;       ;; => (receipt-rows . count)
;;       ```
;;     %
;; : (-> [PooSessionMemoryIntent] PooSessionTransform PooSession PooSession (Cons [Alist] Fixnum))
(def (poo-flow-session-memory-receipt-row-bundle memory-intents
                                                 transform
                                                 source-session
                                                 derived-session)
  (let (bundle
        (foldl (lambda (memory-intent result)
                 (cons
                  (cons (poo-flow-session-memory-receipt-row
                         memory-intent
                         transform
                         source-session
                         derived-session)
                        (car result))
                  (fx+ (cdr result) 1)))
               (cons '() 0)
               memory-intents))
    (cons (reverse (car bundle)) (cdr bundle))))

;; : (-> Alist PooSessionMemoryReceipt)
(def (poo-flow-session-memory-receipt-row->object row)
  (object<-alist
   (list
    (cons 'kind (poo-flow-session-alist-ref row 'kind #f))
    (cons 'schema (poo-flow-session-alist-ref row 'schema #f))
    (cons 'intent-name (poo-flow-session-alist-ref row 'intent-name #f))
    (cons 'store-ref (poo-flow-session-alist-ref row 'store-ref #f))
    (cons 'scope (poo-flow-session-alist-ref row 'scope #f))
    (cons 'recall (poo-flow-session-alist-ref row 'recall '()))
    (cons 'commit-policy
          (poo-flow-session-alist-ref row 'commit-policy #f))
    (cons 'transform-name
          (poo-flow-session-alist-ref row 'transform-name #f))
    (cons 'source-session-id
          (poo-flow-session-alist-ref row 'source-session-id #f))
    (cons 'derived-session-id
          (poo-flow-session-alist-ref row 'derived-session-id #f))
    (cons 'runtime-owner
          (poo-flow-session-alist-ref row 'runtime-owner
                                      "marlin-agent-core"))
    (cons 'handoff-required
          (poo-flow-session-alist-ref row 'handoff-required #t))
    (cons 'descriptor-realized?
          (poo-flow-session-alist-ref row 'descriptor-realized? #f))
    (cons 'runtime-executed
          (poo-flow-session-alist-ref row 'runtime-executed #f))
    (cons 'metadata (poo-flow-session-alist-ref row 'metadata '())))))

;; : (-> PooSessionMemoryIntent PooSessionTransform PooSession PooSession PooSessionMemoryReceipt)
(def (poo-flow-session-memory-receipt memory-intent
                                      transform
                                      source-session
                                      derived-session)
  (poo-flow-session-memory-receipt-row->object
   (poo-flow-session-memory-receipt-row
    memory-intent
    transform
    source-session
    derived-session)))

;; : (-> [Alist] [PooSessionMemoryReceipt])
(def (poo-flow-session-memory-receipt-rows->objects rows)
  (cond
   ((null? rows) '())
   (else
    (cons (poo-flow-session-memory-receipt-row->object (car rows))
          (poo-flow-session-memory-receipt-rows->objects (cdr rows))))))

;;; Apply a transform in the control plane. The output is a receipt object with
;;; an inspectable derived session; runtime providers still receive only the
;;; handoff intent.
;; : (-> PooSessionTransform PooSession Symbol [PooSessionChunk] [Alist] PooSessionTransformReceipt)
(def (poo-flow-session-transform-apply transform
                                       source-session
                                       derived-session-id
                                       chunks
                                       . maybe-metadata)
  (poo-flow-session-require "session transform apply requires a transform"
                            (poo-flow-session-transform? transform)
                            transform)
  (poo-flow-session-require "session transform apply requires a session"
                            (poo-flow-session? source-session)
                            source-session)
  (poo-flow-session-require "derived session id must be a symbol"
                            (symbol? derived-session-id)
                            derived-session-id)
  (poo-flow-session-require "derived session chunks must be a list"
                            (list? chunks)
                            chunks)
  (poo-flow-session-require
   "derived session chunks must contain only session chunks"
   (poo-flow-session-every? poo-flow-session-chunk? chunks)
   chunks)
  (let* ((metadata-value
          (if (null? maybe-metadata) '() (car maybe-metadata)))
         (source-session-id-value (poo-flow-session-id source-session))
         (derived-session-id-value derived-session-id)
         (memory-intents-value
          (poo-flow-session-transform-memory-intents transform))
         (memory-intent-count-value
          (poo-flow-session-memory-intent-count memory-intents-value))
         (transform-name-value
          (poo-flow-session-transform-name transform))
         (transform-intent-value
          (poo-flow-session-transform-intent transform))
         (transform-runtime-owner-value
          (poo-flow-session-transform-runtime-owner transform))
         (source-placement-value
          (poo-flow-session-value-placement source-session))
         (source-chunk-count-value
          (length (poo-flow-session-chunks source-session)))
         (derived-chunk-count-value
          (length chunks))
         (derived-session-value
          (poo-flow-session-value
           derived-session-id-value
           chunks
           (poo-flow-session-lineage
            derived-session-id-value
            (list source-session-id-value)
            'transform
            (poo-flow-session-transform-lineage-metadata/tail
             transform-name-value
             metadata-value))
           source-placement-value
           (poo-flow-session-transform-derived-metadata/tail
            transform-name-value
            source-session-id-value
            memory-intent-count-value
            metadata-value)))
         (handoff-intent-value
          (poo-flow-session-transform-handoff-intent
           transform
           source-session
           derived-session-value))
         (derived-placement-value
          (poo-flow-session-value-placement derived-session-value))
         (memory-receipt-bundle
          (poo-flow-session-memory-receipt-row-bundle
           memory-intents-value
           transform
           source-session
           derived-session-value))
         (memory-receipts-value (car memory-receipt-bundle))
         (memory-receipt-count-value (cdr memory-receipt-bundle)))
    (object<-alist
     (list
      (cons 'kind 'poo-flow.session.transform.receipt)
      (cons 'schema 'poo-flow.modules.session.transform.receipt.v1)
      (cons 'transform-name transform-name-value)
      (cons 'transform-intent transform-intent-value)
      (cons 'source-session-id source-session-id-value)
      (cons 'derived-session-id derived-session-id-value)
      (cons 'parent-session-ids (list source-session-id-value))
      (cons 'derived-session-chunks chunks)
      (cons 'derived-session-metadata
            (poo-flow-session-metadata derived-session-value))
      (cons 'derived-session-branch-kind 'transform)
      (cons 'placement-profile-ref
            (poo-flow-session-placement-profile-ref
             derived-placement-value))
      (cons 'placement-resolved?
            (poo-flow-session-placement-resolved?
             derived-placement-value))
      (cons 'placement-diagnostics
            (poo-flow-session-placement-diagnostics
             derived-placement-value))
      (cons 'placement-runtime-summary
            (poo-flow-session-placement-runtime-summary
             derived-placement-value))
      (cons 'placement-handoff-summary
            (poo-flow-session-placement-handoff-summary
             derived-placement-value))
      (cons 'placement-metadata
            (.ref derived-placement-value 'placement-metadata))
      (cons 'source-chunk-count source-chunk-count-value)
      (cons 'derived-chunk-count derived-chunk-count-value)
      (cons 'handoff-intent handoff-intent-value)
      (cons 'memory-receipts memory-receipts-value)
      (cons 'memory-receipt-count memory-receipt-count-value)
      (cons 'runtime-owner transform-runtime-owner-value)
      (cons 'handoff-required #t)
      (cons 'descriptor-realized? #f)
      (cons 'runtime-executed #f)
      (cons 'metadata metadata-value)))))

;; : (-> POOObject Boolean)
(def (poo-flow-session-transform-receipt? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.session.transform.receipt)))

;; : (-> PooSessionTransformReceipt PooSession)
(def (poo-flow-session-transform-receipt-derived-session receipt)
  (let ((derived-session-id (.ref receipt 'derived-session-id))
        (parent-session-ids (.ref receipt 'parent-session-ids)))
    (poo-flow-session-value
     derived-session-id
     (.ref receipt 'derived-session-chunks)
     (poo-flow-session-lineage
      derived-session-id
      parent-session-ids
      (.ref receipt 'derived-session-branch-kind))
     (.o placement-kind: 'poo-flow.session.placement
         placement-schema: 'poo-flow.modules.session.placement.v1
         placement-profile-ref: (.ref receipt 'placement-profile-ref)
         placement-resolved?: (.ref receipt 'placement-resolved?)
         placement-diagnostics: (.ref receipt 'placement-diagnostics)
         placement-runtime-summary: (.ref receipt 'placement-runtime-summary)
         placement-handoff-summary: (.ref receipt 'placement-handoff-summary)
         placement-metadata: (.ref receipt 'placement-metadata)
         placement-runtime-executed: #f)
     (.ref receipt 'derived-session-metadata))))

;; : (-> PooSessionTransformReceipt Alist)
(def (poo-flow-session-transform-receipt-handoff-intent receipt)
  (.ref receipt 'handoff-intent))

;; poo-flow-session-transform-receipt-memory-receipts
;;   : (-> PooSessionTransformReceipt [PooSessionMemoryReceipt])
;;   | doc m%
;;       Materialize receipt rows from an inert transform receipt as POO memory
;;       receipt objects for downstream inspection.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-session-transform-receipt-memory-receipts receipt)
;;       ;; => memory-receipt-objects
;;       ```
;;     %
;; : (-> PooSessionTransformReceipt [PooSessionMemoryReceipt])
(def (poo-flow-session-transform-receipt-memory-receipts receipt)
  (poo-flow-session-memory-receipt-rows->objects
   (.ref receipt 'memory-receipts)))

;; : (-> POOObject Boolean)
(def (poo-flow-session-memory-receipt? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.session.memory.receipt)))

;; : (-> PooSessionMemoryReceipt Symbol)
(def (poo-flow-session-memory-receipt-name receipt)
  (.ref receipt 'intent-name))
