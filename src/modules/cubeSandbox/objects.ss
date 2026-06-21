;;; -*- Gerbil -*-
;;; Boundary: CubeSandbox module objects.

(import :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/objects
        :poo-flow/src/modules/sandbox-core/objects)

(export poo-flow-cubeSandbox-object
        poo-flow-cubeSandbox-profile-object
        poo-flow-cubeSandbox-module-objects)

;;; CubeSandbox object data names backend defaults only; adapter execution and
;;; snapshot materialization stay outside this module.
;; : PooModuleObject
(def poo-flow-cubeSandbox-object
  (poo-flow-module-object
   'objects.cubeSandbox.sandbox
   (list poo-flow-shared-sandbox-object)
   (list
    (poo-flow-module-field-contract
     'backend 'Symbol 'override 'cube '((scope . cubeSandbox)))
    (poo-flow-module-field-contract
     'profile 'Symbol 'override 'default '((scope . cubeSandbox))))
   '((namespace . objects.cubeSandbox)
     (domain . sandbox)
     (inherits . objects.shared.sandbox))))

;;; The profile object uses C3 inheritance from sandbox-core plus CubeSandbox
;;; backend defaults, letting user rows override only declared slots.
;; : PooModuleObject
(def poo-flow-cubeSandbox-profile-object
  (poo-flow-module-object
   'objects.cubeSandbox.profile
   (list poo-flow-sandbox-core-profile-object
         poo-flow-cubeSandbox-object)
   (list
    (poo-flow-module-field-contract
     'backend-kind 'Symbol 'override 'cube
     '((scope . cubeSandbox) (owned-by . module-config)))
    (poo-flow-module-field-contract
     'backend-ref 'Symbol 'override 'cubeSandbox
     '((scope . cubeSandbox) (owned-by . module-config)))
    (poo-flow-module-field-contract
     'capabilities 'List 'override '(process-run filesystem-read cache-mount)
     '((scope . cubeSandbox) (dsl-row . capabilities)))
    (poo-flow-module-field-contract
     'resource-policy 'List 'override
     '((filesystem
        (scope . snapshot)
        (snapshot . clone)))
     '((scope . cubeSandbox) (dsl-row . resources))))
   '((namespace . objects.cubeSandbox)
     (domain . profile)
     (module . cubeSandbox)
     (collection . sandbox.profile)
     (backend-owned-by . use-module)
     (inherits . objects.sandbox-core.profile))))

;;; Object catalogs are loader data for validation and auto-import planning.
;; : [PooModuleObject]
(def poo-flow-cubeSandbox-module-objects
  (poo-flow-require-module-objects-validation!
   (list poo-flow-cubeSandbox-object
         poo-flow-cubeSandbox-profile-object)))
