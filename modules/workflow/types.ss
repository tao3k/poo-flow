;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: workflow CI/CD vocabularies and value admission predicates.
;;; Invariant: this layer imports no workflow object, function, or config owner.

(import (only-in :clan/poo/object object?)
        (only-in :std/list/list every))

(export +poo-flow-cicd-check-map-schema+
        +poo-flow-cicd-check-receipt-schema+
        +poo-flow-cicd-pipeline-run-schema+
        +poo-flow-cicd-pipeline-result-schema+
        +poo-flow-cicd-runtime-manifest-readiness-schema+
        +poo-flow-cicd-marlin-runtime-handoff-abi-schema+
        +poo-flow-cicd-marlin-runtime-owner+
        +poo-flow-cicd-marlin-runtime-handoff-abi-fields+
        poo-flow-cicd-check-kind
        poo-flow-cicd-check-map-kind
        poo-flow-cicd-require
        poo-flow-cicd-profile-ref?
        poo-flow-cicd-command-vector?
        poo-flow-cicd-symbol-list?)

(def +poo-flow-cicd-check-map-schema+
  'poo-flow.modules.workflow.cicd.check-map.v1)
(def +poo-flow-cicd-check-receipt-schema+
  'poo-flow.modules.workflow.cicd.check-receipt.v1)
(def +poo-flow-cicd-pipeline-run-schema+
  'poo-flow.modules.workflow.cicd.pipeline-run.v1)
(def +poo-flow-cicd-pipeline-result-schema+
  'poo-flow.modules.workflow.cicd.pipeline-result.v1)
(def +poo-flow-cicd-runtime-manifest-readiness-schema+
  'poo-flow.modules.workflow.cicd.runtime-manifest-readiness.v1)
(def +poo-flow-cicd-marlin-runtime-handoff-abi-schema+
  'poo-flow.workflow.cicd.marlin-runtime-handoff-abi.v1)
(def +poo-flow-cicd-marlin-runtime-owner+ "marlin-agent-core")

(def +poo-flow-cicd-marlin-runtime-handoff-abi-fields+
  '(operation request-id artifact-handle argv request policy plan-id node-id
    frontier durable-task-id action-class artifact-refs artifact-provenance
    artifact-retention sandbox-refs checkpoint-ref compensation-refs
    runtime-owner handoff-required runtime-executed))

(def (poo-flow-cicd-check-kind) 'poo-flow.workflow.cicd.check)
(def (poo-flow-cicd-check-map-kind) 'poo-flow.workflow.cicd.check-map)

(def (poo-flow-cicd-require message ok? value)
  (unless ok? (error message value)))

(def (poo-flow-cicd-profile-ref? value)
  (or (symbol? value)
      (object? value)
      (and (pair? value)
           (list? value)
           (every poo-flow-cicd-profile-ref? value))))

(def (poo-flow-cicd-command-vector? value)
  (and (pair? value)
       (list? value)
       (every string? value)))

(def (poo-flow-cicd-symbol-list? values)
  (and (list? values) (every symbol? values)))
