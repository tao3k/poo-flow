;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type.)
        (only-in :std/list/list every))
(export PooFlowTemporalSupportPremise PooFlowTemporalSupport
        PooFlowTemporalSupportProgram PooFlowTemporalSupportEvaluation
        PooFlowTemporalSupportPolicy PooFlowTemporalSupportGuard)
(def (shape? x kind names)
  (and (object? x) (.slot? x 'kind) (eq? (.ref x 'kind) kind)
       (every (lambda (name) (.slot? x name)) names)))
(define-type (PooFlowTemporalSupportPremise @ Type.)
  .element?: (lambda (x) (shape? x 'poo-flow.temporal-causality.support-premise
                                '(subject-identity revision-identity))))
(define-type (PooFlowTemporalSupport @ Type.)
  .element?: (lambda (x) (shape? x 'poo-flow.temporal-causality.support
                                '(identity conclusion-identity proof-identity premises conclusion-premises))))
(define-type (PooFlowTemporalSupportProgram @ Type.)
  .element?: (lambda (x) (shape? x 'poo-flow.temporal-causality.support-program
                                '(identity policy-identity inventory-complete? supports semantic-digest))))
(define-type (PooFlowTemporalSupportEvaluation @ Type.)
  .element?: (lambda (x) (shape? x 'poo-flow.temporal-causality.support-evaluation
                                '(semantic-digest program-digest cut-digest projection-digest conclusions
                                  evaluated-support-count budget-exhausted? proof-admitted? action-authorized? durable?))))

(define-type (PooFlowTemporalSupportPolicy @ Type.)
  .element?: (lambda (x) (shape? x 'poo-flow.temporal-causality.support-policy
                          '(identity revision-identity start end semantic-digest))))
(define-type (PooFlowTemporalSupportGuard @ Type.)
  .element?: (lambda (x) (shape? x 'poo-flow.temporal-causality.support-guard
                          '(semantic-digest policy policy-digest expected-policy-digest effective-at
                            policy-status policy-applicable? evaluation as-of valid-at budget
                            proof-admitted? source-authenticated? selection-admitted? action-authorized? durable?))))
