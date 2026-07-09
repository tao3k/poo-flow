;;; -*- Gerbil -*-
;;; Boundary: session tool and hook permission predicates.

(import :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy-core
        :poo-flow/src/modules/session/policy-tool-grant)

(export poo-flow-session-tool-permission-policy-allows?
        poo-flow-session-hook-tool-permission-policy-allows?)

;; : (-> PooSessionPolicy Symbol Symbol Boolean)
(def (poo-flow-session-tool-permission-policy-allows? policy
                                                      tool-ref
                                                      action)
  (poo-flow-session-require "session tool permission requires a policy"
                            (poo-flow-session-policy? policy)
                            policy)
  (and (eq? (poo-flow-session-policy-kind policy)
            'agent-tool-permission)
       (not (poo-flow-session-policy-match?
             tool-ref
             (poo-flow-session-policy-slot policy
                                           'denied-tool-refs
                                           '())))
       (poo-flow-session-tool-grants-allow?
        (poo-flow-session-policy-slot policy 'tool-grants '())
        tool-ref
        action)))

;; : (-> PooSessionPolicy Symbol Symbol Symbol Boolean)
(def (poo-flow-session-hook-tool-permission-policy-allows? policy
                                                           hook-event
                                                           tool-ref
                                                           action)
  (poo-flow-session-require "session hook tool permission requires a policy"
                            (poo-flow-session-policy? policy)
                            policy)
  (and (eq? (poo-flow-session-policy-kind policy)
            'hook-tool-permission)
       (poo-flow-session-policy-match?
        hook-event
        (poo-flow-session-policy-slot policy 'hook-events '()))
       (poo-flow-session-tool-grants-allow?
        (poo-flow-session-policy-slot policy 'tool-grants '())
        tool-ref
        action)))
