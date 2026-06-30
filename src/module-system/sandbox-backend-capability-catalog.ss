;;; -*- Gerbil -*-
;;; Boundary: backend capability registry extraction for module-system projections.
;;; Invariant: catalog helpers read user module selections but never probe runtimes.

(import :poo-flow/src/module-system/base
        (only-in :poo-flow/src/modules/sandbox-core/profile-support/policy
                 poo-flow-sandbox-backend-capability-registry/sandbox-core
                 poo-flow-sandbox-backend-capability-registry-merge
                 poo-flow-sandbox-backend-capability-registry-ref
                 poo-flow-sandbox-backend-capability-registries-validation)
        (only-in :poo-flow/src/modules/nono-sandbox/objects
                 poo-flow-nono-sandbox-backend-capability-registry)
        (only-in :poo-flow/src/modules/docker-sandbox/objects
                 poo-flow-docker-sandbox-backend-capability-registry)
        (only-in :poo-flow/src/modules/cubeSandbox/objects
                 poo-flow-cubeSandbox-backend-capability-registry))

(export poo-flow-user-module-selection-sandbox-backend-capability-registry
        poo-flow-user-config-sandbox-backend-capability-registries/add
        poo-flow-user-config-sandbox-backend-capability-registries
        poo-flow-user-config-sandbox-backend-capability-registry/add
        poo-flow-user-config-sandbox-backend-capability-registry
        poo-flow-user-config-sandbox-backend-capability-registry-validation
        poo-flow-user-config-sandbox-backend-capability)

;;; User selections are the module-system input. They select backend capability
;;; contribution objects, not runtime adapters or package descriptors.
;; : (-> PooUserModuleSelection MaybePooSandboxBackendCapabilityRegistry)
(def (poo-flow-user-module-selection-sandbox-backend-capability-registry
      selection)
  (let (key (poo-flow-user-module-selection-key selection))
    (cond
     ((equal? key (cons 'sandbox 'nono-sandbox))
      poo-flow-nono-sandbox-backend-capability-registry)
     ((equal? key (cons 'sandbox 'docker-sandbox))
      poo-flow-docker-sandbox-backend-capability-registry)
     ((equal? key (cons 'sandbox 'cubeSandbox))
      poo-flow-cubeSandbox-backend-capability-registry)
     (else #f))))

;;; Keep the contribution list as a first-class evidence surface so validation
;;; can report duplicate ids before registry merge overwrites later entries.
;; : (-> [PooUserModuleSelection] [PooSandboxBackendCapabilityRegistry])
(def (poo-flow-user-config-sandbox-backend-capability-registries/add selected)
  (cond
   ((null? selected) '())
   ((poo-flow-user-module-selection-sandbox-backend-capability-registry
     (car selected))
    => (lambda (registry)
         (cons registry
               (poo-flow-user-config-sandbox-backend-capability-registries/add
                (cdr selected)))))
   (else
    (poo-flow-user-config-sandbox-backend-capability-registries/add
     (cdr selected)))))

;; : (-> [PooUserModuleSelection] [PooSandboxBackendCapabilityRegistry])
(def (poo-flow-user-config-sandbox-backend-capability-registries selected)
  (cons poo-flow-sandbox-backend-capability-registry/sandbox-core
        (poo-flow-user-config-sandbox-backend-capability-registries/add
         selected)))

;;; Merge selected backend capability registries in declaration order. The base
;;; registry contributes only sandbox-core so disabled backend modules do not
;;; become part of the selected module-system registry.
;; : (-> PooSandboxBackendCapabilityRegistry [PooUserModuleSelection] PooSandboxBackendCapabilityRegistry)
(def (poo-flow-user-config-sandbox-backend-capability-registry/add registry
                                                                   selected)
  (cond
   ((null? selected) registry)
   ((poo-flow-user-module-selection-sandbox-backend-capability-registry
     (car selected))
    => (lambda (extension)
         (poo-flow-user-config-sandbox-backend-capability-registry/add
          (poo-flow-sandbox-backend-capability-registry-merge
           registry
           extension)
          (cdr selected))))
   (else
    (poo-flow-user-config-sandbox-backend-capability-registry/add
     registry
     (cdr selected)))))

;; : (-> [PooUserModuleSelection] PooSandboxBackendCapabilityRegistry)
(def (poo-flow-user-config-sandbox-backend-capability-registry selected)
  (poo-flow-user-config-sandbox-backend-capability-registry/add
   poo-flow-sandbox-backend-capability-registry/sandbox-core
   selected))

;; : (-> [PooUserModuleSelection] PooSandboxBackendCapabilityRegistryValidation)
(def (poo-flow-user-config-sandbox-backend-capability-registry-validation
      selected)
  (poo-flow-sandbox-backend-capability-registries-validation
   (poo-flow-user-config-sandbox-backend-capability-registries selected)))

;; : (-> [PooUserModuleSelection] Symbol PooSandboxBackendCapability)
(def (poo-flow-user-config-sandbox-backend-capability selected backend-kind)
  (poo-flow-sandbox-backend-capability-registry-ref
   (poo-flow-user-config-sandbox-backend-capability-registry selected)
   backend-kind))
