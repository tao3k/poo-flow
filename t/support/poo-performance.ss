;;; -*- Gerbil -*-
;;; Boundary: shared fixtures and helpers for POO performance scenario tests.

(import (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-fixture-ref
                 benchmark-receipt-pass?
                 benchmark-run)
        (only-in :clan/poo/object
                 .all-slots
                 .def
                 .get
                 .mix
                 .o
                 .putdefault!
                 .ref
                 .setslot!
                 $constant-slot-spec)
        :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/extension
        :poo-flow/src/module-system/object-validation
        (only-in :std/srfi/1 iota)
        (only-in :std/sugar ormap filter))

(export poo-performance-load-fixture
        poo-performance-construction-fixture-path
        poo-performance-construction-fixture
        poo-performance-materialization-fixture-path
        poo-performance-materialization-fixture
        poo-performance-validation-fixture-path
        poo-performance-validation-fixture
        poo-performance-catalog-validation-fixture-path
        poo-performance-catalog-validation-fixture
        poo-performance-object-iteration-fixture-path
        poo-performance-object-iteration-fixture
        poo-performance-clone-override-fixture-path
        poo-performance-clone-override-fixture
        poo-performance-field-lookup-fixture-path
        poo-performance-field-lookup-fixture
        poo-performance-composition-fixture-path
        poo-performance-composition-fixture
        poo-performance-extension-children-merge-fixture-path
        poo-performance-extension-children-merge-fixture
        poo-performance-cross-contribution-targeting-fixture-path
        poo-performance-cross-contribution-targeting-fixture
        poo-performance-local-contribution-coalescing-fixture-path
        poo-performance-local-contribution-coalescing-fixture
        poo-performance-fixture-paths
        poo-performance-fixtures
        benchmark-fixture-memory-contract-pass?
        poo-performance-run-gate
        poo-performance-required-form-evidence
        poo-performance-required-usage-call-evidence
        poo-performance-symbol-member?
        poo-performance-evidence-covers?
        poo-performance-api-evidence-contract-pass?
        poo-performance-api-usage-call-receipt
        poo-performance-slot-ref/default
        poo-performance-build-list
        poo-performance-field-name
        poo-performance-field-contract
        poo-performance-field-contracts
        poo-performance-module-object
        poo-performance-module-object-catalog
        poo-performance-contribution-entries
        poo-performance-catalog-contributions
        poo-performance-override-slots
        poo-performance-snapshot-sum
        poo-performance-object-node-lookup-count
        poo-performance-extension-child-name
        poo-performance-extension-child
        poo-performance-extension-children
        poo-performance-extension-merge-root
        poo-performance-extension-node-extend-operations
        poo-performance-cross-contribution-child-name
        poo-performance-cross-contribution-child
        poo-performance-cross-contribution-create-operations
        poo-performance-cross-contribution-targeting-contributions
        poo-performance-local-slot-contributions)

;; : (-> String Alist)
(def (poo-performance-load-fixture path)
  (call-with-input-file path read))

;; : String
(def poo-performance-construction-fixture-path
  "t/scenarios/performance/poo-construction/benchmark.ss")

;; : Alist
(def poo-performance-construction-fixture
  (poo-performance-load-fixture poo-performance-construction-fixture-path))

;; : String
(def poo-performance-materialization-fixture-path
  "t/scenarios/performance/poo-loop-materialization/benchmark.ss")

;; : Alist
(def poo-performance-materialization-fixture
  (poo-performance-load-fixture poo-performance-materialization-fixture-path))

;; : String
(def poo-performance-validation-fixture-path
  "t/scenarios/performance/poo-loop-validation/benchmark.ss")

;; : Alist
(def poo-performance-validation-fixture
  (poo-performance-load-fixture poo-performance-validation-fixture-path))

;; : String
(def poo-performance-catalog-validation-fixture-path
  "t/scenarios/performance/poo-catalog-validation/benchmark.ss")

;; : Alist
(def poo-performance-catalog-validation-fixture
  (poo-performance-load-fixture poo-performance-catalog-validation-fixture-path))

;; : String
(def poo-performance-object-iteration-fixture-path
  "t/scenarios/performance/poo-object-iteration/benchmark.ss")

;; : Alist
(def poo-performance-object-iteration-fixture
  (poo-performance-load-fixture poo-performance-object-iteration-fixture-path))

;; : String
(def poo-performance-clone-override-fixture-path
  "t/scenarios/performance/poo-clone-override/benchmark.ss")

;; : Alist
(def poo-performance-clone-override-fixture
  (poo-performance-load-fixture poo-performance-clone-override-fixture-path))

;; : String
(def poo-performance-field-lookup-fixture-path
  "t/scenarios/performance/poo-field-lookup-loop/benchmark.ss")

;; : Alist
(def poo-performance-field-lookup-fixture
  (poo-performance-load-fixture poo-performance-field-lookup-fixture-path))

;; : String
(def poo-performance-composition-fixture-path
  "t/scenarios/performance/poo-loop-composition/benchmark.ss")

;; : Alist
(def poo-performance-composition-fixture
  (poo-performance-load-fixture poo-performance-composition-fixture-path))

;; : String
(def poo-performance-extension-children-merge-fixture-path
  "t/scenarios/performance/poo-extension-children-merge/benchmark.ss")

;; : Alist
(def poo-performance-extension-children-merge-fixture
  (poo-performance-load-fixture
   poo-performance-extension-children-merge-fixture-path))

;; : String
(def poo-performance-cross-contribution-targeting-fixture-path
  "t/scenarios/performance/poo-cross-contribution-targeting/benchmark.ss")

;; : Alist
(def poo-performance-cross-contribution-targeting-fixture
  (poo-performance-load-fixture
   poo-performance-cross-contribution-targeting-fixture-path))

;; : String
(def poo-performance-local-contribution-coalescing-fixture-path
  "t/scenarios/performance/poo-local-contribution-coalescing/benchmark.ss")

;; : Alist
(def poo-performance-local-contribution-coalescing-fixture
  (poo-performance-load-fixture
   poo-performance-local-contribution-coalescing-fixture-path))

;; : [String]
(def poo-performance-fixture-paths
  (list poo-performance-construction-fixture-path
        poo-performance-materialization-fixture-path
        poo-performance-validation-fixture-path
        poo-performance-catalog-validation-fixture-path
        poo-performance-object-iteration-fixture-path
        poo-performance-clone-override-fixture-path
        poo-performance-field-lookup-fixture-path
        poo-performance-extension-children-merge-fixture-path
        poo-performance-cross-contribution-targeting-fixture-path
        poo-performance-local-contribution-coalescing-fixture-path
        poo-performance-composition-fixture-path))

;; : [Alist]
(def poo-performance-fixtures
  (list poo-performance-construction-fixture
        poo-performance-materialization-fixture
        poo-performance-validation-fixture
        poo-performance-catalog-validation-fixture
        poo-performance-object-iteration-fixture
        poo-performance-clone-override-fixture
        poo-performance-field-lookup-fixture
        poo-performance-extension-children-merge-fixture
        poo-performance-cross-contribution-targeting-fixture
        poo-performance-local-contribution-coalescing-fixture
        poo-performance-composition-fixture))

;; : (-> Alist Boolean)
(def (benchmark-fixture-memory-contract-pass? fixture)
  (let (max-rss-mb (benchmark-fixture-ref fixture 'maxRssMb))
    (and (integer? max-rss-mb)
         (> max-rss-mb 0))))

;; : (-> Alist (-> Value) Alist)
(def (poo-performance-run-gate fixture thunk)
  (if (benchmark-fixture-contract-pass? fixture)
    (benchmark-run fixture thunk)
    (error "poo performance fixture contract failed" fixture)))

;; : [Symbol]
(def poo-performance-required-form-evidence
  '(.o .def defpoo))

;; : [Symbol]
(def poo-performance-required-usage-call-evidence
  '(.ref .get .mix .o .def .putdefault! .setslot! setslots! .all-slots))

;; poo-performance-symbol-member?
;;   : (-> [Symbol] Symbol Boolean)
;;   | doc m%
;;       `poo-performance-symbol-member? values value` checks whether benchmark
;;       evidence includes one required POO API symbol using symbol identity.
;;
;;       # Examples
;;       ```scheme
;;       (poo-performance-symbol-member? '(.o .def) '.o)
;;       ;; => #t
;;       ```
;;     %
(def (poo-performance-symbol-member? values value)
  (ormap (lambda (candidate)
           (eq? candidate value))
         values))

;; poo-performance-evidence-covers?
;;   : (-> Alist Symbol [Symbol] Boolean)
;;   | doc m%
;;       `poo-performance-evidence-covers? fixture key required` verifies that
;;       a benchmark fixture records every required API witness under `key`.
;;
;;       # Examples
;;       ```scheme
;;       (poo-performance-evidence-covers?
;;        '((pooFormEvidence . (.o .def defpoo)))
;;        'pooFormEvidence
;;        '(.o .def))
;;       ;; => #t
;;       ```
;;     %
(def (poo-performance-evidence-covers? fixture key required)
  (let (values (benchmark-fixture-ref fixture key))
    (and (list? values)
         (not (ormap (lambda (required-value)
                       (not (poo-performance-symbol-member?
                             values
                             required-value)))
                     required)))))

;; : (-> Alist Boolean)
(def (poo-performance-api-evidence-contract-pass? fixture)
  (and (poo-performance-evidence-covers?
        fixture
        'pooFormEvidence
        poo-performance-required-form-evidence)
       (poo-performance-evidence-covers?
        fixture
        'pooUsageCallEvidence
        poo-performance-required-usage-call-evidence)))

;; : (-> Alist)
(def (poo-performance-api-usage-call-receipt)
  (let (object (.mix (.o (color 'blue))
                     (.o (name 'poo-api-evidence)
                         (field-count 2))))
    (.putdefault! object 'fallback 'defaulted)
    (.setslot! object dynamic ($constant-slot-spec 'slot-added-through-api))
    (list (cons 'name (.ref object 'name))
          (cons 'color (.get object color))
          (cons 'fallback (.get object fallback))
          (cons 'dynamic (.get object dynamic))
          (cons 'slots (.all-slots object)))))

;; : (-> Alist Symbol Value Value)
(def (poo-performance-slot-ref/default slots key default-value)
  (let (entry (assoc key slots))
    (if entry (cdr entry) default-value)))

;; poo-performance-build-list
;;   : (-> Integer (-> Integer Value) [Value])
;;   | doc m%
;;       `poo-performance-build-list count make-value` builds deterministic
;;       index-addressed fixture lists for synthetic benchmark data.
;;
;;       # Examples
;;       ```scheme
;;       (poo-performance-build-list 3 (lambda (index) index))
;;       ;; => (0 1 2)
;;       ```
;;     %
(def (poo-performance-build-list count make-value)
  (map make-value (iota count)))

;; : (-> Integer Symbol)
(def (poo-performance-field-name index)
  (string->symbol
   (string-append "field-" (number->string index))))

;; : (-> Integer PooModuleFieldContract)
(def (poo-performance-field-contract index)
  (poo-flow-module-field-contract
   (poo-performance-field-name index)
   'Any
   'override
   index
   '((scenario . poo-performance))))

;; : (-> Integer [PooModuleFieldContract])
(def (poo-performance-field-contracts count)
  (poo-performance-build-list count poo-performance-field-contract))

;; : (-> Integer PooModuleObject)
(def (poo-performance-module-object field-count)
  (poo-flow-module-object
   'performance-object
   '()
   (poo-performance-field-contracts field-count)
   '((scenario . poo-performance))))

;; : (-> Integer Integer [PooModuleObject])
(def (poo-performance-module-object-catalog object-count field-count)
  (let (base-object
        (poo-flow-module-object
         'performance-base
         '()
         (poo-performance-field-contracts field-count)
         '((scenario . poo-performance-base))))
    (poo-performance-build-list
     object-count
     (lambda (index)
       (poo-flow-module-object
        (string->symbol
         (string-append "performance-child-"
                        (number->string index)))
        (list base-object)
        '()
        '((scenario . poo-performance-child)))))))

;; : (-> Integer PooModuleObjectContributionEntries)
(def (poo-performance-contribution-entries count)
  (poo-performance-build-list
   count
   (lambda (index)
     (cons (poo-performance-field-name index)
           (+ index 1000)))))

;; poo-performance-catalog-contributions
;;   : (-> [PooModuleObject] Integer [PooModuleFieldContribution])
;;   | doc m%
;;       `poo-performance-catalog-contributions objects field-count` projects
;;       one shared contribution-entry fixture through every object in order.
;;
;;       # Examples
;;       ```scheme
;;       (length (poo-performance-catalog-contributions
;;                (poo-performance-module-object-catalog 2 3)
;;                3))
;;       ;; => 6
;;       ```
;;     %
(def (poo-performance-catalog-contributions objects field-count)
  (let (entries (poo-performance-contribution-entries field-count))
    (apply append
           (map (lambda (object)
                  (poo-flow-module-object-contributions object entries))
                objects))))

;; : (-> Integer Integer PooModuleSlotMap)
(def (poo-performance-override-slots count key-span)
  (poo-performance-build-list
   count
   (lambda (index)
     (cons (poo-performance-field-name (modulo index key-span))
           (+ index 2000)))))

;; poo-performance-snapshot-sum
;;   : (-> [Pair] Integer Integer)
;;   | doc m%
;;       `poo-performance-snapshot-sum slots rounds` repeats the same
;;       materialized slot-value sum to keep benchmark loops scalar and stable.
;;
;;       # Examples
;;       ```scheme
;;       (poo-performance-snapshot-sum '((a . 1) (b . 2)) 3)
;;       ;; => 9
;;       ```
;;     %
(def (poo-performance-snapshot-sum slots rounds)
  (* rounds (apply + (map cdr slots))))

;; poo-performance-object-node-lookup-count
;;   : (-> PooModuleExtensionNode [Symbol] Integer Integer)
;;   | doc m%
;;       `poo-performance-object-node-lookup-count objects-node identities
;;       rounds` counts indexed object hits once, then scales by benchmark rounds.
;;
;;       # Examples
;;       ```scheme
;;       (poo-performance-object-node-lookup-count
;;        (poo-flow-module-objects-node
;;         (poo-performance-module-object-catalog 2 1))
;;        '(performance-child-0 missing)
;;        3)
;;       ;; => 3
;;       ```
;;     %
(def (poo-performance-object-node-lookup-count objects-node identities rounds)
  (let (objects-index (poo-flow-module-objects-index objects-node))
    (* rounds
       (length
        (filter (lambda (identity)
                  (poo-flow-module-objects-ref/index objects-index identity))
                identities)))))

;; : (-> Integer Symbol)
(def (poo-performance-extension-child-name index)
  (string->symbol
   (string-append "extension-child-" (number->string index))))

;; : (-> Integer Integer PooModuleExtensionNode)
(def (poo-performance-extension-child index slot-offset)
  (poo-flow-module-extension-node
   (poo-performance-extension-child-name index)
   (list (cons 'value (+ slot-offset index)))
   '()))

;; : (-> Integer Integer [PooModuleExtensionNode])
(def (poo-performance-extension-children count slot-offset)
  (poo-performance-build-list
   count
   (lambda (index)
     (poo-performance-extension-child index slot-offset))))

;; : (-> Integer PooModuleExtensionNode)
(def (poo-performance-extension-merge-root count)
  (poo-flow-module-extension-node
   'extension-root
   '((kind . extension-merge-root))
   (poo-performance-extension-children count 1000)))

;; : (-> Integer Integer [PooModuleExtensionOperation])
(def (poo-performance-extension-node-extend-operations count key-span)
  (poo-performance-build-list
   count
   (lambda (index)
     (poo-flow-module-extension-node-extend
      (poo-flow-module-extension-node
       (poo-performance-extension-child-name (modulo index key-span))
       (list (cons 'value (+ 2000 index)))
       '())))))

;; : (-> Integer Symbol)
(def (poo-performance-cross-contribution-child-name index)
  (string->symbol
   (string-append "cross-contribution-child-" (number->string index))))

;; : (-> Integer PooModuleExtensionNode)
(def (poo-performance-cross-contribution-child index)
  (poo-flow-module-extension-node
   (poo-performance-cross-contribution-child-name index)
   (list (cons 'created-order index))
   '()))

;; : (-> Integer [PooModuleExtensionOperation])
(def (poo-performance-cross-contribution-create-operations count)
  (poo-performance-build-list
   count
   (lambda (index)
     (poo-flow-module-extension-node-extend
      (poo-performance-cross-contribution-child index)))))

;; : (-> Integer Symbol [PooModuleExtensionContribution])
(def (poo-performance-cross-contribution-targeting-contributions child-count target)
  (list
   (poo-flow-module-extension-contribution
    'extension-root
    (poo-performance-cross-contribution-create-operations child-count))
   (poo-flow-module-extension-contribution
    target
    (list (poo-flow-module-extension-slot-override 'targeted? #t)
          (poo-flow-module-extension-slot-override 'target-phase 'same-pass)))))

;; : (-> Symbol Integer [PooModuleExtensionContribution])
(def (poo-performance-local-slot-contributions target count)
  (poo-performance-build-list
   count
   (lambda (index)
     (poo-flow-module-extension-contribution
      target
      (list
       (poo-flow-module-extension-slot-override
        (poo-performance-field-name index)
        index))))))
