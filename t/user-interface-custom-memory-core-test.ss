;;; -*- Gerbil -*-
;;; Boundary: custom user-interface memory-core scenario.
;;; Invariant: user config declares memory specs and validation receipts only.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-memory-core-case))

(export user-interface-custom-memory-core-test)

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

(def user-interface-custom-memory-core-test
  (test-suite "poo-flow custom user-interface memory-core case"
    (test-case "projects custom memory-core case without runtime execution"
      (let* ((selection-row
              (car poo-flow-custom-my-module-memory-core-case))
             (catalog-row
              (cadr poo-flow-custom-my-module-memory-core-case))
             (validation-row
              (caddr poo-flow-custom-my-module-memory-core-case)))
        (check-equal? (test-ref selection-row 'key)
                      '(session . memory-core))
        (check-equal? (test-ref catalog-row 'catalog-ref)
                      'memory-core/custom)
        (check-equal? (test-ref catalog-row 'store-refs)
                      '(memory/project-notes))
        (check-equal? (test-ref validation-row 'valid?) #t)
        (check-equal? (test-ref validation-row 'resolved-store-refs)
                      '(memory/project-notes))
        (check-equal? (test-ref validation-row 'runtime-owner)
                      "marlin-agent-core")
        (check-equal? (test-ref validation-row 'runtime-executed) #f)))))

(run-tests! user-interface-custom-memory-core-test)
