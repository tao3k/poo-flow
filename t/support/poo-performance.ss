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
        :poo-flow/src/module-system/indexed-family
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
        poo-performance-tool-calling-object-list-control-fixture-path
        poo-performance-tool-calling-object-list-control-fixture
        poo-performance-fixed-slot-projection-fixture-path
        poo-performance-fixed-slot-projection-fixture
        poo-performance-large-profile-projection-fixture-path
        poo-performance-large-profile-projection-fixture
        poo-performance-generated-receipt-boundary-fixture-path
        poo-performance-generated-receipt-boundary-fixture
        poo-performance-runtime-request-family-fixture-path
        poo-performance-runtime-request-family-fixture
        poo-performance-policy-proof-fact-family-fixture-path
        poo-performance-policy-proof-fact-family-fixture
        poo-performance-strategy-profile-family-fixture-path
        poo-performance-strategy-profile-family-fixture
        poo-performance-durable-receipt-family-fixture-path
        poo-performance-durable-receipt-family-fixture
        poo-performance-benchmark-fixture-family-fixture-path
        poo-performance-benchmark-fixture-family-fixture
        poo-performance-marlin-runtime-handoff-profile-fixture-path
        poo-performance-marlin-runtime-handoff-profile-fixture
        poo-performance-prototype-composition-cache-fixture-path
        poo-performance-prototype-composition-cache-fixture
        poo-performance-composition-profile-declaration-fixture-path
        poo-performance-composition-profile-declaration-fixture
        poo-performance-composition-profiles-bulk-fixture-path
        poo-performance-composition-profiles-bulk-fixture
        poo-performance-composition-local-override-fixture-path
        poo-performance-composition-local-override-fixture
        poo-performance-composition-hook-override-fixture-path
        poo-performance-composition-hook-override-fixture
        poo-performance-composition-native-object-reuse-fixture-path
        poo-performance-composition-native-object-reuse-fixture
        poo-performance-fixture-paths
        poo-performance-fixtures
        benchmark-fixture-memory-contract-pass?
        poo-performance-fixture-policy-contract-pass?
        poo-performance-display-receipt
        poo-performance-run-gate
        poo-performance-required-form-evidence
        poo-performance-required-usage-call-evidence
        poo-performance-symbol-member?
        poo-performance-evidence-covers?
        poo-performance-api-evidence-contract-pass?
        poo-performance-api-usage-call-receipt
        poo-performance-family
        poo-performance-family-alist
        poo-performance-family-ref
        poo-performance-family-run-gate
        poo-performance-family-descriptor-vector
        poo-performance-family-slot-lens
        poo-performance-family-slot-lens-ref
        poo-performance-indexed-family
        poo-performance-indexed-family-object
        poo-performance-indexed-family-ref
        poo-performance-indexed-family-slot-lens
        poo-performance-indexed-family-slot-lens-ref
        poo-performance-indexed-family-lenses
        poo-performance-indexed-family-project-descriptors
        +poo-performance-benchmark-receipt-family+
        +poo-performance-large-runtime-profile-family+
        +poo-performance-large-runtime-profile-layout+
        +poo-performance-large-runtime-profile-lenses+
        +poo-performance-fixed-slot-projection-family+
        poo-performance-large-profile-projection-descriptors
        poo-performance-large-profile-indexed-object
        poo-performance-large-profile-indexed-descriptors
        poo-performance-large-profile-indexed-valid-count
        poo-performance-large-profile-projection-valid-count
        poo-performance-large-profile-projection-gate-receipt
        poo-performance-generated-receipt-boundary-alist
        poo-performance-generated-receipt-boundary->alist
        poo-performance-generated-receipt-boundary-valid-count
        poo-performance-generated-receipt-boundary-gate-receipt
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

;; : (-> Alist)
(def (poo-performance-construction-fixture)
  (poo-performance-load-fixture poo-performance-construction-fixture-path))

;; : String
(def poo-performance-materialization-fixture-path
  "t/scenarios/performance/poo-loop-materialization/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-materialization-fixture)
  (poo-performance-load-fixture poo-performance-materialization-fixture-path))

;; : String
(def poo-performance-validation-fixture-path
  "t/scenarios/performance/poo-loop-validation/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-validation-fixture)
  (poo-performance-load-fixture poo-performance-validation-fixture-path))

;; : String
(def poo-performance-catalog-validation-fixture-path
  "t/scenarios/performance/poo-catalog-validation/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-catalog-validation-fixture)
  (poo-performance-load-fixture poo-performance-catalog-validation-fixture-path))

;; : String
(def poo-performance-object-iteration-fixture-path
  "t/scenarios/performance/poo-object-iteration/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-object-iteration-fixture)
  (poo-performance-load-fixture poo-performance-object-iteration-fixture-path))

;; : String
(def poo-performance-clone-override-fixture-path
  "t/scenarios/performance/poo-clone-override/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-clone-override-fixture)
  (poo-performance-load-fixture poo-performance-clone-override-fixture-path))

;; : String
(def poo-performance-field-lookup-fixture-path
  "t/scenarios/performance/poo-field-lookup-loop/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-field-lookup-fixture)
  (poo-performance-load-fixture poo-performance-field-lookup-fixture-path))

;; : String
(def poo-performance-composition-fixture-path
  "t/scenarios/performance/poo-loop-composition/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-composition-fixture)
  (poo-performance-load-fixture poo-performance-composition-fixture-path))

;; : String
(def poo-performance-extension-children-merge-fixture-path
  "t/scenarios/performance/poo-extension-children-merge/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-extension-children-merge-fixture)
  (poo-performance-load-fixture
   poo-performance-extension-children-merge-fixture-path))

;; : String
(def poo-performance-cross-contribution-targeting-fixture-path
  "t/scenarios/performance/poo-cross-contribution-targeting/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-cross-contribution-targeting-fixture)
  (poo-performance-load-fixture
   poo-performance-cross-contribution-targeting-fixture-path))

;; : String
(def poo-performance-local-contribution-coalescing-fixture-path
  "t/scenarios/performance/poo-local-contribution-coalescing/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-local-contribution-coalescing-fixture)
  (poo-performance-load-fixture
   poo-performance-local-contribution-coalescing-fixture-path))

;; : String
(def poo-performance-tool-calling-object-list-control-fixture-path
  "t/scenarios/performance/tool-calling-object-list-control/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-tool-calling-object-list-control-fixture)
  (poo-performance-load-fixture
   poo-performance-tool-calling-object-list-control-fixture-path))

;; : String
(def poo-performance-fixed-slot-projection-fixture-path
  "t/scenarios/performance/poo-fixed-slot-projection/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-fixed-slot-projection-fixture)
  (poo-performance-load-fixture
   poo-performance-fixed-slot-projection-fixture-path))

(def poo-performance-large-profile-projection-fixture-path
  "t/scenarios/performance/poo-large-profile-projection/benchmark.ss")

(def (poo-performance-large-profile-projection-fixture)
  (poo-performance-load-fixture
   poo-performance-large-profile-projection-fixture-path))

(def poo-performance-generated-receipt-boundary-fixture-path
  "t/scenarios/performance/poo-generated-receipt-boundary/benchmark.ss")

(def (poo-performance-generated-receipt-boundary-fixture)
  (poo-performance-load-fixture
   poo-performance-generated-receipt-boundary-fixture-path))

;; : String
(def poo-performance-runtime-request-family-fixture-path
  "t/scenarios/performance/poo-runtime-request-family/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-runtime-request-family-fixture)
  (poo-performance-load-fixture
   poo-performance-runtime-request-family-fixture-path))

;; : String
(def poo-performance-policy-proof-fact-family-fixture-path
  "t/scenarios/performance/poo-policy-proof-fact-family/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-policy-proof-fact-family-fixture)
  (poo-performance-load-fixture
   poo-performance-policy-proof-fact-family-fixture-path))

;; : String
(def poo-performance-strategy-profile-family-fixture-path
  "t/scenarios/performance/poo-strategy-profile-family/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-strategy-profile-family-fixture)
  (poo-performance-load-fixture
   poo-performance-strategy-profile-family-fixture-path))

;; : String
(def poo-performance-durable-receipt-family-fixture-path
  "t/scenarios/performance/poo-durable-receipt-family/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-durable-receipt-family-fixture)
  (poo-performance-load-fixture
   poo-performance-durable-receipt-family-fixture-path))

;; : String
(def poo-performance-benchmark-fixture-family-fixture-path
  "t/scenarios/performance/poo-benchmark-fixture-family/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-benchmark-fixture-family-fixture)
  (poo-performance-load-fixture
   poo-performance-benchmark-fixture-family-fixture-path))

;; : String
(def poo-performance-marlin-runtime-handoff-profile-fixture-path
  "t/scenarios/performance/poo-marlin-runtime-handoff-profile/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-marlin-runtime-handoff-profile-fixture)
  (poo-performance-load-fixture
   poo-performance-marlin-runtime-handoff-profile-fixture-path))

;; : String
(def poo-performance-prototype-composition-cache-fixture-path
  "t/scenarios/performance/poo-prototype-composition-cache/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-prototype-composition-cache-fixture)
  (poo-performance-load-fixture
   poo-performance-prototype-composition-cache-fixture-path))

;; : String
(def poo-performance-composition-profile-declaration-fixture-path
  "t/scenarios/performance/poo-composition-profile-declaration/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-composition-profile-declaration-fixture)
  (poo-performance-load-fixture
   poo-performance-composition-profile-declaration-fixture-path))

;; : String
(def poo-performance-composition-profiles-bulk-fixture-path
  "t/scenarios/performance/poo-composition-profiles-bulk/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-composition-profiles-bulk-fixture)
  (poo-performance-load-fixture
   poo-performance-composition-profiles-bulk-fixture-path))

;; : String
(def poo-performance-composition-local-override-fixture-path
  "t/scenarios/performance/poo-composition-local-override/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-composition-local-override-fixture)
  (poo-performance-load-fixture
   poo-performance-composition-local-override-fixture-path))

;; : String
(def poo-performance-composition-hook-override-fixture-path
  "t/scenarios/performance/poo-composition-hook-override/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-composition-hook-override-fixture)
  (poo-performance-load-fixture
   poo-performance-composition-hook-override-fixture-path))

;; : String
(def poo-performance-composition-native-object-reuse-fixture-path
  "t/scenarios/performance/poo-composition-native-object-reuse/benchmark.ss")

;; : (-> Alist)
(def (poo-performance-composition-native-object-reuse-fixture)
  (poo-performance-load-fixture
   poo-performance-composition-native-object-reuse-fixture-path))

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
        poo-performance-tool-calling-object-list-control-fixture-path
        poo-performance-fixed-slot-projection-fixture-path
        poo-performance-large-profile-projection-fixture-path
        poo-performance-generated-receipt-boundary-fixture-path
        poo-performance-runtime-request-family-fixture-path
        poo-performance-policy-proof-fact-family-fixture-path
        poo-performance-strategy-profile-family-fixture-path
        poo-performance-durable-receipt-family-fixture-path
        poo-performance-benchmark-fixture-family-fixture-path
        poo-performance-marlin-runtime-handoff-profile-fixture-path
        poo-performance-prototype-composition-cache-fixture-path
        poo-performance-composition-profile-declaration-fixture-path
        poo-performance-composition-profiles-bulk-fixture-path
        poo-performance-composition-local-override-fixture-path
        poo-performance-composition-hook-override-fixture-path
        poo-performance-composition-native-object-reuse-fixture-path
        poo-performance-composition-fixture-path))

;; : (-> [Alist])
(def (poo-performance-fixtures)
  (map poo-performance-load-fixture poo-performance-fixture-paths))

;; : (-> Alist Boolean)
(def (benchmark-fixture-memory-contract-pass? fixture)
  (let (max-rss-mb (poo-performance-slot-ref/default
                    fixture
                    'maxRssMb
                    #f))
    (and (integer? max-rss-mb)
         (> max-rss-mb 0))))

;; : [Symbol]
(def poo-performance-required-policy-keys
  '(max_total
    maxCollectMs
    maxParseMs
    maxFileMs
    maxPhaseMs
    observedCollectMs
    observedParseMs
    observedFileMs
    observedPhaseMs
    observed_total
    target_total
    regression_budget
    expected_over_input_budget
    observedTimings
    targetRationale
    maxRssMb
    memoryMetric
    memoryUnit
    iterations
    unit
    sourcePath
    rule
    feature
    optimizationFocus
    inputShape
    expectedRepair
    pooFormEvidence
    pooUsageCallEvidence
    measurementPhases
    tags))

;; : (-> Alist [Symbol] Boolean)
(def (poo-performance-fixture-keys-present? fixture keys)
  (not (ormap (lambda (key)
                (not (assoc key fixture)))
              keys)))

;; : (-> Alist Symbol Boolean)
(def (poo-performance-fixture-positive-integer? fixture key)
  (let (value (poo-performance-slot-ref/default fixture key #f))
    (and (integer? value) (> value 0))))

;; : (-> Alist Symbol Boolean)
(def (poo-performance-fixture-nonempty-string? fixture key)
  (let (value (poo-performance-slot-ref/default fixture key #f))
    (and (string? value) (> (string-length value) 0))))

;; : (-> Alist Boolean)
(def (poo-performance-source-path-contract-pass? fixture)
  (let (source-path (poo-performance-slot-ref/default
                    fixture
                    'sourcePath
                    #f))
    (and (string? source-path)
         (> (string-length source-path) 0)
         (file-exists? source-path))))

;; : (-> Alist Boolean)
(def (poo-performance-timing-budget-contract-pass? fixture)
  (and (poo-performance-fixture-positive-integer? fixture 'maxCollectMs)
       (poo-performance-fixture-positive-integer? fixture 'maxParseMs)
       (poo-performance-fixture-positive-integer? fixture 'maxFileMs)
       (poo-performance-fixture-positive-integer? fixture 'maxPhaseMs)
       (poo-performance-fixture-positive-integer? fixture 'observedCollectMs)
       (poo-performance-fixture-positive-integer? fixture 'observedParseMs)
       (poo-performance-fixture-positive-integer? fixture 'observedFileMs)
       (poo-performance-fixture-positive-integer? fixture 'observedPhaseMs)
       (poo-performance-fixture-positive-integer? fixture 'iterations)))

;; : (-> Alist Boolean)
(def (poo-performance-memory-metric-contract-pass? fixture)
  (and (eq? (poo-performance-slot-ref/default
             fixture
             'memoryMetric
             #f)
            'resident-set-size)
       (equal? (poo-performance-slot-ref/default
                fixture
                'memoryUnit
                #f)
               "MB")
       (benchmark-fixture-memory-contract-pass? fixture)))

;; : (-> Alist Boolean)
(def (poo-performance-text-policy-contract-pass? fixture)
  (and (poo-performance-fixture-nonempty-string? fixture 'targetRationale)
       (poo-performance-fixture-nonempty-string? fixture 'optimizationFocus)
       (poo-performance-fixture-nonempty-string? fixture 'inputShape)
       (poo-performance-fixture-nonempty-string? fixture 'expectedRepair)
       (equal? (poo-performance-slot-ref/default fixture 'unit #f) "ms")
       (symbol? (poo-performance-slot-ref/default fixture 'rule #f))
       (symbol? (poo-performance-slot-ref/default fixture 'feature #f))))

;; : (-> Alist Boolean)
(def (poo-performance-observed-timing-entry-contract-pass? entry)
  (and (list? entry)
       (poo-performance-fixture-nonempty-string? entry 'name)
       (poo-performance-fixture-positive-integer? entry 'durationMs)))

;; : (-> Alist Boolean)
(def (poo-performance-observed-timings-contract-pass? fixture)
  (let (timings (poo-performance-slot-ref/default
                 fixture
                 'observedTimings
                 #f))
    (and (list? timings)
         (not (null? timings))
         (not (ormap (lambda (entry)
                       (not (poo-performance-observed-timing-entry-contract-pass?
                             entry)))
                     timings)))))

;; : (-> Alist Boolean)
(def (poo-performance-measurement-phase-contract-pass? fixture)
  (let (phases (poo-performance-slot-ref/default
                fixture
                'measurementPhases
                #f))
    (and (list? phases)
         (poo-performance-symbol-member? phases 'assert-time-gate)
         (poo-performance-symbol-member? phases 'assert-memory-gate))))

;; : (-> Alist Boolean)
(def (poo-performance-tags-contract-pass? fixture)
  (let (tags (poo-performance-slot-ref/default fixture 'tags #f))
    (and (list? tags)
         (poo-performance-symbol-member? tags 'poo)
         (poo-performance-symbol-member? tags 'performance))))

;; : (-> Alist Boolean)
(def (poo-performance-fixture-policy-contract-pass? fixture)
  (and (benchmark-fixture-contract-pass? fixture)
       (poo-performance-fixture-keys-present?
        fixture
        poo-performance-required-policy-keys)
       (benchmark-fixture-memory-contract-pass? fixture)
       (poo-performance-source-path-contract-pass? fixture)
       (poo-performance-timing-budget-contract-pass? fixture)
       (poo-performance-memory-metric-contract-pass? fixture)
       (poo-performance-text-policy-contract-pass? fixture)
       (poo-performance-observed-timings-contract-pass? fixture)
       (poo-performance-measurement-phase-contract-pass? fixture)
       (poo-performance-tags-contract-pass? fixture)
       (poo-performance-api-evidence-contract-pass? fixture)))

;; : (-> Alist Unit)
(def (poo-performance-display-receipt receipt)
  (display "[poo-flow-benchmark] ")
  (write (benchmark-fixture-ref receipt 'feature))
  (display " ")
  (write receipt)
  (newline)
  (force-output))

;; : (-> Alist (-> Value) Alist)
(def (poo-performance-run-gate fixture thunk)
  (if (poo-performance-fixture-policy-contract-pass? fixture)
    (benchmark-run fixture thunk)
    (error "poo performance fixture policy contract failed" fixture)))

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

;; : (-> Symbol Symbol PooObject)
(def (poo-performance-family family-name source-tag)
  (.o (kind 'poo-performance-family)
      (name family-name)
      (source source-tag)))

;; : PooObject
(def +poo-performance-benchmark-receipt-family+
  (poo-performance-family 'poo-performance-benchmark-receipt-family
                          'poo-flow.performance.benchmark))

;; : PooObject
(def +poo-performance-large-runtime-profile-family+
  (poo-performance-family 'poo-performance-large-runtime-profile-family
                          'poo-flow.performance.large-runtime-profile))

;; : PooObject
(def +poo-performance-fixed-slot-projection-family+
  (poo-performance-family 'poo-performance-fixed-slot-projection-family
                          'poo-flow.performance.fixed-slot-projection))

;; : (-> PooObject Alist Alist)
(def (poo-performance-family-alist family alist)
  (let* ((family-name (.ref family 'name))
         (source-tag (.ref family 'source))
         (with-family
          (if (assoc 'family alist)
            alist
            (cons (cons 'family family-name) alist))))
    (if (or (not source-tag) (assoc 'source with-family))
      with-family
      (cons (cons 'source source-tag) with-family))))

;; : (-> PooObject Alist Symbol Value Value)
(def (poo-performance-family-ref family alist key default-value)
  (if (eq? (poo-performance-slot-ref/default
            alist
            'family
            #f)
           (.ref family 'name))
    (poo-performance-slot-ref/default alist key default-value)
    default-value))

;; : (-> PooObject Alist (-> Value) Alist)
(def (poo-performance-family-run-gate family fixture thunk)
  (poo-performance-family-alist
   family
   (poo-performance-run-gate fixture thunk)))

;; : (-> (Listof Symbol) Alist)
(def (poo-performance-index-slots slot-names)
  (poo-index-slots slot-names))

;; : (-> Symbol Symbol (Listof Symbol) POOObject)
(def (poo-performance-indexed-family family-name source-tag slot-names)
  (poo-indexed-family family-name source-tag slot-names))

;; : (-> POOObject Symbol (Maybe Fixnum))
(def (poo-performance-indexed-family-slot-index family-object slot-name)
  (poo-indexed-family-slot-index family-object slot-name))

;; : (-> POOObject (Listof Any) POOObject)
(def (poo-performance-indexed-family-object family-object values)
  (poo-indexed-family-object family-object values))

;; : (-> POOObject POOObject Symbol Any Any)
(def (poo-performance-indexed-family-ref family-object object slot-name default-value)
  (poo-indexed-family-ref family-object object slot-name default-value))

;; : (-> POOObject Symbol Symbol POOObject)
(def (poo-performance-indexed-family-named-slot-lens family-object slot-name descriptor-name)
  (poo-indexed-family-named-slot-lens family-object
                                      slot-name
                                      descriptor-name))

;; : (-> POOObject Symbol POOObject)
(def (poo-performance-indexed-family-slot-lens family-object slot-name)
  (poo-indexed-family-slot-lens family-object slot-name))

;; : (-> POOObject (Listof Pair) Vector)
(def (poo-performance-indexed-family-lenses family-object specs)
  (poo-indexed-family-lenses family-object specs))

;; : (-> POOObject POOObject Any Any)
(def (poo-performance-indexed-family-slot-lens-ref lens object default-value)
  (poo-indexed-family-slot-lens-ref lens object default-value))

;; : (-> POOObject POOObject Vector Vector)
(def (poo-performance-indexed-family-project-descriptors family-object object lenses)
  (poo-indexed-family-project-descriptors
   family-object
   object
   lenses
   (lambda (descriptor-family descriptor-name value)
     (poo-performance-family-alist
      descriptor-family
      (list (cons 'name descriptor-name)
            (cons 'value value))))))

;; : (-> PooObject PooObject [Pair] Vector)
(def (poo-performance-family-descriptor-vector family object specs)
  (list->vector
   (let loop ((rest specs) (descriptors-rev '()))
     (if (null? rest)
       (reverse descriptors-rev)
       (let* ((spec (car rest))
              (slot (car spec))
              (name (cdr spec)))
         (loop (cdr rest)
               (cons (poo-performance-family-alist
                      family
                      (list (cons 'name name)
                            (cons 'value (.ref object slot))))
                     descriptors-rev)))))))

;; : (-> PooObject Symbol PooObject)
(def (poo-performance-family-slot-lens family-object slot-name)
  (.o (kind 'poo-performance-family-slot-lens)
      (family family-object)
      (slot slot-name)))

;; : (-> PooObject PooObject Value)
(def (poo-performance-family-slot-lens-ref lens object)
  (.ref object (.ref lens 'slot)))

;; : [Pair]
(def +poo-performance-large-profile-projection-specs+
  '((profile-id . profile-id)
    (policy . policy)
    (strategy . strategy)
    (sandbox . sandbox)
    (tool-scope . tool-scope)
    (checkpoint . checkpoint)
    (handoff . handoff)
    (proof . proof)
    (priority . priority)
    (limit . limit)))

(def +poo-performance-large-runtime-profile-layout+
  (poo-performance-indexed-family
   'poo-performance-large-runtime-profile-family
   'poo-flow.performance.large-runtime-profile
   (map car +poo-performance-large-profile-projection-specs+)))

(def +poo-performance-large-runtime-profile-lenses+
  (poo-performance-indexed-family-lenses
   +poo-performance-large-runtime-profile-layout+
   +poo-performance-large-profile-projection-specs+))

;; : (-> PooObject)
(def (poo-performance-large-profile-projection-profile)
  (.o (profile-id 'large-profile)
      (family 'poo-performance-large-runtime-profile-family)
      (policy 'loop-policy)
      (strategy 'graph-strategy)
      (sandbox 'scoped-sandbox)
      (tool-scope 'declared-tools)
      (checkpoint 'durable-checkpoint)
      (handoff 'runtime-language)
      (proof 'lean-required)
      (priority 7)
      (limit 128)))

;; : (-> Vector)
(def (poo-performance-large-profile-projection-descriptors)
  (let (profile (poo-performance-large-profile-projection-profile))
    (poo-performance-family-descriptor-vector
     +poo-performance-large-runtime-profile-family+
     profile
     +poo-performance-large-profile-projection-specs+)))

(def (poo-performance-large-profile-indexed-object)
  (poo-performance-indexed-family-object
   +poo-performance-large-runtime-profile-layout+
   '(large-profile
     loop-policy
     graph-strategy
     scoped-sandbox
     declared-tools
     durable-checkpoint
     runtime-language
     lean-required
     7
     128)))

(def (poo-performance-large-profile-indexed-descriptors)
  (poo-performance-indexed-family-project-descriptors
   +poo-performance-large-runtime-profile-layout+
   (poo-performance-large-profile-indexed-object)
   +poo-performance-large-runtime-profile-lenses+))

(def (poo-performance-large-profile-indexed-valid-count rounds)
  (let* ((object (poo-performance-large-profile-indexed-object))
         (lenses +poo-performance-large-runtime-profile-lenses+)
         (count (vector-length lenses))
         (first-lens (vector-ref lenses 0))
         (last-lens (vector-ref lenses (- count 1))))
    (if (and (= count 10)
             (eq? (.ref object 'family)
                  +poo-performance-large-runtime-profile-layout+)
             (eq? (poo-performance-indexed-family-slot-lens-ref
                   first-lens
                   object
                   #f)
                  'large-profile)
             (= (poo-performance-indexed-family-slot-lens-ref
                 last-lens
                 object
                 #f)
                128))
      rounds
      0)))

;; : (-> Integer Integer)
(def (poo-performance-large-profile-projection-valid-count rounds)
  (let* ((descriptors
          (poo-performance-large-profile-projection-descriptors))
         (count (vector-length descriptors))
         (first-descriptor (vector-ref descriptors 0))
         (last-descriptor (vector-ref descriptors (- count 1)))
         (valid?
          (and (= count 10)
               (eq? (poo-performance-family-ref
                     +poo-performance-large-runtime-profile-family+
                     first-descriptor
                     'name
                     #f)
                    'profile-id)
               (eq? (cdr (assoc 'value first-descriptor)) 'large-profile)
               (= (cdr (assoc 'value last-descriptor)) 128))))
    (if valid? rounds 0)))

;; : (-> Integer Alist)
(def (poo-performance-large-profile-projection-gate-receipt rounds)
  (poo-performance-family-run-gate
   +poo-performance-benchmark-receipt-family+
   (poo-performance-large-profile-projection-fixture)
   (lambda ()
     (poo-performance-large-profile-projection-valid-count rounds))))

(defstruct poo-performance-generated-loop-receipt
  (profile-id status runtime checkpoint sandbox tool-scope proof))

;; : (-> Integer PooPerformanceGeneratedLoopReceipt)
(def (poo-performance-generated-receipt-boundary-record index)
  (make-poo-performance-generated-loop-receipt
   index
   'ready
   'runtime-language
   'durable-checkpoint
   'scoped-sandbox
   'declared-tools
   'lean-required))

;; : (-> PooPerformanceGeneratedLoopReceipt Alist)
(def (poo-performance-generated-receipt-boundary->alist receipt)
  (poo-performance-family-alist
   +poo-performance-benchmark-receipt-family+
   (list
    (cons 'profile-id
          (poo-performance-generated-loop-receipt-profile-id receipt))
    (cons 'status
          (poo-performance-generated-loop-receipt-status receipt))
    (cons 'runtime
          (poo-performance-generated-loop-receipt-runtime receipt))
    (cons 'checkpoint
          (poo-performance-generated-loop-receipt-checkpoint receipt))
    (cons 'sandbox
          (poo-performance-generated-loop-receipt-sandbox receipt))
    (cons 'tool-scope
          (poo-performance-generated-loop-receipt-tool-scope receipt))
    (cons 'proof
          (poo-performance-generated-loop-receipt-proof receipt)))))

;; : (-> Alist)
(def (poo-performance-generated-receipt-boundary-alist)
  (poo-performance-generated-receipt-boundary->alist
   (poo-performance-generated-receipt-boundary-record 41)))

;; : (-> Integer Integer)
(def (poo-performance-generated-receipt-boundary-valid-count rounds)
  (let* ((receipt-alist
          (poo-performance-generated-receipt-boundary-alist))
         (valid?
          (and (= (cdr (assoc 'profile-id receipt-alist)) 41)
               (eq? (cdr (assoc 'status receipt-alist)) 'ready)
               (eq? (cdr (assoc 'proof receipt-alist)) 'lean-required))))
    (if valid? rounds 0)))

;; : (-> Integer Alist)
(def (poo-performance-generated-receipt-boundary-gate-receipt rounds)
  (poo-performance-family-run-gate
   +poo-performance-benchmark-receipt-family+
   (poo-performance-generated-receipt-boundary-fixture)
   (lambda ()
     (poo-performance-generated-receipt-boundary-valid-count rounds))))

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
(def (poo-performance-values/rev-onto values values-rev)
  (let loop ((remaining-values values)
             (result values-rev))
    (if (null? remaining-values)
      result
      (loop (cdr remaining-values)
            (cons (car remaining-values) result)))))

(def (poo-performance-object-contributions/rev objects entries contributions-rev)
  (if (null? objects)
    contributions-rev
    (poo-performance-object-contributions/rev
     (cdr objects)
     entries
     (poo-performance-values/rev-onto
      (poo-flow-module-object-contributions (car objects) entries)
      contributions-rev))))

(def (poo-performance-catalog-contributions objects field-count)
  (let (entries (poo-performance-contribution-entries field-count))
    (reverse
     (poo-performance-object-contributions/rev objects entries '()))))

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
