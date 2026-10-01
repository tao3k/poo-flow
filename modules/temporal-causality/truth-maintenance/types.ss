;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Cut-bound, inert reverse-dependency scheduling.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every))

(export PooFlowTemporalDerivation PooFlowTemporalDependencyIndex
        PooFlowTemporalInvalidationPlan
        poo-flow-temporal-derivation? poo-flow-temporal-dependency-index?
        poo-flow-temporal-invalidation-plan?)

(def (text? value) (and (string? value) (> (string-length value) 0)))
(def (text-list? value)
  (and (list? value) (every text? value)))
(def (slots? value names)
  (and (object? value) (every (lambda (name) (.slot? value name)) names)))

(def (derivation-shape? value)
  (and (slots? value '(kind identity cut-digest projection-digest policy-identity
                             subject-premises conclusion-premises))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.derivation)
       (every text? (list (.ref value 'identity) (.ref value 'cut-digest)
                          (.ref value 'projection-digest)
                          (.ref value 'policy-identity)))
       (text-list? (.ref value 'subject-premises))
       (text-list? (.ref value 'conclusion-premises))))
(define-type (PooFlowTemporalDerivation @ Type.)
  .element?: derivation-shape?)
(def (poo-flow-temporal-derivation? value)
  (element? PooFlowTemporalDerivation value))

(def (index-shape? value)
  (and (slots? value '(kind identity semantic-digest cut-digest
                             projection-digest
                             inventory-complete? derivations))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.dependency-index)
       (every text? (list (.ref value 'identity) (.ref value 'semantic-digest)
                          (.ref value 'cut-digest)
                          (.ref value 'projection-digest)))
       (boolean? (.ref value 'inventory-complete?))
       (list? (.ref value 'derivations))
       (every poo-flow-temporal-derivation? (.ref value 'derivations))))
(define-type (PooFlowTemporalDependencyIndex @ Type.)
  .element?: index-shape?)
(def (poo-flow-temporal-dependency-index? value)
  (element? PooFlowTemporalDependencyIndex value))

(def (plan-shape? value)
  (and (slots? value '(kind index-identity index-digest previous-cut-digest
                             revised-cut-digest previous-projection-digest
                             revised-projection-digest changed-subject-identities
                             affected-conclusion-identities
                             scheduled-for-reevaluation-identities
                             inventory-complete? trigger status runtime-executed?))
       (eq? (.ref value 'kind) 'poo-flow.temporal-causality.invalidation-plan)
       (every text? (list (.ref value 'index-identity)
                          (.ref value 'index-digest)
                          (.ref value 'previous-cut-digest)
                          (.ref value 'revised-cut-digest)
                          (.ref value 'previous-projection-digest)
                          (.ref value 'revised-projection-digest)))
       (every (lambda (name) (text-list? (.ref value name)))
              '(changed-subject-identities affected-conclusion-identities
                scheduled-for-reevaluation-identities))
       (boolean? (.ref value 'inventory-complete?))
       (memq (.ref value 'trigger) '(premise-delta valid-time-reprojection))
       (memq (.ref value 'status) '(scoped-complete partial))
       (eq? (.ref value 'runtime-executed?) #f)))
(define-type (PooFlowTemporalInvalidationPlan @ Type.)
  .element?: plan-shape?)
(def (poo-flow-temporal-invalidation-plan? value)
  (element? PooFlowTemporalInvalidationPlan value))
