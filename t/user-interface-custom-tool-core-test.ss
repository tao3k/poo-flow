;;; -*- Gerbil -*-
;;; Boundary: custom user-interface tool-core scenario.
;;; Invariant: user config declares tool specs and validation receipts only.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :poo-flow/user-interface/custom/my-module/config
                 poo-flow-custom-my-module-tool-core-case))

(export user-interface-custom-tool-core-test)

;; : (-> Alist Symbol MaybeValue)
(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def user-interface-custom-tool-core-test
  (test-suite "poo-flow custom user-interface tool-core case"
    (test-case "projects custom tool-core case without runtime execution"
      (let* ((selection-row
              (car poo-flow-custom-my-module-tool-core-case))
             (catalog-row
              (cadr poo-flow-custom-my-module-tool-core-case))
             (validation-row
              (caddr poo-flow-custom-my-module-tool-core-case)))
        (check-equal? (test-ref selection-row 'key)
                      '(session . tool-core))
        (check-equal? (test-ref catalog-row 'catalog-ref)
                      'tool-core/custom)
        (check-equal? (test-ref catalog-row 'tool-refs)
                      '(calculator))
        (check-equal? (test-ref validation-row 'valid?) #t)
        (check-equal? (test-ref validation-row 'resolved-tool-refs)
                      '(calculator))
        (check-equal? (test-ref validation-row 'runtime-owner)
                      "marlin-agent-core")
        (check-equal? (test-ref validation-row 'runtime-executed) #f)))))

(run-tests! user-interface-custom-tool-core-test)
