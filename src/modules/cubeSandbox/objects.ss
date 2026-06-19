;;; -*- Gerbil -*-
;;; Boundary: CubeSandbox module objects.

(import :modules/extension
        :modules/objects)

(export poo-flow-cubeSandbox-object
        poo-flow-cubeSandbox-module-objects)

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

(def poo-flow-cubeSandbox-module-objects
  (list poo-flow-cubeSandbox-object))
