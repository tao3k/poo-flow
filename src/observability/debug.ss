;;; -*- Gerbil -*-
;;; Boundary: explicit effectful DEVELOPMENT output over aggregate projections.
;;; Upstream owns tracing and typed printing. No global hook or tracer is copied.
(import (only-in :clan/base λ)
        (only-in :clan/poo/object .o .call .ref)
        (only-in :clan/poo/debug DDT trace-poo)
        (only-in :std/error deferror-class)
        (only-in :std/sugar cut)
        (only-in "types.ss"
                 PooFlowDebugMemoryPolicyContract
                 PooFlowDebugMemorySampleContract
                 PooFlowDebugMemoryReceiptContract)
        (only-in "func.ss" poo-flow-observation-admission-summary
                 poo-flow-observation-summary-sexp
                 poo-flow-debug-memory-policy
                 poo-flow-debug-memory-sample
                 poo-flow-debug-memory-receipt
                 poo-flow-debug-memory-receipt-sexp))
(export poo-flow-observation-debug PooFlowObservationProjectionError?
        PooFlowDebugMemoryPolicyContract
        PooFlowDebugMemorySampleContract
        PooFlowDebugMemoryReceiptContract
        poo-flow-debug-memory-policy
        poo-flow-debug-memory-sample
        poo-flow-debug-memory-receipt
        poo-flow-debug-memory-receipt-sexp
        poo-flow-debug-memory-snapshot
        poo-flow-debug-memory-checkpoint
        call-with-poo-flow-debug-memory-span
        call-with-poo-flow-debug-memory-monitor
        PooFlowDebugMemoryAnomaly?
        PooFlowDebugMemoryAnomaly-receipt)

(deferror-class PooFlowObservationProjectionError ())
(deferror-class PooFlowDebugMemoryAnomaly (receipt))

;; : (-> PooFlowDebugMemoryReceipt Never)
;; poo-flow-debug-raise-memory-anomaly
;;   : (-> PooFlowDebugMemoryReceipt Never)
;;   | doc m%
;;       Raise the typed fail-closed anomaly while retaining the exact rejected
;;       receipt for native Scheme handlers and audit projections.
;;       The specialized constructor path mutates only the exception's receipt
;;       field before raising and cannot substitute or recompute the evidence.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-debug-raise-memory-anomaly rejected-receipt)
;;       ;; => raises PooFlowDebugMemoryAnomaly with rejected-receipt
;;       ```
;;     %
(def (poo-flow-debug-raise-memory-anomaly receipt)
  (let (failure
        (PooFlowDebugMemoryAnomaly
         "POO Flow debug memory policy rejected the observed phase"
         irritants: '()))
    (set! (PooFlowDebugMemoryAnomaly-receipt failure) receipt)
    (raise failure)))

;; : (-> PooFlowObservation PooFlowObservationSummary)
(def (poo-flow-observation-debug-summary observation)
  (with-exception-catcher
   (λ (_failure)
     ;; Do not attach the original exception/irritants: they may hold a subject.
     (raise (PooFlowObservationProjectionError "observation projection rejected")))
   (λ () (poo-flow-observation-admission-summary observation))))

;;; This entry point intentionally does not dispatch an arbitrary user .summary
;;; renderer. A fresh closed-schema aggregate is built before any output occurs.
;;; trace? traces only the aggregate view, never the observed Module receiver.
;; : (-> PooFlowObservation OutputPort trace?: Boolean PooFlowObservationSummary)
;; poo-flow-observation-debug
;;   : (-> PooFlowObservation OutputPort trace?: Boolean PooFlowObservationSummary)
;;   | doc m%
;;       Emit only the admitted closed-schema observation summary and return
;;       that identical native POO aggregate to the caller.
;;       The specialized trace branch constructs a fresh bounded view, so it
;;       cannot dispatch a renderer on the observed Module receiver.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-observation-debug observation (current-error-port) trace?: #f)
;;       ;; => PooFlowObservationSummary
;;       ```
;;     %
(def (poo-flow-observation-debug observation port trace?: (trace? #f))
  (unless (and (output-port? port) (boolean? trace?))
    (raise (PooFlowObservationProjectionError "invalid observation debug output request")))
  (let (summary (poo-flow-observation-debug-summary observation))
    (parameterize ((current-error-port port))
      (when trace?
        (let* ((view (.o (render (cut poo-flow-observation-summary-sexp summary))))
               (traced (trace-poo view 'admission-observation-view)))
          (.call traced render)))
      ;; Admission already validated the closed summary contract. DDT receives
      ;; only the pure presentation projection, so no dependency Type adapter is needed.
      (DDT 'observation poo-flow-observation-summary-sexp summary))
    summary))

;;; This is the only runtime-heap read in the framework. The returned value is
;;; a native POO sample, so callers never depend on Gambit's vector layout.
;;; Indices 15..19 are the counters projected by std/debug/heap: heap size,
;;; allocation, live, movable, and still bytes.
;; : (-> Symbol collect?: Boolean PooFlowDebugMemorySample)
;; poo-flow-debug-memory-snapshot
;;   : (-> Symbol collect?: Boolean PooFlowDebugMemorySample)
;;   | doc m%
;;       Read one runtime heap snapshot into the closed native POO sample
;;       contract, optionally collecting immediately before the measurement.
;;       The specialized collection branch runs at most once; both branches
;;       project the same five scalar counters into the result.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-debug-memory-snapshot 'compile collect?: #f)
;;       ;; => PooFlowDebugMemorySample
;;       ```
;;     %
(def (poo-flow-debug-memory-snapshot phase collect?: (collect? #f))
  (unless (and (symbol? phase) (boolean? collect?))
    (error "invalid POO Flow debug memory snapshot request" phase collect?))
  (when collect? (##gc))
  (let* ((usage (##process-statistics))
         (counters
          (map (lambda (index)
                 (inexact->exact (f64vector-ref usage index)))
               '(15 16 17 18 19))))
    (apply (lambda (heap-size allocation live movable still)
             (poo-flow-debug-memory-sample
              phase heap-size allocation live movable still))
           counters)))

;; : (-> PooFlowDebugMemoryPolicy PooFlowDebugMemorySample Symbol port: OutputPort emit?: Boolean PooFlowDebugMemoryReceipt)
;; poo-flow-debug-memory-checkpoint
;;   : (-> PooFlowDebugMemoryPolicy PooFlowDebugMemorySample Symbol port: OutputPort emit?: Boolean PooFlowDebugMemoryReceipt)
;;   | doc m%
;;       Sample one policy checkpoint and return its typed POO receipt, raising
;;       the same receipt as an anomaly when fail-closed policy rejects it.
;;       The specialized emission branch projects only bounded scalar evidence;
;;       it never changes the receipt used for the policy decision.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-debug-memory-checkpoint policy baseline 'compile)
;;       ;; => PooFlowDebugMemoryReceipt
;;       ```
;;     %
(def (poo-flow-debug-memory-checkpoint policy baseline phase
                                       port: (port (current-error-port))
                                       emit?: (emit? #f))
  (unless (and (output-port? port) (boolean? emit?))
    (error "invalid POO Flow debug memory checkpoint output request"))
  (let* ((after
          (poo-flow-debug-memory-snapshot
           phase collect?: (.ref policy 'collect-before-sample?)))
         (receipt (poo-flow-debug-memory-receipt policy baseline after)))
    (when emit?
      (parameterize ((current-error-port port))
        (DDT 'debug-memory poo-flow-debug-memory-receipt-sexp receipt)))
    (when (and (not (.ref receipt 'accepted?))
               (.ref policy 'fail-closed?))
      (poo-flow-debug-raise-memory-anomaly receipt))
    receipt))

;;; A span adds in-band phase evidence around one development operation. Long
;;; operations should expose intermediate checkpoints; launch-time heap caps
;;; remain the final defense before this module can be loaded.
;; : (forall (a) (-> PooFlowDebugMemoryPolicy Symbol (-> a) port: OutputPort emit?: Boolean (values a PooFlowDebugMemoryReceipt)))
;; call-with-poo-flow-debug-memory-span
;;   : (-> PooFlowDebugMemoryPolicy Symbol (-> Object) port: OutputPort emit?: Boolean (values Object PooFlowDebugMemoryReceipt))
;;   | doc m%
;;       Measure one returning development operation and preserve its value
;;       beside a typed POO receipt for the observed heap delta.
;;       The specialized branch evaluates the operation exactly once before
;;       the final checkpoint, so sampling cannot duplicate user effects.
;;
;;       # Examples
;;
;;       ```scheme
;;       (call-with-poo-flow-debug-memory-span policy 'compile (lambda () 'ok))
;;       ;; => (values 'ok PooFlowDebugMemoryReceipt)
;;       ```
;;     %
(def (call-with-poo-flow-debug-memory-span policy phase thunk
                                           port: (port (current-error-port))
                                           emit?: (emit? #f))
  (unless (procedure? thunk)
    (error "POO Flow debug memory span requires a thunk"))
  (let (before
        (poo-flow-debug-memory-snapshot
         phase collect?: (.ref policy 'collect-before-sample?)))
    (let (value (thunk))
      (values value
              (poo-flow-debug-memory-checkpoint
               policy before phase port: port emit?: emit?)))))

;;; The monitored form is the asynchronous debug boundary: the observed
;;; operation runs in a Scheme thread while its owner samples from the calling
;;; thread. A POO lazy-slot cycle therefore need not return before detection.
;;; Gambit's launch ceiling remains necessary for code that cannot yield to the
;;; Scheme scheduler or fails before this module loads.
;; : (forall (a) (-> PooFlowDebugMemoryPolicy Symbol (-> a) port: OutputPort emit?: Boolean (values a PooFlowDebugMemoryReceipt)))
;; call-with-poo-flow-debug-memory-monitor
;;   : (-> PooFlowDebugMemoryPolicy Symbol (-> Object) port: OutputPort emit?: Boolean (values Object PooFlowDebugMemoryReceipt))
;;   | doc m%
;;       Run one development operation in a native Scheme worker while the
;;       caller samples bounded heap counters and enforces its POO policy.
;;       The specialized timeout branch preserves the worker's lexical result
;;       or exception and terminates it only after a fail-closed anomaly.
;;
;;       # Examples
;;
;;       ```scheme
;;       (call-with-poo-flow-debug-memory-monitor policy 'compile (lambda () 'ok))
;;       ;; => (values 'ok PooFlowDebugMemoryReceipt)
;;       ```
;;     %
(def (call-with-poo-flow-debug-memory-monitor policy phase thunk
                                              port: (port (current-error-port))
                                              emit?: (emit? #f))
  (unless (procedure? thunk)
    (error "POO Flow debug memory monitor requires a thunk"))
  (let* ((baseline
          (poo-flow-debug-memory-snapshot
           phase collect?: (.ref policy 'collect-before-sample?)))
         (timeout-token (cons 'poo-flow-debug-memory-timeout '()))
         (interval-seconds
          (/ (max 1 (.ref policy 'sample-interval-milliseconds)) 1000.0))
         (worker
          (make-thread
           (lambda ()
             (with-exception-catcher
              (lambda (failure) (cons 'failure failure))
              (lambda () (cons 'value (thunk)))))))
         (joined? #f))
    (thread-start! worker)
    (dynamic-wind
      (lambda () #!void)
      (lambda ()
        (let monitor ()
          (let (outcome
                (thread-join! worker interval-seconds timeout-token))
            (if (eq? outcome timeout-token)
              (with-exception-catcher
               (lambda (failure)
                 (when (PooFlowDebugMemoryAnomaly? failure)
                   (thread-terminate! worker)
                   (set! joined? #t))
                 (raise failure))
               (lambda ()
                 (poo-flow-debug-memory-checkpoint
                  policy baseline phase port: port emit?: emit?)
                 (monitor)))
              (begin
                (set! joined? #t)
                (let (receipt
                      (poo-flow-debug-memory-checkpoint
                       policy baseline phase port: port emit?: emit?))
                  (if (eq? (car outcome) 'failure)
                    (raise (cdr outcome))
                    (values (cdr outcome) receipt))))))))
      (lambda ()
        (unless joined?
          (thread-terminate! worker))))))
