(import :poo-flow/src/modules/session/config-session-runtime)

(export session-selector-candidate
        session-selector)

;; session-selector-candidate
;;   : (-> Syntax PooSessionSelectorCandidate)
;;   | doc m%
;;       Selector candidates are declarative routing choices, not model calls.
;;     %
(defrules session-selector-candidate
  (kind target description requires metadata)
  ((_ candidate-id
      (kind candidate-kind)
      (target target-ref)
      (description description-value)
      (requires required-receipt-field ...)
      (metadata metadata-entry ...))
   (poo-flow-session-syntax-selector-candidate
    'candidate-id
    'candidate-kind
    'target-ref
    'description-value
    '(required-receipt-field ...)
    '(metadata-entry ...)))
  ((_ candidate-id
      (kind candidate-kind)
      (target target-ref)
      (description description-value)
      (requires required-receipt-field ...))
   (poo-flow-session-syntax-selector-candidate
    'candidate-id
    'candidate-kind
    'target-ref
    'description-value
    '(required-receipt-field ...))))

;; session-selector
;;   : (-> Syntax PooSessionSelectorReceipt)
;;   | doc m%
;;       Selector declarations stay pending receipts; scoring and dispatch are
;;       runtime responsibilities.
;;     %
(defrules session-selector
  (project root input candidates policy fallback metadata)
  ((_ selector-id
      (project project-id)
      (root root-session-ref)
      (input input-session-ref)
      (candidates candidate ...)
      (policy policy-entry ...)
      (fallback fallback-ref)
      (metadata metadata-entry ...))
   (poo-flow-session-syntax-selector
    'selector-id
    'project-id
    'root-session-ref
    'input-session-ref
    (list candidate ...)
    '(policy-entry ...)
    'fallback-ref
    '(metadata-entry ...)))
  ((_ selector-id
      (project project-id)
      (root root-session-ref)
      (input input-session-ref)
      (candidates candidate ...)
      (policy policy-entry ...)
      (fallback fallback-ref))
   (poo-flow-session-syntax-selector
    'selector-id
    'project-id
    'root-session-ref
    'input-session-ref
    (list candidate ...)
    '(policy-entry ...)
    'fallback-ref)))

;; : (-> PooSessionSelectorReceipt Alist)
