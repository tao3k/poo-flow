;;; Boundary: facade for JSON Schema normalization across parse, definition
;;; collection, and reference resolution.
;;; Invariant: this owner wires the normalization pipeline only; new parser
;;; behavior belongs in core/parse/resolve modules and runtime predicate
;;; emission belongs in json-schema-emit.

(import (only-in "./functional.ss"
                 poo-flow-contract-json-object?)
        (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-normalization-record)
        (only-in "./json-schema-normalize-core.ss"
                 +poo-flow-json-schema-missing+
                 poo-flow-json-schema-parse)
        (only-in "./json-schema-normalize-parse.ss"
                 poo-flow-json-schema-parse-definitions)
        (only-in "./json-schema-normalize-resolve.ss"
                 poo-flow-json-schema-resolve-node))

(export poo-flow-json-schema-normalize
        poo-flow-json-schema-parse
        +poo-flow-json-schema-missing+)

;; Engineering boundary: this facade only orchestrates parse, definition
;; collection, and reference resolution. It must not grow local parser logic;
;; new JSON Schema behavior belongs in the core/parse/resolve owners.

;; Boundary: normalization is orchestration only; parser, definition, and
;; resolver semantics must remain in their dedicated owners.
;; poo-flow-json-schema-normalize
;;   : (-> JsonSchema JsonSchemaNormalization)
;;   | doc m%
;;       Parse root schema, collect local definitions, resolve local references,
;;       and preserve diagnostics from each phase for proof receipt generation.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-json-schema-normalize schema)
;;       ;; => json-schema-normalization-record
;;       ```
;;     %
(def (poo-flow-json-schema-normalize schema)
  (let* ((definitions-result
          (if (poo-flow-contract-json-object? schema)
            (poo-flow-json-schema-parse-definitions schema)
            (cons '() '())))
         (root-result (poo-flow-json-schema-parse schema))
         (resolved-result
          (poo-flow-json-schema-resolve-node
           (car root-result)
           (car definitions-result)
           '())))
    (poo-flow-json-schema-normalization-record
     (car resolved-result)
     (car definitions-result)
     (append (cdr root-result)
             (cdr definitions-result)
             (cdr resolved-result)))))
