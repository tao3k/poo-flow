;;; -*- Gerbil -*-
;;; Boundary: custom user-interface session-communication scenario.
;;; Invariant: communication receipts are route declarations only; Scheme does
;;; not deliver messages or mutate session state.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-selection-key)
        :poo-flow/src/module-system/init-syntax)

(export user-interface-custom-session-communication-test)

(load! "../user-interface/custom/my-module/cases/session-communication")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : (-> [PooUserModuleSelection] [Alist])
(def (module-config-rows module-selection-bundle)
  (let* ((selection (car module-selection-bundle))
         (entry
          (poo-flow-user-module-selection-flag-entry selection ':session-rows)))
    (if entry (cdr entry) '())))

;; : TestSuite
(def user-interface-custom-session-communication-test
  (test-suite "poo-flow custom user-interface session-communication case"
    (test-case "projects custom session communication receipt rows"
      (let* ((selection (car poo-flow-custom-module-session-communication-case))
             (rows
              (module-config-rows
               poo-flow-custom-module-session-communication-case))
             (root-build-channel (car rows))
             (audit-release-channel (cadddr rows))
             (communication-rows (cddddr rows))
             (parent-child (car communication-rows))
             (sibling (caddr communication-rows))
             (cross-root (cadddr communication-rows)))
        (check-equal? (poo-flow-user-module-selection-key selection)
                      '(session . session-core))
        (check-equal? (length rows) 8)
        (check-equal? (test-ref root-build-channel 'kind)
                      'poo-flow.session.communication-channel-receipt)
        (check-equal? (test-ref root-build-channel 'channel-id)
                      'channel/root-build)
        (check-equal? (test-ref root-build-channel 'allowed-message-kinds)
                      '(request))
        (check-equal? (test-ref audit-release-channel 'relation-kind)
                      'cross-root)
        (check-equal? (test-ref audit-release-channel 'delivery-policies)
                      '(explicit-project-root))
        (check-equal? (test-ref audit-release-channel 'open?) #f)
        (check-equal? (map (lambda (row) (test-ref row 'relation-kind))
                           communication-rows)
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
