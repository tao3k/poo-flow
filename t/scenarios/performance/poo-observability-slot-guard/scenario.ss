;;; -*- Gerbil -*-
;;; Real phase-separated timing for native POO lazy-slot observability.

(import (only-in :std/srfi/1 iota)
        (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/src/observability/debug
                 PooFlowDebugSlotPolicyContract
                 poo-flow-debug-poo
                 poo-flow-debug-slot-policy)
        (only-in :poo-flow/t/support/performance
                 poo-flow-performance-elapsed-us))

(export observability-slot-performance-scenario
        observability-slot-performance-receipt-sexp)

(def +attempts+ 3)
(def +cold-count+ 16)
(def +trace-count+ 2)
(def +prototype-iterations+ 20)
(def +warm-iterations+ 1000)
(def ObservabilitySlotPerformanceReceipt.
  (.o kind: 'poo-flow.observability-slot-performance.v1
      runtime-executed?: #t))

(def (source index) (.o payload: (+ index 1)))
(def (sources count) (map source (iota count)))
(def (guards policy inputs port emit?)
  (map (lambda (input)
         (poo-flow-debug-poo
          policy 'performance-receiver input port: port emit?: emit?))
       inputs))
(def (sum-payload objects)
  (let loop ((rest objects) (sum 0))
    (if (null? rest) sum
        (loop (cdr rest) (+ sum (.ref (car rest) 'payload))))))
(def (repeat-payload object iterations)
  (let loop ((remaining iterations) (sum 0))
    (if (zero? remaining) sum
        (loop (- remaining 1) (+ sum (.ref object 'payload))))))

;;; Fresh prebuilt batches keep first demand out of construction and prevent
;;; best-of-N selection from measuring an already-warm cache.
(def (best-cold batches)
  (let loop ((rest batches) (best #f) (expected #f))
    (if (null? rest)
      (values best expected)
      (let* ((checksum #f)
             (elapsed
              (poo-flow-performance-elapsed-us
               (lambda () (set! checksum (sum-payload (car rest)))))))
        (when (and expected (not (= checksum expected)))
          (error "cold observability checksum changed" checksum expected))
        (loop (cdr rest) (if best (min best elapsed) elapsed)
              (or expected checksum))))))
(def (best-time thunk)
  (let loop ((remaining +attempts+) (best #f))
    (if (zero? remaining) best
        (let (elapsed (poo-flow-performance-elapsed-us thunk))
          (loop (- remaining 1) (if best (min best elapsed) elapsed))))))
(def (best-construction policy inputs)
  (best-time
   (lambda ()
     (length (guards policy inputs (current-error-port) #f)))))
(def (best-warm object)
  (best-time (lambda () (repeat-payload object +warm-iterations+))))

;;; This isolates lookup placement from guard validation and slot resolution.
;;; The two durations are diagnostic evidence, not a relative-speed assertion.
(def (best-inline-prototype)
  (best-time
   (lambda ()
     (let loop ((remaining +prototype-iterations+))
       (unless (zero? remaining)
         (.o (:: @ (.ref PooFlowDebugSlotPolicyContract 'proto)))
         (loop (- remaining 1)))))))
(def (best-hoisted-prototype prototype)
  (best-time
   (lambda ()
     (let loop ((remaining +prototype-iterations+))
       (unless (zero? remaining)
         (.o (:: @ prototype))
         (loop (- remaining 1)))))))

(def (observability-slot-performance-receipt-sexp receipt)
  (map (lambda (slot) (cons slot (.ref receipt slot)))
       '(prototype-iterations inline-prototype-us hoisted-prototype-us
         guard-count construction-us first-demand-us cold-checksum
         warm-iterations direct-warm-us guarded-warm-us warm-budget-us
         evaluation-count traced-guard-count traced-first-demand-us
         trace-checksum within-budget?)))

(def (observability-slot-performance-scenario)
  (let* ((policy (poo-flow-debug-slot-policy 'performance-slot 8))
         (prototype (.ref PooFlowDebugSlotPolicyContract 'proto))
         (inputs (sources +cold-count+))
         (construction-us-value (best-construction policy inputs))
         (cold-batches
          (map (lambda (_)
                 (guards policy (sources +cold-count+)
                         (current-error-port) #f))
               (iota +attempts+)))
         (trace-ports (map (lambda (_) (open-output-string)) (iota +attempts+)))
         (trace-batches
          (map (lambda (port)
                 (guards policy (sources +trace-count+) port #t))
               trace-ports))
         (evaluations 0)
         (warm-source
          (.o payload: (begin (set! evaluations (+ evaluations 1)) 17)))
         (warm-guard
          (poo-flow-debug-poo policy 'warm-receiver warm-source emit?: #f))
         (_warm-first (.ref warm-guard 'payload)))
    (let-values (((first-demand-us-value cold-checksum-value)
                  (best-cold cold-batches))
                 ((traced-first-demand-us-value trace-checksum-value)
                  (best-cold trace-batches)))
      (let* ((direct-source (source 16))
             (_direct-first (.ref direct-source 'payload))
             (direct-warm-us-value (best-warm direct-source))
             (guarded-warm-us-value (best-warm warm-guard))
             (inline-prototype-us-value (best-inline-prototype))
             (hoisted-prototype-us-value (best-hoisted-prototype prototype))
             (warm-budget-us-value (+ (* 3 direct-warm-us-value) 1000))
             (within-budget-value
              (and (<= construction-us-value 10000)
                   (<= first-demand-us-value 1000)
                   (<= traced-first-demand-us-value 10000)
                   (<= guarded-warm-us-value warm-budget-us-value))))
        (.o (:: @ ObservabilitySlotPerformanceReceipt.)
            recommended-installation-phase: 'before-first-demand
            prototype-lookup-placement: 'before-repeated-construction
            prototype-iterations: +prototype-iterations+
            inline-prototype-us: inline-prototype-us-value
            hoisted-prototype-us: hoisted-prototype-us-value
            guard-count: +cold-count+
            construction-us: construction-us-value
            first-demand-us: first-demand-us-value
            cold-checksum: cold-checksum-value
            expected-cold-checksum: (/ (* +cold-count+ (+ +cold-count+ 1)) 2)
            warm-iterations: +warm-iterations+
            direct-warm-us: direct-warm-us-value
            guarded-warm-us: guarded-warm-us-value
            warm-budget-us: warm-budget-us-value
            evaluation-count: evaluations
            traced-guard-count: +trace-count+
            traced-first-demand-us: traced-first-demand-us-value
            trace-checksum: trace-checksum-value
            expected-trace-checksum: (/ (* +trace-count+ (+ +trace-count+ 1)) 2)
            within-budget?: within-budget-value)))))
