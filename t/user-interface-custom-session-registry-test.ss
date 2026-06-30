;;; -*- Gerbil -*-
;;; Boundary: custom user-interface session-registry scenario.
;;; Invariant: registry receipts index declared sessions; they are not live
;;; runtime stores.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/init-syntax)

(export user-interface-custom-session-registry-test)

(load! "../user-interface/custom/my-module/cases/session-registry")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def user-interface-custom-session-registry-test
  (test-suite "poo-flow custom user-interface session-registry case"
    (test-case "projects custom session registry receipt"
      (let* ((registry poo-flow-custom-module-session-registry-case)
             (entries (.ref registry 'entries))
             (build-entry (cadr entries)))
        (check-equal? (.ref registry 'kind)
                      'poo-flow.session.registry-receipt)
        (check-equal? (.ref registry 'project-id) 'custom/project)
        (check-equal? (.ref registry 'root-session-ids)
                      '(custom/root-session))
        (check-equal? (.ref registry 'child-session-ids)
                      '(custom/build-session custom/audit-session))
        (check-equal? (.ref registry 'entry-count) 3)
        (check-equal? (.ref registry 'durable-policy-refs)
                      '(durable/custom-project
                        durable/custom-project
                        durable/custom-project))
        (check-equal? (test-ref build-entry 'parent-session-ids)
                      '(custom/root-session))
        (check-equal? (test-ref build-entry 'communication-channels)
                      '(channel/build-root channel/build-audit))
        (check-equal? (.ref registry 'runtime-executed) #f)))))

(run-tests! user-interface-custom-session-registry-test)
