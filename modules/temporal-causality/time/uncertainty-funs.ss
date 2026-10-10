;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Pure interval judgments. 'unknown means overlapping uncertainty, while
;;; 'incomparable means no admitted coordinate relation exists.
(import (only-in :clan/poo/object .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/modules/temporal-causality/time/types
                 poo-flow-temporal-instant?)
        (only-in :poo-flow/modules/temporal-causality/time/uncertainty-types
                 poo-flow-temporal-bounded-observation?
                 poo-flow-temporal-duration-assessment?)
        (only-in :poo-flow/modules/temporal-causality/time/uncertainty-objects
                 poo-flow-temporal-bounded-observation-value
                 poo-flow-temporal-duration-assessment-value))

(export poo-flow-temporal-bounded-observation
        poo-flow-temporal-bounded-observation-replay
        poo-flow-temporal-bounded-observation-compare
        poo-flow-temporal-bounded-observation-boundary
        poo-flow-temporal-monotonic-duration
        poo-flow-temporal-duration-assessment-replay)

(def (instant-row instant)
  (list (.ref instant 'identity) (.ref instant 'domain-identity)
        (.ref instant 'coordinate) (.ref instant 'provenance-identity)
        (.ref instant 'modality)))

(def (digest datum)
  (string-append
   "sha256:"
   (hex-encode
    (sha256 (string->utf8
             (call-with-output-string
              (lambda (port) (write datum port))))))))

(def (poo-flow-temporal-bounded-observation
      identity-value role-value source-value earliest-value latest-value
      precision-value acquisition-value receipt-value attestation-value
      attempt-value schema-value)
  (unless (and (poo-flow-temporal-instant? earliest-value)
               (poo-flow-temporal-instant? latest-value)
               (poo-flow-temporal-instant? acquisition-value))
    (error "time observation requires temporal instants"))
  (let (semantic
        (digest (list 'poo-flow.temporal-observation.v1 identity-value
                      role-value source-value
                      (instant-row earliest-value) (instant-row latest-value)
                      precision-value (instant-row acquisition-value)
                      receipt-value attestation-value attempt-value
                      schema-value)))
    (poo-flow-temporal-bounded-observation-value
     identity-value semantic role-value source-value earliest-value
     latest-value precision-value acquisition-value receipt-value
     attestation-value attempt-value schema-value)))

(def (poo-flow-temporal-bounded-observation-replay observation)
  (unless (poo-flow-temporal-bounded-observation? observation)
    (error "invalid temporal observation"))
  (let (canonical
        (poo-flow-temporal-bounded-observation
         (.ref observation 'identity) (.ref observation 'clock-role)
         (.ref observation 'source-identity) (.ref observation 'earliest)
         (.ref observation 'latest) (.ref observation 'precision)
         (.ref observation 'acquisition-instant)
         (.ref observation 'receipt-identity)
         (.ref observation 'attestation-identity)
         (.ref observation 'attempt-identity)
         (.ref observation 'schema-identity)))
    (unless (equal? (.ref canonical 'semantic-digest)
                    (.ref observation 'semantic-digest))
      (error "temporal observation digest mismatch"))
    canonical))

(def (poo-flow-temporal-bounded-observation-compare left right)
  (poo-flow-temporal-bounded-observation-replay left)
  (poo-flow-temporal-bounded-observation-replay right)
  (let ((left-start (.ref left 'earliest))
        (left-end (.ref left 'latest))
        (right-start (.ref right 'earliest))
        (right-end (.ref right 'latest)))
    (cond
     ((not (equal? (.ref left-start 'domain-identity)
                   (.ref right-start 'domain-identity))) 'incomparable)
     ((< (.ref left-end 'coordinate)
         (.ref right-start 'coordinate)) 'before)
     ((> (.ref left-start 'coordinate)
         (.ref right-end 'coordinate)) 'after)
     ((and (= (.ref left-start 'coordinate)
              (.ref left-end 'coordinate))
           (= (.ref right-start 'coordinate)
              (.ref right-end 'coordinate))
           (= (.ref left-start 'coordinate)
              (.ref right-start 'coordinate))) 'equal)
     (else 'unknown))))

(def (poo-flow-temporal-bounded-observation-boundary observation boundary)
  (unless (and (poo-flow-temporal-instant? boundary)
               (eq? (.ref boundary 'modality) 'observed))
    (error "temporal boundary requires an observed instant"))
  (poo-flow-temporal-bounded-observation-replay observation)
  (let ((earliest (.ref observation 'earliest))
        (latest (.ref observation 'latest))
        (position (.ref boundary 'coordinate)))
    (cond
     ((not (equal? (.ref earliest 'domain-identity)
                   (.ref boundary 'domain-identity))) 'incomparable)
     ((< (.ref latest 'coordinate) position) 'before)
     ((> (.ref earliest 'coordinate) position) 'after)
     ((and (= (.ref earliest 'coordinate) position)
           (= (.ref latest 'coordinate) position)) 'equal)
     (else 'unknown))))

(def (poo-flow-temporal-monotonic-duration
      identity-value start-observation end-observation)
  (poo-flow-temporal-bounded-observation-replay start-observation)
  (poo-flow-temporal-bounded-observation-replay end-observation)
  (let* ((start-lower (.ref start-observation 'earliest))
         (start-upper (.ref start-observation 'latest))
         (end-lower (.ref end-observation 'earliest))
         (end-upper (.ref end-observation 'latest))
         (start-domain (.ref start-lower 'domain-identity))
         (end-domain (.ref end-lower 'domain-identity))
         (status
          (cond
           ((not (and (eq? (.ref start-observation 'clock-role) 'monotonic)
                      (eq? (.ref end-observation 'clock-role) 'monotonic)))
            'unsupported-clock)
           ((not (equal? start-domain end-domain)) 'incomparable)
           ((< (.ref end-upper 'coordinate)
               (.ref start-lower 'coordinate)) 'reversed)
           ((< (.ref end-lower 'coordinate)
               (.ref start-upper 'coordinate)) 'unknown)
           (else 'bounded)))
         (minimum
          (and (eq? status 'bounded)
               (- (.ref end-lower 'coordinate)
                  (.ref start-upper 'coordinate))))
         (maximum
          (and (eq? status 'bounded)
               (- (.ref end-upper 'coordinate)
                  (.ref start-lower 'coordinate))))
         (domain (and (equal? start-domain end-domain) start-domain))
         (start-digest (.ref start-observation 'semantic-digest))
         (end-digest (.ref end-observation 'semantic-digest))
         (semantic
          (digest (list 'poo-flow.temporal-duration-assessment.v1
                        identity-value start-digest end-digest
                        status domain minimum maximum))))
    (poo-flow-temporal-duration-assessment-value
     identity-value semantic status start-digest end-digest
     domain minimum maximum)))

(def (poo-flow-temporal-duration-assessment-replay assessment
                                                    start-observation
                                                    end-observation)
  (unless (poo-flow-temporal-duration-assessment? assessment)
    (error "invalid temporal duration assessment"))
  (let (canonical
        (poo-flow-temporal-monotonic-duration
         (.ref assessment 'identity) start-observation end-observation))
    (unless (equal? (.ref canonical 'semantic-digest)
                    (.ref assessment 'semantic-digest))
      (error "temporal duration assessment digest mismatch"))
    canonical))
