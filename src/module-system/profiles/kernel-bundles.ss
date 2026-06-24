;;; -*- Gerbil -*-
;;; Boundary: light kernel module selection rows.
;;; Invariant: this owner contains selection data only, not module config logic.

(import (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-bundle
                 poo-flow-user-module-selection))

(export poo-flow-funflow-cicd-default-payload
        poo-flow-funflow-module-bundles
        poo-upstream-flow-funflow-module-bundles
        +poo-flow-session-core-default-flags+
        poo-flow-session-core-module-bundles
        poo-flow-loop-governor-module-bundles
        poo-flow-nono-sandbox-module-bundles
        poo-flow-cubeSandbox-module-bundles
        poo-flow-docker-sandbox-module-bundles)

;; : UserModuleFlagEntry
(def poo-flow-funflow-cicd-default-payload
  '(+cicd
    (checks +parallel +typed-receipts)
    (artifacts +export)
    (release +manual-gate)
    (webhook +server)
    (runtime +manifest-handoff)))

;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-funflow-module-bundles
  (list
   (list
    (poo-flow-user-module-selection
     'flow
     'funflow
     (list '+functional
           '+dag
           '+typed-receipts
           '+runtime-manifest
           poo-flow-funflow-cicd-default-payload)))))

;; : (-> Unit [[PooUserModuleSelection]])
(def poo-upstream-flow-funflow-module-bundles
  poo-flow-funflow-module-bundles)

;; : [Symbol]
(def +poo-flow-session-core-default-flags+
  '(+lineage +placement +handoff +graph +transform +doctor))

;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-session-core-module-bundles
  (list
   (poo-flow-user-module-bundle
    (session session-core
             +lineage
             +placement
             +handoff
             +graph
             +transform
             +doctor))))

;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-loop-governor-module-bundles
  (list
   (poo-flow-user-module-bundle
    (loop governor +strategy +policy +marlin-handoff +runtime-manifest
          +l1-report))))

;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-nono-sandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox nono-sandbox +nono +native-ffi +doctor))))

;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-cubeSandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox cubeSandbox +cube +doctor))))

;; : (-> Unit [[PooUserModuleSelection]])
(def poo-flow-docker-sandbox-module-bundles
  (list
   (poo-flow-user-module-bundle
    (sandbox docker-sandbox +docker +doctor))))
