;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; The parser remains the sole syntax authority. The POO document retains
;;; its exact qualification identities and a named escape hatch to the
;;; parser-owned tree; it never copies the tree into a second object family.
(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        (only-in :std/list/list filter)
        (only-in :gerbil-parser/languages/tla-plus/parser parse-tla-plus)
        (only-in :gerbil-parser/src/runtime/artifact
                 parse-artifact-ref parse-artifact-success?
                 parse-artifact-roundtrip)
        (only-in :gerbil-parser/src/runtime/cst
                 parse-artifact->cst syntax-node? syntax-node-kind
                 syntax-node-children syntax-field? syntax-field-name
                 syntax-field-start
                 syntax-field-children)
        (only-in :gerbil-parser/src/runtime/token
                 token? token-kind token-lexeme)
        (only-in :poo-flow/modules/temporal-causality/objects
                 poo-flow-temporal-clock-domain
                 poo-flow-temporal-model-observation
                 poo-flow-temporal-constraint
                 poo-flow-temporal-hypothesis)
        (only-in :poo-flow/modules/temporal-causality/funs
                 poo-flow-temporal-model)
        (only-in "types.ss" PooFlowTlaDocument poo-flow-tla-document?)
        (only-in "objects.ss"
                 PooFlowTlaDocument. poo-flow-tla-model-outline-value
                 poo-flow-tla-temporal-projection-value))
(export poo-flow-tla-parse-source poo-flow-tla-parser-cst
        poo-flow-tla-model-outline
        poo-flow-tla-project-temporal-model)

;;; Accepted syntax is not a proof of TLA+ semantics or TLC admission.
;;; Rejected sources fail closed with parser-owned diagnostics.
(def (poo-flow-tla-parse-source source)
  (unless (string? source)
    (error "TLA+ source must be a string" source))
  (let (artifact (parse-tla-plus source))
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
      (validate
       PooFlowTlaDocument
       (.o (:: @ PooFlowTlaDocument.)
           source-digest: (parse-artifact-ref artifact 'sourceDigest)
           grammar-digest: (parse-artifact-ref artifact 'grammarDigest)
           source-byte-length: (parse-artifact-ref artifact 'sourceByteLength)
           .parser-cst: (lambda () (force parser-cst))
           exact-roundtrip?: #t)))))

;;; Explicit advanced access to the *same* parser-owned CST. Normal consumers
;;; use the POO document's identities and qualification status.
(def (poo-flow-tla-parser-cst document)
  (unless (poo-flow-tla-document? document)
    (error "invalid POO Flow TLA+ document" document))
  ((.ref document '.parser-cst)))

(def (tla-fields node name)
  (list-sort
   (lambda (left right)
     (< (syntax-field-start left) (syntax-field-start right)))
   (filter (lambda (child)
             (and (syntax-field? child) (eq? (syntax-field-name child) name)))
           (syntax-node-children node))))

(def (tla-only matches)
  (unless (= (length matches) 1)
    (error "TLA+ model outline requires exactly one CST element" matches))
  (car matches))

(def (tla-identifier field)
  (let (token (tla-only (filter token? (syntax-field-children field))))
    (unless (eq? (token-kind token) 'identifier)
      (error "TLA+ model outline requires an identifier" field))
    (token-lexeme token)))

(def (tla-names-of-kind items kind)
  (apply append
         (map (lambda (item)
                (map tla-identifier (tla-fields item 'name)))
              (filter (lambda (item) (eq? (syntax-node-kind item) kind))
                      items))))

;;; This projects only top-level declaration identities.  Expression bodies
;;; remain in the parser-owned CST; no TLA+ semantics or TLC result is inferred.
(def (poo-flow-tla-model-outline document)
  (let* ((root (poo-flow-tla-parser-cst document))
         (module (tla-only
                  (filter syntax-node?
                          (syntax-field-children
                           (tla-only (tla-fields root 'module))))))
         (items (map (lambda (field)
                       (tla-only (filter syntax-node?
                                         (syntax-field-children field))))
                     (tla-fields module 'item))))
    (unless (eq? (syntax-node-kind module) 'Module)
      (error "TLA+ model outline requires a Module node"))
    (poo-flow-tla-model-outline-value
     document
     (tla-identifier (tla-only (tla-fields module 'name)))
     (tla-names-of-kind items 'VariableDeclaration)
     (tla-names-of-kind items 'ConstantDeclaration)
     (tla-names-of-kind items 'OperatorDefinition))))

;;; Only finite literal sets/tuples, quoted strings without escapes, natural
;;; numbers, and TRUE/FALSE are admitted. An accepted parser CST alone does not
;;; grant this semantic projection.
(def (tla-literal node)
  (case (syntax-node-kind node)
    ((SetExpression TupleExpression)
     (map (lambda (field)
            (tla-literal
             (tla-only (filter syntax-node?
                               (syntax-field-children field)))))
          (tla-fields node 'item)))
    ((StringExpression)
     (let* ((token (tla-only (filter token?
                                     (syntax-field-children
                                      (tla-only (tla-fields node 'value))))))
            (lexeme (token-lexeme token))
            (length-value (string-length lexeme)))
       (unless (and (eq? (token-kind token) 'string)
                    (>= length-value 2)
                    (char=? (string-ref lexeme 0) #\")
                    (char=? (string-ref lexeme (- length-value 1)) #\")
                    (not (memv #\\ (string->list lexeme))))
         (error "unsupported TLA+ string literal" lexeme))
       (substring lexeme 1 (- length-value 1))))
    ((NumberExpression)
     (let* ((token (tla-only (filter token?
                                     (syntax-field-children
                                      (tla-only (tla-fields node 'value))))))
            (value (string->number (token-lexeme token))))
       (unless (and (eq? (token-kind token) 'number)
                    (exact-integer? value) (>= value 0))
         (error "unsupported TLA+ number literal" (token-lexeme token)))
       value))
    ((NameExpression)
     (case (string->symbol
            (tla-identifier (tla-only (tla-fields node 'name))))
       ((TRUE) #t)
       ((FALSE) #f)
       (else (error "unsupported TLA+ name expression" node))))
    (else (error "unsupported TLA+ temporal literal" (syntax-node-kind node)))))

(def (tla-literal-tuples value arity label)
  (unless (and (list? value)
               (every (lambda (tuple)
                        (and (list? tuple) (= (length tuple) arity))) value))
    (error "invalid TLA+ temporal literal tuples" label))
  value)

;;; This is an explicit source-to-POO profile, not a general TLA+ evaluator.
;;; Any extra declaration, operator parameter, or expression kind fails closed.
(def (poo-flow-tla-project-temporal-model document)
  (let* ((outline (poo-flow-tla-model-outline document))
         (root (poo-flow-tla-parser-cst document))
         (module (tla-only
                  (filter syntax-node?
                          (syntax-field-children
                           (tla-only (tla-fields root 'module))))))
         (items (map (lambda (field)
                       (tla-only (filter syntax-node?
                                         (syntax-field-children field))))
                     (tla-fields module 'item)))
         (names '("ClockDomains" "Observations" "Hypotheses"
                  "Constraints" "FamilyComplete")))
    (unless (and (= (length items) (length names))
                 (every (lambda (item)
                          (and (eq? (syntax-node-kind item) 'OperatorDefinition)
                               (null? (tla-fields item 'parameter)))) items)
                 (equal? (list-sort string<? (.ref outline 'operator-identities))
                         (list-sort string<? names)))
      (error "unsupported TLA+ temporal family declarations"
             (.ref outline 'operator-identities)))
    (def (operator name)
      (let (item
            (tla-only
             (filter (lambda (candidate)
                       (equal? (tla-identifier
                                (tla-only (tla-fields candidate 'name))) name))
                     items)))
        (tla-literal
         (tla-only (filter syntax-node?
                           (syntax-field-children
                            (tla-only (tla-fields item 'body))))))))
    (let* ((domain-tuples
            (tla-literal-tuples (operator "ClockDomains") 2 'ClockDomains))
           (observation-tuples
            (tla-literal-tuples (operator "Observations") 5 'Observations))
           (hypothesis-tuples
            (tla-literal-tuples (operator "Hypotheses") 3 'Hypotheses))
           (constraint-tuples
            (tla-literal-tuples (operator "Constraints") 5 'Constraints))
           (complete? (operator "FamilyComplete")))
      (unless (boolean? complete?)
        (error "FamilyComplete must be a TLA+ boolean literal"))
      (unless (every (lambda (tuple) (every string? tuple))
                     (append domain-tuples hypothesis-tuples constraint-tuples))
        (error "TLA+ temporal identifiers and roles must be strings"))
      (unless (every (lambda (tuple)
                       (and (string? (list-ref tuple 0))
                            (string? (list-ref tuple 1))
                            (exact-integer? (list-ref tuple 2))
                            (string? (list-ref tuple 3))
                            (string? (list-ref tuple 4))))
                     observation-tuples)
        (error "invalid TLA+ temporal observation tuple"))
      (let ((hypothesis-index (make-hash-table))
            (constraint-index (make-hash-table)))
        (for-each (lambda (tuple)
                    (hash-put! hypothesis-index (car tuple) #t))
                  hypothesis-tuples)
        (for-each
         (lambda (tuple)
           (let (hypothesis-id (cadr tuple))
             (unless (hash-get hypothesis-index hypothesis-id)
               (error "TLA+ constraint names an unknown hypothesis"
                      hypothesis-id))
             (hash-put!
              constraint-index hypothesis-id
              (cons (poo-flow-temporal-constraint
                     (car tuple) (string->symbol (list-ref tuple 2))
                     (list-ref tuple 3) (list-ref tuple 4))
                    (or (hash-get constraint-index hypothesis-id) '())))))
         constraint-tuples)
        (let* ((domains
              (map (lambda (tuple)
                     (poo-flow-temporal-clock-domain
                      (car tuple) (string->symbol (cadr tuple))))
                   domain-tuples))
             (observations
              (map (lambda (tuple)
                     (poo-flow-temporal-model-observation
                      (list-ref tuple 0) (list-ref tuple 1)
                      (list-ref tuple 2) (list-ref tuple 3)
                      (string->symbol (list-ref tuple 4))))
                   observation-tuples))
             (hypotheses
              (map (lambda (tuple)
                     (poo-flow-temporal-hypothesis
                      (car tuple) (cadr tuple) (caddr tuple)
                      (reverse (or (hash-get constraint-index (car tuple))
                                   '()))))
                   hypothesis-tuples))
             (model
              (poo-flow-temporal-model
               (.ref outline 'module-identity)
               domains observations hypotheses complete?)))
          (poo-flow-tla-temporal-projection-value document model))))))
