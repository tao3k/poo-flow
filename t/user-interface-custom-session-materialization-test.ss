;;; -*- Gerbil -*-
;;; Boundary: custom user-interface session-materialization scenario.
;;; Invariant: materialization receipts are handoff state only; Scheme never
;;; waits on futures, opens sandboxes, or replays IO.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-selection-key)
        :poo-flow/src/module-system/init-syntax)

(export user-interface-custom-session-materialization-test)

(load! "../user-interface/custom/my-module/cases/session-materialization")

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
(def user-interface-custom-session-materialization-test
  (test-suite "poo-flow custom user-interface session-materialization case"
    (test-case "projects custom materialization receipts without runtime work"
      (let* ((selection
              (car poo-flow-custom-module-session-materialization-case))
             (rows
              (module-config-rows
               poo-flow-custom-module-session-materialization-case))
             (pending (car rows))
             (failed (cadr rows)))
        (check-equal? (poo-flow-user-module-selection-key selection)
                      '(session . session-core))
        (check-equal? (test-ref pending 'kind)
                      'poo-flow.session.materialization-receipt)
        (check-equal? (test-ref pending 'request-id)
                      'runtime/custom-build-request)
        (check-equal? (test-ref pending 'materialization-state) 'pending)
        (check-equal? (test-ref pending 'sandbox-handle-ref)
                      'sandbox/custom-build-handle)
        (check-equal? (test-ref failed 'request-id)
                      'runtime/custom-audit-request)
        (check-equal? (test-ref failed 'materialization-state) 'failed)
        (check-equal? (test-ref failed 'sandbox-handle-ref) #f)
        (check-equal? (test-ref pending 'handoff-required) #t)
        (check-equal? (test-ref pending 'declaration-checked?) #t)
        (check-equal? (test-ref pending 'root-session-declared?) #t)
        (check-equal? (test-ref pending 'session-declared?) #t)
        (check-equal? (test-ref pending 'undeclared-session-refs) '())
        (check-equal? (test-ref pending 'undeclared-parent-session-refs)
                      '())
        (check-equal? (test-ref pending 'sandbox-handle-declared?) #t)
        (check-equal? (test-ref pending 'valid?) #t)
        (check-equal? (test-ref pending 'diagnostic-count) 0)
        (check-equal? (test-ref pending 'diagnostics) '())
        (check-equal? (test-ref failed 'declaration-checked?) #t)
        (check-equal? (test-ref failed 'valid?) #t)
        (check-equal? (test-ref failed 'diagnostic-count) 0)
        (check-equal? (test-ref pending 'runtime-executed) #f)
        (check-equal? (test-ref failed 'runtime-executed) #f)))))

(run-tests! user-interface-custom-session-materialization-test)
