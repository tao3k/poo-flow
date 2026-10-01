;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in :poo-flow/modules/temporal-causality/revisions/types
                 poo-flow-temporal-evidence-revision-kind
                 poo-flow-temporal-evidence-journal-kind
                 poo-flow-temporal-evidence-snapshot-kind
                 PooFlowTemporalEvidenceRevision PooFlowTemporalEvidenceJournal
                 PooFlowTemporalEvidenceSnapshot))

(export poo-flow-temporal-evidence-revision
        poo-flow-temporal-evidence-journal-value
        poo-flow-temporal-evidence-snapshot-value)

(def (poo-flow-temporal-evidence-revision
      identity-value subject-value operation-value predecessor-value
      admission-value valid-value content-value)
  (validate PooFlowTemporalEvidenceRevision
    (.o kind: poo-flow-temporal-evidence-revision-kind
        identity: identity-value subject-identity: subject-value
        operation: operation-value predecessor-identity: predecessor-value
        admission-instant: admission-value valid-interval: valid-value
        content-identity: content-value)))

(def (poo-flow-temporal-evidence-journal-value
      identity-value digest-value domain-value revisions-value)
  (validate PooFlowTemporalEvidenceJournal
    (.o kind: poo-flow-temporal-evidence-journal-kind
        identity: identity-value semantic-digest: digest-value
        admission-domain-identity: domain-value revisions: revisions-value)))

(def (poo-flow-temporal-evidence-snapshot-value
      journal-digest-value cut-digest-value projection-digest-value
      as-of-value valid-at-value valid-at-digest-value
      active-value retracted-value conflicted-value outside-value
      uncertain-value incomparable-value visible-value future-value)
  (validate PooFlowTemporalEvidenceSnapshot
    (.o kind: poo-flow-temporal-evidence-snapshot-kind
        journal-digest: journal-digest-value cut-digest: cut-digest-value
        projection-digest: projection-digest-value
        as-of-instant-identity: as-of-value
        valid-at-instant-identity: valid-at-value
        valid-at-instant-digest: valid-at-digest-value
        active-revision-identities: active-value
        retracted-subject-identities: retracted-value
        conflicted-subject-identities: conflicted-value
        outside-valid-subject-identities: outside-value
        uncertain-subject-identities: uncertain-value
        incomparable-subject-identities: incomparable-value
        visible-revision-identities: visible-value
        future-revision-identities: future-value
        runtime-executed?: #f)))
