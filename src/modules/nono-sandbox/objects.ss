;;; -*- Gerbil -*-
;;; Boundary: nono sandbox module objects.

(import :poo-flow/src/modules/extension
        :poo-flow/src/modules/objects
        :poo-flow/src/modules/sandbox-core/objects)

(export poo-flow-nono-sandbox-object
        poo-flow-nono-sandbox-profile-object
        poo-flow-nono-sandbox-module-objects)

;;; Nono sandbox object data names the backend family and binding defaults; C
;;; binding probes and runtime calls remain in their dedicated owners.
;; : PooModuleObject
(def poo-flow-nono-sandbox-object
  (poo-flow-module-object
   'objects.nono-sandbox.sandbox
   (list poo-flow-shared-sandbox-object)
   (list
    (poo-flow-module-field-contract
     'backend 'Symbol 'override 'nono '((scope . nono-sandbox)))
    (poo-flow-module-field-contract
     'binding 'Symbol 'override 'none '((scope . nono-sandbox))))
   '((namespace . objects.nono-sandbox)
     (domain . sandbox)
     (inherits . objects.shared.sandbox))))

;;; The nono profile object specializes sandbox-core through C3 inheritance, so
;;; legacy nono defaults and shared profile rows merge through one object path.
;; : PooModuleObject
(def poo-flow-nono-sandbox-profile-object
  (poo-flow-module-object
   'objects.nono-sandbox.profile
   (list poo-flow-sandbox-core-profile-object
         poo-flow-nono-sandbox-object)
   (list
    (poo-flow-module-field-contract
     'profile-name 'Symbol 'override 'default
     '((scope . nono-sandbox) (dsl-row . profile-name)))
    (poo-flow-module-field-contract
     'backend-kind 'Symbol 'override 'nono
     '((scope . nono-sandbox) (owned-by . module-config)))
    (poo-flow-module-field-contract
     'backend-ref 'Symbol 'override 'nono-sandbox
     '((scope . nono-sandbox) (owned-by . module-config)))
    (poo-flow-module-field-contract
     'network-policy 'List 'override '(deny-by-default)
     '((scope . nono-sandbox) (dsl-row . network)))
    (poo-flow-module-field-contract
     'capabilities 'List 'override '(process filesystem tmpdir)
     '((scope . nono-sandbox) (dsl-row . capabilities)))
    (poo-flow-module-field-contract
     'resource-policy 'List 'override '((filesystem . scoped))
     '((scope . nono-sandbox) (dsl-row . resources)))
    (poo-flow-module-field-contract
     'metadata 'List 'append '()
     '((scope . nono-sandbox) (dsl-row . metadata))))
   '((namespace . objects.nono-sandbox)
     (domain . profile)
     (module . nono-sandbox)
     (collection . sandbox.profile)
     (backend-owned-by . use-module)
     (inherits . objects.nono-sandbox.sandbox))))

;;; Object catalogs are validation and loader inputs; they do not load bindings.
;; : [PooModuleObject]
(def poo-flow-nono-sandbox-module-objects
  (list poo-flow-nono-sandbox-object
        poo-flow-nono-sandbox-profile-object))
