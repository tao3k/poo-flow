;;; -*- Gerbil -*-
;;; Boundary: custom user-interface session-communication scenario.
;;; Invariant: communication receipts are route declarations only; Scheme does
;;; not deliver messages or mutate session state.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/module-system/init-syntax)

(export user-interface-custom-session-communication-test)

(load! "../user-interface/custom/my-module/cases/session-communication")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def user-interface-custom-session-communication-test
  (test-suite "poo-flow custom user-interface session-communication case"
    (test-case "projects custom session communication receipt rows"
      (let* ((rows poo-flow-custom-module-session-communication-case)
             (parent-child (car rows))
             (sibling (caddr rows))
             (cross-root (cadddr rows)))
        (check-equal? (length rows) 4)
        (check-equal? (map (lambda (row) (test-ref row 'relation-kind))
                           rows)
                      '(parent-child child-parent sibling cross-root))
        (check-equal? (test-ref parent-child 'source-session-id)
                      'custom/root-session)
        (check-equal? (test-ref parent-child 'target-session-id)
                      'custom/build-session)
        (check-equal? (test-ref sibling 'channel-id)
                      'channel/build-audit)
        (check-equal? (test-ref cross-root 'target-root-session-id)
                      'custom/release-root)
        (check-equal? (test-ref cross-root 'delivery-policy)
                      'explicit-project-root)
        (check-equal? (test-ref cross-root 'communication-ledger-ref)
                      'runtime/custom-communication-ledger)
        (check-equal? (test-ref cross-root 'durable-policy-ref)
                      'durable/custom-project)
        (check-equal? (test-ref cross-root 'handoff-required) #t)
        (check-equal? (test-ref cross-root 'delivered?) #f)
        (check-equal? (test-ref cross-root 'runtime-executed) #f)))))

(run-tests! user-interface-custom-session-communication-test)
