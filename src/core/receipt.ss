;;; -*- Gerbil -*-
;;; Boundary: receipts record observed execution outcomes.
;;; Invariant: retry, scheduling, and adapter policy remain outside receipts.

(export make-receipt
        receipt?
        receipt-flow
        receipt-task
        receipt-kind
        receipt-node-id
        receipt-strategy
        receipt-adapter-decision
        receipt-request-id
        receipt-input
        receipt-output
        receipt-cache
        receipt-frontier
        receipt-status
        receipt-error
        receipt-children
        receipt->audit-events
        receipt->run-summary
        receipt-event-count
        receipt-adapter-request-count
        receipt-ok?
        receipt-failed?)

;;; Children preserve nested execution evidence without forcing a runner to
;;; flatten or discard subflow receipts.
;;; Frontier evidence records which plan node ids were ready before the
;;; observed execution point, keeping scheduler policy inspectable after a run.
;;; Node identity is captured separately from task identity so replay policy can
;;; detect ordering drift even when task names repeat.
;; Receipt <- Flow Task Symbol NodeId Strategy AdapterDecision RequestId Value Value Cache [Id] Symbol Error [Receipt]
(defstruct receipt
  (flow
   task
   kind
   node-id
   strategy
   adapter-decision
   request-id
   input
   output
   cache
   frontier
   status
   error
   children)
  transparent: #t)

;; Boolean <- Receipt
(def (receipt-ok? receipt)
  (eq? (receipt-status receipt) 'ok))

;; Boolean <- Receipt
(def (receipt-failed? receipt)
  (eq? (receipt-status receipt) 'failed))

;;; Intent: flatten nested receipt trees into a replay-friendly event stream
;;; while preserving child order with a stable path.
;;; Each event omits raw input/output values so external persistence can store
;;; control-plane evidence without capturing potentially large runtime payloads.
;; [AuditEvent] <- Receipt
(def (receipt->audit-events receipt)
  (receipt->audit-events-at receipt '()))

;;; A run summary keeps root status and aggregate counts next to the event log.
;;; This is the durable handoff shape for Rust or external storage layers that
;;; want audit evidence before they implement full replay execution.
;; RunSummary <- Receipt
(def (receipt->run-summary receipt)
  (list (cons 'flow (receipt-flow receipt))
        (cons 'kind (receipt-kind receipt))
        (cons 'status (receipt-status receipt))
        (cons 'strategy (receipt-strategy receipt))
        (cons 'frontier (receipt-frontier receipt))
        (cons 'event-count (receipt-event-count receipt))
        (cons 'adapter-request-count (receipt-adapter-request-count receipt))
        (cons 'events (receipt->audit-events receipt))))

;;; Event count is tree cardinality, not step count; the root receipt is counted
;;; because it carries run-level frontier and status evidence.
;; Nat <- Receipt
(def (receipt-event-count receipt)
  (+ 1 (receipt-list-event-count (receipt-children receipt))))

;;; Adapter request count follows request-id evidence on receipts instead of
;;; task kind names, keeping the summary tied to observed adapter decisions.
;; Nat <- Receipt
(def (receipt-adapter-request-count receipt)
  (+ (if (receipt-request-id receipt) 1 0)
     (receipt-list-adapter-request-count (receipt-children receipt))))

;;; Path construction is separated from event shape so nested subflow receipts
;;; can be replayed without flattening away hierarchy.
;; [AuditEvent] <- Receipt [Nat]
(def (receipt->audit-events-at receipt path)
  (cons (receipt->audit-event receipt path)
        (child-receipts->audit-events (receipt-children receipt) path 0)))

;;; Audit events are intentionally small alists: they describe control-plane
;;; decisions, not application payloads.
;; AuditEvent <- Receipt [Nat]
(def (receipt->audit-event receipt path)
  (list (cons 'path path)
        (cons 'flow (receipt-flow receipt))
        (cons 'task (receipt-task receipt))
        (cons 'kind (receipt-kind receipt))
        (cons 'node-id (receipt-node-id receipt))
        (cons 'strategy (receipt-strategy receipt))
        (cons 'adapter-decision (receipt-adapter-decision receipt))
        (cons 'request-id (receipt-request-id receipt))
        (cons 'cache (receipt-cache receipt))
        (cons 'frontier (receipt-frontier receipt))
        (cons 'status (receipt-status receipt))
        (cons 'error (receipt-error receipt))
        (cons 'child-count (length (receipt-children receipt)))))

;;; Intent: recursively append child event streams in child ordinal order.
;;; The ordinal path is the replay cursor; it remains stable even if task names
;;; repeat inside nested flows.
;; [AuditEvent] <- [Receipt] [Nat] Nat
(def (child-receipts->audit-events children parent-path ordinal)
  (if (null? children)
    '()
    (append (receipt->audit-events-at (car children)
                                      (append parent-path (list ordinal)))
            (child-receipts->audit-events (cdr children)
                                          parent-path
                                          (+ ordinal 1)))))

;; Nat <- [Receipt]
(def (receipt-list-event-count receipts)
  (if (null? receipts)
    0
    (+ (receipt-event-count (car receipts))
       (receipt-list-event-count (cdr receipts)))))

;; Nat <- [Receipt]
(def (receipt-list-adapter-request-count receipts)
  (if (null? receipts)
    0
    (+ (receipt-adapter-request-count (car receipts))
       (receipt-list-adapter-request-count (cdr receipts)))))
