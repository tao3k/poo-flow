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
(def (poo-flow-debug-memory-snapshot phase collect?: (collect? #f))
  (unless (and (symbol? phase) (boolean? collect?))
    (error "invalid POO Flow debug memory snapshot request" phase collect?))
  (when collect? (##gc))
  (let (usage (##process-statistics))
    (poo-flow-debug-memory-sample
     phase
     (inexact->exact (f64vector-ref usage 15))
     (inexact->exact (f64vector-ref usage 16))
     (inexact->exact (f64vector-ref usage 17))
     (inexact->exact (f64vector-ref usage 18))
     (inexact->exact (f64vector-ref usage 19)))))

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
