;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .ref .o)
        (only-in :std/misc/ports read-all-as-string)
        :std/test
        (only-in :poo-flow/modules/temporal-causality/objects
                 poo-flow-temporal-clock-domain poo-flow-temporal-model-observation
                 poo-flow-temporal-hypothesis poo-flow-temporal-query)
        (only-in :poo-flow/modules/temporal-causality/funs
                 poo-flow-temporal-model poo-flow-temporal-overlapping-model
                 poo-flow-temporal-model-classify)
        :poo-flow/modules/tla-plus/interface)
(export tla-temporal-emission-test)
(def (fixture identity overlapping?)
  ((if overlapping? poo-flow-temporal-overlapping-model poo-flow-temporal-model)
   identity (list (poo-flow-temporal-clock-domain "timeline" 'logical-version))
   (list (poo-flow-temporal-model-observation "a" "timeline" 1 "source" 'observed)
         (poo-flow-temporal-model-observation "b" "timeline" 4 "source" 'observed)
         (poo-flow-temporal-model-observation "effect" "timeline" 3 "source" 'observed))
   (list (poo-flow-temporal-hypothesis "via-a" "a" "effect" '())
         (poo-flow-temporal-hypothesis "via-b" "b" "effect" '())) #t))
(def tla-temporal-emission-test
  (test-suite "POO Temporal TLA+ emission"
    (poo-flow-test-case "two vocabularies preserve identity and family mode through source"
      (for-each
       (lambda (identity)
         (for-each
          (lambda (overlapping?)
            (let* ((model (fixture identity overlapping?))
                   (query (poo-flow-temporal-query "query" "via-a" #f))
                   (emission (poo-flow-tla-emit-temporal-model model query))
                   (projection (poo-flow-tla-project-temporal-model
                                (poo-flow-tla-parse-source (.ref emission 'data-source))))
                   (restored (.ref projection 'model)))
              (check (.ref restored 'identity) => identity)
              (check (.ref restored 'semantic-digest) => (.ref model 'semantic-digest))
              (check (.ref restored 'family-semantics) => (.ref model 'family-semantics))
              (check (.ref projection 'semantic-subset)
                     => 'poo-flow.tla-plus.literal-hypothesis-family.v2)
              (check (.ref (poo-flow-temporal-model-classify restored query) 'classification)
                     => (if overlapping? 'possible 'necessary))
              (check (poo-flow-tla-document?
                      (poo-flow-tla-parse-source (.ref emission 'check-source))) => #t)
              (check (.ref (poo-flow-tla-temporal-emission-replay emission) 'config-source)
                     => (.ref emission 'config-source)))) '(#f #t)))
       '("care/prescription" "software/release")))
    (poo-flow-test-case "relabeling and altered checking config fail replay"
      (let* ((emission (poo-flow-tla-emit-temporal-model
                       (fixture "release" #t)
                       (poo-flow-temporal-query "q" "via-a" 1)))
             (forged (.o (:: @ emission) config-source: "SPECIFICATION Other\n")))
        (check-exception (poo-flow-tla-temporal-emission-replay forged) true)))
    (poo-flow-test-case "source literal injection is rejected"
      (check-exception
       (poo-flow-tla-emit-temporal-model
        (fixture "name\"\nInjected == TRUE" #f)
        (poo-flow-temporal-query "q" "via-a" #f)) true))
    (poo-flow-test-case "correspondence pins the native emitter and every semantic import"
      (let* ((emission (poo-flow-tla-emit-temporal-model (fixture "bound-source" #t)
                        (poo-flow-temporal-query "q" "via-a" #f)))
             (libraries (map (lambda (name) (poo-flow-tla-source-file name
                               (call-with-input-file
                                 (path-expand name "packages/proofs/tla/temporal-causality") read-all-as-string)))
                             '("TemporalFamilyExplorer.tla" "TemporalFamilySemantics.tla" "TemporalOrder.tla")))
             (tools (poo-flow-tla-toolchain "/owned/java" "/owned/tlc.jar"
                      (list (poo-flow-tla-tool-artifact "/owned/java" "sha256:host-pin"))))
             (bundle (poo-flow-tla-correspondence-bundle emission libraries tools)))
        (check (length (.ref bundle 'sources)) => 6)
        (check (.ref (poo-flow-tla-bundle-replay bundle) 'semantic-digest) => (.ref bundle 'semantic-digest))
        (check-exception (poo-flow-tla-correspondence-bundle emission (cdr libraries) tools) true)
        (check-exception (poo-flow-tla-correspondence-bundle
                          (.o (:: @ emission) config-source: "SPECIFICATION Trivial\n") libraries tools) true)
        (check-exception (poo-flow-tla-correspondence-bundle emission
                          (cons (.o (:: @ (car libraries)) content: "---- MODULE TemporalFamilyExplorer ----\nTrivial == TRUE\n====\n")
                                (cdr libraries)) tools) true)))))
