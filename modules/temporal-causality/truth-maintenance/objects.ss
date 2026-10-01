;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in :poo-flow/modules/temporal-causality/truth-maintenance/types
                 PooFlowTemporalDerivation PooFlowTemporalDependencyIndex
                 PooFlowTemporalInvalidationPlan))

(export poo-flow-temporal-derivation
        poo-flow-temporal-dependency-index-value
        poo-flow-temporal-invalidation-plan-value)

(def (poo-flow-temporal-derivation id-value cut-value projection-value policy-value
                                    subjects-value conclusions-value)
  (validate PooFlowTemporalDerivation
    (.o kind: 'poo-flow.temporal-causality.derivation
        identity: id-value cut-digest: cut-value
        projection-digest: projection-value policy-identity: policy-value
        subject-premises: subjects-value conclusion-premises: conclusions-value)))

(def (poo-flow-temporal-dependency-index-value
      id-value digest-value cut-value projection-value complete-value entries-value)
  (validate PooFlowTemporalDependencyIndex
    (.o kind: 'poo-flow.temporal-causality.dependency-index
        identity: id-value semantic-digest: digest-value cut-digest: cut-value
        projection-digest: projection-value
        inventory-complete?: complete-value derivations: entries-value)))

(def (poo-flow-temporal-invalidation-plan-value
      index-value digest-value old-value new-value
      old-projection-value new-projection-value changed-value
      affected-value complete-value trigger-value)
  (validate PooFlowTemporalInvalidationPlan
    (.o kind: 'poo-flow.temporal-causality.invalidation-plan
        index-identity: index-value index-digest: digest-value
        previous-cut-digest: old-value
        revised-cut-digest: new-value changed-subject-identities: changed-value
        previous-projection-digest: old-projection-value
        revised-projection-digest: new-projection-value
        affected-conclusion-identities: affected-value
        scheduled-for-reevaluation-identities: affected-value
        inventory-complete?: complete-value
        trigger: trigger-value
        status: (if complete-value 'scoped-complete 'partial)
        runtime-executed?: #f)))
