;;; -*- Gerbil -*-
;;; Boundary: Funflow module configuration belongs to the Funflow module owner.
;;; Invariant: this file only declares maintained Funflow module rows.

(import :modules/user-config-base)

(export poo-flow-funflow-cicd-default-payload
        poo-flow-funflow-module-bundles
        poo-upstream-flow-funflow-module-bundles)

;;; The CI/CD payload is a Funflow feature, not a new top-level category. It is
;;; inspectable module data; adapters such as GitHub, Docker, or Nix stay out.
;; : UserModuleFlagEntry
(def poo-flow-funflow-cicd-default-payload
  '(+cicd
    (checks +parallel +typed-receipts)
    (artifacts +export)
    (release +manual-gate)
    (webhook +server)
    (runtime +manifest-handoff)))

;;; The Funflow module is the default functional DAG flow surface.
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
