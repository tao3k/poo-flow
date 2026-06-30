;;; -*- Gerbil -*-
;;; Boundary: hygienic macros for repeated sandbox backend module object families.
;;; Invariant: macros expand to ordinary POO module objects and field contracts.

(import :poo-flow/src/module-system/object-core
        :poo-flow/src/module-system/objects
        :poo-flow/src/modules/sandbox-core/objects)

(export defpoo-sandbox-backend-object-family)

;; defpoo-sandbox-backend-object-family
;;   : (-> Identifier Identifier Identifier Identifier Identifier Syntax ...)
;;   | doc m%
;;       Internal macro family generator for sandbox backend object modules.
;;       The call site still names every exported binding, identity, slot, and
;;       contract value; the macro removes only the repeated POO construction
;;       frame shared by nono, CubeSandbox, and Docker backend modules.
;;
;;       The generated code is normal =poo-flow-module-object= and
;;       =poo-flow-module-field-contract= data. It is not a user-facing DSL.
;;     %
(defrules defpoo-sandbox-backend-object-family
  (sandbox backend profile)
  ((_ sandbox-object
      backend-capability
      backend-capability-registry
      profile-object
      module-objects
      (sandbox sandbox-identity namespace-value sandbox-inherits-value
       ((sandbox-field sandbox-type sandbox-merge sandbox-default sandbox-metadata)
        ...))
      (backend backend-key capability-value registry-metadata)
      (profile profile-identity module-value profile-inherits-value
       (profile-super ...)
       ((profile-field profile-type profile-merge profile-default profile-metadata)
        ...)))
   (begin
     (def sandbox-object
       (poo-flow-module-object
        'sandbox-identity
        (list poo-flow-shared-sandbox-object)
        (list
         (poo-flow-module-field-contract
          'sandbox-field 'sandbox-type 'sandbox-merge
          sandbox-default
          sandbox-metadata)
         ...)
        '((namespace . namespace-value)
          (domain . sandbox)
          (inherits . sandbox-inherits-value))))

     (def backend-capability
       capability-value)

     (def backend-capability-registry
       (poo-flow-sandbox-backend-capability-registry
        (list (cons 'backend-key backend-capability))
        registry-metadata))

     (def profile-object
       (poo-flow-module-object
        'profile-identity
        (list profile-super ...)
        (list
         (poo-flow-module-field-contract
          'profile-field 'profile-type 'profile-merge
          profile-default
          profile-metadata)
         ...)
        '((namespace . namespace-value)
          (domain . profile)
          (module . module-value)
          (collection . sandbox.profile)
          (backend-owned-by . use-module)
          (inherits . profile-inherits-value))))

     (def module-objects
       (list sandbox-object profile-object)))))
