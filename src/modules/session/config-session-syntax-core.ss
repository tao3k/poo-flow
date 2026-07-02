(import :poo-flow/src/modules/session/config-session-runtime)

(export session
        session-graph
        session-registry-entry
        session-registry)

;; session
;;   : (-> Syntax PooSessionValue)
;;   | doc m%
;;       `session` keeps user-facing session declarations close to the
;;       OpenRath tutorial shape while expanding to ordinary POO session
;;       objects.
;;
;;       # Examples
;;       ```scheme
;;       (session custom/root
;;         (chunk request user "Run checks.")
;;         (lineage root)
;;         (placement agent/nono)
;;         (metadata (source . user-interface)))
;;       ;; => poo-session-value
;;       ```
;;     %
(defrules session (chunk lineage placement metadata)
  ((_ session-id
      (chunk chunk-id role content)
      ...
      (lineage branch-kind parent-id ...)
      (placement profile-ref)
      (metadata metadata-entry ...))
   (poo-flow-session-syntax-value
    'session-id
    (list (poo-flow-session-syntax-chunk 'chunk-id 'role content) ...)
    (poo-flow-session-syntax-lineage
     'session-id
     '(parent-id ...)
     'branch-kind)
    (poo-flow-session-syntax-default-placement
     'profile-ref
     '(metadata-entry ...))
    '(metadata-entry ...)))
  ((_ session-id
      (chunk chunk-id role content)
      ...
      (lineage branch-kind parent-id ...)
      (placement profile-ref))
   (poo-flow-session-syntax-value
    'session-id
    (list (poo-flow-session-syntax-chunk 'chunk-id 'role content) ...)
    (poo-flow-session-syntax-lineage
     'session-id
     '(parent-id ...)
     'branch-kind)
    (poo-flow-session-syntax-default-placement 'profile-ref))))

;; session-graph
;;   : (-> Syntax PooSessionGraphPresentation)
;;   | doc m%
;;       `session-graph` mirrors the declaration form: users list session values
;;       and receive the existing report-only graph receipt.
;;
;;       # Examples
;;       ```scheme
;;       (session-graph root-session branch-session)
;;       ;; => pooFlowSessionGraphPresentation receipt
;;       ```
;;     %
(defrules session-graph ()
  ((_ session-value ...)
   (poo-flow-session-syntax-graph-presentation
    (list session-value ...))))

;; session-registry-entry
;;   : (-> Syntax PooSessionRegistryEntry)
;;   | doc m%
;;       User-facing registry entries describe the session address space without
;;       exposing the lower-level registry constructor.
;;     %
(defrules session-registry-entry (agent channels policies metadata)
  ((_ session-value
      (agent agent-id)
      (channels channel-id ...)
      (policies (policy-kind policy-summary) ...)
      (metadata metadata-entry ...))
   (poo-flow-session-syntax-registry-entry
    session-value
    'agent-id
    '(channel-id ...)
    '((policy-kind . policy-summary) ...)
    '(metadata-entry ...)))
  ((_ session-value
      (agent agent-id)
      (channels channel-id ...)
      (policies (policy-kind policy-summary) ...))
   (poo-flow-session-syntax-registry-entry
    session-value
    'agent-id
    '(channel-id ...)
    '((policy-kind . policy-summary) ...))))

;; session-registry
;;   : (-> Syntax PooSessionRegistryReceipt)
;;   | doc m%
;;       Registry declarations keep project/root/child topology visible at the
;;       module facade and leave live runtime state to Marlin.
;;     %
(defrules session-registry (roots children active entries metadata)
  ((_ project-id
      (roots root-session-id ...)
      (children child-session-id ...)
      (active active-session-ref)
      (entries entry ...)
      (metadata metadata-entry ...))
   (poo-flow-session-syntax-registry
    'project-id
    '(root-session-id ...)
    '(child-session-id ...)
    'active-session-ref
    (list entry ...)
    '(metadata-entry ...)))
  ((_ project-id
      (roots root-session-id ...)
      (children child-session-id ...)
      (active active-session-ref)
      (entries entry ...))
   (poo-flow-session-syntax-registry
    'project-id
    '(root-session-id ...)
    '(child-session-id ...)
    'active-session-ref
    (list entry ...))))
