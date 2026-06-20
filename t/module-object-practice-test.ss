;;; -*- Gerbil -*-
;;; Boundary: executable POO best-practice guard for module object layering.

(import (only-in :std/test
                 check
                 check-eq?
                 check-equal?
                 check-false
                 check-not-equal?
                 check-output
                 check-true
                 run-tests!
                 test-case
                 test-error
                 test-suite)
        :poo-flow/src/modules/extension
        :poo-flow/src/modules/object-core)

(export module-object-practice-test)

;; : (-> PooModuleExtensionNode Symbol MaybeAny)
(def (slot-value node slot-name)
  (let (entry (assoc slot-name (poo-flow-module-extension-node-slots node)))
    (if entry (cdr entry) #f)))

;; : TestSuite
;;; This suite keeps object-extension examples executable as policy evidence for
;;; downstream module authors.
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
                      "object-core owns contract wrappers")))

    (test-case "wraps standard list and map transformers as object contracts"
      (let* ((capabilities-field
              (poo-flow-module-field-contract
               'capabilities
               'List
               'override
               '(filesystem-read process-run cache-mount)
               '((scope . best-practice)
                 (owner . object-core))))
             (metadata-field
              (poo-flow-module-field-contract
               'metadata-map
               'Map
               'override
               '((stage . default))
               '((scope . best-practice)
                 (owner . object-core))))
             (practice-object
              (poo-flow-module-object
               'objects.practice.transformers
               '()
               (list capabilities-field metadata-field)
               '((namespace . objects.practice)
                 (domain . profile))))
             (base-node
              (poo-flow-module-object-node practice-object '() '()))
             (append-contribution
              (poo-flow-module-transformer-field-contribution
               (poo-flow-module-object-identity practice-object)
               capabilities-field
               poo-flow-module-transformer-list-append-contract
               '(network-access cache-mount)))
             (remove-contribution
              (poo-flow-module-transformer-field-contribution
               (poo-flow-module-object-identity practice-object)
               capabilities-field
               poo-flow-module-transformer-list-remove-contract
               '(process-run)))
             (map-set-contribution
              (poo-flow-module-transformer-field-contribution
               (poo-flow-module-object-identity practice-object)
               metadata-field
               poo-flow-module-transformer-map-set-contract
               '((stage . build)
                 (owner . object-core))))
             (merge-result
              (poo-flow-module-config-mk-merge
               base-node
               (list append-contribution
                     remove-contribution
                     map-set-contribution)))
             (resolved-node
              (poo-flow-module-config-merge-result-root merge-result)))
        (check-equal? (poo-flow-module-transformer-contract?
                       poo-flow-module-transformer-list-append-contract)
                      #t)
        (check-equal? (poo-flow-module-transformer-contract-identity
                       poo-flow-module-transformer-list-remove-contract)
                      'list.remove)
        (check-equal? (poo-flow-module-transformer-contract-idempotent?
                       poo-flow-module-transformer-list-append-contract)
                      #t)
        (check-equal? (poo-flow-module-transformer-contract-diagnostics
                       poo-flow-module-transformer-list-append-contract
                       capabilities-field
                       '(network-access))
                      '())
        (check-equal? (poo-flow-module-field-contribution-merge
                       append-contribution)
                      'append)
        (check-equal? (poo-flow-module-field-contribution-merge
                       remove-contribution)
                      'remove)
        (check-equal? (poo-flow-module-field-contribution-merge
                       map-set-contribution)
                      'override)
        (check-equal? (poo-flow-module-transformer-contract-diagnostics
                       poo-flow-module-transformer-map-set-contract
                       capabilities-field
                       '((stage . build)))
                      '("transformer:map.set:field-kind-mismatch"))
        (check-equal? (poo-flow-module-transformer-contract-diagnostics
                       poo-flow-module-transformer-list-remove-contract
                       capabilities-field
                       'process-run)
                      '("transformer:list.remove:argument-kind-mismatch"))
        (check-equal? (poo-flow-module-config-merge-result-stable?
                       merge-result)
                      #t)
        (check-equal? (slot-value resolved-node 'capabilities)
                      '(filesystem-read cache-mount network-access))
        (check-equal? (slot-value resolved-node 'metadata-map)
                      '((stage . build)
                        (owner . object-core)))))))

(run-tests! module-object-practice-test)
