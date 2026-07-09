;;; -*- Gerbil -*-
;;; Contract: read pinned JSON Schema source files into JSON-like Scheme data.
;;; Invariant: this owner performs file decoding only. Normalization,
;;; reference resolution, contract emission, and validation live elsewhere.

(import (only-in :std/text/json
                 read-json
                 read-json-array-as-vector?
                 read-json-key-as-symbol?
                 read-json-object-as-walist?)
        (only-in :std/misc/walist
                 walist?
                 walist->alist))

(export poo-flow-json-schema-source->json-like
        poo-flow-json-schema-read-file)

;; : (-> Pair Pair)
(def (poo-flow-json-schema-source-row->json-like row)
  (cons (car row)
        (poo-flow-json-schema-source->json-like (cdr row))))

;; : (-> JsonRuntimeDatum JsonLikeDatum)
(def (poo-flow-json-schema-source->json-like value)
  (cond
   ((walist? value)
    (map poo-flow-json-schema-source-row->json-like
         (walist->alist value)))
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
  (parameterize ((read-json-key-as-symbol? #t)
                 (read-json-object-as-walist? #t)
                 (read-json-array-as-vector? #f))
    (poo-flow-json-schema-source->json-like
     (call-with-input-file path read-json))))
