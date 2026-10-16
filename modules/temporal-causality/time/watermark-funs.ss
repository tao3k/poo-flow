;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Structural coverage claims never authenticate a source's inventory or
;;; perform cut publication. A caller must bind the named coverage receipt.
(import (only-in :clan/poo/object .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/modules/temporal-causality/time/types
                 poo-flow-temporal-instant?)
        (only-in :poo-flow/modules/temporal-causality/time/uncertainty-types
                 poo-flow-temporal-bounded-observation?)
        (only-in :poo-flow/modules/temporal-causality/time/uncertainty-funs
                 poo-flow-temporal-bounded-observation-replay)
        (only-in :poo-flow/modules/temporal-causality/time/watermark-types
                 poo-flow-temporal-watermark?)
        (only-in :poo-flow/modules/temporal-causality/time/watermark-objects
                 poo-flow-temporal-watermark-value))

(export poo-flow-temporal-watermark
        poo-flow-temporal-watermark-replay
        poo-flow-temporal-watermark-cut-claim)

(def (digest datum)
  (string-append
   "sha256:"
   (hex-encode
    (sha256 (string->utf8
             (call-with-output-string
              (lambda (port) (write datum port))))))))

(def (poo-flow-temporal-watermark
      identity-value source-value partition-value first-value last-value
      observation-value issuer-value coverage-value policy-value receipt-value)
  (unless (poo-flow-temporal-bounded-observation? observation-value)
    (error "watermark requires a bounded time observation"))
  (let* ((observation (poo-flow-temporal-bounded-observation-replay observation-value))
         (semantic
          (digest (list 'poo-flow.temporal-watermark.v1 identity-value
                        source-value partition-value first-value last-value
                        (.ref observation 'semantic-digest) issuer-value
                        coverage-value policy-value receipt-value))))
    (poo-flow-temporal-watermark-value
     identity-value semantic source-value partition-value first-value
     last-value observation issuer-value coverage-value policy-value
     receipt-value)))

(def (poo-flow-temporal-watermark-replay watermark)
  (unless (poo-flow-temporal-watermark? watermark)
    (error "invalid temporal watermark"))
  (let (canonical
        (poo-flow-temporal-watermark
         (.ref watermark 'identity) (.ref watermark 'source-identity)
         (.ref watermark 'partition-identity)
         (.ref watermark 'first-sequence) (.ref watermark 'last-sequence)
         (.ref watermark 'time-observation) (.ref watermark 'issuer-identity)
         (.ref watermark 'coverage-identity)
         (.ref watermark 'late-policy-identity)
         (.ref watermark 'receipt-identity)))
    (unless (equal? (.ref canonical 'semantic-digest)
                    (.ref watermark 'semantic-digest))
      (error "temporal watermark digest mismatch"))
    canonical))

;;; 'coverage-claimed is deliberately weaker than a closed cut. An issuer's
;;; coverage identity must be verified separately, and late events may still
;;; require correction or reconciliation under the named policy.
(def (poo-flow-temporal-watermark-cut-claim
      watermark source partition sequence boundary)
  (unless (and (string? source) (string? partition)
               (exact-integer? sequence) (>= sequence 0)
               (poo-flow-temporal-instant? boundary)
               (eq? (.ref boundary 'modality) 'observed))
    (error "invalid watermark cut query"))
  (poo-flow-temporal-watermark-replay watermark)
  (cond
   ((or (not (equal? source (.ref watermark 'source-identity)))
        (not (equal? partition (.ref watermark 'partition-identity)))
        (< sequence (.ref watermark 'first-sequence))
        (> sequence (.ref watermark 'last-sequence))) 'outside-scope)
   (else
    (let* ((observation (.ref watermark 'time-observation))
           (lower (.ref observation 'earliest))
           (upper (.ref observation 'latest))
           (position (.ref boundary 'coordinate)))
      (cond
       ((not (equal? (.ref lower 'domain-identity)
                     (.ref boundary 'domain-identity))) 'incomparable)
       ((>= (.ref lower 'coordinate) position) 'coverage-claimed)
       ((< (.ref upper 'coordinate) position) 'not-covered)
       (else 'unknown))))))
