;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :core/observability/testing-case poo-flow-test-case)
         (only-in :clan/poo/object .ref)
        (only-in :std/list/list any)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/test check-equal? check-exception test-suite)
        (only-in :gerbil-parser/src/runtime/artifact sha256-text)
        (only-in :poo-flow/modules/temporal-causality/interface
                 poo-flow-temporal-clock-domain
                 poo-flow-temporal-model-observation
                 poo-flow-temporal-constraint
                 poo-flow-temporal-hypothesis
                 poo-flow-temporal-model
                 poo-flow-temporal-query poo-flow-temporal-model-classify)
        (only-in :gerbil-parser/src/runtime/cst
                 syntax-node? syntax-node-kind syntax-node-start syntax-node-end
                 syntax-node-children syntax-field? syntax-field-children)
        (only-in :poo-flow/modules/tla-plus/interface
                 PooFlowTlaLanguage. PooFlowTlaPlusModule.
                 poo-flow-tla-language? poo-flow-tla-document?
                 poo-flow-tla-model-outline?
                 poo-flow-tla-temporal-projection?
                 poo-flow-tla-parse-source poo-flow-tla-parser-cst
                 poo-flow-tla-model-outline
                 poo-flow-tla-project-temporal-model))
(export tla-plus-interface-test)

(def sample-source
  "---- MODULE Example ----\nVARIABLE active\nInit == active = TRUE\n====\n")

(def modular-source
  "---- MODULE Modular ----\nVARIABLES active,\n queued\nWork == INSTANCE WorkLifecycle\nInit ==\n  /\\ Work!Init\n  /\\ active = TRUE\n====\n")

(def (contains-node-kind? element kind)
  (or (and (syntax-node? element) (eq? (syntax-node-kind element) kind))
      (let (children
            (cond ((syntax-node? element) (syntax-node-children element))
                  ((syntax-field? element) (syntax-field-children element))
                  (else '())))
        (any (lambda (child) (contains-node-kind? child kind)) children))))

(def tla-plus-interface-test
  (test-suite "POO Flow TLA+ syntax interface"
    (poo-flow-test-case "accepted source retains parser-owned tree without copying"
      (let* ((document (poo-flow-tla-parse-source sample-source))
             (root (poo-flow-tla-parser-cst document)))
        (check-equal? (poo-flow-tla-document? document) #t)
        (check-equal? (poo-flow-tla-language? (.ref document 'language)) #t)
        (check-equal? (.ref PooFlowTlaPlusModule. 'language)
                      PooFlowTlaLanguage.)
        (check-equal? (.ref (.ref document 'language) 'parser-owner)
                      'gerbil-parser)
        (check-equal? (.ref PooFlowTlaLanguage. 'syntax-contract)
                      "tla-plus.native-layout.v2")
        (check-equal? (.ref document 'source-digest)
                      (sha256-text sample-source))
        (check-equal? (.ref document 'source-byte-length)
                      (u8vector-length (string->utf8 sample-source)))
        (check-equal? (.ref document 'exact-roundtrip?) #t)
        (check-equal? (.ref document 'semantic-validation?) #f)
        (check-equal? (.ref document 'model-checking?) #f)
        (check-equal? (syntax-node? root) #t)
        (check-equal? (syntax-node-kind root) 'SourceFile)
        (check-equal? (syntax-node-start root) 0)
        (check-equal? (syntax-node-end root)
                      (u8vector-length (string->utf8 sample-source)))
        (check-equal? (eq? root (poo-flow-tla-parser-cst document)) #t)))
    (poo-flow-test-case "maintained governance model uses the same interface"
      (let* ((source
              (call-with-input-file "packages/proofs/tla/GovernanceCore.tla"
                                    read-all-as-string))
             (document (poo-flow-tla-parse-source source)))
        (check-equal? (poo-flow-tla-document? document) #t)
        (check-equal? (.ref document 'source-digest)
                      (sha256-text source))
        (check-equal? (syntax-node?
                       (poo-flow-tla-parser-cst document)) #t)))
    (poo-flow-test-case "multiline modules preserve named instances and qualified names"
      (let* ((document (poo-flow-tla-parse-source modular-source))
             (root (poo-flow-tla-parser-cst document))
             (outline (poo-flow-tla-model-outline document)))
        (check-equal? (poo-flow-tla-document? document) #t)
        (check-equal? (contains-node-kind? root 'InstanceExpression) #t)
        (check-equal? (contains-node-kind? root 'QualifiedNameExpression) #t)
        (check-equal? (.ref outline 'variable-identities)
                      '("active" "queued"))))
    (poo-flow-test-case "declaration outline retains source identity and parser boundary"
      (let* ((document (poo-flow-tla-parse-source sample-source))
             (outline (poo-flow-tla-model-outline document)))
        (check-equal? (poo-flow-tla-model-outline? outline) #t)
        (check-equal? (.ref outline 'document) document)
        (check-equal? (.ref outline 'source-digest)
                      (.ref document 'source-digest))
        (check-equal? (.ref outline 'module-identity) "Example")
        (check-equal? (.ref outline 'variable-identities) '("active"))
        (check-equal? (.ref outline 'constant-identities) '())
        (check-equal? (.ref outline 'operator-identities) '("Init"))
        (check-equal? (.ref outline 'semantic-validation?) #f)
        (check-equal? (.ref outline 'model-checking?) #f)))
    (poo-flow-test-case "finite literal TLA+ family projects to the POO model"
      (let* ((source
              (call-with-input-file
               "packages/proofs/tla/temporal-causality/TemporalHypothesisFamily.tla"
               read-all-as-string))
             (document (poo-flow-tla-parse-source source))
             (projection (poo-flow-tla-project-temporal-model document))
             (model (.ref projection 'model))
             (native-model
              (poo-flow-temporal-model
               "TemporalHypothesisFamily"
               (list (poo-flow-temporal-clock-domain
                      "timeline" 'logical-version))
               (list (poo-flow-temporal-model-observation
                      "source-a" "timeline" 1 "ledger" 'observed)
                     (poo-flow-temporal-model-observation
                      "source-b" "timeline" 2 "ledger" 'observed)
                     (poo-flow-temporal-model-observation
                      "result" "timeline" 3 "ledger" 'observed))
               (list (poo-flow-temporal-hypothesis
                      "via-a" "source-a" "result"
                      (list (poo-flow-temporal-constraint
                             "a-before-result" 'before "source-a" "result")))
                     (poo-flow-temporal-hypothesis
                      "via-b" "source-b" "result" '()))
               #t))
             (receipt (poo-flow-temporal-model-classify
                       model (poo-flow-temporal-query "why-result" "via-a" 2))))
        (check-equal? (poo-flow-tla-temporal-projection? projection) #t)
        (check-equal? (.ref projection 'source-digest)
                      (.ref document 'source-digest))
        (check-equal? (.ref projection 'semantic-digest)
                      (.ref model 'semantic-digest))
        (check-equal? (.ref model 'semantic-digest)
                      (.ref native-model 'semantic-digest))
        (check-equal? (.ref projection 'model-checking?) #f)
        (check-equal?
         (length (.ref (car (.ref model 'hypotheses)) 'constraints)) 1)
        (check-equal? (.ref receipt 'classification) 'possible)))
    (poo-flow-test-case "discriminating TLA+ data changes the projected answer"
      (let* ((source
              (call-with-input-file
               "packages/proofs/tla/temporal-causality/TemporalDiscriminatingFamily.tla"
               read-all-as-string))
             (projection
              (poo-flow-tla-project-temporal-model
               (poo-flow-tla-parse-source source)))
             (model (.ref projection 'model))
             (receipt
              (poo-flow-temporal-model-classify
               model (poo-flow-temporal-query "why-result" "via-a" #f))))
        (check-equal? (.ref receipt 'classification) 'necessary)
        (check-equal? (.ref receipt 'refuted-hypothesis-ids) '("via-b"))
        (check-equal? (.ref receipt 'exhausted?) #t)))
    (poo-flow-test-case "unsupported TLA+ expression cannot enter the POO model"
      (check-exception
       (poo-flow-tla-project-temporal-model
        (poo-flow-tla-parse-source
         "---- MODULE Unsupported ----\nClockDomains == {<<\"clock\",\"logical-version\">>}\nObservations == {}\nHypotheses == {}\nConstraints == {}\nFamilyComplete == 1 + 1\n====\n"))
       true))
    (poo-flow-test-case "rejected syntax cannot become a POO document"
      (check-exception
       (poo-flow-tla-parse-source
        "---- MODULE Broken ----\nWork == INSTANCE\n====\n")
       true))))
