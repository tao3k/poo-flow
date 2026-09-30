;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Native module-schema admission. Gerbil POO owns Type and C4 semantics;
;;; this module checks only the field and catalog contracts built on them.

(import :gerbil/core
        (only-in :clan/poo/object .o .ref object? compute-precedence-list!)
        (only-in :std/list/list foldl)
        :core/module-system/schema/interface)

(export poo-flow-module-object-validation-kind
        poo-flow-module-object-validation-schema
        poo-flow-module-field-contract-validation-kind
        poo-flow-module-field-contract-validation
        poo-flow-module-field-contract-validation-valid?
        poo-flow-module-object-inheritance-chain
        poo-flow-module-object-validation
        poo-flow-module-object-validation?
        poo-flow-module-object-validation-valid?
        poo-flow-module-object-validation-diagnostics
        poo-flow-module-objects-validation
        poo-flow-module-objects-validation-summary
        poo-flow-require-module-object-validation!
        poo-flow-require-module-objects-validation!)

(def poo-flow-module-object-validation-kind "core.module-schema.validation")
(def poo-flow-module-object-validation-schema
  "core.module-schema.validation/v1")
(def poo-flow-module-field-contract-validation-kind
  "core.module-schema.field-validation")

(def +module-schema-merge-kinds+
  '(override append prepend remove node-extend node-remove))

(def (module-schema-metadata? value)
  (and (list? value) (andmap pair? value)))

(def (module-schema-diagnostic code subject evidence)
  (let ((diagnostic-code code)
        (diagnostic-subject subject)
        (diagnostic-evidence evidence))
    (.o code: diagnostic-code
        subject: diagnostic-subject
        evidence: diagnostic-evidence)))

(def (module-schema-merge-type-compatible? merge type)
  (let (type-kind (and (poo-flow-module-value-type? type)
                      (poo-flow-module-value-type-kind type)))
    (cond
     ((eq? merge 'node-extend) (eq? type-kind 'Node))
     ((eq? merge 'node-remove) (eq? type-kind 'Symbol))
     (else #t))))

(def (module-schema-field-diagnostics field)
  (let* ((identity (poo-flow-module-field-contract-identity field))
         (type (poo-flow-module-field-contract-value-type field))
         (merge (poo-flow-module-field-contract-merge field))
         (default (poo-flow-module-field-contract-default field))
         (metadata (poo-flow-module-field-contract-metadata field)))
    (append
     (if (poo-flow-module-value-type? type)
       '()
       (list (module-schema-diagnostic 'invalid-native-type identity type)))
     (if (memq merge +module-schema-merge-kinds+)
       '()
       (list (module-schema-diagnostic 'unsupported-merge identity merge)))
     (if (module-schema-merge-type-compatible? merge type)
       '()
       (list (module-schema-diagnostic 'merge-type-incompatible
                                       identity merge)))
     (if (module-schema-metadata? metadata)
       '()
       (list (module-schema-diagnostic 'metadata-not-association-list
                                       identity metadata)))
     (if (or (not default)
             (poo-flow-module-value-type-accepts? type default))
       '()
       (list (module-schema-diagnostic 'default-not-in-native-type
                                       identity default))))))

(def (poo-flow-module-field-contract-validation schema-object field-contract)
  (let* ((type (poo-flow-module-field-contract-value-type field-contract))
         (field-diagnostics (module-schema-field-diagnostics field-contract)))
    (.o kind: poo-flow-module-field-contract-validation-kind
        schema: poo-flow-module-object-validation-schema
        object: (poo-flow-module-object-identity schema-object)
        field: (poo-flow-module-field-contract-identity field-contract)
        valueKind: (if (poo-flow-module-value-type? type)
                     (poo-flow-module-value-type-kind type)
                     'invalid-native-type)
        merge: (poo-flow-module-field-contract-merge field-contract)
        valid: (null? field-diagnostics)
        diagnostics: field-diagnostics)))

(def (poo-flow-module-field-contract-validation-valid? validation)
  (.ref validation 'valid))

(def (module-schema-field-identities fields)
  (map (lambda (field)
         (and (poo-flow-module-field-contract? field)
              (poo-flow-module-field-contract-identity field)))
       fields))

(def (poo-flow-module-object-inheritance-chain schema-object)
  (map poo-flow-module-object-identity
       (compute-precedence-list! schema-object)))

(def (module-schema-duplicate-identities identities)
  (let ((seen (make-hash-table))
        (duplicates (make-hash-table)))
    (reverse
     (foldl
      (lambda (identity result)
        (cond
         ((hash-key? duplicates identity) result)
         ((hash-key? seen identity)
          (hash-put! duplicates identity #t)
          (cons identity result))
         (else
          (hash-put! seen identity #t)
          result)))
      '()
      identities))))

(def (module-schema-field-provider precedence identity)
  (let loop ((rest precedence))
    (cond
     ((null? rest) #f)
     ((memq identity
            (module-schema-field-identities
             (poo-flow-module-object-fields (car rest))))
      (car rest))
     (else (loop (cdr rest))))))

(def (module-schema-field-origin schema-object precedence field-contract)
  (let* ((identity (poo-flow-module-field-contract-identity field-contract))
         (field-provider (module-schema-field-provider precedence identity)))
    (.o field: identity
        origin: (if (eq? field-provider schema-object) 'direct 'inherited)
        provider: (and field-provider
                       (poo-flow-module-object-identity field-provider)))))

(def (module-schema-validation-phase name valid? count)
  (.o phase: name status: (if valid? 'ok 'invalid) diagnostic-count: count))

(def (module-schema-object-validation/uncached schema-object)
  (let* ((precedence (compute-precedence-list! schema-object))
         (direct-fields (poo-flow-module-object-fields schema-object))
         (malformed-fields
          (apply append
                 (map (lambda (candidate)
                        (filter (lambda (field)
                                  (not (poo-flow-module-field-contract? field)))
                                (poo-flow-module-object-fields candidate)))
                      precedence)))
         (resolved-fields
          (if (null? malformed-fields)
            (poo-flow-module-object-resolved-fields schema-object)
            '()))
         (direct-identities (module-schema-field-identities direct-fields))
         (resolved-identities (module-schema-field-identities resolved-fields))
         (duplicates (module-schema-duplicate-identities resolved-identities))
         (field-validations
          (map (lambda (field)
                 (poo-flow-module-field-contract-validation schema-object field))
               resolved-fields))
         (field-diagnostics
          (apply append
                 (map (lambda (validation) (.ref validation 'diagnostics))
                      field-validations)))
         (object-metadata (poo-flow-module-object-metadata schema-object))
         (local-diagnostics
          (append
           (map (lambda (field)
                  (module-schema-diagnostic
                   'invalid-field-contract
                   (poo-flow-module-object-identity schema-object)
                   field))
                malformed-fields)
           (if (module-schema-metadata? object-metadata)
             '()
             (list (module-schema-diagnostic
                    'object-metadata-not-association-list
                    (poo-flow-module-object-identity schema-object)
                    object-metadata)))
           (if (null? duplicates)
             '()
             (list (module-schema-diagnostic
                    'duplicate-resolved-field
                   (poo-flow-module-object-identity schema-object)
                   duplicates)))))
         (diagnostic-list (append field-diagnostics local-diagnostics)))
    (.o kind: poo-flow-module-object-validation-kind
        schema: poo-flow-module-object-validation-schema
        object: (poo-flow-module-object-identity schema-object)
        inherits: (map poo-flow-module-object-identity
                       (poo-flow-module-object-inherits schema-object))
        inheritance-chain: (poo-flow-module-object-inheritance-chain
                            schema-object)
        inherit-count: (length (poo-flow-module-object-inherits schema-object))
        direct-field-count: (length direct-fields)
        direct-field-identities: direct-identities
        resolved-field-count: (length resolved-fields)
        resolved-field-identities: resolved-identities
        field-origins: (map (lambda (field)
                             (module-schema-field-origin schema-object precedence field))
                           resolved-fields)
        metadata: object-metadata
        fieldContractValidations: field-validations
        validationPhases:
        (list (module-schema-validation-phase 'native-field-contracts
                                              (null? field-diagnostics)
                                              (length field-diagnostics))
              (module-schema-validation-phase 'module-schema
                                              (null? local-diagnostics)
                                              (length local-diagnostics)))
        valid: (null? diagnostic-list)
        diagnostics: diagnostic-list
        checkedSignals:
        '(native-poo-type native-c4-precedence field-merge-kind
          field-default-type field-metadata-shape object-metadata-shape
          resolved-field-identity))))

(def (poo-flow-module-object-validation object)
  (let (cache (poo-flow-module-object-validation-cache object))
    (if (vector-ref cache 0)
      (vector-ref cache 1)
      (let (validation (module-schema-object-validation/uncached object))
        (vector-set! cache 0 #t)
        (vector-set! cache 1 validation)
        validation))))

(def (poo-flow-module-object-validation? value)
  (and (object? value)
       (equal? (.ref value 'kind)
               poo-flow-module-object-validation-kind)
       (equal? (.ref value 'schema)
               poo-flow-module-object-validation-schema)))

(def (poo-flow-module-object-validation-valid? validation)
  (.ref validation 'valid))

(def (poo-flow-module-object-validation-diagnostics validation)
  (.ref validation 'diagnostics))

(def (poo-flow-module-objects-validation objects)
  (map poo-flow-module-object-validation objects))

(def (poo-flow-module-objects-validation-summary validations)
  (let* ((invalid (filter (lambda (validation)
                            (not (poo-flow-module-object-validation-valid?
                                  validation)))
                          validations))
         (identities (map (lambda (validation) (.ref validation 'object))
                          validations))
         (duplicate-object-ids
          (module-schema-duplicate-identities identities)))
    (.o kind: "core.module-schema.catalog-validation"
        schema: poo-flow-module-object-validation-schema
        object-count: (length validations)
        object-identities: identities
        invalid-count: (length invalid)
        invalid-objects:
        (map (lambda (validation) (.ref validation 'object)) invalid)
        duplicate-identities: duplicate-object-ids
        duplicate-count: (length duplicate-object-ids)
        inheritance-counts:
        (map (lambda (validation) (.ref validation 'inherit-count)) validations)
        inheritance-chains:
        (map (lambda (validation) (.ref validation 'inheritance-chain)) validations)
        field-origins:
        (map (lambda (validation) (.ref validation 'field-origins)) validations)
        validation-phases:
        (map (lambda (validation) (.ref validation 'validationPhases)) validations)
        valid: (and (null? invalid) (null? duplicate-object-ids))
        checkedSignals: '(native-poo-catalog-validation)
        descriptor-realized?: #f
        runtime-executed: #f)))

(def (poo-flow-require-module-object-validation! object)
  (let (validation (poo-flow-module-object-validation object))
    (if (poo-flow-module-object-validation-valid? validation)
      object
      (error "module schema validation failed" validation))))

(def (poo-flow-require-module-objects-validation! objects)
  (let (summary
        (poo-flow-module-objects-validation-summary
         (poo-flow-module-objects-validation objects)))
    (if (.ref summary 'valid)
      objects
      (error "module schema catalog validation failed" summary))))
