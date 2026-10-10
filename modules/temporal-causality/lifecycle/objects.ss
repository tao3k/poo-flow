;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in :poo-flow/modules/temporal-causality/lifecycle/types
                 PooFlowTemporalFamilyRevision PooFlowTemporalFamilyArchive))
(export poo-flow-temporal-family-revision-value poo-flow-temporal-family-archive-value)
(def (poo-flow-temporal-family-revision-value
      digest-value admission-value revision-value predecessor-value frontier-value)
  (validate PooFlowTemporalFamilyRevision
    (.o kind: 'poo-flow.temporal-causality.family-revision.v1
        semantic-digest: digest-value admission: admission-value
        revision: revision-value predecessor: predecessor-value frontier: frontier-value
        runtime-executed?: #f source-authenticated?: #f action-authorized?: #f)))

(def (poo-flow-temporal-family-archive-value identity-value digest-value values-value journal-value)
  (validate PooFlowTemporalFamilyArchive
    (.o kind: 'poo-flow.temporal-causality.family-archive.v1
        identity: identity-value semantic-digest: digest-value
        family-revisions: values-value journal: journal-value
        source-authenticated?: #f action-authorized?: #f runtime-executed?: #f durable?: #f)))
