;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A POO policy around native std/test cases.  This does not own test
;;; discovery, assertion semantics, or the gxtest runner.
(import (only-in :std/test test-case)
        (only-in :clan/poo/object .call .o .ref .slot? object?)
        (only-in :clan/poo/mop element?)
        (only-in :asp-gerbil-scheme/testing-api
                 +testing-memory-profile+
                 testing-memory-profile-max-heap-mib)
        (only-in "debug.ss"
                 PooFlowDebugMemoryPolicyContract
                 poo-flow-debug-memory-policy
                 call-with-poo-flow-debug-memory-monitor))

(export poo-flow-testing-case-profile-prototype
        poo-flow-testing-case-profile?
        poo-flow-default-testing-case-profile
        poo-flow-current-testing-case-profile
        poo-flow-test-case
        poo-flow-test-case/with)

;;; All declared POO Flow cases receive this default.  The heap counters are
;;; process-wide, so the memory policy is a guard on a Case execution span,
;;; not a claim of independent thread-local heap accounting.  The native
;;; worker's hard managed-heap cap is set by the Testing Interface.
(def poo-flow-testing-case-profile-prototype
  (.o (testing-case-profile? #t)
      (identity 'testing/default-case)
      (memory-policy
       (poo-flow-debug-memory-policy
        'testing/default-case
        heap-limit-bytes:
        (* 1048576
           (testing-memory-profile-max-heap-mib
            +testing-memory-profile+))
        live-growth-limit-bytes: 536870912
        sample-interval-milliseconds: 100))
      (max-duration-milliseconds 60000)
      (emit? #f)
      .run: (lambda (self description thunk)
              (unless (poo-flow-testing-case-profile? self)
                (error "invalid POO Flow testing Case profile" self))
              (unless (and (string? description) (procedure? thunk))
                (error "invalid POO Flow testing Case" description thunk))
              (call-with-poo-flow-debug-memory-monitor
               (.ref self 'memory-policy)
               (string->symbol description)
               thunk
               emit?: (.ref self 'emit?)
               max-duration-milliseconds:
               (.ref self 'max-duration-milliseconds)))))

(def (poo-flow-testing-case-profile? value)
  (and (object? value)
       (.slot? value 'testing-case-profile?)
       (eq? (.ref value 'testing-case-profile?) #t)
       (.slot? value 'identity)
       (symbol? (.ref value 'identity))
       (.slot? value 'memory-policy)
       (element? PooFlowDebugMemoryPolicyContract
                 (.ref value 'memory-policy))
       (.slot? value 'max-duration-milliseconds)
       (exact-integer? (.ref value 'max-duration-milliseconds))
       (> (.ref value 'max-duration-milliseconds) 0)
       (.slot? value 'emit?)
       (boolean? (.ref value 'emit?))
       (.slot? value '.run)
       (procedure? (.ref value '.run))))

(def poo-flow-default-testing-case-profile
  (.o (:: @ poo-flow-testing-case-profile-prototype)))

(def poo-flow-current-testing-case-profile
  (make-parameter poo-flow-default-testing-case-profile))

;;; Hygienic syntax projects directly to the upstream test-case macro.  The
;;; native harness still registers and reports the resulting TestCase.
(defrules poo-flow-test-case ()
  ((_ description body rest ...)
   (poo-flow-test-case/with
    (poo-flow-current-testing-case-profile)
    description body rest ...)))

(defrules poo-flow-test-case/with ()
  ((_ profile description body rest ...)
   (test-case description
     (call-with-values
      (lambda ()
        (.call profile .run profile description
               (lambda () body rest ...)))
      (lambda (value receipt) value)))))
