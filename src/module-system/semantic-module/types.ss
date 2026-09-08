;;; -*- Gerbil -*-
;;; Boundary: explicit native type declarations for Module responsibilities.
(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop define-type)
        (only-in "../types.ss"
                 PooFlowContract. PooFlowNativeObjectContract.
                 poo-flow-classification-evidence))
(export ModuleIdentityContract ModuleImportsContract ModuleProfilesContract
        ModuleCapabilitiesContract SemanticModuleContract ImportContributionContract)

;; : (-> Object Object PooFlowClassificationEvidence)
(def (semantic-symbol-classify candidate context)
  (poo-flow-classification-evidence
   'semantic-symbol candidate (symbol? candidate)
   (if (symbol? candidate) '() '(expected-symbol)) context))

;;; Invariant: module identities use symbols so equality and projection remain canonical.
(define-type (SemanticSymbol @ PooFlowContract.)
  identity: 'semantic-symbol
  .classify: semantic-symbol-classify)

;;; Boundary: identity owns exactly the namespace/name pair used by module lookup.
(define-type (ModuleIdentityContract @ PooFlowNativeObjectContract.)
  identity: 'module-identity
  proto: (.o)
  responsibilities: (.o namespace: SemanticSymbol name: SemanticSymbol))

;;; Each relation has its own native ancestry and fresh instances.
;;; Lazy contributions are admitted at evaluation, not at Module construction.
(define-type (ModuleImportsContract @ PooFlowNativeObjectContract.)
  identity: 'module-imports
  proto: (.o contributions: '())
  responsibilities: (.o))

;;; Invariant: profile contributions have an ancestry distinct from import contributions.
(define-type (ModuleProfilesContract @ PooFlowNativeObjectContract.)
  identity: 'module-profiles
  proto: (.o contributions: '())
  responsibilities: (.o))

;;; Invariant: requirements and provisions cannot alias through a shared prototype.
(define-type (CapabilityRequirementsContract @ PooFlowNativeObjectContract.)
  identity: 'capability-requirements
  proto: (.o contributions: '())
  responsibilities: (.o))

;;; Invariant: provision contributions remain independently extensible POO values.
(define-type (CapabilityProvisionsContract @ PooFlowNativeObjectContract.)
  identity: 'capability-provisions
  proto: (.o contributions: '())
  responsibilities: (.o))

;;; Boundary: the capability contract binds the two directional relations explicitly.
(define-type (ModuleCapabilitiesContract @ PooFlowNativeObjectContract.)
  identity: 'module-capabilities
  proto: (.o)
  responsibilities: (.o requirements: CapabilityRequirementsContract
                        provisions: CapabilityProvisionsContract))

;;; Invariant: a semantic module is admitted only through all four native responsibilities.
(define-type (SemanticModuleContract @ PooFlowNativeObjectContract.)
  identity: 'semantic-module
  proto: (.o)
  responsibilities: (.o identity: ModuleIdentityContract
                        imports: ModuleImportsContract
                        capabilities: ModuleCapabilitiesContract
                        profiles: ModuleProfilesContract))

;;; Boundary: an import contribution preserves every identity hop and its revision witness.
(define-type (ImportContributionContract @ PooFlowNativeObjectContract.)
  identity: 'import-contribution
  proto: (.o)
  responsibilities: (.o identity: ModuleIdentityContract owner: ModuleIdentityContract
                        instance: ModuleIdentityContract source: ModuleIdentityContract
                        revision: SemanticSymbol))
