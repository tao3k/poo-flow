;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Final User Composition.  The root owns one explicit composition value;
;;; reusable Profiles and Scenarios keep their own import paths.

(import (only-in :poo-flow/src/module-system/profile-composition/use-syntax
                 use-composition))

(export default-agent-control-plane)

(def default-agent-control-plane
  (use-composition default-agent-control-plane
    (modules
      (use-module langgraph as control
        (profiles session state router agent-node tool-node bounded-loop
                  runtime-handoff))
      (use-module tool-calling as tools
        (profiles tool-request tool-schema tool-permission sandbox-scope
                  argument-validation untrusted-observation tool-cooldown
                  result-contract runtime-binding receipt-gate observability)))
    (compose
      (profiles control session state router agent-node tool-node bounded-loop
                runtime-handoff)
      (profiles tools tool-request tool-schema tool-permission sandbox-scope
                argument-validation untrusted-observation tool-cooldown
                result-contract runtime-binding receipt-gate observability))
    (stage development
      (graph pull-request-agent-loop)
      (loop #:fuel 8 #:exit tested-change)
      (prove typed-state-merge tool-arguments-match-schema))
    (stage staging
      (graph release-candidate-agent-loop)
      (loop #:fuel 5 #:exit qualified-candidate)
      (prove tool-permission-before-call runtime-receipt-matches-tool-plan))
    (stage production
      (graph production-agent-loop)
      (loop #:fuel 3 #:exit accepted-result)
      (prove explicit-runtime-handoff trace-covers-tool-request-call-result)
      (handoff marlin-control-plane))))
