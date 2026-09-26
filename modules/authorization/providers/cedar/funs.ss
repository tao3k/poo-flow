;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: bind an admitted Governance composition to one Cedar authority input.
;;; Invariant: this adapter only constructs inert POO values; the independent
;;; Rust+Lean Runtime Host remains the sole dual-engine execution boundary.
(import (only-in :clan/poo/object .cc)
        (only-in :poo-flow/modules/authorization/providers/cedar/objects
                 poo-flow-cedar-authority-snapshot)
        (only-in "contracts.ss" poo-flow-cedar-governance-contract))

(export poo-flow-cedar-governance-snapshot)

(def (poo-flow-cedar-governance-snapshot
      composition-identity profile-values assessment-values
      context-value proof-value policy-values
      schema-value entities-value capability-values)
  (poo-flow-cedar-governance-contract
   composition-identity profile-values assessment-values proof-value)
  (.cc
   (poo-flow-cedar-authority-snapshot
    context-value proof-value policy-values schema-value entities-value
    capability-values)
   'governance-assessments assessment-values))
