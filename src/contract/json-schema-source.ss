;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Contract: read pinned JSON Schema source files into JSON-like Scheme data.
;;; Invariant: this owner performs file decoding only. Normalization,
;;; reference resolution, contract emission, and validation live elsewhere.

(import (only-in :std/encoding/json
                 JSONReadOptions
                 current-json-read-options
                 read-json)
        (only-in :std/list/walist
                 PureAList?
                 walist->list))

(export poo-flow-json-schema-source->json-like
        poo-flow-json-schema-read-file)

;; : (-> Pair Pair)
(def (poo-flow-json-schema-source-row->json-like row)
  (cons (car row)
        (poo-flow-json-schema-source->json-like (cdr row))))

;; : (-> JsonRuntimeDatum JsonLikeDatum)
(def (poo-flow-json-schema-source->json-like value)
  (cond
   ((PureAList? value)
    (map poo-flow-json-schema-source-row->json-like
         (walist->list value)))
   ((vector? value)
    (map poo-flow-json-schema-source->json-like
         (vector->list value)))
   ((list? value)
    (map poo-flow-json-schema-source->json-like value))
   (else value)))

;;; Boundary: the bridge consumes symbol-key walists so downstream contract
;;; logic stays independent from hash-table iteration order and string/symbol
;;; key drift.
;; : (-> PathString JsonLikeSchema)
(def (poo-flow-json-schema-read-file path)
  (parameterize ((current-json-read-options
                  (JSONReadOptions key-as-symbol: #t)))
    (poo-flow-json-schema-source->json-like
     (call-with-input-file path read-json))))
