;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Clock-indexed temporal primitives. Coordinates have meaning only in their
;;; declared domain; this module never reads a live clock.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every))

(export poo-flow-temporal-instant-kind
        poo-flow-temporal-interval-kind
        poo-flow-temporal-axes-kind
        PooFlowTemporalInstant PooFlowTemporalInterval PooFlowTemporalAxes
        poo-flow-temporal-instant? poo-flow-temporal-interval?
        poo-flow-temporal-axes?)

(def poo-flow-temporal-instant-kind 'poo-flow.temporal-causality.instant)
(def poo-flow-temporal-interval-kind 'poo-flow.temporal-causality.interval)
(def poo-flow-temporal-axes-kind 'poo-flow.temporal-causality.time-axes)

(def (text? value)
  (and (string? value) (> (string-length value) 0)))

(def (slots? value names)
  (and (object? value) (every (lambda (name) (.slot? value name)) names)))

(def (instant-shape? value)
  (and (slots? value '(kind identity domain-identity coordinate
                             provenance-identity modality))
       (eq? (.ref value 'kind) poo-flow-temporal-instant-kind)
       (every text? (list (.ref value 'identity)
                          (.ref value 'domain-identity)
                          (.ref value 'provenance-identity)))
       (exact-integer? (.ref value 'coordinate))
       (>= (.ref value 'coordinate) 0)
       (symbol? (.ref value 'modality))))

(define-type (PooFlowTemporalInstant @ Type.)
  .element?: instant-shape?)
(def (poo-flow-temporal-instant? value)
  (element? PooFlowTemporalInstant value))

(def (interval-shape? value)
  (and (slots? value '(kind identity start end start-closed? end-closed?))
       (eq? (.ref value 'kind) poo-flow-temporal-interval-kind)
       (text? (.ref value 'identity))
       (poo-flow-temporal-instant? (.ref value 'start))
       (poo-flow-temporal-instant? (.ref value 'end))
       (equal? (.ref (.ref value 'start) 'domain-identity)
               (.ref (.ref value 'end) 'domain-identity))
       (<= (.ref (.ref value 'start) 'coordinate)
           (.ref (.ref value 'end) 'coordinate))
       (boolean? (.ref value 'start-closed?))
       (boolean? (.ref value 'end-closed?))))

(define-type (PooFlowTemporalInterval @ Type.)
  .element?: interval-shape?)
(def (poo-flow-temporal-interval? value)
  (element? PooFlowTemporalInterval value))

;;; An event may have only some axes. The role is given by its slot, and no
;;; relation among event, ingress and processing coordinates is inferred.
(def (axes-shape? value)
  (and (slots? value '(kind identity event-instant ingress-instant
                             processing-instant))
       (eq? (.ref value 'kind) poo-flow-temporal-axes-kind)
       (text? (.ref value 'identity))
       (let ((axes (list (.ref value 'event-instant)
                         (.ref value 'ingress-instant)
                         (.ref value 'processing-instant))))
         (and (ormap poo-flow-temporal-instant? axes)
              (every (lambda (axis)
                       (or (not axis) (poo-flow-temporal-instant? axis)))
                     axes)))))

(define-type (PooFlowTemporalAxes @ Type.)
  .element?: axes-shape?)
(def (poo-flow-temporal-axes? value)
  (element? PooFlowTemporalAxes value))
