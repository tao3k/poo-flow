;;; -*- Gerbil -*-
;;; Boundary: custom user-interface durable recovery scenario.
;;; Invariant: recovery rows describe crash/replay/repair handoff data only;
;;; Scheme never replays logs, claims leases, repairs state, or runs workflow.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/module-system/init-syntax)

(export user-interface-custom-durable-recovery-test)

(load! "../user-interface/custom/my-module/cases/durable-recovery")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def user-interface-custom-durable-recovery-test
  (test-suite "poo-flow custom user-interface durable-recovery case"
    (test-case "projects custom durable recovery handoff row"
      (let* ((row poo-flow-custom-module-durable-recovery-case)
             (observability-rows (test-ref row 'observability-rows)))
        (check-equal? (test-ref row 'kind)
                      'poo-flow.durable.recovery-scenario)
        (check-equal? (test-ref row 'scenario-id)
                      'recovery-scenario/custom-build-audit)
        (check-equal? (test-ref row 'valid?) #t)
        (check-equal? (test-ref row 'diagnostic-count) 0)
        (check-equal? (test-ref row 'deterministic-replay?) #t)
        (check-equal? (length observability-rows) 6)
        (check-equal? (map (lambda (entry)
                             (test-ref entry 'runtime-executed))
                           observability-rows)
                      '(#f #f #f #f #f #f))
        (check-equal? (test-ref row 'handoff-required) #t)
        (check-equal? (test-ref row 'runtime-executed) #f)))))

(run-tests! user-interface-custom-durable-recovery-test)
