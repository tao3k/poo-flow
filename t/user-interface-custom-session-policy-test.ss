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

;; : (-> [Alist] (-> Alist Boolean) MaybeAlist)
(def (find-row rows predicate)
  (cond
   ((null? rows) #f)
   ((predicate (car rows)) (car rows))
   (else (find-row (cdr rows) predicate))))

;; : (-> [Alist] Symbol MaybeAlist)
(def (find-policy-row rows policy-kind)
  (find-row rows
            (lambda (row)
              (equal? (test-ref row 'policy-kind) policy-kind))))

;; : (-> [Alist] MaybeAlist)
(def (find-validation-row rows)
  (find-row rows
            (lambda (row)
              (equal? (test-ref row 'kind)
                      'poo-flow.session.policy-validation-receipt))))

;; : (-> [Alist] MaybeAlist)
(def (find-tool-catalog-validation-row rows)
  (find-row rows
            (lambda (row)
              (equal? (test-ref row 'kind)
                      'poo-flow.tool-core.policy-catalog-validation-receipt))))

;; : TestSuite
(def user-interface-custom-session-policy-test
  (test-suite "poo-flow custom user-interface session-policy case"
    (test-case "projects custom effective session-policy validation"
      (let* ((rows poo-flow-custom-module-session-policy-case)
             (durable-row (car rows))
             (sandbox-row (find-policy-row rows 'session-sandbox))
             (sandbox-slots (test-ref sandbox-row 'policy-slots))
             (sharing-row (find-policy-row rows 'session-sharing))
             (sharing-slots (test-ref sharing-row 'policy-slots))
             (tool-catalog-validation
              (find-tool-catalog-validation-row rows))
             (validation (find-validation-row rows))
             (codes (diagnostic-codes
                     (test-ref validation 'diagnostics))))
        (check-equal? (test-ref durable-row 'runtime-executed) #f)
        (check-equal? (test-ref sandbox-row 'schema)
                      'poo-flow.modules.session.policy.sandbox.v1)
        (check-equal? (test-ref sandbox-slots 'profile-ref)
                      'sandbox/nono-build)
        (check-equal? (test-ref sandbox-slots 'sharing-mode)
                      'isolated-filesystem)
        (check-equal? (test-ref sharing-row 'schema)
                      'poo-flow.modules.session.policy.sharing.v1)
        (check-equal? (test-ref sharing-slots 'memory-refs)
                      '(memory/project))
        (check-equal? (test-ref sharing-slots 'workspace-paths)
                      '("build/" "reports/"))
        (check-equal? (test-ref tool-catalog-validation 'valid?) #t)
        (check-equal? (test-ref tool-catalog-validation 'resolved-tool-refs)
                      '(read-workspace-file run-build-command))
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
        (check-equal? (test-ref validation 'tool-catalog-validation-id)
                      'validation/custom-session-tool-catalog)
        (check-equal? (test-ref validation 'tool-catalog-ref)
                      'tool-core/custom-session-policy)
        (check-equal? (test-ref validation 'tool-catalog-valid?) #t)
        (check-equal? (test-ref validation
                                'tool-catalog-resolved-tool-refs)
                      '(read-workspace-file run-build-command))
        (check-equal? (test-ref validation 'valid?) #f)
        (check-equal?
         (has-code? 'hook-tool-agent-permission-not-inherited codes)
         #t)
        (check-equal? (test-ref validation 'runtime-executed) #f)))))

(run-tests! user-interface-custom-session-policy-test)
