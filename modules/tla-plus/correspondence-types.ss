;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every)
        "bundle-types.ss" "emission-types.ss")
(export PooFlowTlaCorrespondence poo-flow-tla-correspondence?)
(def (correspondence? value)
  (and (object? value)
       (every (lambda (s) (.slot? value s))
              '(kind identity emission bundle checked-bundle model-digest semantic-subset
                     step-table-identity bounded-differential? semantic-refinement? action-authorized?))
       (eq? (.ref value 'kind) 'tla/native-correspondence)
       (or (poo-flow-tla-temporal-emission? (.ref value 'emission))
           (poo-flow-tla-behavior-emission? (.ref value 'emission)))
       (poo-flow-tla-bundle? (.ref value 'bundle))
       (poo-flow-tla-checked-bundle? (.ref value 'checked-bundle))
       (every string? (map (lambda (s) (.ref value s)) '(identity model-digest step-table-identity)))
       (eq? (.ref value 'bounded-differential?) #t)
       (eq? (.ref value 'semantic-refinement?) #f)
       (eq? (.ref value 'action-authorized?) #f)))
(define-type (PooFlowTlaCorrespondence @ Type.) .element?: correspondence?)
(def (poo-flow-tla-correspondence? value) (element? PooFlowTlaCorrespondence value))
