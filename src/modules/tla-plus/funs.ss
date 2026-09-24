;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; The parser remains the sole syntax authority. The POO document retains
;;; its exact qualification identities and a named escape hatch to the
;;; parser-owned tree; it never copies the tree into a second object family.
(import (only-in :clan/poo/object .o .ref)
        (only-in :gerbil-parser/languages/tla-plus/v1/parser parse-tla-plus-v1)
        (only-in :gerbil-parser/src/runtime/artifact
                 parse-artifact-ref parse-artifact-success?
                 parse-artifact-roundtrip)
        (only-in :gerbil-parser/src/runtime/cst parse-artifact->cst)
        (only-in "objects.ss" PooFlowTlaDocument. poo-flow-tla-document?))
(export poo-flow-tla-parse-source poo-flow-tla-parser-cst)

;;; Accepted syntax is not a proof of TLA+ semantics or TLC admission.
;;; Rejected sources fail closed with parser-owned diagnostics.
(def (poo-flow-tla-parse-source source)
  (unless (string? source)
    (error "TLA+ source must be a string" source))
  (let (artifact (parse-tla-plus-v1 source))
    (unless (parse-artifact-success? artifact)
      (error "gerbil-parser rejected TLA+ source"
             (parse-artifact-ref artifact 'diagnostics)))
    ;; roundtrip validates the complete event stream before returning source;
    ;; a separate valid? call would traverse and hash it a second time.
    (unless (equal? source (parse-artifact-roundtrip artifact))
      (error "gerbil-parser TLA+ source roundtrip mismatch"))
    ;; Most qualification consumers need only the source/grammar identities.
    ;; Keep the parser-owned tree demand-driven and cache it per document.
    (let (parser-cst (delay (parse-artifact->cst artifact)))
      (.o (:: @ PooFlowTlaDocument.)
          source-digest: (parse-artifact-ref artifact 'sourceDigest)
          grammar-digest: (parse-artifact-ref artifact 'grammarDigest)
          source-byte-length: (parse-artifact-ref artifact 'sourceByteLength)
          .parser-cst: (lambda () (force parser-cst))
          exact-roundtrip?: #t))))

;;; Explicit advanced access to the *same* parser-owned CST. Normal consumers
;;; use the POO document's identities and qualification status.
(def (poo-flow-tla-parser-cst document)
  (unless (poo-flow-tla-document? document)
    (error "invalid POO Flow TLA+ document" document))
  ((.ref document '.parser-cst)))
