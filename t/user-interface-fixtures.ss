;;; -*- Gerbil -*-
;;; Boundary: shared fixtures for root user-interface tests.
;;; Invariant: fixtures are declarative data and never realize descriptors.

(import (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        :poo-flow/src/module-system/profiles/kernel)

(export test-poo-flow-user-module-bundles
        test-poo-flow-user-modules
        test-poo-flow-user-custom-module-bundles
        test-poo-flow-user-custom-profile
        test-poo-flow-user-profile
        test-poo-flow-user-broken-profile
        test-poo-flow-user-profile-set
        test-poo-flow-user-broken-profile-set
        test-poo-flow-user-settings
        test-poo-flow-user-config
        alist-value
        diagnostic-code-member?)

;; : (-> Unit [[PooUserModuleSelection]])
(def test-poo-flow-user-module-bundles
  (poo-flow-user-module-bundles-extend
   poo-flow-kernel-profile-module-bundles
   (list
    (use-module loop-engine
      :config
      (.def (test-loop @ loop-engine-use-case name)
        name: 'test-loop)

      (.def (test-loop-governor @ loop-engine-governor capabilities)
        capabilities: '(+strategy +policy))

      (.def (test-loop-judges @ loop-engine-agent-judges
                              auditor verifier governor)
        auditor: 'repo-audit-agent
        verifier: 'repo-verifier-agent
        governor: 'repo-governor)

      (.def (test-loop-human-audit @ loop-engine-human-audit actions)
        actions: '(+approval +changes-requested))

      (.def (test-loop-runtime @ loop-engine-runtime capabilities)
        capabilities: '(+manifest-handoff))

      (.def (test-loop-profile @ loop-engine-profile
                               use-case governor agent-judges
                               human-audit runtime)
        use-case: test-loop
        governor: test-loop-governor
        agent-judges: test-loop-judges
        human-audit: test-loop-human-audit
        runtime: test-loop-runtime)))))

;; : (-> Unit [PooUserModuleSelection])
(def test-poo-flow-user-modules
  (poo-flow-user-module-bundles->modules test-poo-flow-user-module-bundles))

;; : (-> Unit [[PooUserModuleSelection]])
(def test-poo-flow-user-custom-module-bundles
  (poo-flow-custom-module-bundles
   (my-module "./custom/my-module" +private +doctor)))

;; : (-> Unit PooUserProfile)
(def test-poo-flow-user-custom-profile
  (pooFlowUserProfileExtend
   'custom-developer
   poo-flow-kernel-profile
   test-poo-flow-user-custom-module-bundles))

;; : (-> Unit PooUserProfile)
(def test-poo-flow-user-profile
  (pooFlowUserProfile
   'developer
   test-poo-flow-user-module-bundles
   (pooFlowDefaultUserSettings 'developer)
   poo-flow-default-user-setting-keys))

;; : (-> Unit PooUserProfile)
(def test-poo-flow-user-broken-profile
  (poo-flow-profile broken
   (modules
    (poo-flow-user-module-bundle
     (flow workflow +typed-receipts)
     (flow workflow +duplicate))
    (poo-flow-user-module-when #f
     (sandbox cubeSandbox +doctor)))
   (settings
    surface: "poo-flow")
   (setting-keys
    surface
    missing-key)))

;; : (-> Unit PooUserProfileSet)
(def test-poo-flow-user-profile-set
  (poo-flow-profile-set workspace
   (default developer)
   (profiles
    test-poo-flow-user-profile
    test-poo-flow-user-custom-profile)))

;; : (-> Unit PooUserProfileSet)
(def test-poo-flow-user-broken-profile-set
  (poo-flow-profile-set broken-workspace
   (default missing)
   (profiles
    test-poo-flow-user-profile
    test-poo-flow-user-profile)))

;; : (-> Unit POOObject)
(def test-poo-flow-user-settings
  (poo-flow-user-profile-settings test-poo-flow-user-profile))

;; : (-> Unit PooUserConfig)
(def test-poo-flow-user-config
  (pooFlowUserConfigFromProfile test-poo-flow-user-profile))

;; : (-> UserInterfaceEntry Alist MaybeValue)
(def (alist-value key entries)
  (cond
   ((null? entries) #f)
   ((equal? key (caar entries)) (cdar entries))
   (else
    (alist-value key (cdr entries)))))

;; : (-> Symbol [Alist] Boolean)
(def (diagnostic-code-member? code diagnostics)
  (cond
   ((null? diagnostics) #f)
   ((equal? code (alist-value 'code (car diagnostics))) #t)
   (else
    (diagnostic-code-member? code (cdr diagnostics)))))
