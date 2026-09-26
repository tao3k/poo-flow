;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: construct values from prototypes owned by explicit Type declarations.
(import (only-in :clan/poo/object .o .mix .ref)
        (only-in :clan/poo/mop validate)
        "types.ss")
(export SemanticModule. SemanticImports. ModuleSourceRole.
        ModuleAuthoringProfile. ModuleAuthoringExecutor.
        TypesSourceRole. ObjectsSourceRole. FunsSourceRole.
        ConfigSourceRole. UserConfigSourceRole.
        InterfaceSourceRole. ImportContribution.
        SemanticModuleContract ModuleIdentityContract ModuleImportsContract
        ModuleProfilesContract ModuleCapabilitiesContract
        ModuleSourceRoleContract ModuleAuthoringProfileContract
        ImportContributionContract
        poo-flow-semantic-identity poo-flow-semantic-module
        poo-flow-empty-imports poo-flow-empty-capabilities poo-flow-empty-profiles
        poo-flow-default-module-authoring-profile
        poo-flow-user-root-module-authoring-profile
        poo-flow-import-contribution poo-flow-module-imports)

(def SemanticModule. (.ref SemanticModuleContract 'proto))
(def SemanticImports. (.ref ModuleImportsContract 'proto))
(def SemanticProfiles. (.ref ModuleProfilesContract 'proto))
(def SemanticCapabilities. (.ref ModuleCapabilitiesContract 'proto))
(def ModuleIdentity. (.ref ModuleIdentityContract 'proto))
(def ModuleSourceRole. (.ref ModuleSourceRoleContract 'proto))
(def ModuleAuthoringProfile. (.ref ModuleAuthoringProfileContract 'proto))
(def ImportContribution. (.ref ImportContributionContract 'proto))
(def CapabilityResponsibilities.
  (.ref ModuleCapabilitiesContract 'responsibilities))
(def CapabilityRequirements.
  (.ref (.ref CapabilityResponsibilities. 'requirements) 'proto))
(def CapabilityProvisions.
  (.ref (.ref CapabilityResponsibilities. 'provisions) 'proto))

;;; The executor stays a native POO prototype.  CLOS specializes it through
;;; the explicit prototype bridge rather than requiring a duplicate class.
(def ModuleAuthoringExecutor.
  (.o identity: 'module-authoring/default-executor))

;; : (-> Symbol [Symbol] [Symbol] [Symbol] Symbol PooModuleSourceRole)
(def (poo-flow-module-source-role identity-value recommended-forms-value
                                  forbidden-slot-verbs-value
                                  forbidden-root-forms-value freedom-value)
  (validate ModuleSourceRoleContract
    (.o (:: @ ModuleSourceRole.)
        identity: identity-value
        recommended-forms: recommended-forms-value
        forbidden-slot-verbs: forbidden-slot-verbs-value
        forbidden-root-forms: forbidden-root-forms-value
        recursive-root-forms?: #f
        forbidden-imports: '()
        forbidden-forms: '()
        forbid-raw-behavior-hooks?: #f
        forbid-raw-query-initializers?: #t
        repair-operators: '(? => =>.+ override)
        freedom: freedom-value)))

;;; Role Profiles state the default engineering envelope.  They intentionally
;;; admit ordinary Scheme helpers; the Contract rejects only competing public
;;; semantics, leaving algorithms and domain behavior open to the module owner.
(def TypesSourceRole.
  (poo-flow-module-source-role
   'types '(define-type def defstruct) '(add remove replace delete) '()
   'open-with-boundary-contracts))
(def ObjectsSourceRole.
  (poo-flow-module-source-role
   'objects '(.def .o .defgeneric defmethod) '(add remove replace delete) '()
   'open-native-poo))
(def FunsSourceRole.
  (poo-flow-module-source-role
   'funs '(def lambda) '(add remove replace delete) '()
   'open-pure-functions))
(def ConfigSourceRole.
  (poo-flow-module-source-role
   'config '(.def .o user-composition use-module)
   '(add remove replace delete)
   '(stage graph loop prove handoff provider runtime)
   'composition-only))

;;; The ordinary user root is deliberately narrower than a maintained module's
;;; config.ss.  It selects maintained values and never reopens the advanced
;;; POO object layer; vertical owners retain that layer in their own Profiles.
(def UserConfigSourceRole.
  (validate ModuleSourceRoleContract
    (.o (:: @ ConfigSourceRole.)
        identity: 'user-config
        recommended-forms: '(user-composition compose use-module)
        forbidden-root-forms:
        '(.def .o stage graph loop prove handoff provider runtime)
        recursive-root-forms?: #t
        forbidden-imports:
        '(:clan/poo/mop
          :core/poo-clos/interface)
        forbidden-forms:
        '(poo-clos-class
          poo-clos-generic-function
          poo-clos-method
          poo-clos-method-bundle
          .defmethod-bundle)
        forbid-raw-behavior-hooks?: #t
        forbid-raw-query-initializers?: #t
        freedom: 'maintained-value-composition-only)))
(def InterfaceSourceRole.
  (poo-flow-module-source-role
   'interface '(import export) '(add remove replace delete) '()
   'reexport-only))

;; : (-> Symbol Symbol ModuleIdentity)
(def (poo-flow-semantic-identity namespace-value name-value)
  (validate ModuleIdentityContract
    (.o (:: @ ModuleIdentity.)
        namespace: namespace-value name: name-value)))

(def (poo-flow-empty-imports) (.mix SemanticImports.))
(def (poo-flow-empty-profiles) (.mix SemanticProfiles.))
(def (poo-flow-empty-capabilities)
  (.o (:: @ SemanticCapabilities.)
      requirements: (.mix CapabilityRequirements.)
      provisions: (.mix CapabilityProvisions.)))

(def (poo-flow-default-module-authoring-profile)
  (validate ModuleAuthoringProfileContract
    (.o (:: @ ModuleAuthoringProfile.)
        executor: (.mix ModuleAuthoringExecutor.)
        types: TypesSourceRole.
        objects: ObjectsSourceRole.
        funs: FunsSourceRole.
        config: ConfigSourceRole.
        interface: InterfaceSourceRole.)))

(def (poo-flow-user-root-module-authoring-profile)
  (validate ModuleAuthoringProfileContract
    (.o (:: @ (poo-flow-default-module-authoring-profile))
        config: UserConfigSourceRole.)))

;; : (-> ModuleIdentity imports: ModuleImports capabilities: ModuleCapabilities profiles: ModuleProfiles authoring: ModuleAuthoringProfile SemanticModule)
(def (poo-flow-semantic-module identity-value
                             imports: (imports-value (poo-flow-empty-imports))
                             capabilities: (capabilities-value (poo-flow-empty-capabilities))
                             profiles: (profiles-value (poo-flow-empty-profiles))
                             authoring: (authoring-value
                                         (poo-flow-default-module-authoring-profile)))
  (validate SemanticModuleContract
    (.o (:: @ SemanticModule.) identity: identity-value imports: imports-value
        capabilities: capabilities-value profiles: profiles-value
        authoring: authoring-value)))

;; : (-> ModuleIdentity ModuleIdentity ModuleIdentity ModuleIdentity Symbol Object ImportContribution)
(def (poo-flow-import-contribution identity-value owner-value instance-value source-value revision-value target-value)
  (validate ImportContributionContract
    (.o (:: @ ImportContribution.) identity: identity-value owner: owner-value instance: instance-value
        source: source-value revision: revision-value target: target-value)))

;; : (-> ImportContribution ... ModuleImports)
(def (poo-flow-module-imports . contribution-values)
  (.o (:: @ SemanticImports.) contributions: contribution-values))
