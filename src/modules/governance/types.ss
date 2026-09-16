;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: engine-neutral governance Profiles and Sources.
;;; Invariant: semantic admission never implies Cedar authorization.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :std/srfi/1 every))

(export poo-flow-governance-profile-kind
        poo-flow-governance-source?
        poo-flow-governance-profile?)

(def poo-flow-governance-profile-kind 'poo-flow.governance-profile)

(def (governance-text? value)
  (and (string? value) (> (string-length value) 0)))

(def (governance-has-slots? value slots)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot)) slots)))

(def (poo-flow-governance-source? value)
  (and (governance-has-slots? value '(identity path language))
       (governance-text? (.ref value 'identity))
       (governance-text? (.ref value 'path))
       (symbol? (.ref value 'language))))

(def (poo-flow-governance-profile? value)
  (and
   (governance-has-slots?
    value '(kind identity revision owner ontology policies source-assets))
   (eq? (.ref value 'kind) poo-flow-governance-profile-kind)
   (every (lambda (slot) (governance-text? (.ref value slot)))
          '(identity revision owner))
   (object? (.ref value 'ontology))
   (object? (.ref value 'policies))
   (list? (.ref value 'source-assets))
   (every poo-flow-governance-source? (.ref value 'source-assets))))
