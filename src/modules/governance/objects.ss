;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO-native governance declarations shared by every contributor.
;;; Invariant: the root is abstract; identity, revision, and owner are explicit.
(import (only-in :clan/poo/object .o)
        (only-in :poo-flow/src/modules/governance/types
                 poo-flow-governance-profile-kind
                 poo-flow-governance-source?))

(export PooFlowGovernanceProfile.
        poo-flow-governance-source)

(def PooFlowGovernanceProfile.
  (.o kind: poo-flow-governance-profile-kind
      identity: #f
      revision: #f
      owner: #f
      ontology: (.o)
      policies: (.o)
      source-assets: '()))

(def (poo-flow-governance-source identity-value path-value language-value)
  (let (value
        (.o identity: identity-value
            path: path-value
            language: language-value))
    (unless (poo-flow-governance-source? value)
      (error "invalid governance source" identity-value))
    value))
