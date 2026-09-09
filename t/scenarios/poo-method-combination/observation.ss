;;; -*- Gerbil -*-
;;; Pure scenario: real Module admission -> source-owned Observation summary.
(import (only-in :clan/poo/object .ref .cc)
        "../../../src/module-system/poo-method-combination/plugins/observation.ss"
        "../../../src/module-system/observability/interface.ss"
        "../../../src/module-system/semantic-module/objects.ss")
(export combination-observation-scenario combination-observation-event)
(def (identity-value name) (poo-flow-observation-identity 'module name 'v1))
(def (combination-observation-event (accepted? #f))
  (let* ((context (poo-flow-observation-context
                    (identity-value 'event) (identity-value 'module) (identity-value 'generation)
                    '() (poo-flow-observation-provenance
                          (identity-value 'admission) (identity-value 'gerbil-poo) 'admission)))
         (module (poo-flow-semantic-module (poo-flow-semantic-identity 'module 'sample)))
         (event (poo-flow-observe-contract-admission context SemanticModuleContract
                  (if accepted? module (.cc module 'imports 'invalid)))))
    event))
(def (combination-observation-scenario)
  (let ((base (poo-observation-combination-renderer))
        (detailed (poo-observation-combination-renderer explanation?: #t))
        (event (combination-observation-event)))
    (values (poo-observation-combination-summary base event)
            (poo-observation-combination-summary detailed event))))
