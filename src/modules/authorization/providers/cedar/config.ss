;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :poo-flow/src/modules/authorization/objects
                 poo-flow-authorization-provider))

(export CedarDualEngineAuthorizationProvider)

(def CedarDualEngineAuthorizationProvider
  (poo-flow-authorization-provider
   "poo-flow/authorization/cedar-dual-engine"
   '("cedar-rust" "cedar-lean")
   'strict-lockstep
   'native.cedar-authority))
