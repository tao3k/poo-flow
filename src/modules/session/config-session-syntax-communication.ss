(import :poo-flow/src/modules/session/config-session-runtime)

(export session-communication-channel
        session-communication-channel-rows
        session-communication
        session-communication-rows)

;; session-communication-channel
;;   : (-> Syntax PooSessionCommunicationChannelReceipt)
;;   | doc m%
;;       Channel declarations are first-class route capability receipts. They
;;       describe which sessions and agents may communicate over a channel,
;;       but Scheme never opens or delivers that channel.
;;     %
(defrules session-communication-channel
  (relation sessions agents messages delivery metadata)
  ((_ project-id channel-id
      (relation relation-kind)
      (sessions source-session-id target-session-id)
      (agents source-agent-id target-agent-id)
      (messages message-kind ...)
      (delivery delivery-policy ...)
      (metadata metadata-entry ...))
   (poo-flow-session-syntax-communication-channel
    'project-id
    'channel-id
    'relation-kind
    'source-session-id
    'target-session-id
    'source-agent-id
    'target-agent-id
    '(message-kind ...)
    '(delivery-policy ...)
    '(metadata-entry ...)))
  ((_ project-id channel-id
      (relation relation-kind)
      (sessions source-session-id target-session-id)
      (agents source-agent-id target-agent-id)
      (messages message-kind ...)
      (delivery delivery-policy ...))
   (poo-flow-session-syntax-communication-channel
    'project-id
    'channel-id
    'relation-kind
    'source-session-id
    'target-session-id
    'source-agent-id
    'target-agent-id
    '(message-kind ...)
    '(delivery-policy ...))))

;; : (-> PooSessionCommunicationChannelReceipt Alist)
(defrules session-communication-channel-rows ()
  ((_ receipt ...)
   (poo-flow-session-syntax-communication-channel-rows
    (list receipt ...))))

;; session-communication
;;   : (-> Syntax PooSessionCommunicationReceipt)
;;   | doc m%
;;       Communication declarations are report-only route receipts. They never
;;       deliver messages from Scheme.
;;     %
(defrules session-communication
  (relation roots sessions agents channel message delivery metadata)
  ((_ project-id
      (relation relation-kind)
      (roots source-root-session-id target-root-session-id)
      (sessions source-session-id target-session-id)
      (agents source-agent-id target-agent-id)
      (channel channel-id)
      (message message-kind payload-summary)
      (delivery delivery-policy)
      (metadata metadata-entry ...))
   (poo-flow-session-syntax-communication
    'project-id
    'relation-kind
    'source-root-session-id
    'target-root-session-id
    'source-session-id
    'target-session-id
    'source-agent-id
    'target-agent-id
    'channel-id
    'message-kind
    'payload-summary
    'delivery-policy
    '(metadata-entry ...)))
  ((_ project-id
      (relation relation-kind)
      (roots source-root-session-id target-root-session-id)
      (sessions source-session-id target-session-id)
      (agents source-agent-id target-agent-id)
      (channel channel-id)
      (message message-kind payload-summary)
      (delivery delivery-policy))
   (poo-flow-session-syntax-communication
    'project-id
    'relation-kind
    'source-root-session-id
    'target-root-session-id
    'source-session-id
    'target-session-id
    'source-agent-id
    'target-agent-id
    'channel-id
    'message-kind
    'payload-summary
    'delivery-policy)))

;; session-communication-rows
;;   : (-> Syntax [Alist])
;;   | doc m%
;;       Bounded projection helper for module rows.
;;     %
(defrules session-communication-rows ()
  ((_ receipt ...)
   (poo-flow-session-syntax-communication-rows
    (list receipt ...))))
