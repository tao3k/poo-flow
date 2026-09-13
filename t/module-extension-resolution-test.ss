;;; -*- Gerbil -*-
;;; Boundary: focused native test for the extension operation algebra.
;;; Invariant: this owner imports only the extension facade, so native gxtest
;;; cannot pass through a stale aggregate user-interface build.

(import (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        :poo-flow/src/module-system/extension/interface)

(export module-extension-resolution-test)

;; : (-> PooModuleExtensionNode Symbol MaybeAny)
(def (extension-slot-value node slot-name)
  (let (entry (assoc slot-name (poo-flow-module-extension-node-slots node)))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def module-extension-resolution-test
  (test-suite "native POO module extension resolution"
    (test-case "dispatches ordered operations through native prototypes"
      (let* ((child
              (poo-flow-module-extension-node
               'workflow/build
               '((run . "gxi build.ss") (artifacts . ()))
               '()))
             (root
              (poo-flow-module-extension-node
               'workflow
               '((needs . (test)))
               (list child)))
             (result
              (poo-flow-module-extension-resolve
               root
               (list
                (poo-flow-module-extension-contribution
                 'workflow
                 (list
                  (poo-flow-module-extension-slot-prepend 'needs '(setup))
                  (poo-flow-module-extension-slot-append 'needs '(lint test))))
                (poo-flow-module-extension-contribution
                 'workflow/build
                 (list
                  (poo-flow-module-extension-slot-override
                   'run "gxi build.ss --optimized")
                  (poo-flow-module-extension-slot-append
                   'artifacts '(dist)))))))
             (resolved (poo-flow-module-extension-result-root result))
             (resolved-child
              (poo-flow-module-extension-child-ref
               (poo-flow-module-extension-node-children resolved)
               'workflow/build)))
        (check-equal? (poo-flow-module-extension-result-stable? result) #t)
        (check-equal? (poo-flow-module-extension-result-iterations result) 1)
        (check-equal? (extension-slot-value resolved 'needs)
                      '(setup test lint))
        (check-equal? (extension-slot-value resolved-child 'run)
                      "gxi build.ss --optimized")
        (check-equal? (extension-slot-value resolved-child 'artifacts)
                      '(dist))))
    (test-case "repeated idempotent append demand reports no change"
      (let* ((root
              (poo-flow-module-extension-node
               'workflow '((needs . (test lint))) '()))
             (contribution
              (poo-flow-module-extension-contribution
               'workflow
               (list
                (poo-flow-module-extension-slot-append
                 'needs '(lint test)))))
             (result
              (poo-flow-module-extension-resolve root (list contribution))))
        (check-equal? (poo-flow-module-extension-result-iterations result) 0)
        (check-equal?
         (extension-slot-value
          (poo-flow-module-extension-result-root result)
          'needs)
         '(test lint))))))
