;;; -*- Gerbil -*-
;;; Boundary: POO object validation receipts for module object contracts.
;;; This module is intentionally report-oriented; it does not execute runtime
;;; backends and it keeps heavy source scanning in the harness.

(import :gerbil/gambit
        (only-in :std/srfi/1 append-map)
        :poo-flow/src/modules/extension)

(export poo-flow-module-object-validation-kind
        poo-flow-module-object-validation-schema
        poo-flow-module-object-validation-source-ref
        poo-flow-module-object-harness-validation
        poo-flow-module-object-validation
        poo-flow-module-object-validation?
        poo-flow-module-object-validation-valid?
        poo-flow-module-object-validation-diagnostics
        poo-flow-module-objects-validation)

;; : String
(def poo-flow-module-object-validation-kind
  "poo-flow-module-object-validation")

;; : String
(def poo-flow-module-object-validation-schema
  "poo-flow-module-object-validation/v1")

;; : (-> Pair... HashTable)
(def (receipt . entries)
  (let (table (make-hash-table))
    (for-each
     (lambda (entry)
       (hash-put! table (car entry) (cdr entry)))
     entries)
    table))

;; : (-> Symbol String Any Any HashTable)
(def (diagnostic code message subject evidence)
  (receipt (cons 'code code)
           (cons 'message message)
           (cons 'subject subject)
           (cons 'evidence evidence)))

;; : (-> Any Boolean)
(def (metadata-list? value)
  (or (null? value)
      (and (list? value)
           (let loop ((rest value))
             (cond
              ((null? rest) #t)
              ((pair? (car rest)) (loop (cdr rest)))
              (else #f))))))

;; : (-> Symbol Boolean)
(def (merge-kind? value)
  (memq value '(override append prepend remove node-extend node-remove)))

;; : (-> Symbol Any Boolean)
(def (default-matches-kind? kind value)
  (or (not value)
      (case kind
        ((Symbol) (symbol? value))
        ((String) (string? value))
        ((List) (list? value))
        ((Boolean) (boolean? value))
        ((Number) (number? value))
        (else #t))))

;; : (-> PooModuleObject HashTable)
(def (poo-flow-module-object-validation-source-ref object)
  (receipt
   (cons 'kind "dependency")
   (cons 'manager "gerbil.pkg")
   (cons 'dependency "github.com/tao3k/gerbil-scheme-language-project-harness")
   (cons 'repository "github.com/tao3k/agent-semantic-protocols")
   (cons 'localSource "languages/gerbil-scheme-language-project-harness")
   (cons 'repositorySource "src/extensions/poo-validation.ss")
   (cons 'indexHint "poo-type-validation")
   (cons 'pathPolicy "package-dependency")
   (cons 'selectorScheme "gerbil-poo")
   (cons 'object (poo-flow-module-object-identity object))
   (cons 'inherits
         (map poo-flow-module-object-identity
              (poo-flow-module-object-inherits object)))
   (cons 'fields
         (map poo-flow-module-field-contract-identity
              (poo-flow-module-object-fields object)))
   (cons 'resolvedFields
         (map poo-flow-module-field-contract-identity
              (poo-flow-module-object-resolved-fields object)))))

;;; Harness validation is report-only here. The Gerbil language-project harness
;;; owns structural POO checks upstream; poo-flow records the object-aware source
;;; reference without importing a second validation module namespace.
;; : (-> PooModuleObject HashTable)
(def (poo-flow-module-object-harness-validation object)
  (receipt
   (cons 'kind "poo-pattern-structural-validation")
   (cons 'schema "poo-pattern-evidence/v1")
   (cons 'patternKind "type-validation")
   (cons 'valid #t)
   (cons 'sourceRef
         (poo-flow-module-object-validation-source-ref object))))

;; : (-> PooModuleObject PooModuleFieldContract [HashTable])
(def (field-diagnostics object field)
  (let ((identity (poo-flow-module-field-contract-identity field))
        (value-kind (poo-flow-module-field-contract-value-kind field))
        (merge (poo-flow-module-field-contract-merge field))
        (default (poo-flow-module-field-contract-default field))
        (metadata (poo-flow-module-field-contract-metadata field)))
    (append
     (if (merge-kind? merge)
       '()
       (list
        (diagnostic
         'invalid-merge
         "field contract merge kind is not supported by module object validation"
         identity
         merge)))
     (if (default-matches-kind? value-kind default)
       '()
       (list
        (diagnostic
         'default-kind-mismatch
         "field contract default does not match declared value kind"
         identity
         (receipt (cons 'valueKind value-kind)
                  (cons 'default default)))))
     (if (metadata-list? metadata)
       '()
       (list
        (diagnostic
         'metadata-not-list
         "field contract metadata must be an association list"
         identity
         metadata))))))

;; : (-> [Symbol] [Symbol])
(def (duplicate-identities identities)
  (let loop ((rest identities) (seen '()) (dupes '()))
    (cond
     ((null? rest) (reverse dupes))
     ((memq (car rest) seen)
      (loop (cdr rest) seen
            (if (memq (car rest) dupes) dupes (cons (car rest) dupes))))
    (else
      (loop (cdr rest) (cons (car rest) seen) dupes)))))

;; : (-> PooModuleObject [HashTable])
(def (object-diagnostics object)
  (let* ((fields (poo-flow-module-object-fields object))
         (resolved-fields (poo-flow-module-object-resolved-fields object))
         (resolved-identities
          (map poo-flow-module-field-contract-identity resolved-fields))
         (duplicates (duplicate-identities resolved-identities)))
    (append
     (if (metadata-list? (poo-flow-module-object-metadata object))
       '()
       (list
        (diagnostic
         'object-metadata-not-list
         "module object metadata must be an association list"
         (poo-flow-module-object-identity object)
         (poo-flow-module-object-metadata object))))
     (append-map (lambda (field) (field-diagnostics object field)) fields)
     (if (null? duplicates)
       '()
       (list
        (diagnostic
         'duplicate-resolved-field
         "module object resolved fields contain duplicate identities"
         (poo-flow-module-object-identity object)
         duplicates))))))

;; : (-> PooModuleObject HashTable)
(def (poo-flow-module-object-validation object)
  (let* ((harness-validation
          (poo-flow-module-object-harness-validation object))
         (diagnostics (object-diagnostics object))
         (valid? (null? diagnostics)))
    (receipt
     (cons 'kind poo-flow-module-object-validation-kind)
     (cons 'schema poo-flow-module-object-validation-schema)
     (cons 'object (poo-flow-module-object-identity object))
     (cons 'harnessValidation harness-validation)
     (cons 'valid valid?)
     (cons 'diagnostics diagnostics)
     (cons 'checkedSignals
           '(harness-type-validation
             field-merge-kind
             field-default-kind
             metadata-shape
             resolved-field-identity)))))

;; : (-> Any Boolean)
(def (poo-flow-module-object-validation? value)
  (and (hash-table? value)
       (equal? (hash-get value 'kind)
               poo-flow-module-object-validation-kind)
       (equal? (hash-get value 'schema)
               poo-flow-module-object-validation-schema)))

;; : (-> HashTable Boolean)
(def (poo-flow-module-object-validation-valid? validation)
  (hash-get validation 'valid))

;; : (-> HashTable [HashTable])
(def (poo-flow-module-object-validation-diagnostics validation)
  (hash-get validation 'diagnostics))

;; : (-> [PooModuleObject] [HashTable])
(def (poo-flow-module-objects-validation objects)
  (map poo-flow-module-object-validation objects))
