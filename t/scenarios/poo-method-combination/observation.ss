;;; -*- Gerbil -*-
;;; Pure scenario: real Module admission -> source-owned Observation summary.
(import (only-in :gerbil/gambit f64vector-ref f64vector-length)
        (only-in :clan/poo/object .o .ref .cc)
        "../../../src/module-system/poo-method-combination/plugins/observation.ss"
        "../../../src/module-system/observability/interface.ss"
        "../../../src/module-system/semantic-module/objects.ss")
(export combination-observation-scenario combination-observation-event
        combination-observation-performance-matrix)
(def (identity-value name) (poo-flow-observation-identity 'module name 'v1))
(def (combination-observation-event (accepted? #f))
  (let* ((context (poo-flow-observation-context
                    (identity-value 'event) (identity-value 'module) (identity-value 'generation)
                    '() (poo-flow-observation-provenance
                          (identity-value 'admission) (identity-value 'gerbil-poo) 'admission)))
         (module (poo-flow-semantic-module (poo-flow-semantic-identity 'module 'sample)))
         (event (poo-flow-observe-contract-admission context SemanticModuleContract
                  (if accepted? module (.cc module 'imports 'invalid)))))
    event))
(def (combination-observation-scenario)
  (let ((base (poo-observation-combination-renderer))
        (detailed (poo-observation-combination-renderer explanation?: #t))
        (event (combination-observation-event)))
    (values (poo-observation-combination-summary base event)
            (poo-observation-combination-summary detailed event))))

;;; Observation is the first optional consumer. These rows measure its real,
;;; pure detailed-summary path against the equivalent functional composition.
;;; Gambit process statistics: wall=2, GC wall=5, GC count=6, allocation=7.
(def (sample thunk)
  (let* ((start (##process-statistics)) (result (thunk)) (end (##process-statistics)))
    (unless (and (>= (f64vector-length start) 8) (>= (f64vector-length end) 8))
      (error "Gambit process statistics unavailable"))
    (def (delta index) (- (f64vector-ref end index) (f64vector-ref start index)))
    (.o checksum: result wall-ms: (* 1000 (delta 2)) gc-ms: (* 1000 (delta 5))
        gc-count: (delta 6) allocated-bytes: (delta 7))))
(def (summary-checksum summary)
  (+ (.ref summary 'failure-count)
     (length (.ref (.ref summary 'explanation) 'failures))))
(def (sum-observations render event iterations)
  (let loop ((remaining iterations) (checksum 0))
    (if (zero? remaining) checksum
        (loop (- remaining 1) (+ checksum (summary-checksum (render event)))))))
(def (functional-detailed-summary event)
  (.cc (poo-flow-observation-summary event)
       'explanation
       (poo-flow-observation-explain event)))
(def (trial-receipt iterations-value trial-value order-value expected-value
                    combination-value functional-value)
  (.o kind: 'poo-combination/performance-trial schema: 'v1
      producer: 'poo-flow/module-system/poo-method-combination runtime-executed?: #t
      depth: 1 from: 'observation qualifiers: 'detailed
      iterations: iterations-value trial: trial-value order: order-value
      expected: expected-value plan-reused?: #t
      combination: combination-value functional: functional-value))
(def (combination-observation-performance-matrix (iterations 100) (repetitions 5))
  (unless (and (exact-integer? iterations) (> iterations 0)
               (exact-integer? repetitions) (>= repetitions 2))
    (error "Invalid Observation performance matrix bounds"))
  (let* ((renderer (poo-observation-combination-renderer explanation?: #t))
         (plan (.ref renderer 'poo-method-combination/summary-plan))
         (event (combination-observation-event))
         (combined (lambda (value) (poo-observation-combination-summary renderer value)))
         (functional functional-detailed-summary)
         (expected (* iterations 2)))
    ;; Equal untimed warm-up; alternating order reduces systematic order bias.
    (sum-observations combined event iterations)
    (sum-observations functional event iterations)
    (let loop ((trial 0) (rows '()))
      (if (= trial repetitions) (reverse rows)
          (let* ((combination-first? (even? trial))
                 (first (sample (lambda ()
                                  (sum-observations
                                   (if combination-first? combined functional)
                                   event iterations))))
                 (second (sample (lambda ()
                                   (sum-observations
                                    (if combination-first? functional combined)
                                    event iterations))))
                 (combination (if combination-first? first second))
                 (baseline (if combination-first? second first)))
            (unless (and (= (.ref combination 'checksum) expected)
                         (= (.ref baseline 'checksum) expected)
                         (eq? plan (.ref renderer 'poo-method-combination/summary-plan)))
              (error "Observation performance semantic invariant failed"))
            (loop (+ trial 1)
                  (cons (trial-receipt
                         iterations trial
                         (if combination-first? 'combination-first 'functional-first)
                         expected combination baseline)
                        rows)))))))
