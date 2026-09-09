;;; -*- Gerbil -*-
;;; Boundary: construct values from prototypes owned by explicit Type declarations.
(import (only-in :clan/poo/object .o .mix .ref)
        (only-in :clan/poo/mop validate)
        "types.ss")
(export SemanticModule. SemanticImports. ImportContribution.
        SemanticModuleContract ModuleIdentityContract ModuleImportsContract
        ModuleProfilesContract ModuleCapabilitiesContract ImportContributionContract
        poo-flow-semantic-identity poo-flow-semantic-module
        poo-flow-empty-imports poo-flow-empty-capabilities poo-flow-empty-profiles
        poo-flow-import-contribution poo-flow-module-imports)

(def SemanticModule. (.ref SemanticModuleContract 'proto))
(def SemanticImports. (.ref ModuleImportsContract 'proto))
(def SemanticProfiles. (.ref ModuleProfilesContract 'proto))
(def SemanticCapabilities. (.ref ModuleCapabilitiesContract 'proto))
(def ModuleIdentity. (.ref ModuleIdentityContract 'proto))
(def ImportContribution. (.ref ImportContributionContract 'proto))
(def CapabilityResponsibilities.
  (.ref ModuleCapabilitiesContract 'responsibilities))
(def CapabilityRequirements.
  (.ref (.ref CapabilityResponsibilities. 'requirements) 'proto))
(def CapabilityProvisions.
  (.ref (.ref CapabilityResponsibilities. 'provisions) 'proto))

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

;; : (-> ModuleIdentity imports: ModuleImports capabilities: ModuleCapabilities profiles: ModuleProfiles SemanticModule)
(def (poo-flow-semantic-module identity-value
                             imports: (imports-value (poo-flow-empty-imports))
                             capabilities: (capabilities-value (poo-flow-empty-capabilities))
                             profiles: (profiles-value (poo-flow-empty-profiles)))
  (validate SemanticModuleContract
    (.o (:: @ SemanticModule.) identity: identity-value imports: imports-value
        capabilities: capabilities-value profiles: profiles-value)))

;; : (-> ModuleIdentity ModuleIdentity ModuleIdentity ModuleIdentity Symbol Object ImportContribution)
(def (poo-flow-import-contribution identity-value owner-value instance-value source-value revision-value target-value)
  (validate ImportContributionContract
    (.o (:: @ ImportContribution.) identity: identity-value owner: owner-value instance: instance-value
        source: source-value revision: revision-value target: target-value)))

;; : (-> ImportContribution ... ModuleImports)
(def (poo-flow-module-imports . contribution-values)
  (.o (:: @ SemanticImports.) contributions: contribution-values))
