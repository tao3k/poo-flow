;;; -*- Gerbil -*-
;;; Boundary: replay policy validates receipts against planned graph evidence.
;;; Invariant: replay validation never re-executes tasks or adapter requests.

(import :core/plan
        :core/receipt)

(export make-replay-report
        replay-report?
        replay-report-status
        replay-report-reasons
        replay-report-summary
        replay-report-expected-node-ids
        replay-report-observed-node-ids
        validate-replay-report
        replay-report-valid?
        replay-report-reason-count)

;;; Reports keep validation status beside the summary they validated so Rust or
;;; external replay tooling can persist one bounded control-plane object.
;; ReplayReport <- Symbol [Reason] RunSummary [Id] [Id]
(defstruct replay-report
  (status
   reasons
   summary
   expected-node-ids
   observed-node-ids)
  transparent: #t)

;;; Intent: validate that a receipt can be replayed against the plan topology
;;; that produced it.
;;; The policy checks root frontier, child count, node order, child frontiers,
;;; root status, and exported summary counts without running any task again.
;; ReplayReport <- ExecutionPlan Receipt
(def (validate-replay-report plan receipt)
  (let* ((summary (receipt->run-summary receipt))
         (expected-node-ids (execution-plan-node-ids plan))
         (observed-node-ids (top-level-receipt-node-ids receipt))
         (reasons
          (append (root-status-reasons receipt)
                  (root-frontier-reasons plan receipt)
                  (child-count-reasons expected-node-ids
                                       (receipt-children receipt))
                  (child-replay-reasons plan
                                        (receipt-children receipt)
                                        expected-node-ids
                                        '())
                  (summary-count-reasons summary receipt))))
    (make-replay-report (if (null? reasons) 'valid 'invalid)
                        reasons
                        summary
                        expected-node-ids
                        observed-node-ids)))

;; Boolean <- ReplayReport
(def (replay-report-valid? report)
  (eq? (replay-report-status report) 'valid))

;; Nat <- ReplayReport
(def (replay-report-reason-count report)
  (length (replay-report-reasons report)))

;;; Root status is part of replay policy because failed runs can still be
;;; summarized, but they are not valid successful replay baselines.
;; [Reason] <- Receipt
(def (root-status-reasons receipt)
  (if (receipt-ok? receipt)
    '()
    (list (list 'root-status-mismatch (receipt-status receipt)))))

;;; The first frontier must match the graph frontier before any node completes.
;;; This catches summaries built from a different plan or strategy policy.
;; [Reason] <- ExecutionPlan Receipt
(def (root-frontier-reasons plan receipt)
  (let ((expected (execution-plan-ready-node-ids plan '()))
        (observed (receipt-frontier receipt)))
    (if (equal? expected observed)
      '()
      (list (list 'root-frontier-mismatch expected observed)))))

;;; Child count is the coarse guard before node-by-node replay checks run.
;;; Detailed checks still operate on the common prefix so diagnostics remain
;;; useful when the trace is too short or too long.
;; [Reason] <- [Id] [Receipt]
(def (child-count-reasons expected-node-ids children)
  (let ((expected (length expected-node-ids))
        (observed (length children)))
    (if (= expected observed)
      '()
      (list (list 'child-count-mismatch expected observed)))))

;;; Node replay checks are ordered by plan node ids and recorded child receipts.
;;; Completed ids advance according to the expected plan so one bad receipt does
;;; not cascade into unrelated frontier calculations.
;; [Reason] <- ExecutionPlan [Receipt] [Id] [Id]
(def (child-replay-reasons plan children expected-node-ids completed-node-ids)
  (if (or (null? children) (null? expected-node-ids))
    '()
    (let ((expected-node-id (car expected-node-ids)))
      (append (child-replay-reason plan
                                   (car children)
                                   expected-node-id
                                   completed-node-ids)
              (child-replay-reasons plan
                                    (cdr children)
                                    (cdr expected-node-ids)
                                    (cons expected-node-id
                                          completed-node-ids))))))

;;; A child receipt is replay-valid when it names the expected node and records
;;; the exact ready frontier visible before that node ran.
;; [Reason] <- ExecutionPlan Receipt Id [Id]
(def (child-replay-reason plan child expected-node-id completed-node-ids)
  (append (child-node-id-reasons child expected-node-id)
          (child-frontier-reasons plan
                                  child
                                  expected-node-id
                                  completed-node-ids)))

;; [Reason] <- Receipt Id
(def (child-node-id-reasons child expected-node-id)
  (let ((observed (receipt-node-id child)))
    (if (equal? expected-node-id observed)
      '()
      (list (list 'node-id-mismatch expected-node-id observed)))))

;;; Frontier comparison is deliberately stricter than "expected node is ready":
;;; replay traces must preserve the whole ready-set policy, not only the chosen
;;; sequential node.
;; [Reason] <- ExecutionPlan Receipt Id [Id]
(def (child-frontier-reasons plan child expected-node-id completed-node-ids)
  (let ((expected (execution-plan-ready-node-ids plan completed-node-ids))
        (observed (receipt-frontier child)))
    (if (equal? expected observed)
      '()
      (list (list 'frontier-mismatch
                  expected-node-id
                  expected
                  observed)))))

;;; Summary count validation keeps the export surface honest even though the
;;; summary is derived locally today.
;; [Reason] <- RunSummary Receipt
(def (summary-count-reasons summary receipt)
  (append (summary-event-count-reasons summary receipt)
          (summary-adapter-count-reasons summary receipt)))

;; [Reason] <- RunSummary Receipt
(def (summary-event-count-reasons summary receipt)
  (let ((expected (receipt-event-count receipt))
        (observed (alist-ref 'event-count summary)))
    (if (equal? expected observed)
      '()
      (list (list 'event-count-mismatch expected observed)))))

;; [Reason] <- RunSummary Receipt
(def (summary-adapter-count-reasons summary receipt)
  (let ((expected (receipt-adapter-request-count receipt))
        (observed (alist-ref 'adapter-request-count summary)))
    (if (equal? expected observed)
      '()
      (list (list 'adapter-request-count-mismatch expected observed)))))

;;; Intent: project the top-level child receipt stream into the observed plan
;;; node sequence.
;;; The map transform is valid because each child receipt owns exactly one
;;; node-id slot at this replay boundary.
;;; Nested flow evidence stays in audit events so this sequence remains aligned
;;; with the parent execution plan.
;; [Id] <- Receipt
(def (top-level-receipt-node-ids receipt)
  (map receipt-node-id (receipt-children receipt)))

;; Value <- Symbol Alist
(def (alist-ref key alist)
  (let ((entry (assoc key alist)))
    (and entry (cdr entry))))
