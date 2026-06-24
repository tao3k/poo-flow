;;; -*- Gerbil -*-
;;; Boundary: focused user-interface loop-engine capability backend checks.
;;; Invariant: capability backends name sandbox modules, never runtime owners.

(import (only-in :std/test
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/facade
        :poo-flow/src/module-system/init-syntax)

(export user-interface-custom-loop-engine-capability-test)

;;; Intent rows stay at the public presentation boundary so this focused owner
;;; validates the same shape Marlin receives through the runtime manifest.
;; | LoopEngineIntentRow = Alist
;; | LoopEngineIntentKey = Symbol
;; : (-> LoopEngineIntentRow LoopEngineIntentKey MaybeValue)
(def (test-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;;; Field extraction keeps capability diagnostics readable while preserving the
;;; raw alist receipt shape used by the runtime handoff.
;; : (-> [Alist] Symbol [Value])
(def (test-field-values rows key)
  (map (lambda (row) (test-ref row key)) rows))

;;; Invalid capability backend fixture protects the sandbox backend contract:
;;; user-facing backend names are sandbox modules, not the Marlin runtime owner.
;; : [PooUserModuleSelection]
(def custom-loop-invalid-capability-module
  (use-module loop-engine
    :config
    (.def (invalid-capability-loop @ loop-engine-use-case name workflow)
      name: 'invalid-capability-loop
      workflow: 'funflow-cicd)

    (.def (invalid-capability-policy @ loop-engine-capability-policy
                                      backend required)
      backend: 'marlin-sandbox
      required: '(command-run))

    (.def (invalid-capability-profile @ loop-engine-profile
                                      use-case capability-policy)
      use-case: invalid-capability-loop
      capability-policy: invalid-capability-policy)))

;;; Presentation construction mirrors downstream use-module config: the test
;;; never calls private loop-engine lowering helpers directly.
;; : (-> [PooUserModuleSelection] POOObject)
(def (custom-loop-presentation module-bundle)
  (pooFlowUserConfigPresentation
   (pooFlowUserConfig
    (poo-flow-user-module-bundles->modules (list module-bundle))
    (poo-flow-settings))))

;;; Capability policy validates backend names as sandbox backends. Marlin is the
;;; runtime owner, not a sandbox backend value.
;; : TestCase
(def user-interface-custom-loop-engine-invalid-capability-case
  (test-case "diagnoses invalid loop-engine capability backend"
    (let* ((presentation
            (custom-loop-presentation custom-loop-invalid-capability-module))
           (intent
            (car (.ref presentation 'loop-engine-intents)))
           (capability-receipt
            (test-ref intent 'capability-receipt))
           (runtime-manifest
            (test-ref intent 'runtime-command-manifest))
           (runtime-manifest-request
            (test-ref runtime-manifest 'request))
           (diagnostics
            (test-ref capability-receipt 'diagnostics)))
      (check-equal? (test-ref capability-receipt 'backend) 'marlin-sandbox)
      (check-equal? (test-ref capability-receipt 'valid?) #f)
      (check-equal? (test-ref capability-receipt 'diagnostic-count) 1)
      (check-equal? (test-field-values diagnostics 'code)
                    '(unsupported-capability-backend))
      (check-equal? (test-ref capability-receipt 'supported-backends)
                    '(nono-sandbox cube-sandbox))
      (check-equal? (test-ref (test-ref runtime-manifest-request
                                         'capability-receipt)
                              'valid?)
                    #f)
      (check-equal? (car (.ref presentation
                            'loop-engine-capability-receipts))
                    capability-receipt)
      (check-equal? (test-ref intent 'runtime-executed) #f))))

;; : TestSuite
(def user-interface-custom-loop-engine-capability-test
  (test-suite "poo-flow custom loop-engine capability policy"
    user-interface-custom-loop-engine-invalid-capability-case))
