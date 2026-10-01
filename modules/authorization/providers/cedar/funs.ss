;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: bind an admitted Governance composition to one Cedar authority input.
;;; Invariant: this adapter only constructs inert POO values; the independent
;;; Rust+Lean Runtime Host remains the sole dual-engine execution boundary.
(import (only-in :clan/poo/object .cc)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :poo-flow/modules/authorization/providers/cedar/objects
                 poo-flow-cedar-authority-snapshot
                 poo-flow-cedar-policy)
        (only-in "contracts.ss" poo-flow-cedar-governance-contract))

(export poo-flow-cedar-governance-snapshot
        poo-flow-cedar-policy-file)

;; Load the exact exported Cedar artifact as an inert POO policy value.
;; Cedar syntax and policy-set expansion remain owned by the native boundary.
(def (poo-flow-cedar-policy-file identity path)
  (unless (and (string? path)
               (>= (string-length path) 6)
               (string=? (substring path (- (string-length path) 6)
                                    (string-length path))
                         ".cedar"))
    (error "Cedar policy file must be an exported .cedar artifact" path))
  (poo-flow-cedar-policy
   identity
   (call-with-input-file path read-all-as-string)))

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
