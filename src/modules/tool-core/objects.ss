;;; -*- Gerbil -*-
;;; Boundary: POO-native tool specs, catalogs, and handoff receipts.
;;; Invariant: this module describes tools and validates policy refs; it never
;;; starts shells, filesystem IO, MCP servers, or backend runtimes.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/module-system/projection-syntax
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/session/policy)

(export +poo-flow-tool-core-spec-kind+
        +poo-flow-tool-core-catalog-kind+
        +poo-flow-tool-core-handoff-manifest-kind+
        +poo-flow-tool-core-policy-validation-receipt-kind+
        poo-flow-tool-spec
        poo-flow-tool-spec?
        poo-flow-tool-spec-ref
        poo-flow-tool-spec-tool-kind
        poo-flow-tool-spec-actions
        poo-flow-tool-spec-sandbox-required?
        poo-flow-tool-spec-sandbox-profile-ref
        poo-flow-tool-spec->alist
        poo-flow-tool-handoff-manifest
        poo-flow-tool-handoff-manifest?
        poo-flow-tool-handoff-manifest->alist
        poo-flow-tool-catalog
        poo-flow-tool-catalog?
        poo-flow-tool-catalog-ref
        poo-flow-tool-catalog-tool-refs
        poo-flow-tool-catalog-tool-count
        poo-flow-tool-catalog-find
        poo-flow-tool-catalog->alist
        poo-flow-tool-policy-catalog-validation-receipt
        poo-flow-tool-policy-catalog-validation-receipt?
        poo-flow-tool-policy-catalog-validation-receipt-valid?
        poo-flow-tool-policy-catalog-validation-receipt-diagnostics
        poo-flow-tool-policy-catalog-validation-receipt->alist
        poo-flow-tool-core-builtin-read-workspace-file
        poo-flow-tool-core-builtin-write-workspace-file
        poo-flow-tool-core-builtin-run-shell-command
        poo-flow-tool-core-mcp-tool
        poo-flow-tool-core-default-catalog)

;; : Symbol
(def +poo-flow-tool-core-spec-kind+ 'poo-flow.tool-core.spec)

;; : Symbol
(def +poo-flow-tool-core-catalog-kind+ 'poo-flow.tool-core.catalog)

;; : Symbol
(def +poo-flow-tool-core-handoff-manifest-kind+
  'poo-flow.tool-core.handoff-manifest)

;; : Symbol
(def +poo-flow-tool-core-policy-validation-receipt-kind+
  'poo-flow.tool-core.policy-catalog-validation-receipt)

;; : (-> POOObject Symbol Value Value)
(def (poo-flow-tool-slot object key default-value)
  (with-catch
   (lambda (_failure) default-value)
   (lambda ()
     (.ref object key))))

;; : (-> Symbol Boolean)
(def (poo-flow-tool-ref? value)
  (symbol? value))

;; : (-> [Any] Boolean)
(def (poo-flow-tool-symbol-list? values)
  (and (list? values)
       (poo-flow-session-every? symbol? values)))

;; : (-> [Any] Boolean)
(def (poo-flow-tool-alist? value)
  (list? value))

;; : (-> Boolean Value Boolean)
(def (poo-flow-tool-valid-sandbox-profile-ref? sandbox-required?
                                               sandbox-profile-ref)
  (or (not sandbox-required?)
      (symbol? sandbox-profile-ref)))

;; : (-> Symbol Symbol [Symbol] Alist Alist String Symbol Boolean MaybeSymbol Symbol [Alist] PooToolSpec)
(def (poo-flow-tool-spec tool-ref
                         tool-kind
                         actions
                         input-schema
                         output-schema
                         runtime-owner
                         handoff-operation
                         sandbox-required?
                         sandbox-profile-ref
                         runtime-backend
                         . maybe-metadata)
  (poo-flow-session-require "tool spec ref must be a symbol"
                            (symbol? tool-ref)
                            tool-ref)
  (poo-flow-session-require "tool spec kind must be a symbol"
                            (symbol? tool-kind)
                            tool-kind)
  (poo-flow-session-require "tool spec actions must be symbols"
                            (poo-flow-tool-symbol-list? actions)
                            actions)
  (poo-flow-session-require "tool spec input schema must be an alist"
                            (poo-flow-tool-alist? input-schema)
                            input-schema)
  (poo-flow-session-require "tool spec output schema must be an alist"
                            (poo-flow-tool-alist? output-schema)
                            output-schema)
  (poo-flow-session-require "tool spec runtime owner must be a string"
                            (string? runtime-owner)
                            runtime-owner)
  (poo-flow-session-require "tool spec handoff operation must be a symbol"
                            (symbol? handoff-operation)
                            handoff-operation)
  (poo-flow-session-require "tool spec sandbox-required? must be boolean"
                            (boolean? sandbox-required?)
                            sandbox-required?)
  (poo-flow-session-require "tool spec runtime backend must be a symbol"
                            (symbol? runtime-backend)
                            runtime-backend)
  (object<-alist
   (list
    (cons 'kind +poo-flow-tool-core-spec-kind+)
    (cons 'schema 'poo-flow.modules.tool-core.spec.v1)
    (cons 'tool-ref tool-ref)
    (cons 'tool-kind tool-kind)
    (cons 'actions actions)
    (cons 'input-schema input-schema)
    (cons 'output-schema output-schema)
    (cons 'runtime-owner runtime-owner)
    (cons 'handoff-operation handoff-operation)
    (cons 'sandbox-required? sandbox-required?)
    (cons 'sandbox-profile-ref sandbox-profile-ref)
    (cons 'runtime-backend runtime-backend)
    (cons 'runtime-executed #f)
    (cons 'metadata (if (null? maybe-metadata)
                      '()
                      (car maybe-metadata))))))

;; : (-> POOObject Boolean)
(def (poo-flow-tool-spec? value)
  (and (object? value)
       (eq? (poo-flow-tool-slot value 'kind #f)
            +poo-flow-tool-core-spec-kind+)))

;; : (-> PooToolSpec Symbol)
(def (poo-flow-tool-spec-ref spec)
  (.ref spec 'tool-ref))

;; : (-> PooToolSpec Symbol)
(def (poo-flow-tool-spec-tool-kind spec)
  (.ref spec 'tool-kind))

;; : (-> PooToolSpec [Symbol])
(def (poo-flow-tool-spec-actions spec)
  (.ref spec 'actions))

;; : (-> PooToolSpec Boolean)
(def (poo-flow-tool-spec-sandbox-required? spec)
  (.ref spec 'sandbox-required?))

;; : (-> PooToolSpec MaybeSymbol)
(def (poo-flow-tool-spec-sandbox-profile-ref spec)
  (.ref spec 'sandbox-profile-ref))

;; : (-> PooToolSpec Alist)
(defpoo-module-final-projection
  poo-flow-tool-spec->alist (spec)
  (bindings ((checked-spec
              (poo-flow-session-require
               "tool spec projection requires a tool spec"
               (poo-flow-tool-spec? spec)
               spec))))
  (fields ((kind (.ref checked-spec 'kind))
           (schema (.ref checked-spec 'schema))
           (tool-ref (.ref checked-spec 'tool-ref))
           (tool-kind (.ref checked-spec 'tool-kind))
           (actions (.ref checked-spec 'actions))
           (input-schema (.ref checked-spec 'input-schema))
           (output-schema (.ref checked-spec 'output-schema))
           (runtime-owner (.ref checked-spec 'runtime-owner))
           (handoff-operation (.ref checked-spec 'handoff-operation))
           (sandbox-required? (.ref checked-spec 'sandbox-required?))
           (sandbox-profile-ref (.ref checked-spec 'sandbox-profile-ref))
           (runtime-backend (.ref checked-spec 'runtime-backend))
           (runtime-executed (.ref checked-spec 'runtime-executed))
           (metadata (.ref checked-spec 'metadata)))))

;; : (-> [PooToolSpec] [Alist])
(defpoo-module-final-projection-batch
  poo-flow-tool-specs->alists (specs)
  (projector poo-flow-tool-spec->alist)
  (error-message "tool spec serialization requires a list"))

;; : (-> Symbol PooToolSpec [Alist] PooToolHandoffManifest)
(def (poo-flow-tool-handoff-manifest request-id spec . maybe-metadata)
  (poo-flow-session-require "tool handoff request id must be a symbol"
                            (symbol? request-id)
                            request-id)
  (poo-flow-session-require "tool handoff requires a tool spec"
                            (poo-flow-tool-spec? spec)
                            spec)
  (let* ((sandbox-required?
          (poo-flow-tool-spec-sandbox-required? spec))
         (sandbox-profile-ref
          (poo-flow-tool-spec-sandbox-profile-ref spec))
         (diagnostics
          (if (poo-flow-tool-valid-sandbox-profile-ref?
               sandbox-required?
               sandbox-profile-ref)
            '()
            (list
             (list (cons 'code 'tool-spec-missing-sandbox-profile)
                   (cons 'tool-ref (poo-flow-tool-spec-ref spec))
                   (cons 'severity 'error))))))
    (object<-alist
     (list
      (cons 'kind +poo-flow-tool-core-handoff-manifest-kind+)
      (cons 'schema 'poo-flow.modules.tool-core.handoff-manifest.v1)
      (cons 'request-id request-id)
      (cons 'tool-ref (poo-flow-tool-spec-ref spec))
      (cons 'tool-kind (poo-flow-tool-spec-tool-kind spec))
      (cons 'actions (poo-flow-tool-spec-actions spec))
      (cons 'operation (.ref spec 'handoff-operation))
      (cons 'input-schema (.ref spec 'input-schema))
      (cons 'output-schema (.ref spec 'output-schema))
      (cons 'runtime-owner (.ref spec 'runtime-owner))
      (cons 'runtime-backend (.ref spec 'runtime-backend))
      (cons 'sandbox-required? sandbox-required?)
      (cons 'sandbox-profile-ref sandbox-profile-ref)
      (cons 'handoff-ready? (null? diagnostics))
      (cons 'diagnostic-count (length diagnostics))
      (cons 'diagnostics diagnostics)
      (cons 'runtime-executed #f)
      (cons 'metadata (if (null? maybe-metadata)
                        '()
                        (car maybe-metadata)))))))

;; : (-> POOObject Boolean)
(def (poo-flow-tool-handoff-manifest? value)
  (and (object? value)
       (eq? (poo-flow-tool-slot value 'kind #f)
            +poo-flow-tool-core-handoff-manifest-kind+)))

;; : (-> PooToolHandoffManifest Alist)
(defpoo-module-final-projection
  poo-flow-tool-handoff-manifest->alist (manifest)
  (bindings ((checked-manifest
              (poo-flow-session-require
               "tool handoff projection requires a handoff manifest"
               (poo-flow-tool-handoff-manifest? manifest)
               manifest))))
  (fields ((kind (.ref checked-manifest 'kind))
           (schema (.ref checked-manifest 'schema))
           (request-id (.ref checked-manifest 'request-id))
           (tool-ref (.ref checked-manifest 'tool-ref))
           (tool-kind (.ref checked-manifest 'tool-kind))
           (actions (.ref checked-manifest 'actions))
           (operation (.ref checked-manifest 'operation))
           (input-schema (.ref checked-manifest 'input-schema))
           (output-schema (.ref checked-manifest 'output-schema))
           (runtime-owner (.ref checked-manifest 'runtime-owner))
           (runtime-backend (.ref checked-manifest 'runtime-backend))
           (sandbox-required? (.ref checked-manifest 'sandbox-required?))
           (sandbox-profile-ref (.ref checked-manifest 'sandbox-profile-ref))
           (handoff-ready? (.ref checked-manifest 'handoff-ready?))
           (diagnostic-count (.ref checked-manifest 'diagnostic-count))
           (diagnostics (.ref checked-manifest 'diagnostics))
           (runtime-executed (.ref checked-manifest 'runtime-executed))
           (metadata (.ref checked-manifest 'metadata)))))

;; : (-> [PooToolSpec] (Cons [Symbol] Integer))
(def (poo-flow-tool-catalog-summary tools)
  (let loop ((remaining-tools tools)
             (tool-refs-rev '())
             (tool-count 0))
    (if (null? remaining-tools)
      (cons (reverse tool-refs-rev) tool-count)
      (loop (cdr remaining-tools)
            (cons (poo-flow-tool-spec-ref (car remaining-tools))
                  tool-refs-rev)
            (+ tool-count 1)))))

;; : (-> Symbol [PooToolSpec] [Alist] PooToolCatalog)
(def (poo-flow-tool-catalog catalog-ref tools . maybe-metadata)
  (poo-flow-session-require "tool catalog ref must be a symbol"
                            (symbol? catalog-ref)
                            catalog-ref)
  (poo-flow-session-require "tool catalog tools must be specs"
                            (poo-flow-session-every? poo-flow-tool-spec?
                                                     tools)
                            tools)
  (let* ((catalog-summary (poo-flow-tool-catalog-summary tools))
         (tool-refs (car catalog-summary))
         (tool-count (cdr catalog-summary)))
    (object<-alist
     (list
      (cons 'kind +poo-flow-tool-core-catalog-kind+)
      (cons 'schema 'poo-flow.modules.tool-core.catalog.v1)
      (cons 'catalog-ref catalog-ref)
      (cons 'tools tools)
      (cons 'tool-refs tool-refs)
      (cons 'tool-count tool-count)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f)
      (cons 'metadata (if (null? maybe-metadata)
                        '()
                        (car maybe-metadata)))))))

;; : (-> POOObject Boolean)
(def (poo-flow-tool-catalog? value)
  (and (object? value)
       (eq? (poo-flow-tool-slot value 'kind #f)
            +poo-flow-tool-core-catalog-kind+)))

;; : (-> PooToolCatalog Symbol)
(def (poo-flow-tool-catalog-ref catalog)
  (.ref catalog 'catalog-ref))

;; : (-> PooToolCatalog [Symbol])
(def (poo-flow-tool-catalog-tool-refs catalog)
  (.ref catalog 'tool-refs))

;; : (-> PooToolCatalog Integer)
(def (poo-flow-tool-catalog-tool-count catalog)
  (.ref catalog 'tool-count))

;; : (-> [PooToolSpec] Symbol MaybePooToolSpec)
(def (poo-flow-tool-spec-find tools tool-ref)
  (cond
   ((null? tools) #f)
   ((eq? (poo-flow-tool-spec-ref (car tools)) tool-ref) (car tools))
   (else
    (poo-flow-tool-spec-find (cdr tools) tool-ref))))

;; : (-> PooToolCatalog Symbol MaybePooToolSpec)
(def (poo-flow-tool-catalog-find catalog tool-ref)
  (poo-flow-tool-spec-find (.ref catalog 'tools) tool-ref))

;; : (-> PooToolCatalog Alist)
(defpoo-module-final-projection
  poo-flow-tool-catalog->alist (catalog)
  (bindings ((checked-catalog
              (poo-flow-session-require
               "tool catalog projection requires a catalog"
               (poo-flow-tool-catalog? catalog)
               catalog))))
  (fields ((kind (.ref checked-catalog 'kind))
           (schema (.ref checked-catalog 'schema))
           (catalog-ref (.ref checked-catalog 'catalog-ref))
           (tool-count (.ref checked-catalog 'tool-count))
           (tool-refs (.ref checked-catalog 'tool-refs))
           (tools
            (poo-flow-tool-specs->alists (.ref checked-catalog 'tools)))
           (runtime-owner (.ref checked-catalog 'runtime-owner))
           (runtime-executed (.ref checked-catalog 'runtime-executed))
           (metadata (.ref checked-catalog 'metadata)))))

;; : (-> [PooSessionToolGrant] [Symbol])
(def (poo-flow-tool-policy-grant-tool-refs grants)
  (cond
   ((null? grants) '())
   (else
    (cons (poo-flow-session-tool-grant-tool-ref (car grants))
          (poo-flow-tool-policy-grant-tool-refs (cdr grants))))))

;; : (-> PooSessionPolicy [PooSessionToolGrant])
(def (poo-flow-tool-policy-grants policy)
  (poo-flow-session-alist-ref
   (poo-flow-session-policy->alist policy)
   'tool-grants
   '()))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-tool-unique-symbols values seen)
  (cond
   ((null? values) '())
   ((or (eq? (car values) '*)
        (member (car values) seen))
    (poo-flow-tool-unique-symbols (cdr values) seen))
   (else
    (cons (car values)
          (poo-flow-tool-unique-symbols (cdr values)
                                        (cons (car values) seen))))))

;; : (-> [Symbol] [Symbol] [Symbol] (Cons [Symbol] [Symbol]))
(def (poo-flow-tool-unique-symbols/accumulate values seen values-rev)
  (cond
   ((null? values) (cons seen values-rev))
   ((or (eq? (car values) '*)
        (member (car values) seen))
    (poo-flow-tool-unique-symbols/accumulate
     (cdr values)
     seen
     values-rev))
   (else
    (poo-flow-tool-unique-symbols/accumulate
     (cdr values)
     (cons (car values) seen)
     (cons (car values) values-rev)))))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-tool-merge-policy-tool-refs agent-tool-refs hook-tool-refs)
  (let* ((agent-bundle
          (poo-flow-tool-unique-symbols/accumulate agent-tool-refs '() '()))
         (hook-bundle
          (poo-flow-tool-unique-symbols/accumulate
           hook-tool-refs
           (car agent-bundle)
           (cdr agent-bundle))))
    (reverse (cdr hook-bundle))))

;; : (-> PooSessionPolicy [Symbol])
(def (poo-flow-tool-policy-tool-refs policy)
  (poo-flow-tool-unique-symbols
   (poo-flow-tool-policy-grant-tool-refs
    (poo-flow-tool-policy-grants policy))
   '()))

;; : (-> Symbol Symbol Alist)
(def (poo-flow-tool-diagnostic code tool-ref)
  (list (cons 'kind 'poo-flow.tool-core.diagnostic)
        (cons 'schema 'poo-flow.modules.tool-core.diagnostic.v1)
        (cons 'code code)
        (cons 'tool-ref tool-ref)
        (cons 'severity 'error)
        (cons 'runtime-executed #f)))

;; : (-> Symbol Symbol [Symbol] [Symbol] [Symbol] Alist)
(def (poo-flow-tool-action-diagnostic grant-id
                                      tool-ref
                                      requested-actions
                                      supported-actions
                                      unsupported-actions)
  (list (cons 'kind 'poo-flow.tool-core.diagnostic)
        (cons 'schema 'poo-flow.modules.tool-core.diagnostic.v1)
        (cons 'code 'tool-grant-action-not-supported)
        (cons 'grant-id grant-id)
        (cons 'tool-ref tool-ref)
        (cons 'requested-actions requested-actions)
        (cons 'supported-actions supported-actions)
        (cons 'unsupported-actions unsupported-actions)
        (cons 'severity 'error)
        (cons 'runtime-executed #f)))

;; : (-> Symbol [Symbol] Boolean)
(def (poo-flow-tool-action-supported? action supported-actions)
  (or (member action supported-actions)
      (member '* supported-actions)))

;; : (-> [Symbol] [Symbol] [Symbol])
(def (poo-flow-tool-unsupported-actions requested-actions supported-actions)
  (cond
   ((null? requested-actions) '())
   ((poo-flow-tool-action-supported? (car requested-actions)
                                     supported-actions)
    (poo-flow-tool-unsupported-actions (cdr requested-actions)
                                       supported-actions))
   (else
    (cons (car requested-actions)
          (poo-flow-tool-unsupported-actions (cdr requested-actions)
                                             supported-actions)))))

;; : (-> PooSessionToolGrant PooToolSpec Alist)
(def (poo-flow-tool-action-mismatch-row grant spec)
  (let* ((requested-actions
          (poo-flow-session-tool-grant-actions grant))
         (supported-actions
          (poo-flow-tool-spec-actions spec))
         (unsupported-actions
          (poo-flow-tool-unsupported-actions requested-actions
                                             supported-actions)))
    (if (null? unsupported-actions)
      #f
      (list
       (cons 'grant-id (poo-flow-session-tool-grant-id grant))
       (cons 'tool-ref (poo-flow-session-tool-grant-tool-ref grant))
       (cons 'requested-actions requested-actions)
       (cons 'supported-actions supported-actions)
       (cons 'unsupported-actions unsupported-actions)))))

;; : (-> PooToolCatalog [PooSessionToolGrant] [Alist])
(def (poo-flow-tool-action-mismatch-bundle/fold catalog
                                                grants
                                                rows-rev
                                                diagnostics-rev)
  (cond
   ((null? grants)
    (cons rows-rev diagnostics-rev))
   (else
    (let* ((grant (car grants))
           (tool-ref (poo-flow-session-tool-grant-tool-ref grant))
           (spec (poo-flow-tool-catalog-find catalog tool-ref))
           (mismatch-row
            (if spec
              (poo-flow-tool-action-mismatch-row grant spec)
              #f)))
      (if mismatch-row
        (poo-flow-tool-action-mismatch-bundle/fold
         catalog
         (cdr grants)
         (cons mismatch-row rows-rev)
         (cons (poo-flow-tool-action-diagnostic
                (poo-flow-session-alist-ref mismatch-row 'grant-id #f)
                (poo-flow-session-alist-ref mismatch-row 'tool-ref #f)
                (poo-flow-session-alist-ref
                 mismatch-row
                 'requested-actions
                 '())
                (poo-flow-session-alist-ref
                 mismatch-row
                 'supported-actions
                 '())
                (poo-flow-session-alist-ref
                 mismatch-row
                 'unsupported-actions
                 '()))
               diagnostics-rev))
        (poo-flow-tool-action-mismatch-bundle/fold
         catalog
         (cdr grants)
         rows-rev
         diagnostics-rev))))))

;; : (-> PooToolCatalog [PooSessionToolGrant] [PooSessionToolGrant] Alist)
(def (poo-flow-tool-action-mismatch-bundle catalog agent-grants hook-grants)
  (let* ((agent-bundle
          (poo-flow-tool-action-mismatch-bundle/fold
           catalog
           agent-grants
           '()
           '()))
         (hook-bundle
          (poo-flow-tool-action-mismatch-bundle/fold
           catalog
           hook-grants
           (car agent-bundle)
           (cdr agent-bundle))))
    (list
     (cons 'rows (reverse (car hook-bundle)))
     (cons 'diagnostics (reverse (cdr hook-bundle))))))

;; : (-> [Value] [Value] [Value])
(def (poo-flow-tool-reverse-onto values tail)
  (if (null? values)
    tail
    (poo-flow-tool-reverse-onto
     (cdr values)
     (cons (car values) tail))))

;; : (-> [Alist] [Alist] [Alist] [Alist])
(def (poo-flow-tool-validation-diagnostics/tail unresolved-diagnostics-rev
                                                sandbox-diagnostics-rev
                                                tail)
  (poo-flow-tool-reverse-onto
   unresolved-diagnostics-rev
   (poo-flow-tool-reverse-onto sandbox-diagnostics-rev tail)))

;; : (-> [Alist] [Alist] [Alist])
(def (poo-flow-tool-validation-diagnostics unresolved-diagnostics-rev
                                           sandbox-diagnostics-rev)
  (poo-flow-tool-validation-diagnostics/tail unresolved-diagnostics-rev
                                             sandbox-diagnostics-rev
                                             '()))

;; : (-> PooToolCatalog [Symbol] Alist)
(def (poo-flow-tool-policy-catalog-validation-summary catalog tool-refs)
  (let loop ((remaining-tool-refs tool-refs)
             (resolved-tool-refs-rev '())
             (unresolved-tool-refs-rev '())
             (sandbox-required-tool-refs-rev '())
             (unresolved-diagnostics-rev '())
             (sandbox-diagnostics-rev '()))
    (cond
     ((null? remaining-tool-refs)
      (list
       (cons 'resolved-tool-refs (reverse resolved-tool-refs-rev))
       (cons 'unresolved-tool-refs (reverse unresolved-tool-refs-rev))
       (cons 'sandbox-required-tool-refs
             (reverse sandbox-required-tool-refs-rev))
       (cons 'unresolved-diagnostics-rev unresolved-diagnostics-rev)
       (cons 'sandbox-diagnostics-rev sandbox-diagnostics-rev)
       (cons 'diagnostics
             (poo-flow-tool-validation-diagnostics
              unresolved-diagnostics-rev
              sandbox-diagnostics-rev))))
     (else
      (let* ((tool-ref (car remaining-tool-refs))
             (spec (poo-flow-tool-catalog-find catalog tool-ref)))
        (cond
         (spec
          (let ((sandbox-required?
                 (poo-flow-tool-spec-sandbox-required? spec))
                (sandbox-profile-ref
                 (poo-flow-tool-spec-sandbox-profile-ref spec)))
            (loop
             (cdr remaining-tool-refs)
             (cons tool-ref resolved-tool-refs-rev)
             unresolved-tool-refs-rev
             (if sandbox-required?
               (cons tool-ref sandbox-required-tool-refs-rev)
               sandbox-required-tool-refs-rev)
             unresolved-diagnostics-rev
             (if (and sandbox-required?
                      (not (symbol? sandbox-profile-ref)))
               (cons (poo-flow-tool-diagnostic
                      'tool-spec-missing-sandbox-profile
                      tool-ref)
                     sandbox-diagnostics-rev)
               sandbox-diagnostics-rev))))
         (else
          (loop
           (cdr remaining-tool-refs)
           resolved-tool-refs-rev
           (cons tool-ref unresolved-tool-refs-rev)
           sandbox-required-tool-refs-rev
           (cons (poo-flow-tool-diagnostic 'tool-spec-not-in-catalog tool-ref)
                 unresolved-diagnostics-rev)
           sandbox-diagnostics-rev))))))))

;; : (-> Symbol PooToolCatalog PooSessionPolicy PooSessionPolicy [Alist] PooToolPolicyCatalogValidationReceipt)
(def (poo-flow-tool-policy-catalog-validation-receipt validation-id
                                                      catalog
                                                      agent-tool-policy
                                                      hook-tool-policy
                                                      . maybe-metadata)
  (poo-flow-session-require "tool validation id must be a symbol"
                            (symbol? validation-id)
                            validation-id)
  (poo-flow-session-require "tool validation requires a catalog"
                            (poo-flow-tool-catalog? catalog)
                            catalog)
  (poo-flow-session-require "tool validation requires agent tool policy"
                            (poo-flow-session-policy? agent-tool-policy)
                            agent-tool-policy)
  (poo-flow-session-require "tool validation requires hook tool policy"
                            (poo-flow-session-policy? hook-tool-policy)
                            hook-tool-policy)
  (let* ((agent-tool-refs
          (poo-flow-tool-policy-tool-refs agent-tool-policy))
         (hook-tool-refs
          (poo-flow-tool-policy-tool-refs hook-tool-policy))
         (policy-tool-refs
          (poo-flow-tool-merge-policy-tool-refs
           agent-tool-refs
           hook-tool-refs))
         (validation-summary
          (poo-flow-tool-policy-catalog-validation-summary
           catalog
           policy-tool-refs))
         (agent-tool-grants
          (poo-flow-tool-policy-grants agent-tool-policy))
         (hook-tool-grants
          (poo-flow-tool-policy-grants hook-tool-policy))
         (action-mismatch-bundle
          (poo-flow-tool-action-mismatch-bundle catalog
                                                agent-tool-grants
                                                hook-tool-grants))
         (action-mismatch-grants
          (poo-flow-session-alist-ref action-mismatch-bundle 'rows '()))
         (action-diagnostics
          (poo-flow-session-alist-ref
           action-mismatch-bundle
           'diagnostics
           '()))
         (resolved-tool-refs
          (poo-flow-session-alist-ref
           validation-summary
           'resolved-tool-refs
           '()))
         (unresolved-tool-refs
          (poo-flow-session-alist-ref
           validation-summary
           'unresolved-tool-refs
           '()))
         (sandbox-required-tool-refs
          (poo-flow-session-alist-ref
           validation-summary
           'sandbox-required-tool-refs
           '()))
         (diagnostics
          (poo-flow-tool-validation-diagnostics/tail
           (poo-flow-session-alist-ref
            validation-summary
            'unresolved-diagnostics-rev
            '())
           (poo-flow-session-alist-ref
            validation-summary
            'sandbox-diagnostics-rev
            '())
           action-diagnostics)))
    (object<-alist
     (list
      (cons 'kind +poo-flow-tool-core-policy-validation-receipt-kind+)
      (cons 'schema 'poo-flow.modules.tool-core.policy-catalog-validation.v1)
      (cons 'validation-id validation-id)
      (cons 'catalog-ref (poo-flow-tool-catalog-ref catalog))
      (cons 'catalog-tool-count (poo-flow-tool-catalog-tool-count catalog))
      (cons 'catalog-tool-refs (poo-flow-tool-catalog-tool-refs catalog))
      (cons 'agent-tool-policy-ref
            (poo-flow-session-policy-name agent-tool-policy))
      (cons 'hook-tool-policy-ref
            (poo-flow-session-policy-name hook-tool-policy))
      (cons 'policy-tool-refs policy-tool-refs)
      (cons 'resolved-tool-refs resolved-tool-refs)
      (cons 'unresolved-tool-refs unresolved-tool-refs)
      (cons 'sandbox-required-tool-refs sandbox-required-tool-refs)
      (cons 'action-mismatch-grants action-mismatch-grants)
      (cons 'valid? (null? diagnostics))
      (cons 'diagnostic-count (length diagnostics))
      (cons 'diagnostics diagnostics)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-executed #f)
      (cons 'metadata (if (null? maybe-metadata)
                        '()
                        (car maybe-metadata)))))))

;; : (-> POOObject Boolean)
(def (poo-flow-tool-policy-catalog-validation-receipt? value)
  (and (object? value)
       (eq? (poo-flow-tool-slot value 'kind #f)
            +poo-flow-tool-core-policy-validation-receipt-kind+)))

;; : (-> PooToolPolicyCatalogValidationReceipt Boolean)
(def (poo-flow-tool-policy-catalog-validation-receipt-valid? receipt)
  (.ref receipt 'valid?))

;; : (-> PooToolPolicyCatalogValidationReceipt [Alist])
(def (poo-flow-tool-policy-catalog-validation-receipt-diagnostics receipt)
  (.ref receipt 'diagnostics))

;; : (-> PooToolPolicyCatalogValidationReceipt Alist)
(defpoo-module-final-projection
  poo-flow-tool-policy-catalog-validation-receipt->alist (receipt)
  (bindings ((checked-receipt
              (poo-flow-session-require
               "tool policy validation projection requires a validation receipt"
               (poo-flow-tool-policy-catalog-validation-receipt? receipt)
               receipt))))
  (fields ((kind (.ref checked-receipt 'kind))
           (schema (.ref checked-receipt 'schema))
           (validation-id (.ref checked-receipt 'validation-id))
           (catalog-ref (.ref checked-receipt 'catalog-ref))
           (catalog-tool-count (.ref checked-receipt 'catalog-tool-count))
           (catalog-tool-refs (.ref checked-receipt 'catalog-tool-refs))
           (agent-tool-policy-ref
            (.ref checked-receipt 'agent-tool-policy-ref))
           (hook-tool-policy-ref
            (.ref checked-receipt 'hook-tool-policy-ref))
           (policy-tool-refs (.ref checked-receipt 'policy-tool-refs))
           (resolved-tool-refs (.ref checked-receipt 'resolved-tool-refs))
           (unresolved-tool-refs (.ref checked-receipt 'unresolved-tool-refs))
           (sandbox-required-tool-refs
            (.ref checked-receipt 'sandbox-required-tool-refs))
           (action-mismatch-grants
            (.ref checked-receipt 'action-mismatch-grants))
           (valid? (.ref checked-receipt 'valid?))
           (diagnostic-count (.ref checked-receipt 'diagnostic-count))
           (diagnostics (.ref checked-receipt 'diagnostics))
           (runtime-owner (.ref checked-receipt 'runtime-owner))
           (runtime-executed (.ref checked-receipt 'runtime-executed))
           (metadata (.ref checked-receipt 'metadata)))))

;; : PooToolSpec
(def poo-flow-tool-core-builtin-read-workspace-file
  (poo-flow-tool-spec
   'read-workspace-file
   'builtin-filesystem
   '(read)
   '((path . string) (mode . read-only))
   '((content-ref . artifact) (summary . string))
   "marlin-agent-core"
   'tool/read-workspace-file
   #t
   'agent/nono
   'marlin-tool-adapter
   '((builtin . #t))))

;; : PooToolSpec
(def poo-flow-tool-core-builtin-write-workspace-file
  (poo-flow-tool-spec
   'write-workspace-file
   'builtin-filesystem
   '(write)
   '((path . string) (content . string))
   '((artifact-ref . artifact))
   "marlin-agent-core"
   'tool/write-workspace-file
   #t
   'agent/nono
   'marlin-tool-adapter
   '((builtin . #t))))

;; : PooToolSpec
(def poo-flow-tool-core-builtin-run-shell-command
  (poo-flow-tool-spec
   'run-shell-command
   'builtin-command
   '(run)
   '((argv . list) (cwd . string))
   '((exit-status . integer) (stdout-ref . artifact) (stderr-ref . artifact))
   "marlin-agent-core"
   'tool/run-shell-command
   #t
   'agent/nono
   'marlin-tool-adapter
   '((builtin . #t))))

;; : (-> Symbol Symbol [Symbol] Alist Alist [Alist] PooToolSpec)
(def (poo-flow-tool-core-mcp-tool tool-ref
                                  server-ref
                                  actions
                                  input-schema
                                  output-schema
                                  . maybe-metadata)
  (poo-flow-tool-spec
   tool-ref
   'mcp
   actions
   input-schema
   output-schema
   "mcp-runtime"
   'tool/mcp-call
   #f
   #f
   server-ref
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : PooToolCatalog
(def poo-flow-tool-core-default-catalog
  (poo-flow-tool-catalog
   'tool-core/default
   (list poo-flow-tool-core-builtin-read-workspace-file
         poo-flow-tool-core-builtin-write-workspace-file
         poo-flow-tool-core-builtin-run-shell-command)
   '((source . poo-flow-tool-core)
     (runtime-executed . #f))))
