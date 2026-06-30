;;; -*- Gerbil -*-
;;; Boundary: report-only session communication receipts.
;;; Invariant: receipts describe routed intent; Scheme never delivers messages.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/modules/session/config)

(export session-communication-receipt-test)

;; : (-> Alist Symbol Value)
(def (test-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def session-communication-receipt-test
  (test-suite "poo-flow session communication receipts"
    (test-case "names parent, child, sibling, and cross-root routing edges"
      (let* ((parent-child
              (poo-flow-session-communication-receipt
               'project/session
               'parent-child
               'root/a
               'root/a
               'session/root
               'session/build
               'agent/root
               'agent/build
               'channel/root-build
               'request
               '((summary . "run build checks"))
               'receipt-only))
             (child-parent
              (poo-flow-session-communication-receipt
               'project/session
               'child-parent
               'root/a
               'root/a
               'session/build
               'session/root
               'agent/build
               'agent/root
               'channel/build-root
               'result
               '((summary . "build completed"))
               'receipt-only))
             (sibling
              (poo-flow-session-communication-receipt
               'project/session
               'sibling
               'root/a
               'root/a
               'session/build
               'session/audit
               'agent/build
               'agent/audit
               'channel/build-audit
               'artifact
               '((artifact . build-report))
               'declared-channel-only))
             (cross-root
              (poo-flow-session-communication-receipt
               'project/session
               'cross-root
               'root/a
               'root/b
               'session/audit
               'session/release
               'agent/audit
               'agent/release
               'channel/audit-release
               'receipt
               '((receipt . release-gate))
               'explicit-project-root
               '((communication-ledger-ref . runtime/communication-ledger)
                 (durable-policy-ref . durable/session-communication))))
             (rows
              (poo-flow-session-communication-receipts->alists
               (list parent-child child-parent sibling cross-root)))
             (cross-root-row (cadddr rows)))
        (check-equal? (poo-flow-session-communication-receipt?
                       parent-child)
                      #t)
        (check-equal?
         (poo-flow-session-communication-receipt-project-id parent-child)
         'project/session)
        (check-equal?
         (poo-flow-session-communication-receipt-relation-kind sibling)
         'sibling)
        (check-equal?
         (poo-flow-session-communication-receipt-channel-id sibling)
         'channel/build-audit)
        (check-equal?
         (poo-flow-session-communication-receipt-source-session-id
          child-parent)
         'session/build)
        (check-equal?
         (poo-flow-session-communication-receipt-target-session-id
          cross-root)
         'session/release)
        (check-equal?
         (poo-flow-session-communication-receipt-target-root-session-id
          cross-root)
         'root/b)
        (check-equal? (test-ref cross-root-row 'kind)
                      +poo-flow-session-communication-receipt-kind+)
        (check-equal? (test-ref cross-root-row 'communication-ledger-ref)
                      'runtime/communication-ledger)
        (check-equal? (test-ref cross-root-row 'durable-policy-ref)
                      'durable/session-communication)
        (check-equal? (test-ref cross-root-row 'valid?) #t)
        (check-equal? (test-ref cross-root-row 'diagnostic-count) 0)
        (check-equal? (test-ref (car rows) 'handoff-required) #t)
        (check-equal? (test-ref (car rows) 'delivered?) #f)
        (check-equal? (test-ref (car rows) 'runtime-executed) #f)))))

(run-tests! session-communication-receipt-test)
