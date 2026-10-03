;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Explicit runtime handoff: invoke parser-owned qualification and TLC, then
;;; bind its checked source/config/output to an inert POO evidence value.
(import (only-in :clan/poo/object .ref)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :gerbil-parser/src/runtime/artifact sha256-text)
        (only-in :gerbil-parser/languages/tla-plus/qualification
                 qualify-tla-plus-model
                 tla-plus-model-receipt-output
                 tla-plus-model-receipt->alist)
        (only-in "types.ss" poo-flow-tla-document?)
        (only-in "checked-source-types.ss"
                 poo-flow-tla-checked-source?)
        (only-in "checked-source-objects.ss"
                 poo-flow-tla-checked-source-value))

(export poo-flow-tla-check-source!
        poo-flow-tla-checked-source-replay)

(def (field row key)
  (let (entry (assq key row))
    (and entry (cdr entry))))
(def (file-digest path)
  (sha256-text (call-with-input-file path read-all-as-string)))
(def (digest-fields source config schema contract tool version output
                    workers generated distinct left depth)
  (sha256-text
   (call-with-output-string
    (lambda (port)
      (write (list 'poo-flow.tla-plus.checked-source.v1 source config
                   schema contract tool version output workers generated
                   distinct left depth) port)))))

(def (poo-flow-tla-checked-source-replay receipt document)
  (unless (and (poo-flow-tla-checked-source? receipt)
               (poo-flow-tla-document? document)
               (equal? (.ref receipt 'source-digest)
                       (.ref document 'source-digest)))
    (error "TLA+ checked source differs from parsed document"))
  (let (expected
        (digest-fields
         (.ref receipt 'source-digest) (.ref receipt 'config-digest)
         (.ref receipt 'qualification-schema)
         (.ref receipt 'syntax-contract) (.ref receipt 'tool-digest)
         (.ref receipt 'tlc-version) (.ref receipt 'output-digest)
         (.ref receipt 'workers) (.ref receipt 'states-generated)
         (.ref receipt 'distinct-states) (.ref receipt 'states-left)
         (.ref receipt 'graph-depth)))
    (unless (and (equal? expected (.ref receipt 'semantic-digest))
                 (equal? expected (.ref receipt 'identity)))
      (error "TLA+ checked source digest mismatch"))
    receipt))

(def (poo-flow-tla-check-source! document spec-path config-path
                                  workers: (workers 1))
  (unless (and (poo-flow-tla-document? document)
               (string? spec-path) (string? config-path)
               (exact-integer? workers) (> workers 0))
    (error "invalid TLA+ source check request"))
  (let ((source-before (file-digest spec-path))
        (config-before (file-digest config-path)))
    (unless (equal? source-before (.ref document 'source-digest))
      (error "TLA+ source differs from parsed document"))
    (let* ((native
            (qualify-tla-plus-model spec-path config-path workers: workers))
           (row (tla-plus-model-receipt->alist native)))
      (unless (and (field row 'admitted)
                   (field row 'syntax-accepted)
                   (field row 'roundtrip)
                   (equal? (field row 'source-digest) source-before)
                   (equal? (field row 'config-digest) config-before)
                   (equal? (file-digest spec-path) source-before)
                   (equal? (file-digest config-path) config-before)
                   (equal? (field row 'output-digest)
                           (sha256-text (tla-plus-model-receipt-output native)))
                   (equal? (field row 'workers) workers))
        (error "TLA+ source qualification or identity check failed" row))
      (let* ((semantic
              (digest-fields
               source-before config-before
               (field row 'schema) (field row 'syntax-contract)
               (field row 'tool-digest) (field row 'tlc-version)
               (field row 'output-digest) workers
               (field row 'states-generated) (field row 'distinct-states)
               (field row 'states-left) (field row 'graph-depth)))
             (receipt
              (poo-flow-tla-checked-source-value
               semantic semantic source-before config-before
               (field row 'schema) (field row 'syntax-contract)
               (field row 'tool-digest) (field row 'tlc-version)
               (field row 'output-digest) workers
               (field row 'states-generated) (field row 'distinct-states)
               (field row 'states-left) (field row 'graph-depth))))
        (poo-flow-tla-checked-source-replay receipt document)))))
