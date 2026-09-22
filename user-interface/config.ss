;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Final User Composition.  Profile and Scenario modules are discovered from
;;; the sibling directories by the POO Flow macro.

(import :poo-flow/src/user-interface/config-discovery-syntax)

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
    (handoff marlin-control-plane)))
