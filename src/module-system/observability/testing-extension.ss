;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO Flow owns test-operation observation while ASP retains the
;;; native Gerbil test runner.  The upstream build verbosity environment is
;;; reused as the sole opt-in; no parallel observability setting is invented.

(import (only-in :clan/poo/object .cc .o .ref .slot? object?)
        (only-in :asp-gerbil-scheme/testing-api
                 testing-interface-call-with-operation)
        (only-in "build-projection.ss"
                 poo-flow-write-observation-line!)
        (only-in "debug.ss"
                 poo-flow-debug-call-policy
                 call-with-poo-flow-debug-trace))

(export poo-flow-native-observability-enabled?
        poo-flow-testing-observability-profile-prototype
        make-poo-flow-testing-observability-profile
        poo-flow-testing-observability-profile?
        poo-flow-testing-observability-profile-identity
        poo-flow-testing-observability-profile-heartbeat-interval-seconds
        poo-flow-default-testing-observability-profile
        poo-flow-current-testing-observability-profile
        poo-flow-observe-testing-operation
        poo-flow-testing-observability-extension)

(def +poo-flow-testing-observation-policy+
  (poo-flow-debug-call-policy 'native-gerbil-testing 8))

;;; Heartbeat timing is a POO profile so CI, a user profile, or an atomic test
;;; can refine observation cadence without patching the observer.
(def poo-flow-testing-observability-profile-prototype
  (.o (testing-observability-profile? #t)
      (identity 'testing/default)
      (heartbeat-interval-seconds 15)))

(def (poo-flow-testing-observability-profile? value)
  (and (object? value)
       (.slot? value 'testing-observability-profile?)
       (.ref value 'testing-observability-profile?)
       (.slot? value 'identity)
       (symbol? (.ref value 'identity))
       (.slot? value 'heartbeat-interval-seconds)
       (real? (.ref value 'heartbeat-interval-seconds))
       (> (.ref value 'heartbeat-interval-seconds) 0)))

(def (make-poo-flow-testing-observability-profile identity-value
                                                   heartbeat-interval-value)
  (let (profile
        (.o (:: @ poo-flow-testing-observability-profile-prototype)
            (identity identity-value)
            (heartbeat-interval-seconds heartbeat-interval-value)))
    (unless (poo-flow-testing-observability-profile? profile)
      (error "invalid POO Flow testing observability profile" profile))
    profile))

(def (poo-flow-testing-observability-profile-identity profile)
  (.ref profile 'identity))

(def (poo-flow-testing-observability-profile-heartbeat-interval-seconds profile)
  (.ref profile 'heartbeat-interval-seconds))

(def poo-flow-default-testing-observability-profile
  (.o (:: @ poo-flow-testing-observability-profile-prototype)))

(def poo-flow-current-testing-observability-profile
  (make-parameter poo-flow-default-testing-observability-profile))

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
                  (poo-flow-testing-observability-profile-heartbeat-interval-seconds
                   (poo-flow-current-testing-observability-profile)))
                 (parameterize ((current-output-port port)
                                (current-error-port port))
                   (poo-flow-write-observation-line!
                    "[poo-flow-testing] phase=operation-heartbeat operation=~a elapsedNs=~a"
                    operation
                    (poo-flow-testing-elapsed-nanoseconds started-jiffy)))
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
(def (poo-flow-testing-observability-extension testing . maybe-profile)
  (let (profile
        (if (null? maybe-profile)
          poo-flow-default-testing-observability-profile
          (car maybe-profile)))
    (unless (poo-flow-testing-observability-profile? profile)
      (error "invalid POO Flow testing observability extension profile" profile))
    (.cc testing
         around-operation:
         (lambda (operation thunk)
           (parameterize
               ((poo-flow-current-testing-observability-profile profile))
             (poo-flow-observe-testing-operation operation thunk))))))
