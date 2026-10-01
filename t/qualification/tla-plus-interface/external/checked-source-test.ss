;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .ref)
        (only-in :std/misc/ports read-all-as-string)
        :std/test
        (only-in :poo-flow/modules/tla-plus/checked-source-objects
                 poo-flow-tla-checked-source-value)
        :poo-flow/modules/tla-plus/interface)
(export tla-checked-source-test)

(def spec
  "packages/proofs/tla/temporal-causality/TemporalConclusionSelectionCase.tla")
(def config
  "packages/proofs/tla/temporal-causality/TemporalConclusionSelectionCase.cfg")
(def (source-document)
  (poo-flow-tla-parse-source
   (call-with-input-file spec read-all-as-string)))

(def tla-checked-source-test
  (test-suite "typed checked TLA+ source receipt"
    (poo-flow-test-case "exact parsed source and TLC output are bound"
      (let* ((document (source-document))
             (receipt (poo-flow-tla-check-source!
                       document spec config workers: 1)))
        (check (poo-flow-tla-checked-source? receipt) => #t)
        (check (.ref receipt 'source-digest)
               => (.ref document 'source-digest))
        (check (.ref receipt 'states-left) => 0)
        (check (.ref receipt 'source-checked?) => #t)
        (check (.ref receipt 'semantic-refinement?) => #f)
        (check (.ref receipt 'action-authorized?) => #f)
        (check (.ref (poo-flow-tla-checked-source-replay receipt document)
                     'semantic-digest)
               => (.ref receipt 'semantic-digest))
        (let (forged
              (poo-flow-tla-checked-source-value
               "sha256:forged" "sha256:forged"
               (.ref receipt 'source-digest) (.ref receipt 'config-digest)
               (.ref receipt 'qualification-schema)
               (.ref receipt 'syntax-contract) (.ref receipt 'tool-digest)
               (.ref receipt 'tlc-version) (.ref receipt 'output-digest)
               (.ref receipt 'workers) (.ref receipt 'states-generated)
               (.ref receipt 'distinct-states) (.ref receipt 'states-left)
               (.ref receipt 'graph-depth)))
          (check-exception
           (poo-flow-tla-checked-source-replay forged document) true))))
    (poo-flow-test-case "another parsed source cannot borrow the run"
      (check-exception
       (poo-flow-tla-check-source!
        (poo-flow-tla-parse-source
         "---- MODULE Other ----\nX == 1\n====\n")
        spec config workers: 1)
       true))))
