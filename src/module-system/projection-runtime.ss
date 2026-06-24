;;; -*- Gerbil -*-
;;; Boundary: module runtime-facing projections and presentation receipts.
;;; Invariant: projection returns inspectable Scheme values, not runtime handles.

(import (only-in :clan/poo/object .@ .ref object<-alist)
        :poo-flow/src/core/agent-harness-vocabulary
        :poo-flow/src/module-system/interface
        :poo-flow/src/module-system/descriptor
        :poo-flow/src/module-system/context
        :poo-flow/src/module-system/projection-catalog
        :poo-flow/src/module-system/projection-options)

(export poo-flow-module-runtime-import
        poo-flow-module-apply
        poo-flow-module-evaluate
        poo-flow-module-workflow
        poo-flow-module-runtime-capability-projection
        poo-flow-module-value-catalog-find
        poo-flow-module-value-catalog-active?
        poo-flow-module-value-catalog-root
        pooFlowModuleActive?
        poo-flow-module-active?
        pooFlowEvalModules
        poo-flow-eval-modules
        pooFlowModuleSystemPresentation
        poo-flow-module-system-presentation)

;;; Boundary: runtime imports unwrap structured imports but preserve payloads.
;; : (-> ModuleImportValue RuntimeImport)
(def (poo-flow-module-runtime-import import-value)
  (let (profile (poo-flow-module-import-profile import-value))
    (cond
     ((poo-flow-module-config? profile)
      (poo-flow-module-apply profile))
     (else profile))))

;;; Boundary: apply creates an inspectable runtime-module value, not a handle.
;; : (-> PooModuleDescriptor POOObject)
(def (poo-flow-module-apply module)
  (object<-alist
   (list
    (cons 'kind "poo-flow.modules.runtime-module.v1")
    (cons 'id (poo-flow-module-name module))
    (cons 'group (poo-flow-module-group module))
    (cons 'flags (poo-flow-module-flags module))
    (cons 'features (poo-flow-module-features module))
    (cons 'depth (poo-flow-module-depth module))
    (cons 'phase-files (poo-flow-module-phase-files module))
    (cons 'hooks (poo-flow-module-hooks module))
    (cons 'imports
          (map poo-flow-module-runtime-import (poo-flow-module-imports module)))
    (cons 'extensions (poo-flow-module-extensions module))
    (cons 'scripts (poo-flow-module-scripts module))
    (cons 'options (poo-flow-module-option-configs module))
    (cons 'metadata (poo-flow-module-metadata module)))))

;;; Boundary: projection append preserves closure module order.
;; : (-> [PooModuleDescriptor] (-> PooModuleDescriptor ProjectionValueList) [ProjectionValue])
(def (poo-flow-module-append-projection modules projector)
  (foldr append '() (map projector modules)))

;;; Boundary: evaluation folds the import closure into one receipt object.
;; : (-> PooModuleDescriptor POOObject)
(def (poo-flow-module-evaluate module)
  (let (closed-modules (poo-flow-module-closure (list module)))
    (object<-alist
     (list
      (cons 'kind "poo-flow.modules.runtime-evaluation.v1")
      (cons 'module-ids (poo-flow-module-names closed-modules))
      (cons 'init-module-ids
            (poo-flow-module-names
             (poo-flow-module-phase-order closed-modules 'init)))
      (cons 'config-module-ids
            (poo-flow-module-names
             (poo-flow-module-phase-order closed-modules 'config)))
      (cons 'hooks
            (poo-flow-module-append-projection
             closed-modules
             poo-flow-module-hooks))
      (cons 'extensions
            (poo-flow-module-append-projection
             closed-modules
             poo-flow-module-extensions))
      (cons 'scripts
            (poo-flow-module-append-projection
             closed-modules
             poo-flow-module-scripts))
      (cons 'options
            (poo-flow-module-append-projection
             closed-modules
             poo-flow-module-option-configs))
      (cons 'validation-receipts
            (poo-flow-module-append-projection
             closed-modules
             poo-flow-module-option-validation-receipts))))))

;;; Boundary: workflow groups root projections and validation receipts.
;; : (-> PooModuleDescriptor [AllowedHookId] POOObject)
(def (poo-flow-module-workflow module . maybe-allowed-hook-id-values)
  (let* ((allowed-hook-id-values
          (if (null? maybe-allowed-hook-id-values)
            '()
            (car maybe-allowed-hook-id-values)))
         (runtime-module-value (poo-flow-module-apply module))
         (evaluation-value (poo-flow-module-evaluate module)))
    (object<-alist
     (list
      (cons 'kind poo-flow-module-workflow-kind)
      (cons 'config module)
      (cons 'runtime-module runtime-module-value)
      (cons 'evaluation evaluation-value)
      (cons 'allowed-hook-ids allowed-hook-id-values)
      (cons 'root-options (poo-flow-module-option-configs module))
      (cons 'option-schemas (poo-flow-module-option-schemas module))
      (cons 'root-validation-receipts
            (poo-flow-module-option-validation-receipts module))
      (cons 'validation-receipts
            (.ref evaluation-value 'validation-receipts))))))

;;; Boundary: this projection reports runtime-facing object family capability.
;;; It does not construct runtime handles, start sessions, or submit dispatches.
;; : (-> POOObject)
(def (poo-flow-module-runtime-capability-projection)
  (object<-alist
   (list
    (cons 'kind "poo-flow.modules.runtime-capability-projection.v1")
    (cons 'owner poo-flow-module-system-owner)
    (cons 'runtime-owner "marlin-agent-core")
    (cons 'runtime-executed #f)
    (cons 'object-families
          '(agent-profile
            agent-harness
            agent-session
            agent-operation
            workflow-run
            dispatch-receipt
            runtime-snapshot))
    (cons 'operation-kinds +poo-flow-agent-operation-kinds+)
    (cons 'snapshot-statuses +poo-flow-runtime-snapshot-statuses+)
    (cons 'handoff-contracts
          '(start-workflow-run
            admit-dispatch
            open-agent-session
            execute-agent-operation
            stream-events
            read-runtime-snapshot))
    (cons 'presentation-trace
          '((stage . runtime-capability-projection)
            (runtime-executed . #f)
            (projection-only . #t))))))

;;; Boundary: value catalog lookup is by module id only.
;; : (-> PooModuleValueCatalog ModuleName MaybePooModuleDescriptor)
(def (poo-flow-module-value-catalog-find catalog module-id-value)
  (find (lambda (module)
          (equal? (poo-flow-module-name module) module-id-value))
        (.ref catalog 'modules)))

;;; Boundary: catalog active checks make Doom's modulep behavior data-driven.
;; : (-> PooModuleValueCatalog ModuleName [ModuleFlag] Boolean)
(def (poo-flow-module-value-catalog-active? catalog module-id-value . required-flags)
  (let (module (poo-flow-module-value-catalog-find catalog module-id-value))
    (and module
         (apply poo-flow-module-active? module required-flags))))

;; : (-> PooModuleValueCatalog ModuleName [ModuleFlag] Boolean)
(def (pooFlowModuleActive? catalog module-id-value . required-flags)
  (apply poo-flow-module-value-catalog-active?
         catalog
         module-id-value
         required-flags))

;;; Boundary: missing root id falls back to the first catalog module.
;; : (-> PooModuleValueCatalog MaybeModuleName PooModuleDescriptor)
(def (poo-flow-module-value-catalog-root catalog module-id-value)
  (cond
   (module-id-value
    (or (poo-flow-module-value-catalog-find catalog module-id-value)
        (error "poo-flow module root not found" module-id-value)))
   ((pair? (.ref catalog 'modules))
    (car (.ref catalog 'modules)))
   (else
    (error "poo-flow module catalog is empty"))))

;;; Boundary: evalModules mirrors Marlin without entering runtime execution.
;; | PooFlowEvalModuleOptions = [MaybeModuleName [AllowedHookId]]
;; pooFlowEvalModules
;;   : (-> PooModuleValueCatalog PooFlowEvalModuleOptions POOObject)
;;   | contract: returns branded POO Flow evaluation data, never runtime handles
;;   | doc m%
;;   | # Examples
;;   | ```scheme
;;   | (pooFlowEvalModules catalog 'root '("after-config"))
;;   | ```
;;   | result: replayable module evaluation receipt with brand and owner fields.
;; : (-> PooModuleValueCatalog PooFlowEvalModuleOptions POOObject)
(def (poo-flow-eval-modules catalog . eval-options)
  (let* ((root-module-id-value
          (if (null? eval-options) #f (car eval-options)))
         (allowed-hook-id-values
          (if (or (null? eval-options)
                  (null? (cdr eval-options)))
            '()
            (cadr eval-options)))
         (root-module
          (poo-flow-module-value-catalog-root catalog root-module-id-value))
         (workflow
          (poo-flow-module-workflow root-module allowed-hook-id-values))
         (evaluation-value (.ref workflow 'evaluation))
         (runtime-capabilities
          (poo-flow-module-runtime-capability-projection)))
    (object<-alist
     (list
      (cons 'kind poo-flow-eval-modules-result-kind)
      (cons 'catalog-kind (.ref catalog 'kind))
      (cons 'root-module-id (poo-flow-module-name root-module))
      (cons 'root-module-kind (.@ root-module kind))
      (cons 'workflow-kind (.ref workflow 'kind))
      (cons 'module-evaluation-kind (.ref evaluation-value 'kind))
      (cons 'module-count (length (.ref evaluation-value 'module-ids)))
      (cons 'init-module-count
            (length (.ref evaluation-value 'init-module-ids)))
      (cons 'config-module-count
            (length (.ref evaluation-value 'config-module-ids)))
      (cons 'hook-count (length (.ref evaluation-value 'hooks)))
      (cons 'extension-count (length (.ref evaluation-value 'extensions)))
      (cons 'script-count (length (.ref evaluation-value 'scripts)))
      (cons 'option-count (length (.ref evaluation-value 'options)))
      (cons 'validation-receipt-count
            (length (.ref evaluation-value 'validation-receipts)))
      (cons 'brand-name poo-flow-brand-name)
      (cons 'brand-group poo-flow-brand-group)
      (cons 'scheme-owner poo-flow-scheme-owner)
      (cons 'module-system-owner poo-flow-module-system-owner)
      (cons 'runtime-owner "marlin-agent-core")
      (cons 'runtime-boundary-owner "marlin-agent-core")
      (cons 'runtime-capability-projection-kind
            (.ref runtime-capabilities 'kind))
      (cons 'runtime-object-families
            (.ref runtime-capabilities 'object-families))
      (cons 'runtime-object-family-count
            (length (.ref runtime-capabilities 'object-families)))
      (cons 'runtime-snapshot-statuses
            (.ref runtime-capabilities 'snapshot-statuses))
      (cons 'runtime-handoff-contracts
            (.ref runtime-capabilities 'handoff-contracts))
      (cons 'runtime-executed #f)
      (cons 'replayable #t)))))

;; : (-> PooModuleValueCatalog PooFlowEvalModuleOptions POOObject)
(def (pooFlowEvalModules catalog . eval-options)
  (apply poo-flow-eval-modules catalog eval-options))

;;; Boundary: presentation is the debug/doctor scalar summary of evalModules.
;; | PooFlowModulePresentationOptions = [MaybeModuleName [AllowedHookId]]
;; pooFlowModuleSystemPresentation
;;   : (-> PooModuleValueCatalog PooFlowModulePresentationOptions POOObject)
;;   | contract: presents POO Flow brand, module counts, and owner boundaries
;;   | doc m%
;;   | # Examples
;;   | ```scheme
;;   | (pooFlowModuleSystemPresentation catalog 'root)
;;   | ```
;;   | result: user-facing presentation object with runtime-executed set to #f.
;; : (-> PooModuleValueCatalog PooFlowModulePresentationOptions POOObject)
(def (poo-flow-module-system-presentation catalog . eval-options)
  (let* ((root-module-id-value
          (if (null? eval-options) #f (car eval-options)))
         (allowed-hook-id-values
          (if (or (null? eval-options)
                  (null? (cdr eval-options)))
            '()
            (cadr eval-options)))
         (root-module
          (poo-flow-module-value-catalog-root catalog root-module-id-value))
         (eval-result
          (cond
           ((null? eval-options)
            (poo-flow-eval-modules catalog))
           ((null? (cdr eval-options))
            (poo-flow-eval-modules catalog root-module-id-value))
           (else
            (poo-flow-eval-modules
             catalog
             root-module-id-value
             allowed-hook-id-values))))
         (runtime-capabilities
          (poo-flow-module-runtime-capability-projection)))
    (object<-alist
     (list
      (cons 'kind poo-flow-module-system-presentation-kind)
      (cons 'catalog-kind (.ref catalog 'kind))
      (cons 'catalog-module-count (length (.ref catalog 'modules)))
      (cons 'root-module-id (poo-flow-module-name root-module))
      (cons 'root-module-kind (.@ root-module kind))
      (cons 'root-import-count (length (poo-flow-module-imports root-module)))
      (cons 'root-flag-count (length (poo-flow-module-flags root-module)))
      (cons 'root-hook-count (length (poo-flow-module-hooks root-module)))
      (cons 'root-extension-count
            (length (poo-flow-module-extensions root-module)))
      (cons 'root-script-count (length (poo-flow-module-scripts root-module)))
      (cons 'allowed-hook-count (length allowed-hook-id-values))
      (cons 'user-entrypoints
            '("poo-flow-modules"
              "poo-flow-module-catalog"
              "poo-flow-module-active?"
              "poo-flow-module-value-catalog-active?"
              "poo-flow-eval-modules"
              "poo-flow-module-system-presentation"))
      (cons 'module-eval-result-kind (.ref eval-result 'kind))
      (cons 'workflow-kind (.ref eval-result 'workflow-kind))
      (cons 'module-evaluation-receipt-kind
            (.ref eval-result 'module-evaluation-kind))
      (cons 'module-count (.ref eval-result 'module-count))
      (cons 'init-module-count (.ref eval-result 'init-module-count))
      (cons 'config-module-count (.ref eval-result 'config-module-count))
      (cons 'hook-count (.ref eval-result 'hook-count))
      (cons 'extension-count (.ref eval-result 'extension-count))
      (cons 'script-count (.ref eval-result 'script-count))
      (cons 'option-count (.ref eval-result 'option-count))
      (cons 'validation-receipt-count
            (.ref eval-result 'validation-receipt-count))
      (cons 'import-graph-owner "poo-flow-module-system")
      (cons 'brand-name poo-flow-brand-name)
      (cons 'brand-group poo-flow-brand-group)
      (cons 'option-policy-owner poo-flow-module-system-owner)
      (cons 'extension-composition-owner poo-flow-module-system-owner)
      (cons 'scheme-owner (.ref eval-result 'scheme-owner))
      (cons 'module-system-owner (.ref eval-result 'module-system-owner))
      (cons 'runtime-owner (.ref eval-result 'runtime-owner))
      (cons 'runtime-boundary-owner (.ref eval-result 'runtime-boundary-owner))
      (cons 'runtime-lifecycle-owner "marlin-agent-core")
      (cons 'runtime-capability-projection-kind
            (.ref runtime-capabilities 'kind))
      (cons 'runtime-object-family-count
            (.ref eval-result 'runtime-object-family-count))
      (cons 'runtime-object-families
            (.ref eval-result 'runtime-object-families))
      (cons 'runtime-snapshot-statuses
            (.ref eval-result 'runtime-snapshot-statuses))
      (cons 'runtime-handoff-contracts
            (.ref eval-result 'runtime-handoff-contracts))
      (cons 'runtime-executed (.ref eval-result 'runtime-executed))
      (cons 'runtime-parses-scheme-source #f)
      (cons 'scheme-manufactures-runtime-handlers #f)
      (cons 'replayable (.ref eval-result 'replayable))))))

;; : (-> PooModuleValueCatalog PooFlowModulePresentationOptions POOObject)
(def (pooFlowModuleSystemPresentation catalog . eval-options)
  (apply poo-flow-module-system-presentation catalog eval-options))
