;;; -*- Gerbil -*-
;;; Boundary: Docker sandbox module objects.

(import :modules/extension
        :modules/objects
        :modules/sandbox-core/objects)

(export poo-flow-docker-sandbox-object
        poo-flow-docker-sandbox-profile-object
        poo-flow-docker-sandbox-module-objects)

;;; Docker sandbox object data records container defaults only; image pulls,
;;; mounts, and process execution remain owned by runtime adapters.
;; : PooModuleObject
(def poo-flow-docker-sandbox-object
  (poo-flow-module-object
   'objects.docker-sandbox.sandbox
   (list poo-flow-shared-sandbox-object)
   (list
    (poo-flow-module-field-contract
     'backend 'Symbol 'override 'docker '((scope . docker-sandbox)))
    (poo-flow-module-field-contract
     'image 'String 'override "ubuntu:latest" '((scope . docker-sandbox))))
   '((namespace . objects.docker-sandbox)
     (domain . sandbox)
     (inherits . objects.shared.sandbox))))

;;; The Docker profile object combines sandbox-core rows with Docker defaults,
;;; so user profile extension remains pure POO merge/remove behavior.
;; : PooModuleObject
(def poo-flow-docker-sandbox-profile-object
  (poo-flow-module-object
   'objects.docker-sandbox.profile
   (list poo-flow-sandbox-core-profile-object
         poo-flow-docker-sandbox-object)
   (list
    (poo-flow-module-field-contract
     'backend-kind 'Symbol 'override 'docker
     '((scope . docker-sandbox) (owned-by . module-config)))
    (poo-flow-module-field-contract
     'backend-ref 'Symbol 'override 'docker-sandbox
     '((scope . docker-sandbox) (owned-by . module-config)))
    (poo-flow-module-field-contract
     'capabilities 'List 'override
     '(process-run filesystem-read filesystem-write tmpdir)
     '((scope . docker-sandbox) (dsl-row . capabilities)))
    (poo-flow-module-field-contract
     'resource-policy 'List 'override '((filesystem . volume))
     '((scope . docker-sandbox) (dsl-row . resources))))
   '((namespace . objects.docker-sandbox)
     (domain . profile)
     (module . docker-sandbox)
     (collection . sandbox.profile)
     (backend-owned-by . use-module)
     (inherits . objects.sandbox-core.profile))))

;;; Object catalogs are inert loader inputs, not module activation effects.
;; : [PooModuleObject]
(def poo-flow-docker-sandbox-module-objects
  (list poo-flow-docker-sandbox-object
        poo-flow-docker-sandbox-profile-object))
