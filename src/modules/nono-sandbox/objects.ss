;;; -*- Gerbil -*-
;;; Boundary: nono sandbox module objects.

(import :modules/extension
        :modules/objects)

(export poo-flow-nono-sandbox-object
        poo-flow-nono-sandbox-module-objects)

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

(def poo-flow-nono-sandbox-module-objects
  (list poo-flow-nono-sandbox-object))
