;;; -*- Gerbil -*-
;;; Boundary: upstream POO objects for downstream user-interface declarations.
;;; Invariant: root user-interface files never own object contracts.

(import :poo-flow/src/modules/object-core
        :poo-flow/src/modules/objects)

(export poo-flow-user-interface-shared-sandbox-object
        poo-flow-user-interface-root-module-objects)

(def poo-flow-user-interface-shared-sandbox-object
  (poo-flow-module-object
   'objects.user-interface.shared.sandbox
   (list poo-flow-shared-sandbox-object)
   (list
    (poo-flow-module-field-contract
     'flags 'List 'append '(doctor) '((scope . user-interface))))
   '((namespace . objects.user-interface)
     (domain . sandbox)
     (inherits . objects.shared.sandbox))))

(def poo-flow-user-interface-root-module-objects
  (list poo-flow-user-interface-shared-sandbox-object))
