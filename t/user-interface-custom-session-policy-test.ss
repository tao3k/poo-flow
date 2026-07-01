;;; -*- Gerbil -*-
;;; Boundary: custom user-interface session-policy scenario.
;;; Invariant: user config projects effective policy validation only; Scheme
;;; never executes tools, hooks, providers, sandboxes, or communication.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/module-system/init-syntax
        :poo-flow/src/modules/session/config)

(export user-interface-custom-session-policy-test)

(load! "../user-interface/custom/my-module/cases/session-policy")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : (-> [Alist] [Symbol])
(def (diagnostic-codes diagnostics)
  (map (lambda (diagnostic)
         (test-ref diagnostic 'code))
       diagnostics))

;; : (-> Symbol [Symbol] Boolean)
(def (has-code? code codes)
  (if (member code codes) #t #f))

;; : TestSuite
(def user-interface-custom-session-policy-test
  (test-suite "poo-flow custom user-interface session-policy case"
    (test-case "projects custom effective session-policy validation"
      (let* ((rows poo-flow-custom-module-session-policy-case)
             (durable-row (car rows))
             (validation (list-ref rows 12))
             (codes (diagnostic-codes
                     (test-ref validation 'diagnostics))))
        (check-equal? (test-ref durable-row 'runtime-executed) #f)
        (check-equal? (test-ref validation 'kind)
                      'poo-flow.session.policy-validation-receipt)
        (check-equal? (test-ref validation 'validation-id)
                      'validation/custom-build)
        (check-equal? (test-ref validation 'scope-ref)
                      'custom/session-build-child)
        (check-equal? (test-ref validation 'effective-model-ref)
                      'marlin/model/build-review)
        (check-equal? (test-ref validation 'effective-prompt-session-ref)
                      'custom/session-build-system)
        (check-equal? (test-ref validation 'allowed-context-refs)
                      '(custom/session-root))
        (check-equal? (test-ref validation 'denied-resource-refs)
                      '(network-egress))
        (check-equal? (test-ref validation 'valid?) #f)
        (check-equal?
         (has-code? 'hook-tool-agent-permission-not-inherited codes)
         #t)
        (check-equal? (test-ref validation 'runtime-executed) #f)))))

(run-tests! user-interface-custom-session-policy-test)
