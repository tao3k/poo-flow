;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: inert authorization Provider objects; execution is external.
(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        (only-in :poo-flow/src/modules/authorization/types
                 poo-flow-authorization-provider-kind
                 poo-flow-authorization-capability-kind
                 PooFlowAuthorizationProvider
                 PooFlowAuthorizationCapability))

(export poo-flow-authorization-provider
        poo-flow-authorization-capability)

(def (poo-flow-authorization-provider identity-value engines-value
                                      arbitration-value runtime-owner-value)
  (validate
   PooFlowAuthorizationProvider
   (.o kind: poo-flow-authorization-provider-kind
       identity: identity-value
       engines: engines-value
       arbitration: arbitration-value
       runtime-owner: runtime-owner-value
       runtime-executed?: #f)))

(def (poo-flow-authorization-capability identity-value action-value
                                        event-kind-value risk-value)
  (validate
   PooFlowAuthorizationCapability
   (.o kind: poo-flow-authorization-capability-kind
       identity: identity-value
       action: action-value
       event-kind: event-kind-value
       risk: risk-value
       runtime-executed?: #f)))
