;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every)
        (only-in :poo-flow/modules/temporal-causality/admission/interface
                 poo-flow-temporal-family-admission?)
        (only-in :poo-flow/modules/temporal-causality/conclusions/types
                 poo-flow-temporal-conclusion-revision? poo-flow-temporal-conclusion-journal?)
        (only-in :poo-flow/modules/temporal-causality/truth-maintenance/types
                 poo-flow-temporal-invalidation-plan?))
(export PooFlowTemporalFamilyRevision poo-flow-temporal-family-revision?
        PooFlowTemporalFamilyArchive poo-flow-temporal-family-archive?)
(def (shape? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind semantic-digest admission revision predecessor frontier
                runtime-executed? source-authenticated? action-authorized?))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.family-revision.v1)
       (string? (.ref value 'semantic-digest))
       (poo-flow-temporal-family-admission? (.ref value 'admission))
       (poo-flow-temporal-conclusion-revision? (.ref value 'revision))
       (or (and (not (.ref value 'predecessor)) (not (.ref value 'frontier)))
           (and (object? (.ref value 'predecessor))
                (poo-flow-temporal-invalidation-plan? (.ref value 'frontier))))
       (every (lambda (slot) (eq? (.ref value slot) #f))
              '(runtime-executed? source-authenticated? action-authorized?))))
(define-type (PooFlowTemporalFamilyRevision @ Type.) .element?: shape?)
(def (poo-flow-temporal-family-revision? value)
  (element? PooFlowTemporalFamilyRevision value))

(def (archive-shape? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind identity semantic-digest family-revisions journal
                source-authenticated? action-authorized? runtime-executed? durable?))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.family-archive.v1)
       (string? (.ref value 'identity)) (string? (.ref value 'semantic-digest))
       (list? (.ref value 'family-revisions))
       (<= 1 (length (.ref value 'family-revisions)) 128)
       (every poo-flow-temporal-family-revision? (.ref value 'family-revisions))
       (poo-flow-temporal-conclusion-journal? (.ref value 'journal))
       (every (lambda (slot) (eq? (.ref value slot) #f))
              '(source-authenticated? action-authorized? runtime-executed? durable?))))
(define-type (PooFlowTemporalFamilyArchive @ Type.) .element?: archive-shape?)
(def (poo-flow-temporal-family-archive? value)
  (element? PooFlowTemporalFamilyArchive value))
