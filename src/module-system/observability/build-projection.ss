;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: bootstrap-safe observation of ASP PackageSpec projection.
;;; This owner depends only on gerbil-poo and its module-owned configuration
;;; because build.ss loads it before the POO Flow package image exists.  It
;;; observes and rejects; ASP PackageSpec and std/make retain projection and
;;; execution ownership.

(import (only-in :clan/poo/object .ref object?)
        (only-in :gerbil/gambit spawn thread-sleep!))

(export poo-flow-make-observed-package-spec-projector
        poo-flow-observe-build-projection-start
        poo-flow-observe-build-projection
        poo-flow-observe-build-executor-handoff)

;;; Compose observation into PackageSpec's native spec projection.  The
;;; generated spec procedure and std/build-script remain the sole execution
;;; path; this adapter only decorates the POO-owned projection method.
(def (poo-flow-make-observed-package-spec-projector projector policy)
  (unless (procedure? projector)
    (error "POO Flow observed PackageSpec projector must be a procedure"
           projector))
  (lambda (package-spec)
    (let (started (current-jiffy))
      (poo-flow-observe-build-projection-start policy)
      (let* ((spec (projector package-spec))
             (target-count (length spec))
             (elapsed-ms
              (quotient (* (- (current-jiffy) started) 1000)
                        (jiffies-per-second))))
        (poo-flow-observe-build-projection
         policy target-count elapsed-ms)
        (poo-flow-observe-build-executor-handoff policy target-count)
        spec))))

(def (poo-flow-build-policy-ref policy slot)
  (unless (object? policy)
    (error "POO Flow build observation policy must be a POO object" policy))
  (.ref policy slot))

(def (poo-flow-build-policy-budget policy slot)
  (let (value (poo-flow-build-policy-ref policy slot))
    (if (or (not value) (and (exact-integer? value) (> value 0)))
      value
      (error "POO Flow build observation budget must be positive or false"
             (.ref policy 'id) slot value))))

(def (poo-flow-build-budget-action policy slot)
  (let (action (poo-flow-build-policy-ref policy slot))
    (if (memq action '(observe reject))
      action
      (error "POO Flow build observation action must be observe or reject"
             (.ref policy 'id) slot action))))

(def (poo-flow-build-budget-exceeded! policy reason observed budget action)
  (let (profile-name (poo-flow-build-policy-ref policy 'profile))
    (displayln "[poo-flow] phase=spec-budget-exceeded profile=" profile-name
             " reason=" reason
             " observed=" observed
             " budget=" budget
             " action=" action
             " policy=" (poo-flow-build-policy-ref policy 'id)
             " owner=module-system/observability"
             " executor=asp-build-api/std-make")
    (force-output)
    (when (eq? action 'reject)
      (error "POO Flow build observation exceeded its configured budget"
             profile-name reason observed budget))))

(def (poo-flow-observe-build-projection-start policy)
  (when (poo-flow-build-policy-ref policy 'enabled?)
    (let (profile-name (poo-flow-build-policy-ref policy 'profile))
    (displayln "[poo-flow] phase=spec-start profile=" profile-name
               " policy=" (poo-flow-build-policy-ref policy 'id)
               " owner=module-system/observability"
               " executor=asp-build-api/std-make")
      (force-output))))

(def (poo-flow-observe-build-projection policy target-count
                                        elapsed-ms)
  (let* ((profile-name (poo-flow-build-policy-ref policy 'profile))
         (target-budget
          (poo-flow-build-policy-budget policy 'target-budget))
         (projection-budget-ms
          (poo-flow-build-policy-budget policy 'projection-budget-ms))
         (target-budget-action
          (poo-flow-build-budget-action policy 'target-budget-action))
         (projection-budget-action
          (poo-flow-build-budget-action policy 'projection-budget-action)))
    (when (poo-flow-build-policy-ref policy 'enabled?)
      (displayln "[poo-flow] phase=spec-projected profile=" profile-name
                 " target-count=" target-count
                 " elapsedMs=" elapsed-ms
                 " policy=" (poo-flow-build-policy-ref policy 'id)
                 " owner=module-system/observability"
                 " executor=asp-build-api/std-make")
      (force-output))
    (when (and target-budget (> target-count target-budget))
      (poo-flow-build-budget-exceeded!
       policy "target-count" target-count target-budget target-budget-action))
    (when (and projection-budget-ms (> elapsed-ms projection-budget-ms))
      (poo-flow-build-budget-exceeded!
       policy "projection-elapsed-ms" elapsed-ms projection-budget-ms
       projection-budget-action))))

;;; defbuild-script hands the projected value directly to std/make, which does
;;; not report its source-import/currentness barrier.  This observer thread is
;;; deliberately outside execution ownership: it neither imports, schedules,
;;; retries, nor mutates targets.  It only keeps that native boundary visible
;;; until the build process exits.  Derived POO policies may disable it with
;;; executor-heartbeat-ms: #f or select another positive interval.
(def (poo-flow-observe-build-executor-handoff policy target-count)
  (let (interval-ms (poo-flow-build-policy-ref policy 'executor-heartbeat-ms))
    (when interval-ms
      (unless (and (exact-integer? interval-ms) (> interval-ms 0))
        (error "POO Flow executor heartbeat must be positive or false"
               (.ref policy 'id) interval-ms))
      (displayln
       "[poo-flow] phase=executor-handoff profile="
       (poo-flow-build-policy-ref policy 'profile)
       " boundary=std/make/source-import-currentness-or-compile"
       " target-count=" target-count
       " heartbeatMs=" interval-ms
       " policy=" (poo-flow-build-policy-ref policy 'id)
       " owner=module-system/observability"
       " executor=asp-build-api/std-make")
      (force-output)
      (spawn
       (lambda ()
         (let loop ((elapsed-ms interval-ms))
           (thread-sleep! (/ interval-ms 1000.0))
           (displayln
            "[poo-flow] phase=executor-active profile="
            (poo-flow-build-policy-ref policy 'profile)
            " boundary=std/make/source-import-currentness-or-compile"
            " target-count=" target-count
            " elapsedMs=" elapsed-ms
            " policy=" (poo-flow-build-policy-ref policy 'id)
            " owner=module-system/observability"
            " executor=asp-build-api/std-make")
           (force-output)
           (loop (+ elapsed-ms interval-ms))))))))
