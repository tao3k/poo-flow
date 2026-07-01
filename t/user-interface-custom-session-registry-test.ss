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
        (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-selection-key)
        :poo-flow/src/module-system/init-syntax)

(export user-interface-custom-session-registry-test)

(load! "../user-interface/custom/my-module/cases/session-registry")

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : (-> [PooUserModuleSelection] [Value])
(def (module-config-rows module-selection-bundle)
  (let* ((selection (car module-selection-bundle))
         (entry
          (poo-flow-user-module-selection-flag-entry selection ':session-rows)))
    (if entry (cdr entry) '())))

;; : TestSuite
(def user-interface-custom-session-registry-test
  (test-suite "poo-flow custom user-interface session-registry case"
    (test-case "projects custom session registry receipt"
      (let* ((selection (car poo-flow-custom-module-session-registry-case))
             (rows
              (module-config-rows poo-flow-custom-module-session-registry-case))
             (registry (car rows))
             (entries (.ref registry 'entries))
             (build-entry (cadr entries)))
        (check-equal? (poo-flow-user-module-selection-key selection)
                      '(session . session-core))
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
