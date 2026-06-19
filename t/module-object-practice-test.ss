;;; -*- Gerbil -*-
;;; Boundary: executable POO best-practice guard for module object layering.

(import :std/test
        :poo-flow/src/modules/extension
        :poo-flow/src/modules/object-core)

(export module-object-practice-test)

;; : (-> PooModuleExtensionNode Symbol MaybeAny)
(def (slot-value node slot-name)
  (let (entry (assoc slot-name (poo-flow-module-extension-node-slots node)))
    (if entry (cdr entry) #f)))

;; : TestSuite
(def module-object-practice-test
  (test-suite "poo-flow module object best practices"
    (test-case "projects object-owned field contracts into the extension graph"
      (let* ((capabilities-field
              (poo-flow-module-field-contract
               'capabilities
               'List
               'append
               '(filesystem-read)
               '((scope . best-practice)
                 (owner . object-core))))
             (note-field
              (poo-flow-module-field-contract
               'note
               'String
               'override
               "unset"
               '((scope . best-practice)
                 (owner . object-core))))
             (practice-object
              (poo-flow-module-object
               'objects.practice.profile
               '()
               (list capabilities-field note-field)
               '((namespace . objects.practice)
                 (domain . profile))))
             (base-node
              (poo-flow-module-object-node practice-object '() '()))
             (contributions
              (poo-flow-module-object-contributions
               practice-object
               '((capabilities . (process-run cache-mount))
                 (note . "object-core owns contract wrappers"))))
             (extension-contributions
              (poo-flow-module-field-contributions->extensions contributions))
             (merge-result
              (poo-flow-module-config-mk-merge base-node contributions))
             (resolved-node
              (poo-flow-module-config-merge-result-root merge-result)))
        (check-equal? (poo-flow-module-object? practice-object) #t)
        (check-equal? (map poo-flow-module-field-contract-identity
                           (poo-flow-module-object-resolved-fields
                            practice-object))
                      '(capabilities note))
        (check-equal? (map poo-flow-module-field-contribution? contributions)
                      '(#t #t))
        (check-equal? (map poo-flow-module-extension-contribution?
                           extension-contributions)
                      '(#t #t))
        (check-equal? (poo-flow-module-config-merge-result? merge-result) #t)
        (check-equal? (poo-flow-module-config-merge-result-stable?
                       merge-result)
                      #t)
        (check-equal? (poo-flow-module-config-merge-result-contributions
                       merge-result)
                      contributions)
        (check-equal? (slot-value resolved-node 'capabilities)
                      '(filesystem-read process-run cache-mount))
        (check-equal? (slot-value resolved-node 'note)
                      "object-core owns contract wrappers")))))

(run-tests! module-object-practice-test)
