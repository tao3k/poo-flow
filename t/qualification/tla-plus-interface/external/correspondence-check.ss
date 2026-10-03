;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
(import (only-in :clan/poo/object .o .ref)
        (only-in :std/encoding/json read-json JSONReadOptions current-json-read-options)
        (only-in :std/misc/ports read-all-as-string)
        :poo-flow/modules/tla-plus/interface
        :poo-flow/modules/temporal-causality/objects
        :poo-flow/modules/temporal-causality/funs
        :poo-flow/modules/temporal-causality/behavior/interface
        "../../../fixtures/temporal-behaviors.ss")
(export main)
(def (libraries names)
  (map (lambda (name) (poo-flow-tla-source-file name (call-with-input-file
         (path-expand name "packages/proofs/tla/temporal-causality") read-all-as-string))) names))
(def (reject! thunk)
  (let (rejected? #f)
    (with-catch (lambda (_) (set! rejected? #t)) thunk)
    (unless rejected? (error "forged correspondence accepted"))))
(def (check! emission-value sources tools)
  (let (receipt (poo-flow-tla-check-correspondence! emission-value sources tools))
    (poo-flow-tla-correspondence-replay receipt)
    (reject! (lambda () (poo-flow-tla-correspondence-replay (.o (:: @ receipt) model-digest: "forged"))))
    (reject! (lambda () (poo-flow-tla-correspondence-replay (.o (:: @ receipt) step-table-identity: "forged"))))
    (reject! (lambda () (poo-flow-tla-correspondence-replay (.o (:: @ receipt) action-authorized?: #t))))
    (reject! (lambda () (poo-flow-tla-correspondence-replay
                         (.o (:: @ receipt) emission: (.o (:: @ emission-value) config-source: "SPECIFICATION Trivial\n")))))
    (displayln "CORRESPONDENCE-CHECK-OK " (.ref receipt 'semantic-subset) " " (.ref receipt 'identity)) (force-output)))
(def (main pins-path)
  (let* ((pins (parameterize ((current-json-read-options (JSONReadOptions object-as-hash: #t)))
                (call-with-input-file pins-path read-json)))
         (tools (poo-flow-tla-toolchain (hash-get pins "java") (hash-get pins "jar")
                  (map (lambda (row) (apply poo-flow-tla-tool-artifact row)) (hash-get pins "artifacts"))))
         (model (poo-flow-temporal-overlapping-model "bound-hypothesis"
                  (list (poo-flow-temporal-clock-domain "clock" 'logical-version))
                  (list (poo-flow-temporal-model-observation "a" "clock" 1 "source" 'observed)
                        (poo-flow-temporal-model-observation "b" "clock" 2 "source" 'observed))
                  (list (poo-flow-temporal-hypothesis "a-b" "a" "b" '())) #t)))
    (check! (poo-flow-tla-emit-temporal-model model (poo-flow-temporal-query "q" "a-b" #f))
            (libraries '("TemporalFamilyExplorer.tla" "TemporalFamilySemantics.tla" "TemporalOrder.tla")) tools)
    (check! (poo-flow-tla-emit-behavior-model (medication-model '())
              (poo-flow-temporal-property "safety" 'safety
                (list (poo-flow-temporal-condition "protected" "control-measurement" "baseline")) 2))
            (libraries '("TemporalBehaviorSemantics.tla")) tools)))
