;;; -*- Gerbil -*-
;;; Boundary: POO Flow owns test-operation observation while ASP retains the
;;; native Gerbil test runner.  The upstream build verbosity environment is
;;; reused as the sole opt-in; no parallel observability setting is invented.

(import (only-in :clan/poo/object .cc)
        (only-in :asp-gerbil-scheme/testing-api
                 testing-interface-call-with-operation)
        (only-in "debug.ss"
                 poo-flow-debug-call-policy
                 call-with-poo-flow-debug-trace))

(export poo-flow-native-observability-enabled?
        poo-flow-testing-heartbeat-interval-seconds
        poo-flow-observe-testing-operation
        poo-flow-testing-observability-extension)

(def +poo-flow-testing-observation-policy+
  (poo-flow-debug-call-policy 'native-gerbil-testing 8))

;;; The default keeps every long native batch observable well below the
;;; project's 60-second silence boundary. Tests parameterize it; users keep the
;;; single upstream GERBIL_BUILD_VERBOSE enablement contract.
(def poo-flow-testing-heartbeat-interval-seconds (make-parameter 15))

;; : (-> Integer Natural)
(def (poo-flow-testing-elapsed-nanoseconds started-jiffy)
  (quotient (* (- (current-jiffy) started-jiffy) 1000000000)
            (jiffies-per-second)))

;; : (forall (a) (-> Symbol (-> a) a))
(def (poo-flow-call-with-testing-heartbeat operation thunk)
  (if (not (poo-flow-native-observability-enabled?))
    (thunk)
    (let* ((started-jiffy (current-jiffy))
           (port (current-error-port))
           (heartbeat
            (make-thread
             (lambda ()
               (let loop ()
                 (thread-sleep!
                  (poo-flow-testing-heartbeat-interval-seconds))
                 (parameterize ((current-output-port port)
                                (current-error-port port))
                   (displayln
                    "[poo-flow-testing] phase=operation-heartbeat operation="
                    operation
                    " elapsedNs="
                    (poo-flow-testing-elapsed-nanoseconds started-jiffy))
                   (force-output port))
                 (loop))))))
      (thread-start! heartbeat)
      (dynamic-wind
        void
        thunk
        (lambda () (thread-terminate! heartbeat))))))

;; : (-> Boolean)
(def (poo-flow-native-observability-enabled?)
  (cond
   ((getenv "GERBIL_BUILD_VERBOSE" #f)
    => (lambda (value)
         (let (level (string->number value))
           (and (real? level) (> level 0)))))
   (else #f)))

;; : (forall (a) (-> Symbol (-> a) a))
(def (poo-flow-observe-testing-operation operation thunk)
  (call-with-poo-flow-debug-trace
   +poo-flow-testing-observation-policy+
   operation
   (lambda ()
     (poo-flow-call-with-testing-heartbeat operation thunk))
   '()
   emit?: (poo-flow-native-observability-enabled?)))

;;; Extend the ASP POO value with behavior only. ASP calls the optional slot
;;; without owning its policy, receipt schema, presentation, or enablement.
;; : (-> TestingInterface TestingInterface)
(def (poo-flow-testing-observability-extension testing)
  (.cc testing around-operation: poo-flow-observe-testing-operation))
