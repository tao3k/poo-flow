;;; -*- Gerbil -*-
;;; Boundary: compare two same-host Scheme compile sample sets.
;;; Invariant: absolute wall-clock limits are not performance budgets.  The
;;; budget is a relative policy over comparable, identity-scoped medians.

(import :clan/poo/object
        :gerbil/gambit
        (only-in :std/text/json
                 json-object->string
                 write-json-sort-keys?)
        (only-in :poo-flow/src/utilities/functional
                 poo-flow-all?
                 poo-flow-fold-left
                 poo-flow-map))

(export poo-flow-scheme-compile-performance-observation
        poo-flow-scheme-compile-performance-observation?
        poo-flow-scheme-compile-performance-budget-receipt
        poo-flow-scheme-compile-performance-budget-receipt-accepted?
        poo-flow-scheme-compile-performance-budget-receipt->alist
        poo-flow-scheme-compile-performance-budget-receipt->json-object
        poo-flow-scheme-compile-performance-budget-receipt->json-string)

(def +poo-flow-scheme-compile-performance-observation-schema+
  'poo-flow.scheme-compile-performance-observation.v1)

(def +poo-flow-scheme-compile-performance-budget-schema+
  'poo-flow.scheme-compile-performance-budget-receipt.v1)

(def +poo-flow-scheme-compile-comparable-identity-fields+
  '(runner
    host-session-id
    toolchain-identity
    execution-policy
    logical-cpu-count
    worker-count
    coldness-class
    dependency-cache-state))

(def +poo-flow-scheme-compile-sample-set-identity-fields+
  (append +poo-flow-scheme-compile-comparable-identity-fields+
          '(revision source-digest spec-count)))

;; : (-> String Boolean Object Void)
(def (poo-flow-scheme-compile-performance-require message condition value)
  (unless condition
    (error message value)))

;; : (-> Object Boolean)
(def (poo-flow-scheme-compile-positive-integer? value)
  (and (exact-integer? value) (> value 0)))

;; : (-> Object Boolean)
(def (poo-flow-scheme-compile-nonnegative-integer? value)
  (and (exact-integer? value) (>= value 0)))

;; : (-> String String String String Symbol Integer Integer Integer Symbol Symbol Integer POOObject)
(def (poo-flow-scheme-compile-performance-observation
      revision
      runner
      host-session-id
      toolchain-identity
      source-digest
      execution-policy
      logical-cpu-count
      worker-count
      spec-count
      coldness-class
      dependency-cache-state
      elapsed-ms)
  (for-each
   (lambda (entry)
     (poo-flow-scheme-compile-performance-require
      "Scheme compile performance identity must be a non-empty string"
      (and (string? (cdr entry))
           (> (string-length (cdr entry)) 0))
      entry))
   (list (cons 'revision revision)
         (cons 'runner runner)
         (cons 'host-session-id host-session-id)
         (cons 'toolchain-identity toolchain-identity)
         (cons 'source-digest source-digest)))
  (for-each
   (lambda (entry)
     (poo-flow-scheme-compile-performance-require
      "Scheme compile performance capacity must be a positive integer"
      (poo-flow-scheme-compile-positive-integer? (cdr entry))
      entry))
   (list (cons 'logical-cpu-count logical-cpu-count)
         (cons 'worker-count worker-count)
         (cons 'spec-count spec-count)
         (cons 'elapsed-ms elapsed-ms)))
  (for-each
   (lambda (entry)
     (poo-flow-scheme-compile-performance-require
      "Scheme compile performance classification must be a symbol"
      (symbol? (cdr entry))
      entry))
   (list (cons 'execution-policy execution-policy)
         (cons 'coldness-class coldness-class)
         (cons 'dependency-cache-state dependency-cache-state)))
  (let ((revision-value revision)
        (runner-value runner)
        (host-session-id-value host-session-id)
        (toolchain-identity-value toolchain-identity)
        (source-digest-value source-digest)
        (execution-policy-value execution-policy)
        (logical-cpu-count-value logical-cpu-count)
        (worker-count-value worker-count)
        (spec-count-value spec-count)
        (coldness-class-value coldness-class)
        (dependency-cache-state-value dependency-cache-state)
        (elapsed-ms-value elapsed-ms))
    (.o (schema +poo-flow-scheme-compile-performance-observation-schema+)
        (kind 'scheme-compile-performance-observation)
        (revision revision-value)
        (runner runner-value)
        (host-session-id host-session-id-value)
        (toolchain-identity toolchain-identity-value)
        (source-digest source-digest-value)
        (execution-policy execution-policy-value)
        (logical-cpu-count logical-cpu-count-value)
        (worker-count worker-count-value)
        (spec-count spec-count-value)
        (coldness-class coldness-class-value)
        (dependency-cache-state dependency-cache-state-value)
        (elapsed-ms elapsed-ms-value))))

;; : (-> Object Boolean)
(def (poo-flow-scheme-compile-performance-observation? value)
  (with-catch
   (lambda (_error) #f)
   (lambda ()
     (eq? (.ref value 'schema)
          +poo-flow-scheme-compile-performance-observation-schema+))))

;; : (-> Object [Integer] [Integer])
(def (poo-flow-scheme-compile-insert-elapsed elapsed sorted)
  (cond
   ((null? sorted) (list elapsed))
   ((<= elapsed (car sorted)) (cons elapsed sorted))
   (else
    (cons (car sorted)
          (poo-flow-scheme-compile-insert-elapsed elapsed (cdr sorted))))))

;; : (-> [Integer] [Integer])
(def (poo-flow-scheme-compile-sort-elapsed values)
  (poo-flow-fold-left
   (lambda (value sorted)
     (poo-flow-scheme-compile-insert-elapsed value sorted))
   '()
   values))

;; : (-> [Integer] Integer)
(def (poo-flow-scheme-compile-median values)
  (let (sorted (poo-flow-scheme-compile-sort-elapsed values))
    (list-ref sorted (quotient (length sorted) 2))))

;; : (-> POOObject [Symbol] Alist)
(def (poo-flow-scheme-compile-observation-identity observation fields)
  (poo-flow-map
   (lambda (field) (cons field (.ref observation field)))
   fields))

;; : (-> [POOObject] [Symbol] Boolean)
(def (poo-flow-scheme-compile-observations-share-identity?
      observations fields)
  (let (expected
        (poo-flow-scheme-compile-observation-identity
         (car observations)
         fields))
    (poo-flow-all?
     (lambda (observation)
       (equal?
        expected
        (poo-flow-scheme-compile-observation-identity
         observation
         fields)))
     (cdr observations))))

;; : (-> Symbol [POOObject] Void)
(def (poo-flow-scheme-compile-validate-sample-set! label observations)
  (poo-flow-scheme-compile-performance-require
   "Scheme compile performance samples must be a non-empty list"
   (and (list? observations) (pair? observations))
   label)
  (poo-flow-scheme-compile-performance-require
   "Scheme compile performance samples must contain an odd count of at least three"
   (and (>= (length observations) 3)
        (odd? (length observations)))
   (cons label (length observations)))
  (poo-flow-scheme-compile-performance-require
   "Scheme compile performance samples must be observation objects"
   (poo-flow-all?
    poo-flow-scheme-compile-performance-observation?
    observations)
   label)
  (poo-flow-scheme-compile-performance-require
   "Scheme compile performance samples must share one side-local identity"
   (poo-flow-scheme-compile-observations-share-identity?
    observations
    +poo-flow-scheme-compile-sample-set-identity-fields+)
   label))

;; : (-> Integer Integer Integer)
(def (poo-flow-scheme-compile-relative-ceiling-ms
      baseline-median-ms maximum-regression-basis-points)
  (quotient
   (+ (* baseline-median-ms
         (+ 10000 maximum-regression-basis-points))
      9999)
   10000))

;; : (-> Integer Integer Integer)
(def (poo-flow-scheme-compile-regression-basis-points
      baseline-median-ms candidate-median-ms)
  (quotient
   (* (- candidate-median-ms baseline-median-ms) 10000)
   baseline-median-ms))

;; : (-> [POOObject] [POOObject] Integer POOObject)
(def (poo-flow-scheme-compile-performance-budget-receipt
      baseline-observations
      candidate-observations
      maximum-regression-basis-points)
  (poo-flow-scheme-compile-validate-sample-set!
   'baseline
   baseline-observations)
  (poo-flow-scheme-compile-validate-sample-set!
   'candidate
   candidate-observations)
  (poo-flow-scheme-compile-performance-require
   "Scheme compile performance sample sets must contain the same sample count"
   (= (length baseline-observations)
      (length candidate-observations))
   (list (length baseline-observations)
         (length candidate-observations)))
  (poo-flow-scheme-compile-performance-require
   "Scheme compile performance budget must be non-negative basis points"
   (poo-flow-scheme-compile-nonnegative-integer?
    maximum-regression-basis-points)
   maximum-regression-basis-points)
  (let* ((baseline-first (car baseline-observations))
         (candidate-first (car candidate-observations))
         (comparable?
          (equal?
           (poo-flow-scheme-compile-observation-identity
            baseline-first
            +poo-flow-scheme-compile-comparable-identity-fields+)
           (poo-flow-scheme-compile-observation-identity
            candidate-first
            +poo-flow-scheme-compile-comparable-identity-fields+)))
         (baseline-median-ms
          (poo-flow-scheme-compile-median
           (poo-flow-map
            (lambda (observation) (.ref observation 'elapsed-ms))
            baseline-observations)))
         (candidate-median-ms
          (poo-flow-scheme-compile-median
           (poo-flow-map
            (lambda (observation) (.ref observation 'elapsed-ms))
            candidate-observations)))
         (relative-ceiling-ms
          (poo-flow-scheme-compile-relative-ceiling-ms
           baseline-median-ms
           maximum-regression-basis-points))
         (within-budget?
          (and comparable?
               (<= candidate-median-ms relative-ceiling-ms)))
         (outcome
          (cond
           ((not comparable?) 'incomparable)
           (within-budget? 'accepted)
           (else 'regressed)))
         (diagnostics
          (cond
           ((not comparable?) '(comparison-identity-mismatch))
           (within-budget? '())
           (else '(relative-performance-budget-exceeded)))))
    (let ((outcome-value outcome)
          (comparable-value comparable?)
          (within-budget-value within-budget?)
          (diagnostics-value diagnostics)
          (maximum-regression-basis-points-value
           maximum-regression-basis-points)
          (baseline-median-ms-value baseline-median-ms)
          (candidate-median-ms-value candidate-median-ms)
          (relative-ceiling-ms-value relative-ceiling-ms)
          (regression-basis-points-value
           (poo-flow-scheme-compile-regression-basis-points
            baseline-median-ms
            candidate-median-ms))
          (baseline-source-digest-value
           (.ref baseline-first 'source-digest))
          (candidate-source-digest-value
           (.ref candidate-first 'source-digest))
          (baseline-spec-count-value
           (.ref baseline-first 'spec-count))
          (candidate-spec-count-value
           (.ref candidate-first 'spec-count))
          (sample-count-value (length baseline-observations))
          (comparison-identity-value
           (poo-flow-scheme-compile-observation-identity
            baseline-first
            +poo-flow-scheme-compile-comparable-identity-fields+)))
      (.o (schema +poo-flow-scheme-compile-performance-budget-schema+)
          (kind 'scheme-compile-performance-budget-receipt)
          (outcome outcome-value)
          (comparable comparable-value)
          (within-budget within-budget-value)
          (diagnostics diagnostics-value)
          (maximum-regression-basis-points
           maximum-regression-basis-points-value)
          (sample-count sample-count-value)
          (baseline-median-ms baseline-median-ms-value)
          (candidate-median-ms candidate-median-ms-value)
          (relative-ceiling-ms relative-ceiling-ms-value)
          (regression-basis-points regression-basis-points-value)
          (baseline-source-digest baseline-source-digest-value)
          (candidate-source-digest candidate-source-digest-value)
          (baseline-spec-count baseline-spec-count-value)
          (candidate-spec-count candidate-spec-count-value)
          (comparison-identity comparison-identity-value)
          (runtime-owner 'poo-flow-scheme-control-plane)
          (runtime-executed #f)))))

;; : (-> POOObject Boolean)
(def (poo-flow-scheme-compile-performance-budget-receipt-accepted? receipt)
  (and (.ref receipt 'comparable)
       (.ref receipt 'within-budget)
       (eq? (.ref receipt 'outcome) 'accepted)))

;; : (-> POOObject Alist)
(def (poo-flow-scheme-compile-performance-budget-receipt->alist receipt)
  (poo-flow-map
   (lambda (slot) (cons slot (.ref receipt slot)))
   '(schema
     kind
     outcome
     comparable
     within-budget
     diagnostics
     maximum-regression-basis-points
     sample-count
     baseline-median-ms
     candidate-median-ms
     relative-ceiling-ms
     regression-basis-points
     baseline-source-digest
     candidate-source-digest
     baseline-spec-count
     candidate-spec-count
     comparison-identity
     runtime-owner
     runtime-executed)))

;; : (-> Object Object)
(def (poo-flow-scheme-compile-performance-json-value value)
  (cond
   ((symbol? value) (symbol->string value))
   ((list? value)
    (poo-flow-map
     poo-flow-scheme-compile-performance-json-value
     value))
   (else value)))

;; : (-> Alist Symbol Object)
(def (poo-flow-scheme-compile-performance-alist-ref rows key)
  (let (entry (assq key rows))
    (if entry
      (cdr entry)
      (error "missing Scheme compile comparison identity field" key))))

;; : (-> POOObject HashTable)
(def (poo-flow-scheme-compile-performance-budget-receipt->json-object receipt)
  (let (identity (.ref receipt 'comparison-identity))
    (hash
     ("schema"
      (symbol->string (.ref receipt 'schema)))
     ("kind"
      (symbol->string (.ref receipt 'kind)))
     ("version" 1)
     ("outcome"
      (symbol->string (.ref receipt 'outcome)))
     ("comparable" (.ref receipt 'comparable))
     ("withinBudget" (.ref receipt 'within-budget))
     ("diagnostics"
      (poo-flow-scheme-compile-performance-json-value
       (.ref receipt 'diagnostics)))
     ("maximumRegressionBasisPoints"
      (.ref receipt 'maximum-regression-basis-points))
     ("sampleCount" (.ref receipt 'sample-count))
     ("baselineMedianMs" (.ref receipt 'baseline-median-ms))
     ("candidateMedianMs" (.ref receipt 'candidate-median-ms))
     ("relativeCeilingMs" (.ref receipt 'relative-ceiling-ms))
     ("regressionBasisPoints" (.ref receipt 'regression-basis-points))
     ("baselineSourceDigest" (.ref receipt 'baseline-source-digest))
     ("candidateSourceDigest" (.ref receipt 'candidate-source-digest))
     ("baselineSpecCount" (.ref receipt 'baseline-spec-count))
     ("candidateSpecCount" (.ref receipt 'candidate-spec-count))
     ("comparisonIdentity"
      (hash
       ("runner"
        (poo-flow-scheme-compile-performance-alist-ref identity 'runner))
       ("hostSessionId"
        (poo-flow-scheme-compile-performance-alist-ref
         identity
         'host-session-id))
       ("toolchainIdentity"
        (poo-flow-scheme-compile-performance-alist-ref
         identity
         'toolchain-identity))
       ("executionPolicy"
        (symbol->string
         (poo-flow-scheme-compile-performance-alist-ref
          identity
          'execution-policy)))
       ("logicalCpuCount"
        (poo-flow-scheme-compile-performance-alist-ref
         identity
         'logical-cpu-count))
       ("workerCount"
        (poo-flow-scheme-compile-performance-alist-ref
         identity
         'worker-count))
       ("coldnessClass"
        (symbol->string
         (poo-flow-scheme-compile-performance-alist-ref
          identity
          'coldness-class)))
       ("dependencyCacheState"
        (symbol->string
         (poo-flow-scheme-compile-performance-alist-ref
          identity
          'dependency-cache-state)))))
     ("runtimeOwner"
      (symbol->string (.ref receipt 'runtime-owner)))
     ("runtimeExecuted" (.ref receipt 'runtime-executed)))))

;; : (-> POOObject String)
(def (poo-flow-scheme-compile-performance-budget-receipt->json-string receipt)
  (parameterize ((write-json-sort-keys? #t))
    (json-object->string
     (poo-flow-scheme-compile-performance-budget-receipt->json-object
      receipt))))
