;;; -*- Gerbil -*-
;;; Boundary: POO-native policy-catalog validation receipts.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/module-system/projection-syntax
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy
        :poo-flow/src/modules/tool-core/objects-catalog
        :poo-flow/src/modules/tool-core/objects-policy-refs
        :poo-flow/src/modules/tool-core/objects-support
        :poo-flow/src/modules/tool-core/objects-validation)

(export +poo-flow-tool-core-policy-validation-receipt-kind+
        poo-flow-tool-policy-catalog-validation-receipt
        poo-flow-tool-policy-catalog-validation-receipt?
        poo-flow-tool-policy-catalog-validation-receipt-valid?
        poo-flow-tool-policy-catalog-validation-receipt-diagnostics
        poo-flow-tool-policy-catalog-validation-receipt->alist)

(def +poo-flow-tool-core-policy-validation-receipt-kind+
  'poo-flow.tool-core.policy-catalog-validation-receipt)

(def (poo-flow-tool-policy-catalog-validation-receipt validation-id catalog
                                                      agent-policy hook-policy
                                                      . maybe-metadata)
  (poo-flow-session-require "tool validation id must be a symbol"
                            (symbol? validation-id) validation-id)
  (poo-flow-session-require "tool validation requires a catalog"
                            (poo-flow-tool-catalog? catalog) catalog)
  (poo-flow-session-require "tool validation requires agent tool policy"
                            (poo-flow-session-policy? agent-policy) agent-policy)
  (poo-flow-session-require "tool validation requires hook tool policy"
                            (poo-flow-session-policy? hook-policy) hook-policy)
  (let* ((policy-refs
          (poo-flow-tool-merge-policy-tool-refs
           (poo-flow-tool-policy-tool-refs agent-policy)
           (poo-flow-tool-policy-tool-refs hook-policy)))
         (summary (poo-flow-tool-policy-catalog-validation-summary catalog policy-refs))
         (action-bundle
          (poo-flow-tool-action-mismatch-bundle
           catalog (poo-flow-tool-policy-grants agent-policy)
           (poo-flow-tool-policy-grants hook-policy)))
         (action-diagnostics
          (poo-flow-session-alist-ref action-bundle 'diagnostics '()))
         (diagnostics
          (append (poo-flow-session-alist-ref summary 'diagnostics '())
                  action-diagnostics)))
    (object<-alist
     (list
      (cons 'kind +poo-flow-tool-core-policy-validation-receipt-kind+)
      (cons 'schema 'poo-flow.modules.tool-core.policy-catalog-validation.v1)
      (cons 'validation-id validation-id)
      (cons 'catalog-ref (poo-flow-tool-catalog-ref catalog))
      (cons 'catalog-tool-count (poo-flow-tool-catalog-tool-count catalog))
      (cons 'catalog-tool-refs (poo-flow-tool-catalog-tool-refs catalog))
      (cons 'agent-tool-policy-ref (poo-flow-session-policy-name agent-policy))
      (cons 'hook-tool-policy-ref (poo-flow-session-policy-name hook-policy))
      (cons 'policy-tool-refs policy-refs)
      (cons 'resolved-tool-refs
            (poo-flow-session-alist-ref summary 'resolved-tool-refs '()))
      (cons 'unresolved-tool-refs
            (poo-flow-session-alist-ref summary 'unresolved-tool-refs '()))
      (cons 'sandbox-required-tool-refs
            (poo-flow-session-alist-ref summary 'sandbox-required-tool-refs '()))
      (cons 'action-mismatch-grants
            (poo-flow-session-alist-ref action-bundle 'rows '()))
      (cons 'valid? (null? diagnostics))
      (cons 'diagnostic-count (length diagnostics))
      (cons 'diagnostics diagnostics)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f)
      (cons 'metadata (if (null? maybe-metadata) '() (car maybe-metadata)))))))

(def (poo-flow-tool-policy-catalog-validation-receipt? value)
  (and (object? value)
       (eq? (poo-flow-tool-slot value 'kind #f)
            +poo-flow-tool-core-policy-validation-receipt-kind+)))

(def (poo-flow-tool-policy-catalog-validation-receipt-valid? receipt)
  (.ref receipt 'valid?))

(def (poo-flow-tool-policy-catalog-validation-receipt-diagnostics receipt)
  (.ref receipt 'diagnostics))

(defpoo-module-final-projection
  poo-flow-tool-policy-catalog-validation-receipt->alist (receipt)
  (bindings ((checked-receipt
              (poo-flow-session-require
               "tool validation projection requires a receipt"
               (poo-flow-tool-policy-catalog-validation-receipt? receipt)
               receipt))))
  (fields ((kind (.ref checked-receipt 'kind))
           (schema (.ref checked-receipt 'schema))
           (validation-id (.ref checked-receipt 'validation-id))
           (catalog-ref (.ref checked-receipt 'catalog-ref))
           (catalog-tool-count (.ref checked-receipt 'catalog-tool-count))
           (catalog-tool-refs (.ref checked-receipt 'catalog-tool-refs))
           (agent-tool-policy-ref (.ref checked-receipt 'agent-tool-policy-ref))
           (hook-tool-policy-ref (.ref checked-receipt 'hook-tool-policy-ref))
           (policy-tool-refs (.ref checked-receipt 'policy-tool-refs))
           (resolved-tool-refs (.ref checked-receipt 'resolved-tool-refs))
           (unresolved-tool-refs (.ref checked-receipt 'unresolved-tool-refs))
           (sandbox-required-tool-refs
            (.ref checked-receipt 'sandbox-required-tool-refs))
           (action-mismatch-grants (.ref checked-receipt 'action-mismatch-grants))
           (valid? (.ref checked-receipt 'valid?))
           (diagnostic-count (.ref checked-receipt 'diagnostic-count))
           (diagnostics (.ref checked-receipt 'diagnostics))
           (runtime-owner (.ref checked-receipt 'runtime-owner))
           (runtime-executed (.ref checked-receipt 'runtime-executed))
           (metadata (.ref checked-receipt 'metadata)))))
