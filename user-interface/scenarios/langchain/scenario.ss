;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Reusable Scenario object; root config decides whether to compose it.

(import (only-in :poo-flow/src/module-system/profile-composition/use-syntax
                 use-composition)
        :poo-flow/user-interface/profiles/langchain)
(export langchain-scenario)

(def langchain-scenario
  (use-composition langchain
  (use-module langchain as chain
    (profiles memory prompt model parser no-tool))
  (compose
   (profiles chain memory prompt model parser no-tool))
  (stage production
    (graph langchain-linear-chain)
    (loop #:fuel 1 #:exit parsed-output)
    (prove chain-order
           prompt-before-model
           parser-after-model
           no-implicit-tool-branch))))
