;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every)
        (only-in :poo-flow/modules/temporal-causality/time/types
                 poo-flow-temporal-instant?)
        (only-in :poo-flow/modules/temporal-causality/impact/types
                 poo-flow-temporal-intervention-window-audit?))
(export PooFlowTemporalImpactScope PooFlowTemporalImpactScopeAudit
        poo-flow-temporal-impact-scope?
        poo-flow-temporal-impact-scope-audit?)

(def (text? value) (and (string? value) (> (string-length value) 0)))
(def (slots? value names)
  (and (object? value) (every (lambda (name) (.slot? value name)) names)))

(def (scope-shape? value)
  (and (slots? value '(kind identity semantic-digest intervention-identity
                             subject-identity source-cut-digest
                             source-projection-digest time-domain-identity
                             onset end direct-target-outcomes
                             protected-outcomes))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.impact-scope)
       (every text? (map (lambda (slot) (.ref value slot))
                         '(identity semantic-digest intervention-identity
                           subject-identity source-cut-digest
                           source-projection-digest time-domain-identity)))
       (poo-flow-temporal-instant? (.ref value 'onset))
       (poo-flow-temporal-instant? (.ref value 'end))
       (list? (.ref value 'direct-target-outcomes))
       (pair? (.ref value 'direct-target-outcomes))
       (every text? (.ref value 'direct-target-outcomes))
       (list? (.ref value 'protected-outcomes))
       (every text? (.ref value 'protected-outcomes))))
(define-type (PooFlowTemporalImpactScope @ Type.)
  .element?: scope-shape?)
(def (poo-flow-temporal-impact-scope? value)
  (element? PooFlowTemporalImpactScope value))

(def (scope-audit-shape? value)
  (and (slots? value '(kind identity semantic-digest scope-digest
                             candidate-scenario-identity
                             baseline-scenario-identity audited-outcomes
                             window-audits prefix-status protected-status
                             status causal-impact-admitted?
                             runtime-executed?))
       (eq? (.ref value 'kind)
            'poo-flow.temporal-causality.impact-scope-audit)
       (every text? (map (lambda (slot) (.ref value slot))
                         '(identity semantic-digest scope-digest
                           candidate-scenario-identity
                           baseline-scenario-identity)))
       (list? (.ref value 'audited-outcomes))
       (pair? (.ref value 'audited-outcomes))
       (every text? (.ref value 'audited-outcomes))
       (list? (.ref value 'window-audits))
       (= (length (.ref value 'audited-outcomes))
          (length (.ref value 'window-audits)))
       (every poo-flow-temporal-intervention-window-audit?
              (.ref value 'window-audits))
       (memq (.ref value 'prefix-status)
             '(consistent diverged unobserved))
       (memq (.ref value 'protected-status)
             '(consistent diverged unobserved))
       (memq (.ref value 'status)
             '(consistent-with-declaration violated unknown))
       (eq? (.ref value 'causal-impact-admitted?) #f)
       (eq? (.ref value 'runtime-executed?) #f)))
(define-type (PooFlowTemporalImpactScopeAudit @ Type.)
  .element?: scope-audit-shape?)
(def (poo-flow-temporal-impact-scope-audit? value)
  (element? PooFlowTemporalImpactScopeAudit value))
