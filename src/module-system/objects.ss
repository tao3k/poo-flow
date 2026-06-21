;;; -*- Gerbil -*-
;;; Boundary: shared module objects available to every module namespace.

(import :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/object-validation)

(export (import: :poo-flow/src/module-system/object-core)
        (import: :poo-flow/src/module-system/object-validation)
        poo-flow-shared-sandbox-object
        poo-flow-shared-module-objects)

(def poo-flow-shared-sandbox-object
  (poo-flow-module-object
   'objects.shared.sandbox
   '()
   (list
    (poo-flow-module-field-contract
     'backend 'Symbol 'override 'sandbox '((scope . shared)))
    (poo-flow-module-field-contract
     'flags 'List 'append '() '((scope . shared)))
    (poo-flow-module-field-contract
     'runtime-args 'List 'append '() '((scope . shared))))
   '((namespace . objects.shared)
     (domain . sandbox))))

(def poo-flow-shared-module-objects
  (poo-flow-require-module-objects-validation!
   (list poo-flow-shared-sandbox-object)))
