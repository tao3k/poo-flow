;;; -*- Gerbil -*-
;;; Real timing, checksum and native cache identity; no synthetic timing rows.
(import (only-in :gerbil/gambit current-time time->seconds f64vector-ref f64vector-length)
        (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop .defgeneric)
        "../../../../src/research/poo-method-combination/interface.ss")
(export combination-performance-scenario CombinationPerformanceInput
        combination-performance-matrix)
(def CombinationPerformanceInput
  (.o iterations: 1000 depth: 8 warm-budget-ms: 10000))
(def PerformanceReceipt.
  (.o kind: 'poo-combination/performance-receipt schema: 'v1
      producer: 'poo-flow/research runtime-executed?: #t))
(def (measure thunk)
  (let* ((start (time->seconds (current-time))) (result (thunk))
         (elapsed (* 1000 (- (time->seconds (current-time)) start))))
    (values result elapsed)))
(def (base-value _frame _receiver value) value)
(def (increment-next frame _receiver _value) (+ 1 (poo-call-next-method frame)))
(.defgeneric (native-call receiver value) slot: native/call)
(def (combination-performance-scenario (input CombinationPerformanceInput))
  (let* ((iterations-value (.ref input 'iterations)) (depth-value (.ref input 'depth))
         (budget-value (.ref input 'warm-budget-ms))
         (generic (poo-combination-generic 'benchmark 'benchmark/plan required: 1 rest?: #f))
         (increment (poo-method-bundle primary: (poo-combination-method 'increment increment-next)))
         (native (.o native/call: (lambda (value) (+ value depth-value)))))
    (unless (and (exact-integer? iterations-value) (> iterations-value 0)
                 (exact-integer? depth-value) (>= depth-value 0))
      (error "Invalid benchmark scenario input"))
    (def (sum-calls call)
      (let loop ((i 0) (sum 0))
        (if (= i iterations-value) sum (loop (+ i 1) (+ sum (call i))))))
    (let*-values
        (((receiver construction-time)
          (measure (lambda ()
            (let loop ((remaining depth-value)
                       (current (poo-method-prototype (poo-method-root generic) generic
                                  (poo-method-bundle primary: (poo-combination-method 'base base-value)))))
              (if (= remaining 0) current
                  (loop (- remaining 1) (poo-method-prototype current generic increment)))))))
         ((first-value first-time) (measure (lambda () (poo-combination-call generic receiver 0))))
         ((plan-before) (values (.ref receiver 'benchmark/plan)))
         ((checksum-value warm-time)
          (measure (lambda () (sum-calls (lambda (i) (poo-combination-call generic receiver i))))))
         ((native-checksum-value native-time)
          (measure (lambda () (sum-calls (lambda (i) (native-call native i)))))))
      (.o (:: @ PerformanceReceipt.) iterations: iterations-value depth: depth-value
          construction-ms: construction-time first-demand-ms: first-time warm-ms: warm-time
          native-ms: native-time budget-ms: budget-value first-result: first-value
          checksum: checksum-value native-checksum: native-checksum-value
          expected: (+ (/ (* iterations-value (- iterations-value 1)) 2) (* iterations-value depth-value))
          plan-reused?: (eq? plan-before (.ref receiver 'benchmark/plan))
          within-budget?: (and (>= warm-time 0) (<= warm-time budget-value))))))

;;; Gambit process statistics: wall=2, GC wall=5, GC count=6, allocation=7.
;;; These describe this process only and include the measurement scaffolding.
;;; Missing counters fail explicitly; no fabricated zero-allocation receipts.
(def (sample thunk)
  (let* ((start (##process-statistics)) (result (thunk)) (end (##process-statistics)))
    (unless (and (>= (f64vector-length start) 8) (>= (f64vector-length end) 8))
      (error "Gambit process statistics unavailable"))
    (def (delta index) (- (f64vector-ref end index) (f64vector-ref start index)))
    (.o checksum: result wall-ms: (* 1000 (delta 2)) gc-ms: (* 1000 (delta 5))
        gc-count: (delta 6) allocated-bytes: (delta 7))))
(def (delegate frame _receiver _value) (poo-call-next-method frame))
(def (auxiliary _frame _receiver _value) (void))
(def (functional-auxiliary _value) (void))
(def (functional-layer next) (lambda (value) (+ 1 (next value))))
(def (functional-around next) (lambda (value) (next value)))
(def (functional-core primary depth)
  (lambda (value)
    (let before ((remaining depth))
      (unless (zero? remaining) (functional-auxiliary value) (before (- remaining 1))))
    (let (result (primary value))
      (let after ((remaining depth))
        (unless (zero? remaining) (functional-auxiliary value) (after (- remaining 1))))
      result)))
(def (repeat-layer layer base depth)
  (if (zero? depth) base (repeat-layer layer (layer base) (- depth 1))))
(def (sum-invocations call iterations)
  (let loop ((i 0) (sum 0))
    (if (= i iterations) sum (loop (+ i 1) (+ sum (call i))))))
(def (trial-receipt depth-value mode-value qualifiers-value iterations-value trial-value
                    order-value expected-value combination-value functional-value)
  (.o kind: 'poo-combination/performance-trial schema: 'v1
      producer: 'poo-flow/research runtime-executed?: #t
      depth: depth-value from: mode-value qualifiers: qualifiers-value iterations: iterations-value trial: trial-value
      order: order-value expected: expected-value plan-reused?: #t
      combination: combination-value functional: functional-value))
(def (matrix-case depth mode qualifiers iterations repetitions)
  (let* ((generic (poo-combination-generic 'matrix 'matrix/plan from: mode required: 1 rest?: #f))
         (all? (eq? qualifiers 'all))
         (bundle (poo-method-bundle
                   primary: (poo-combination-method 'increment increment-next)
                   around: (and all? (poo-combination-method 'around delegate))
                   before: (and all? (poo-combination-method 'before auxiliary))
                   after: (and all? (poo-combination-method 'after auxiliary))))
         (owner (let loop ((remaining depth)
                           (base (poo-method-prototype (poo-method-root generic) generic
                                   (poo-method-bundle primary: (poo-combination-method 'base base-value)))))
                  (if (zero? remaining) base
                      (loop (- remaining 1) (poo-method-prototype base generic bundle)))))
         (receiver (if (eq? mode 'type) (.o .type: owner) owner))
         (call (lambda (value) (poo-combination-call generic receiver value)))
         (primary (repeat-layer functional-layer (lambda (value) value) depth))
         (functional (if all? (repeat-layer functional-around (functional-core primary depth) depth) primary))
         (plan (.ref owner 'matrix/plan))
         (expected (+ (/ (* iterations (- iterations 1)) 2) (* iterations depth))))
    ;; Equal untimed warm-up; alternating order reduces systematic order bias.
    (sum-invocations call iterations)
    (sum-invocations functional iterations)
    (let loop ((trial 0) (rows '()))
      (if (= trial repetitions) (reverse rows)
          (let* ((combination-first? (even? trial))
                 (first (sample (lambda () (sum-invocations (if combination-first? call functional) iterations))))
                 (second (sample (lambda () (sum-invocations (if combination-first? functional call) iterations))))
                 (combination (if combination-first? first second))
                 (baseline (if combination-first? second first)))
            (unless (and (= (.ref combination 'checksum) expected) (= (.ref baseline 'checksum) expected)
                         (eq? plan (.ref owner 'matrix/plan)))
              (error "Performance matrix semantic invariant failed"))
            (loop (+ trial 1)
              (cons (trial-receipt depth mode qualifiers iterations trial
                       (if combination-first? 'combination-first 'functional-first) expected combination baseline)
                    rows)))))))
(def (combination-performance-matrix (iterations 100) (repetitions 5))
  (unless (and (exact-integer? iterations) (> iterations 0)
               (exact-integer? repetitions) (>= repetitions 2))
    (error "Invalid performance matrix bounds"))
  (apply append
    (map (lambda (depth)
           (apply append
             (map (lambda (mode)
                    (apply append
                      (map (lambda (qualifiers) (matrix-case depth mode qualifiers iterations repetitions))
                           '(primary all)))) '(instance type)))) '(0 1 4 8))))
