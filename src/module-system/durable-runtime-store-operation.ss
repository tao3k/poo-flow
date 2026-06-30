;;; -*- Gerbil -*-
;;; Boundary: durable runtime store operation receipts for Marlin handoff.
;;; Invariant: Scheme projects operation intent only; Rust/Marlin owns append,
;;; fsync, checkpoint IO, index rebuild, leases, and repair side effects.

(import (only-in :poo-flow/src/core/runtime-adapter
                 +runtime-request-schema+
                 make-runtime-command-descriptor
                 runtime-command-descriptor->manifest)
        :poo-flow/src/module-system/durable-runtime-store-backend)

(export +poo-flow-durable-runtime-store-operation-receipt-kind+
        +poo-flow-durable-runtime-store-operation-receipt-schema+
        +poo-flow-durable-runtime-store-operation-handoff-schema+
        +poo-flow-durable-runtime-store-operation-specs+
        make-poo-flow-durable-runtime-store-operation-receipt
        poo-flow-durable-runtime-store-operation-receipt?
        poo-flow-durable-runtime-store-operation-receipt-valid?
        poo-flow-durable-runtime-store-operation-receipt-diagnostics
        poo-flow-durable-runtime-store-operation
        poo-flow-durable-runtime-store-operation-receipts
        poo-flow-durable-runtime-store-operation-receipt->alist
        poo-flow-durable-runtime-store-operation-receipts->alists
        poo-flow-durable-runtime-store-operations->marlin-handoff)

(def +poo-flow-durable-runtime-store-operation-receipt-kind+
  'poo-flow.durable.runtime-store-operation-receipt)

(def +poo-flow-durable-runtime-store-operation-receipt-schema+
  'poo-flow.module-system.durable-runtime-store-operation.receipt.v1)

(def +poo-flow-durable-runtime-store-operation-handoff-schema+
  'poo-flow.module-system.durable-runtime-store-operation.marlin-handoff.v1)

;; OperationSpec = (Kind LedgerKind CapabilityFlag TargetSlot)
(def +poo-flow-durable-runtime-store-operation-specs+
  '((append-fact fact-log append-fact fact-log-ref)
    (write-checkpoint checkpoint write-checkpoint checkpoint-store-ref)
    (rebuild-index derived-index rebuild-index derived-index-ref)
    (claim-job-lease job claim-job-lease job-store-ref)
    (append-repair-event repair append-repair-event repair-journal-ref)
    (retain-artifact artifact retain-artifact artifact-store-ref)
    (append-communication-event
     communication append-communication-event communication-ledger-ref)
    (attach-sandbox-handle sandbox attach-sandbox-handle sandbox-ledger-ref)))

;; : (-> Alist Symbol Value Value)
(def (durable-runtime-store-ref row key default)
  (if (list? row)
    (let (entry (assoc key row))
      (if entry (cdr entry) default))
    default))

;; : (-> Symbol MaybeAlist)
(def (durable-runtime-store-operation-spec operation-kind)
  (let loop ((rest +poo-flow-durable-runtime-store-operation-specs+))
    (cond
     ((null? rest) #f)
     ((eq? (caar rest) operation-kind) (car rest))
     (else (loop (cdr rest))))))

;; : (-> Symbol Symbol Value Alist)
(def (durable-runtime-store-operation-diagnostic code slot value)
  (list (cons 'kind 'poo-flow.durable.runtime-store-operation.diagnostic)
        (cons 'schema
              'poo-flow.module-system.durable-runtime-store-operation.diagnostic.v1)
        (cons 'code code)
        (cons 'phase 'durable-runtime-store-operation)
        (cons 'slot slot)
        (cons 'value value)
        (cons 'severity 'error)
        (cons 'recoverable? #t)
        (cons 'runtime-executed #f)))

;; : (-> Boolean Symbol Symbol Value [Alist])
(def (durable-runtime-store-operation-diagnostic-unless ok? code slot value)
  (if ok?
    '()
    (list (durable-runtime-store-operation-diagnostic code slot value))))

;; : (-> Value Boolean)
(def (durable-runtime-store-symbol-list? value)
  (and (list? value)
       (let loop ((rest value))
         (cond
          ((null? rest) #t)
          ((symbol? (car rest)) (loop (cdr rest)))
          (else #f)))))

;; : PooDurableRuntimeStoreOperationReceipt
(defstruct poo-flow-durable-runtime-store-operation-receipt
  (operation-id
   operation-kind
   store-id
   backend-id
   project-id
   root-session-id
   session-id
   ledger-kind
   capability-flag
   target-ref
   payload-summary
   causal-refs
   watermark
   negotiation
   valid?
   diagnostics
   metadata
   runtime-owner
   handoff-required
   runtime-executed)
  transparent: #t)

;; Projection table keeps the ABI boundary compact without introducing a new
;; public DSL; each accessor is fixed by the defstruct above.
(def +poo-flow-durable-runtime-store-operation-receipt-projection+
  (list
   (cons 'operation-id
         poo-flow-durable-runtime-store-operation-receipt-operation-id)
   (cons 'operation-kind
         poo-flow-durable-runtime-store-operation-receipt-operation-kind)
   (cons 'store-id
         poo-flow-durable-runtime-store-operation-receipt-store-id)
   (cons 'backend-id
         poo-flow-durable-runtime-store-operation-receipt-backend-id)
   (cons 'project-id
         poo-flow-durable-runtime-store-operation-receipt-project-id)
   (cons 'root-session-id
         poo-flow-durable-runtime-store-operation-receipt-root-session-id)
   (cons 'session-id
         poo-flow-durable-runtime-store-operation-receipt-session-id)
   (cons 'ledger-kind
         poo-flow-durable-runtime-store-operation-receipt-ledger-kind)
   (cons 'capability-flag
         poo-flow-durable-runtime-store-operation-receipt-capability-flag)
   (cons 'target-ref
         poo-flow-durable-runtime-store-operation-receipt-target-ref)
   (cons 'payload-summary
         poo-flow-durable-runtime-store-operation-receipt-payload-summary)
   (cons 'causal-refs
         poo-flow-durable-runtime-store-operation-receipt-causal-refs)
   (cons 'watermark
         poo-flow-durable-runtime-store-operation-receipt-watermark)
   (cons 'valid?
         poo-flow-durable-runtime-store-operation-receipt-valid?)
   (cons 'diagnostics
         poo-flow-durable-runtime-store-operation-receipt-diagnostics)
   (cons 'metadata
         poo-flow-durable-runtime-store-operation-receipt-metadata)
   (cons 'runtime-owner
         poo-flow-durable-runtime-store-operation-receipt-runtime-owner)
   (cons 'handoff-required
         poo-flow-durable-runtime-store-operation-receipt-handoff-required)
   (cons 'runtime-executed
         poo-flow-durable-runtime-store-operation-receipt-runtime-executed)))

;; : (-> Symbol Symbol Alist Alist Symbol [Alist])
(def (durable-runtime-store-operation-diagnostics operation-id
                                                  operation-kind
                                                  spec
                                                  negotiation
                                                  target-ref
                                                  causal-refs)
  (append
   (durable-runtime-store-operation-diagnostic-unless
    (symbol? operation-id)
    'missing-operation-id
    'operation-id
    operation-id)
   (durable-runtime-store-operation-diagnostic-unless
    spec
    'unsupported-operation-kind
    'operation-kind
    operation-kind)
   (durable-runtime-store-operation-diagnostic-unless
    (eq? (durable-runtime-store-ref negotiation 'handoff-ready? #f) #t)
    'runtime-store-handoff-not-ready
    'negotiation
    negotiation)
   (durable-runtime-store-operation-diagnostic-unless
    (or (not spec)
        (member operation-kind
                (durable-runtime-store-ref negotiation 'operation-kinds '())))
    'operation-kind-not-supported-by-backend
    'operation-kind
    operation-kind)
   (durable-runtime-store-operation-diagnostic-unless
    (symbol? target-ref)
    'missing-target-ref
    'target-ref
    target-ref)
   (durable-runtime-store-operation-diagnostic-unless
    (durable-runtime-store-symbol-list? causal-refs)
    'invalid-causal-refs
    'causal-refs
    causal-refs)))

;; : (-> Symbol Symbol PooDurableRuntimeStoreNegotiationReceipt Any [Alist] PooDurableRuntimeStoreOperationReceipt)
(def (poo-flow-durable-runtime-store-operation operation-id
                                               operation-kind
                                               negotiation
                                               payload-summary
                                               . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (negotiation-row
          (if (poo-flow-durable-runtime-store-negotiation-receipt? negotiation)
            (poo-flow-durable-runtime-store-negotiation-receipt->alist
             negotiation)
            negotiation))
         (contract-row
          (durable-runtime-store-ref negotiation-row 'contract-row '()))
         (spec
          (durable-runtime-store-operation-spec operation-kind))
         (target-slot (and spec (cadddr spec)))
         (target-ref
          (durable-runtime-store-ref
           options
           'target-ref
           (durable-runtime-store-ref contract-row target-slot #f)))
         (causal-refs
          (durable-runtime-store-ref options 'causal-refs '()))
         (watermark
          (durable-runtime-store-ref options 'watermark #f))
         (metadata
          (durable-runtime-store-ref options 'metadata '()))
         (diagnostics
          (durable-runtime-store-operation-diagnostics
           operation-id
           operation-kind
           spec
           negotiation-row
           target-ref
           causal-refs)))
    (make-poo-flow-durable-runtime-store-operation-receipt
     operation-id
     operation-kind
     (durable-runtime-store-ref negotiation-row 'store-id #f)
     (durable-runtime-store-ref negotiation-row 'backend-id #f)
     (durable-runtime-store-ref contract-row 'project-id #f)
     (durable-runtime-store-ref contract-row 'root-session-id #f)
     (durable-runtime-store-ref contract-row 'session-id #f)
     (and spec (cadr spec))
     (and spec (caddr spec))
     target-ref
     payload-summary
     causal-refs
     watermark
     negotiation-row
     (null? diagnostics)
     diagnostics
     metadata
     (durable-runtime-store-ref negotiation-row
                                'runtime-owner
                                "marlin-agent-core")
     #t
     #f)))

;; : (-> PooDurableRuntimeStoreNegotiationReceipt [Alist] [PooDurableRuntimeStoreOperationReceipt])
(def (poo-flow-durable-runtime-store-operation-receipts negotiation
                                                         . maybe-options)
  (let ((options (if (null? maybe-options) '() (car maybe-options))))
    (map (lambda (spec)
           (poo-flow-durable-runtime-store-operation
            (car spec)
            (car spec)
            negotiation
            (durable-runtime-store-ref
             options
             'payload-summary
             (list (cons 'operation-kind (car spec))))
            options))
         +poo-flow-durable-runtime-store-operation-specs+)))

;; : (-> PooDurableRuntimeStoreOperationReceipt Alist)
(def (poo-flow-durable-runtime-store-operation-receipt->alist receipt)
  (append
   (list
    (cons 'kind +poo-flow-durable-runtime-store-operation-receipt-kind+)
    (cons 'schema +poo-flow-durable-runtime-store-operation-receipt-schema+))
   (map (lambda (projection)
          (cons (car projection)
                ((cdr projection) receipt)))
        +poo-flow-durable-runtime-store-operation-receipt-projection+)
   (list
    (cons 'diagnostic-count
          (length
           (poo-flow-durable-runtime-store-operation-receipt-diagnostics
            receipt))))))

;; : (-> [Alist] Boolean)
(def (durable-runtime-store-operation-rows-valid? rows)
  (let loop ((rest rows))
    (cond
     ((null? rest) #t)
     ((eq? (durable-runtime-store-ref (car rest) 'valid? #f) #t)
      (loop (cdr rest)))
     (else #f))))

;; : (-> [PooDurableRuntimeStoreOperationReceipt] [Alist])
(def (poo-flow-durable-runtime-store-operation-receipts->alists receipts)
  (map poo-flow-durable-runtime-store-operation-receipt->alist receipts))

;; : (-> PooDurableRuntimeStoreNegotiationReceipt [PooDurableRuntimeStoreOperationReceipt] Alist)
(def (poo-flow-durable-runtime-store-operations->marlin-handoff negotiation
                                                                  receipts
                                                                  . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (negotiation-row
          (if (poo-flow-durable-runtime-store-negotiation-receipt? negotiation)
            (poo-flow-durable-runtime-store-negotiation-receipt->alist
             negotiation)
            negotiation))
         (backend-row
          (durable-runtime-store-ref negotiation-row 'backend-row '()))
         (operation-rows
          (poo-flow-durable-runtime-store-operation-receipts->alists receipts))
         (operation
          (durable-runtime-store-ref options
                                     'manifest-operation
                                     'durable-runtime-store-operations))
         (descriptor
          (make-runtime-command-descriptor
           operation
           (durable-runtime-store-ref backend-row
                                      'executable
                                      "marlin-runtime-store")
           (durable-runtime-store-ref options
                                      'arguments
                                      '("durable-runtime-store" "operations"))
           (durable-runtime-store-ref backend-row
                                      'protocol
                                      'stdout-s-expression)
           (list (cons 'source 'poo-flow.durable.runtime-store.operation)
                 (cons 'operation-count (length operation-rows))
                 (cons 'runtime-executed #f))))
         (envelope
          (list (cons 'schema +runtime-request-schema+)
                (cons 'runtime 'marlin)
                (cons 'operation operation)
                (cons 'request-id
                      (list 'poo-flow.durable.runtime-store.operations
                            (durable-runtime-store-ref negotiation-row
                                                       'store-id
                                                       #f)))
                (cons 'artifact-handle #f)
                (cons 'request
                      (list (cons 'negotiation negotiation-row)
                            (cons 'operation-rows operation-rows)))
                (cons 'policy
                      (list (cons 'runtime-owner
                                  (durable-runtime-store-ref
                                   negotiation-row
                                   'runtime-owner
                                   "marlin-agent-core"))
                            (cons 'handoff-required #t)
                            (cons 'runtime-executed #f)))
                (cons 'plan-id #f)
                (cons 'node-id
                      (durable-runtime-store-ref negotiation-row
                                                 'store-id
                                                 #f))
                (cons 'frontier '())))
         (manifest
          (runtime-command-descriptor->manifest descriptor envelope)))
    (list
     (cons 'kind 'poo-flow.durable.runtime-store.operation-handoff)
     (cons 'schema +poo-flow-durable-runtime-store-operation-handoff-schema+)
     (cons 'request-schema +runtime-request-schema+)
     (cons 'operation operation)
     (cons 'request-id (durable-runtime-store-ref manifest 'request-id #f))
     (cons 'runtime-owner
           (durable-runtime-store-ref negotiation-row
                                      'runtime-owner
                                      "marlin-agent-core"))
     (cons 'handoff-ready?
           (and (eq? (durable-runtime-store-ref negotiation-row
                                                'handoff-ready?
                                                #f)
                     #t)
                (durable-runtime-store-operation-rows-valid? operation-rows)))
     (cons 'operation-count (length operation-rows))
     (cons 'negotiation negotiation-row)
     (cons 'operation-rows operation-rows)
     (cons 'runtime-command-manifest manifest)
     (cons 'runtime-executed #f)
     (cons 'runtime-parses-scheme-source #f)
     (cons 'scheme-manufactures-runtime-handlers #f))))
