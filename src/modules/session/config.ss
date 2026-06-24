;;; -*- Gerbil -*-
;;; Boundary: user-facing session object module facade.
;;; Invariant: session declarations are report-only until a runtime bridge
;;; consumes their handoff receipts.

(import (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-default-sandbox-profiles)
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/transform)

(export (import: :poo-flow/src/modules/session/objects)
        (import: :poo-flow/src/modules/session/transform)
        poo-flow-session-default-placement
        session
        session-graph
        session-memory-intent
        session-transform
        transform-session)

;;; The default user-facing placement resolves against the maintained sandbox
;;; catalog. It remains report-only and never realizes a runtime descriptor.
;; : (-> Symbol [Alist] PooSessionPlacement)
(def (poo-flow-session-default-placement profile-ref . maybe-metadata)
  (apply poo-flow-session-placement-resolve
         profile-ref
         poo-flow-default-sandbox-profiles
         maybe-metadata))

;;; Public session declaration syntax. The macro keeps user cases close to the
;;; OpenRath tutorial shape while expanding to ordinary POO session objects.
;;
;;   (session custom/root
;;     (chunk request user "Run checks.")
;;     (lineage root)
;;     (placement agent/nono)
;;     (metadata (source . user-interface)))
;;
;;   (session custom/branch
;;     (chunk review assistant "Review receipt.")
;;     (lineage fork custom/root)
;;     (placement agent/nono))
(defrules session (chunk lineage placement metadata)
  ((_ session-id
      (chunk chunk-id role content)
      ...
      (lineage branch-kind parent-id ...)
      (placement profile-ref)
      (metadata metadata-entry ...))
   (poo-flow-session-value
    'session-id
    (list (poo-flow-session-chunk 'chunk-id 'role content) ...)
    (poo-flow-session-lineage 'session-id '(parent-id ...) 'branch-kind)
    (poo-flow-session-default-placement
     'profile-ref
     '(metadata-entry ...))
    '(metadata-entry ...)))
  ((_ session-id
      (chunk chunk-id role content)
      ...
      (lineage branch-kind parent-id ...)
      (placement profile-ref))
   (poo-flow-session-value
    'session-id
    (list (poo-flow-session-chunk 'chunk-id 'role content) ...)
    (poo-flow-session-lineage 'session-id '(parent-id ...) 'branch-kind)
    (poo-flow-session-default-placement 'profile-ref))))

;;; Graph presentation syntax mirrors the declaration form: users list session
;;; values and receive the existing report-only graph receipt.
(defrules session-graph ()
  ((_ session-value ...)
   (pooFlowSessionGraphPresentation
    (list session-value ...))))

;;; Public transform syntax keeps the agent-flow layer declarative. It creates
;;; a POO transform spec and never invokes a provider.
;;;
;;; Memory intents are POO objects too. They describe runtime memory recall or
;;; commit requests without reaching into a memory backend from Scheme.
(defrules session-memory-intent (store scope recall commit metadata)
  ((_ intent-name
      (store store-ref)
      (scope scope-value)
      (recall recall-key ...)
      (commit commit-policy)
      (metadata metadata-entry ...))
   (poo-flow-session-memory-intent
    'intent-name
    'store-ref
    'scope-value
    '(recall-key ...)
    'commit-policy
    '(metadata-entry ...)))
  ((_ intent-name
      (store store-ref)
      (scope scope-value)
      (recall recall-key ...)
      (commit commit-policy))
   (poo-flow-session-memory-intent
    'intent-name
    'store-ref
    'scope-value
    '(recall-key ...)
    'commit-policy)))

(defrules session-transform (intent description capabilities memory-intents metadata)
  ((_ transform-name
      (intent intent-value)
      (description description-value)
      (capabilities capability ...)
      (memory-intents memory-intent ...)
      (metadata metadata-entry ...))
   (poo-flow-session-transform
    'transform-name
    'intent-value
    description-value
    '(capability ...)
    '(metadata-entry ...)
    (list memory-intent ...)))
  ((_ transform-name
      (intent intent-value)
      (description description-value)
      (capabilities capability ...)
      (memory-intents memory-intent ...))
   (poo-flow-session-transform
    'transform-name
    'intent-value
    description-value
    '(capability ...)
    (list memory-intent ...)))
  ((_ transform-name
      (intent intent-value)
      (description description-value)
      (capabilities capability ...)
      (metadata metadata-entry ...))
   (poo-flow-session-transform
    'transform-name
    'intent-value
    description-value
    '(capability ...)
    '(metadata-entry ...)))
  ((_ transform-name
      (intent intent-value)
      (description description-value)
      (capabilities capability ...))
   (poo-flow-session-transform
    'transform-name
    'intent-value
    description-value
    '(capability ...))))

;;; Applying a transform derives a new session value and receipt. Runtime work
;;; remains in the handoff intent emitted by the receipt.
(defrules transform-session (chunk metadata)
  ((_ transform source-session derived-session-id
      (chunk chunk-id role content)
      ...
      (metadata metadata-entry ...))
   (poo-flow-session-transform-apply
    transform
    source-session
    'derived-session-id
    (list (poo-flow-session-chunk 'chunk-id 'role content) ...)
    '(metadata-entry ...)))
  ((_ transform source-session derived-session-id
      (chunk chunk-id role content)
      ...)
   (poo-flow-session-transform-apply
    transform
    source-session
    'derived-session-id
    (list (poo-flow-session-chunk 'chunk-id 'role content) ...))))
