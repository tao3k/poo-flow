;;; -*- Gerbil -*-
;;; Boundary: executable POO best-practice guard for module object layering.

(import :gerbil/gambit
        (only-in :std/test
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
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/object-core)

(export module-object-practice-test)

;; : (-> PooModuleExtensionNode Symbol MaybeAny)
(def (slot-value node slot-name)
  (let (entry (assoc slot-name (poo-flow-module-extension-node-slots node)))
    (if entry (cdr entry) #f)))

;; : (-> Integer (-> Integer Value) [Value])
(def (large-object-build-list count make-value)
  (let loop ((index 0) (values '()))
    (if (= index count)
      (reverse values)
      (loop (+ index 1)
            (cons (make-value index) values)))))

;; : (-> (-> Any) Rational)
(def (elapsed-ms thunk)
  (let ((start-jiffy (current-jiffy)))
    (thunk)
    (/ (* (- (current-jiffy) start-jiffy) 1000)
       (jiffies-per-second))))

;; : (-> Integer (-> Any) Rational)
(def (best-elapsed-ms attempts thunk)
  (let loop ((remaining attempts)
             (best #f))
    (if (= remaining 0)
      best
      (let (elapsed (elapsed-ms thunk))
        (loop (- remaining 1)
              (if (or (not best) (< elapsed best))
                elapsed
                best))))))

;; : (-> Integer Symbol)
(def (large-object-field-name index)
  (string->symbol
   (string-append "field-" (number->string index))))

;; : (-> Integer PooModuleFieldContract)
(def (large-object-field index)
  (poo-flow-module-field-contract
   (large-object-field-name index)
   'Any
   'override
   #f
   '((scope . large-object-performance)
     (owner . object-core))))

;; : (-> Integer PooModuleFieldContract)
(def (large-object-list-field index)
  (poo-flow-module-field-contract
   (large-object-field-name index)
   'List
   'append
   '()
   '((scope . large-object-performance)
     (owner . object-core))))

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

    (test-case "keeps large object contribution projection linear"
      (let* ((field-count 1000)
             (fields
              (large-object-build-list field-count large-object-field))
             (practice-object
              (poo-flow-module-object
               'objects.practice.large
               '()
               fields
               '((namespace . objects.practice)
                 (domain . performance))))
             (entries
              (large-object-build-list
               field-count
               (lambda (index)
                 (cons (large-object-field-name index)
                       (list index)))))
             (start-jiffy (current-jiffy))
             (contributions
              (poo-flow-module-object-contributions practice-object entries))
             (elapsed-ms
              (/ (* (- (current-jiffy) start-jiffy) 1000)
                 (jiffies-per-second)))
             (best-ms
              (best-elapsed-ms
               5
               (lambda ()
                 (poo-flow-module-object-contributions practice-object
                                                       entries)))))
        (check-equal? (length contributions) field-count)
        (check-equal? (poo-flow-module-field-contract-identity
                       (poo-flow-module-field-contribution-field
                        (car contributions)))
                      'field-0)
        (check-equal? (poo-flow-module-field-contribution-value
                       (car contributions))
                      '(0))
        (check-equal? (< elapsed-ms 1000) #t)
        (check-equal? (< best-ms 100) #t)))

    (test-case "keeps large object slot config merge bounded"
      (let* ((field-count 1000)
             (fields
              (large-object-build-list field-count large-object-list-field))
             (practice-object
              (poo-flow-module-object
               'objects.practice.large-merge
               '()
               fields
               '((namespace . objects.practice)
                 (domain . performance))))
             (base-entries
              (large-object-build-list
               field-count
               (lambda (index)
                 (cons (large-object-field-name index)
                       (list index)))))
             (append-entries
              (large-object-build-list
               field-count
               (lambda (index)
                 (cons (large-object-field-name index)
                       (list (+ index field-count))))))
             (base-node
              (poo-flow-module-object-node practice-object base-entries '()))
             (contributions
              (poo-flow-module-object-contributions practice-object
                                                    append-entries))
             (noop-contributions
              (poo-flow-module-object-contributions practice-object
                                                    base-entries))
             (start-jiffy (current-jiffy))
             (merge-result
              (poo-flow-module-config-mk-merge base-node contributions))
             (elapsed-ms
              (/ (* (- (current-jiffy) start-jiffy) 1000)
                 (jiffies-per-second)))
             (best-ms
              (best-elapsed-ms
               5
               (lambda ()
                 (poo-flow-module-config-mk-merge base-node contributions))))
             (noop-best-ms
              (best-elapsed-ms
               5
               (lambda ()
                 (poo-flow-module-config-mk-merge base-node
                                                  noop-contributions))))
             (noop-result
              (poo-flow-module-config-mk-merge base-node noop-contributions))
             (resolved-node
              (poo-flow-module-config-merge-result-root merge-result)))
        (check-equal? (poo-flow-module-config-merge-result-stable?
                       merge-result)
                      #t)
        (check-equal? (length (poo-flow-module-extension-node-slots
                               resolved-node))
                      field-count)
        (check-equal? (slot-value resolved-node 'field-0)
                      '(0 1000))
        (check-equal? (poo-flow-module-config-merge-result-iterations
                       noop-result)
                      0)
        (check-equal? (< elapsed-ms 1000) #t)
        (check-equal? (< best-ms 100) #t)
        (check-equal? (< noop-best-ms 50) #t)))

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
