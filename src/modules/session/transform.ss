;;; -*- Gerbil -*-
;;; Boundary: report-only session transform objects.
;;; Invariant: transforms derive session values and handoff receipts; they never
;;; execute providers, tools, memory stores, selectors, or sandbox runtimes.

(import (only-in :clan/poo/object .o .ref object?)
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

;; : (-> Value Boolean)
(def (poo-flow-session-memory-key? value)
  (or (symbol? value) (string? value)))

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
         (append '((declared-by . poo-flow-session-memory-intent)
                   (runtime-executed . #f))
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

;; : (-> PooSessionMemoryIntent Symbol Value Value)
(def (poo-flow-session-memory-intent-ref intent key default)
  (if (object? intent)
    (.ref intent key)
    (poo-flow-session-alist-ref intent key default)))

;; : (-> Value Boolean)
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

;; : (-> [Any] (Cons Alist [PooSessionMemoryIntent]))
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
          (append '((declared-by . poo-flow-session-transform)
                    (runtime-executed . #f))
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
    (.o kind: 'poo-flow.session.transform
        schema: 'poo-flow.modules.session.transform.v1
        transform-name: transform-name-value
        intent: intent-value
        description: description-value
        capabilities: capability-values
        memory-intents: memory-intents-value
        runtime-owner: "marlin-agent-core"
        handoff-required: #t
        descriptor-realized?: #f
        runtime-executed: #f
        metadata: metadata-value)))

;; : (-> Value Boolean)
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
  (list
   (cons 'kind 'poo-flow.session.transform.handoff-intent)
   (cons 'schema 'poo-flow.modules.session.transform.handoff-intent.v1)
   (cons 'transform-name (poo-flow-session-transform-name transform))
   (cons 'intent (poo-flow-session-transform-intent transform))
   (cons 'source-session-id (poo-flow-session-id source-session))
   (cons 'derived-session-id (poo-flow-session-id derived-session))
   (cons 'capabilities (poo-flow-session-transform-capabilities transform))
   (cons 'memory-intents
         (map poo-flow-session-memory-intent-handoff
              (poo-flow-session-transform-memory-intents transform)))
   (cons 'memory-intent-count
         (length (poo-flow-session-transform-memory-intents transform)))
   (cons 'placement-profile-ref
         (poo-flow-session-placement-profile-ref
          (poo-flow-session-value-placement derived-session)))
   (cons 'placement-resolved?
         (poo-flow-session-placement-resolved?
          (poo-flow-session-value-placement derived-session)))
   (cons 'runtime-owner (poo-flow-session-transform-runtime-owner transform))
   (cons 'handoff-required #t)
   (cons 'descriptor-realized? #f)
   (cons 'runtime-executed #f)))

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

;; : (-> Alist PooSessionMemoryReceipt)
(def (poo-flow-session-memory-receipt-row->object row)
  (.o kind: (poo-flow-session-alist-ref row 'kind #f)
      schema: (poo-flow-session-alist-ref row 'schema #f)
      intent-name: (poo-flow-session-alist-ref row 'intent-name #f)
      store-ref: (poo-flow-session-alist-ref row 'store-ref #f)
      scope: (poo-flow-session-alist-ref row 'scope #f)
      recall: (poo-flow-session-alist-ref row 'recall '())
      commit-policy: (poo-flow-session-alist-ref row 'commit-policy #f)
      transform-name: (poo-flow-session-alist-ref row 'transform-name #f)
      source-session-id: (poo-flow-session-alist-ref row 'source-session-id #f)
      derived-session-id: (poo-flow-session-alist-ref row 'derived-session-id #f)
      runtime-owner: (poo-flow-session-alist-ref row 'runtime-owner
                                                 "marlin-agent-core")
      handoff-required: (poo-flow-session-alist-ref row 'handoff-required #t)
      descriptor-realized?: (poo-flow-session-alist-ref
                             row 'descriptor-realized? #f)
      runtime-executed: (poo-flow-session-alist-ref row 'runtime-executed #f)
      metadata: (poo-flow-session-alist-ref row 'metadata '())))

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
         (derived-session-value
          (poo-flow-session-value
           derived-session-id-value
           chunks
           (poo-flow-session-lineage
            derived-session-id-value
            (list source-session-id-value)
            'transform
            (append
             (list (cons 'transform-name
                         (poo-flow-session-transform-name transform)))
             metadata-value))
           (poo-flow-session-value-placement source-session)
           (append
            (list (cons 'derived-by 'poo-flow-session-transform)
                  (cons 'transform-name
                        (poo-flow-session-transform-name transform))
                  (cons 'source-session-id source-session-id-value)
                  (cons 'memory-intent-count
                        (length memory-intents-value)))
            metadata-value)))
         (handoff-intent-value
          (poo-flow-session-transform-handoff-intent
           transform
           source-session
           derived-session-value))
         (derived-placement-value
          (poo-flow-session-value-placement derived-session-value))
         (memory-receipts-value
          (map (lambda (memory-intent)
                 (poo-flow-session-memory-receipt-row
                  memory-intent
                  transform
                  source-session
                  derived-session-value))
               memory-intents-value)))
    (.o kind: 'poo-flow.session.transform.receipt
        schema: 'poo-flow.modules.session.transform.receipt.v1
        transform-name: (poo-flow-session-transform-name transform)
        transform-intent: (poo-flow-session-transform-intent transform)
        source-session-id: source-session-id-value
        derived-session-id: derived-session-id-value
        parent-session-ids: (list source-session-id-value)
        derived-session-chunks: chunks
        derived-session-metadata:
        (poo-flow-session-metadata derived-session-value)
        derived-session-branch-kind: 'transform
        placement-profile-ref:
        (poo-flow-session-placement-profile-ref
         derived-placement-value)
        placement-resolved?:
        (poo-flow-session-placement-resolved?
         derived-placement-value)
        placement-diagnostics:
        (poo-flow-session-placement-diagnostics
         derived-placement-value)
        placement-runtime-summary:
        (poo-flow-session-placement-runtime-summary
         derived-placement-value)
        placement-handoff-summary:
        (poo-flow-session-placement-handoff-summary
         derived-placement-value)
        placement-metadata:
        (.ref derived-placement-value 'placement-metadata)
        source-chunk-count: (length (poo-flow-session-chunks source-session))
        derived-chunk-count: (length chunks)
        handoff-intent: handoff-intent-value
        memory-receipts: memory-receipts-value
        memory-receipt-count: (length memory-receipts-value)
        runtime-owner: (poo-flow-session-transform-runtime-owner transform)
        handoff-required: #t
        descriptor-realized?: #f
        runtime-executed: #f
        metadata: metadata-value)))

;; : (-> Value Boolean)
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

;; : (-> PooSessionTransformReceipt [PooSessionMemoryReceipt])
(def (poo-flow-session-transform-receipt-memory-receipts receipt)
  (map poo-flow-session-memory-receipt-row->object
       (.ref receipt 'memory-receipts)))

;; : (-> Value Boolean)
(def (poo-flow-session-memory-receipt? value)
  (and (object? value)
       (eq? (.ref value 'kind) 'poo-flow.session.memory.receipt)))

;; : (-> PooSessionMemoryReceipt Symbol)
(def (poo-flow-session-memory-receipt-name receipt)
  (.ref receipt 'intent-name))
