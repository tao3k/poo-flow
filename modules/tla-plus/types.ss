;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO Flow-owned qualification contracts around parser-owned TLA+.
;;; Invariant: syntax ownership stays in gerbil-parser; qualification grants
;;; neither semantic validation nor model-checking authority.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop Type. define-type element?)
        (only-in :std/list/list every)
        (only-in :poo-flow/modules/temporal-causality/types
                 poo-flow-temporal-model?)
        (only-in :poo-flow/modules/temporal-causality/behavior/types
                 poo-flow-temporal-behavior-model? poo-flow-temporal-property?))

(export PooFlowTlaBehaviorProjection poo-flow-tla-behavior-projection?
        PooFlowTlaLanguage
        PooFlowTlaDocument
        PooFlowTlaModelOutline
        PooFlowTlaTemporalProjection
        poo-flow-tla-language?
        poo-flow-tla-document?
        poo-flow-tla-model-outline?
        poo-flow-tla-temporal-projection?)

(def (tla-has-slots? value slots)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot)) slots)))

(def (tla-nonempty-string? value)
  (and (string? value) (> (string-length value) 0)))

(def (tla-language-shape? value)
  (and (tla-has-slots?
        value '(identity parser-owner syntax-contract representation
                         semantic-validation? model-checking?))
       (eq? (.ref value 'identity) 'tla-plus)
       (eq? (.ref value 'parser-owner) 'gerbil-parser)
       (tla-nonempty-string? (.ref value 'syntax-contract))
       (eq? (.ref value 'representation) 'parser-owned-cst)
       (eq? (.ref value 'semantic-validation?) #f)
       (eq? (.ref value 'model-checking?) #f)))

(define-type (PooFlowTlaLanguage @ Type.)
  .element?: tla-language-shape?)

(def (tla-document-shape? value)
  (and (tla-has-slots?
        value '(language source-digest grammar-digest source-byte-length
                         .parser-cst exact-roundtrip? semantic-validation?
                         model-checking?))
       (element? PooFlowTlaLanguage (.ref value 'language))
       (tla-nonempty-string? (.ref value 'source-digest))
       (tla-nonempty-string? (.ref value 'grammar-digest))
       (exact-integer? (.ref value 'source-byte-length))
       (>= (.ref value 'source-byte-length) 0)
       (procedure? (.ref value '.parser-cst))
       (eq? (.ref value 'exact-roundtrip?) #t)
       (eq? (.ref value 'semantic-validation?) #f)
       (eq? (.ref value 'model-checking?) #f)))

(define-type (PooFlowTlaDocument @ Type.)
  .element?: tla-document-shape?)

(def (poo-flow-tla-language? value)
  (element? PooFlowTlaLanguage value))

(def (poo-flow-tla-document? value)
  (element? PooFlowTlaDocument value))

;;; A declaration index over the parser-owned CST, not a second TLA+ AST or
;;; semantic admission. Duplicate names remain visible for later semantic checks.
(def (tla-name-list? value)
  (and (list? value)
       (every tla-nonempty-string? value)))

(def (tla-model-outline-shape? value)
  (and (tla-has-slots?
        value '(kind document source-digest grammar-digest module-identity
                     variable-identities constant-identities
                     operator-identities semantic-validation? model-checking?))
       (eq? (.ref value 'kind) 'poo-flow.tla-plus.model-outline)
       (poo-flow-tla-document? (.ref value 'document))
       (equal? (.ref value 'source-digest)
               (.ref (.ref value 'document) 'source-digest))
       (equal? (.ref value 'grammar-digest)
               (.ref (.ref value 'document) 'grammar-digest))
       (tla-nonempty-string? (.ref value 'module-identity))
       (tla-name-list? (.ref value 'variable-identities))
       (tla-name-list? (.ref value 'constant-identities))
       (tla-name-list? (.ref value 'operator-identities))
       (eq? (.ref value 'semantic-validation?) #f)
       (eq? (.ref value 'model-checking?) #f)))

(define-type (PooFlowTlaModelOutline @ Type.)
  .element?: tla-model-outline-shape?)

(def (poo-flow-tla-model-outline? value)
  (element? PooFlowTlaModelOutline value))

(def (tla-temporal-projection-shape? value)
  (and (tla-has-slots?
        value '(kind document model source-digest grammar-digest
                     semantic-digest semantic-subset model-checking?))
       (eq? (.ref value 'kind) 'poo-flow.tla-plus.temporal-projection)
       (poo-flow-tla-document? (.ref value 'document))
       (poo-flow-temporal-model? (.ref value 'model))
       (equal? (.ref value 'source-digest)
               (.ref (.ref value 'document) 'source-digest))
       (equal? (.ref value 'grammar-digest)
               (.ref (.ref value 'document) 'grammar-digest))
       (equal? (.ref value 'semantic-digest)
               (.ref (.ref value 'model) 'semantic-digest))
       (memq (.ref value 'semantic-subset)
             '(poo-flow.tla-plus.literal-hypothesis-family.v1
               poo-flow.tla-plus.literal-hypothesis-family.v2))
       (eq? (.ref value 'model-checking?) #f)))

(define-type (PooFlowTlaTemporalProjection @ Type.)
  .element?: tla-temporal-projection-shape?)

(def (poo-flow-tla-temporal-projection? value)
  (element? PooFlowTlaTemporalProjection value))

(def (tla-behavior-projection-shape? value)
  (and (tla-has-slots? value '(kind document model property source-digest grammar-digest semantic-digest
                                  semantic-subset model-checking? action-authorized?))
       (eq? (.ref value 'kind) 'poo-flow.tla-plus.behavior-projection)
       (poo-flow-tla-document? (.ref value 'document))
       (poo-flow-temporal-behavior-model? (.ref value 'model))
       (poo-flow-temporal-property? (.ref value 'property))
       (equal? (.ref value 'source-digest) (.ref (.ref value 'document) 'source-digest))
       (equal? (.ref value 'grammar-digest) (.ref (.ref value 'document) 'grammar-digest))
       (equal? (.ref value 'semantic-digest) (.ref (.ref value 'model) 'semantic-digest))
       (eq? (.ref value 'semantic-subset) 'poo-flow.tla-plus.logical-step-behavior.v1)
       (eq? (.ref value 'model-checking?) #f) (eq? (.ref value 'action-authorized?) #f)))
(define-type (PooFlowTlaBehaviorProjection @ Type.) .element?: tla-behavior-projection-shape?)
(def (poo-flow-tla-behavior-projection? value) (element? PooFlowTlaBehaviorProjection value))
