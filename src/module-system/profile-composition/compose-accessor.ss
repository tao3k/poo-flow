;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: compose-clause profile projection for composition stages.
;;; Invariant: projection scans metadata only; it never evaluates graph/loop.

(import (only-in :std/srfi/1 find)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/profile-composition/accessors)

(export poo-flow-scenario-stage-compose-profiles)

;;; Returns profile objects selected by a stage compose clause.
;;; Scan boundary: this is a metadata lookup, not graph or loop evaluation.
;; poo-flow-scenario-stage-compose-profiles
;; : (-> PooFlowScenarioStage PooProfileList)
;; | doc m%
;;   Extracts ordered profile objects selected by a stage compose clause.
;;   # Examples
;;   ```scheme
;;   (poo-flow-scenario-stage-compose-profiles production-stage)
;;   ;; => []
;;   ```
(def (poo-flow-scenario-stage-compose-profiles composition-stage)
  (let (compose-clause
        (find
         (lambda (clause)
           (eq? (.ref clause 'clause-kind) 'compose))
         (poo-flow-scenario-stage-clauses composition-stage)))
    (if compose-clause
      (.ref compose-clause 'payload)
      [])))
