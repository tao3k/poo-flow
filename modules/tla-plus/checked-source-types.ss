;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; One exact source/config TLC run. Its POO envelope is inert and does not
;;; assert source-to-POO semantic refinement or action authority.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/list/list every))

(export PooFlowTlaCheckedSource poo-flow-tla-checked-source?)

(def (text? value)
  (and (string? value) (> (string-length value) 0)))
(def (natural? value)
  (and (exact-integer? value) (>= value 0)))
(def (shape? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind identity semantic-digest source-digest source-set-digest
                     config-digest
                     qualification-schema syntax-contract tool-digest
                     tlc-version output-digest workers states-generated
                     distinct-states states-left graph-depth
                     source-checked? semantic-refinement?
                     action-authorized?))
       (eq? (.ref value 'kind) 'poo-flow.tla-plus.checked-source.v2)
       (every text?
              (map (lambda (slot) (.ref value slot))
                   '(identity semantic-digest source-digest source-set-digest
                     config-digest
                     qualification-schema syntax-contract tool-digest
                     tlc-version output-digest)))
       (every natural?
              (map (lambda (slot) (.ref value slot))
                   '(states-generated distinct-states states-left graph-depth)))
       (exact-integer? (.ref value 'workers))
       (> (.ref value 'workers) 0)
       (= (.ref value 'states-left) 0)
       (eq? (.ref value 'source-checked?) #t)
       (eq? (.ref value 'semantic-refinement?) #f)
       (eq? (.ref value 'action-authorized?) #f)))

(define-type (PooFlowTlaCheckedSource @ Type.)
  .element?: shape?)
(def (poo-flow-tla-checked-source? value)
  (element? PooFlowTlaCheckedSource value))
