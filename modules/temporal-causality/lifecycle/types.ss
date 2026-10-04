;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every)
        (only-in :poo-flow/modules/temporal-causality/admission/interface
                 poo-flow-temporal-family-admission?)
        (only-in :poo-flow/modules/temporal-causality/conclusions/types
                 poo-flow-temporal-conclusion-revision?)
        (only-in :poo-flow/modules/temporal-causality/truth-maintenance/types
                 poo-flow-temporal-invalidation-plan?))
(export PooFlowTemporalFamilyRevision poo-flow-temporal-family-revision?)
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
