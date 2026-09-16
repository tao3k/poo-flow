;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: bind an admitted Governance Profile to a Cedar authority input.
;;; Invariant: this adapter only constructs inert POO values; the independent
;;; Rust+Lean Runtime Host remains the sole dual-engine execution boundary.
(import (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/modules/governance/types
                 poo-flow-governance-profile?)
        (only-in :poo-flow/src/policy/cedar-authority
                 poo-flow-cedar-proof-binding?
                 poo-flow-cedar-authority-snapshot))

(export poo-flow-cedar-governance-snapshot)

(def (poo-flow-cedar-governance-snapshot
      profile-value context-value proof-value policy-values schema-value
      entities-value capability-values)
  (unless (poo-flow-governance-profile? profile-value)
    (error "Cedar governance projection requires an admitted Profile"
           profile-value))
  (unless (poo-flow-cedar-proof-binding? proof-value)
    (error "Cedar governance projection requires a proof binding" proof-value))
  (unless (equal? (.ref profile-value 'identity)
                  (.ref proof-value 'composition))
    (error "Governance Profile and Cedar composition identity mismatch"
           (.ref profile-value 'identity)
           (.ref proof-value 'composition)))
  (poo-flow-cedar-authority-snapshot
   context-value proof-value policy-values schema-value entities-value
   capability-values))
