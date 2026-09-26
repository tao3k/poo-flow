;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO Flow-owned qualification contracts around parser-owned TLA+.
;;; Invariant: syntax ownership stays in gerbil-parser; qualification grants
;;; neither semantic validation nor model-checking authority.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop Type. define-type element?)
        (only-in :std/list/list every))

(export PooFlowTlaLanguage
        PooFlowTlaDocument
        poo-flow-tla-language?
        poo-flow-tla-document?)

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
