;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :poo-flow/src/module-system/observability/testing-case poo-flow-test-case)
         (only-in :clan/poo/object .ref)
        (only-in :std/list/list any)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/test check-equal? check-exception test-suite)
        (only-in :gerbil-parser/src/runtime/artifact sha256-text)
        (only-in :gerbil-parser/src/runtime/cst
                 syntax-node? syntax-node-kind syntax-node-start syntax-node-end
                 syntax-node-children syntax-field? syntax-field-children)
        (only-in :poo-flow/src/modules/tla-plus/interface
                 PooFlowTlaLanguage. PooFlowTlaPlusModule.
                 poo-flow-tla-language? poo-flow-tla-document?
                 poo-flow-tla-parse-source poo-flow-tla-parser-cst))
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
                      "tla-plus.native-core.v1")
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
              (call-with-input-file "packages/proof/tla/GovernanceCore.tla"
                                    read-all-as-string))
             (document (poo-flow-tla-parse-source source)))
        (check-equal? (poo-flow-tla-document? document) #t)
        (check-equal? (.ref document 'source-digest)
                      (sha256-text source))
        (check-equal? (syntax-node?
                       (poo-flow-tla-parser-cst document)) #t)))
    (poo-flow-test-case "multiline modules preserve named instances and qualified names"
      (let* ((document (poo-flow-tla-parse-source modular-source))
             (root (poo-flow-tla-parser-cst document)))
        (check-equal? (poo-flow-tla-document? document) #t)
        (check-equal? (contains-node-kind? root 'InstanceExpression) #t)
        (check-equal? (contains-node-kind? root 'QualifiedNameExpression) #t)))
    (poo-flow-test-case "rejected syntax cannot become a POO document"
      (check-exception
       (poo-flow-tla-parse-source
        "---- MODULE Broken ----\nWork == INSTANCE\n====\n")
       true))))
