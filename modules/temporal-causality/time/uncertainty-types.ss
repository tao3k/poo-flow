;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; An observation bounds one coordinate; its receipt and attestation names
;;; are declarations, not authentication of an external clock.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every)
        (only-in :poo-flow/modules/temporal-causality/time/types
                 poo-flow-temporal-instant?))

(export poo-flow-temporal-bounded-observation-kind
        poo-flow-temporal-duration-assessment-kind
        PooFlowTemporalBoundedObservation PooFlowTemporalDurationAssessment
        poo-flow-temporal-bounded-observation?
        poo-flow-temporal-duration-assessment?)

(def poo-flow-temporal-bounded-observation-kind
  'poo-flow.temporal-causality.bounded-time-observation)
(def poo-flow-temporal-duration-assessment-kind
  'poo-flow.temporal-causality.duration-assessment)

(def (text? value)
  (and (string? value) (> (string-length value) 0)))

(def (observed? value)
  (and (poo-flow-temporal-instant? value)
       (eq? (.ref value 'modality) 'observed)))

(def (observation-shape? value)
  (and (object? value)
       (every (lambda (name) (.slot? value name))
              '(kind identity semantic-digest clock-role source-identity
                     earliest latest precision acquisition-instant
                     receipt-identity attestation-identity attempt-identity
                     schema-identity))
       (eq? (.ref value 'kind) poo-flow-temporal-bounded-observation-kind)
       (every text? (list (.ref value 'identity)
                          (.ref value 'semantic-digest)
                          (.ref value 'source-identity)
                          (.ref value 'receipt-identity)
                          (.ref value 'attempt-identity)
                          (.ref value 'schema-identity)))
       (or (not (.ref value 'attestation-identity))
           (text? (.ref value 'attestation-identity)))
       (symbol? (.ref value 'clock-role))
       (observed? (.ref value 'earliest))
       (observed? (.ref value 'latest))
       (observed? (.ref value 'acquisition-instant))
       (equal? (.ref (.ref value 'earliest) 'domain-identity)
               (.ref (.ref value 'latest) 'domain-identity))
       (<= (.ref (.ref value 'earliest) 'coordinate)
           (.ref (.ref value 'latest) 'coordinate))
       (exact-integer? (.ref value 'precision))
       (>= (.ref value 'precision) 0)))

(define-type (PooFlowTemporalBoundedObservation @ Type.)
  .element?: observation-shape?)
(def (poo-flow-temporal-bounded-observation? value)
  (element? PooFlowTemporalBoundedObservation value))

(def (duration-shape? value)
  (and (object? value)
       (every (lambda (name) (.slot? value name))
              '(kind identity semantic-digest status start-observation-digest
                     end-observation-digest domain-identity minimum maximum))
       (eq? (.ref value 'kind) poo-flow-temporal-duration-assessment-kind)
       (every text? (list (.ref value 'identity)
                          (.ref value 'semantic-digest)
                          (.ref value 'start-observation-digest)
                          (.ref value 'end-observation-digest)))
       (memq (.ref value 'status)
             '(bounded unknown incomparable unsupported-clock reversed))
       (or (not (.ref value 'domain-identity))
           (text? (.ref value 'domain-identity)))
       (if (eq? (.ref value 'status) 'bounded)
         (and (text? (.ref value 'domain-identity))
              (exact-integer? (.ref value 'minimum))
              (>= (.ref value 'minimum) 0)
              (exact-integer? (.ref value 'maximum))
              (>= (.ref value 'maximum) (.ref value 'minimum)))
         (and (not (.ref value 'minimum))
              (not (.ref value 'maximum))))))

(define-type (PooFlowTemporalDurationAssessment @ Type.)
  .element?: duration-shape?)
(def (poo-flow-temporal-duration-assessment? value)
  (element? PooFlowTemporalDurationAssessment value))
