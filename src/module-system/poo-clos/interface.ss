;;; -*- Gerbil -*-
;;; Public POO-native CLOS facade.  Syntax declarations are a later factor.

(import "types.ss" "objects.ss" "generic-evolution.ss" "classes.ss"
        "evolution.ss" "lifecycle.ss" "reflection.ss" "dispatch.ss"
        "load-form.ss" "mop.ss" "syntax.ss")

(export ClosSpecializer ClosLambdaList ClosMethod ClosMethodGroup
        ClosMethodCombination
        ClosGenericProtocol ClosGenericFunction ClosGenericBinding ClosEffectiveMethod
        ClosInvocationFrame ClosFailure ClosUnboundSlotFailure
        ClosDirectSlotDefinition
        ClosEffectiveSlotDefinition ClosClass ClosInstanceState ClosSlotCell
        ClosMopProfile
        poo-clos-any-specializer poo-clos-class-specializer
        poo-clos-eql-specializer poo-clos-method poo-clos-generic-function
        poo-clos-add-method poo-clos-remove-method poo-clos-failure?
        poo-clos-unbound-slot? poo-clos-unbound-slot-instance
        poo-clos-lambda-list poo-clos-lambda-lists-congruent?
        poo-clos-standard-method-combination
        poo-clos-built-in-method-combination
        poo-clos-short-method-combination
        poo-clos-method-group
        poo-clos-long-method-combination
        poo-clos-configure-method-combination
        poo-clos-resolve-method-combination
        poo-clos-method-combination-admits-qualifier?
        poo-clos-generic-protocol poo-clos-default-generic-protocol
        poo-clos-generic-binding poo-clos-generic-binding-current
        poo-clos-generic-binding-add-method!
        poo-clos-register-generic-function! poo-clos-find-generic-function
        poo-clos-ensure-generic-function
        poo-clos-reinitialize-generic-function!
        poo-clos-compute-applicable-methods poo-clos-call
        poo-clos-compute-effective-method
        poo-clos-no-applicable-method poo-clos-no-next-method
        poo-clos-no-applicable-method-generic
        poo-clos-no-next-method-generic
        poo-clos-effective-method-group poo-clos-call-method
        poo-clos-make-method
        poo-clos-call-next-method poo-clos-next-method?
        poo-clos-funcall poo-clos-setf
        poo-clos-make-load-form poo-clos-make-load-form-generic
        poo-clos-make-load-form-saving-slots
        poo-clos-standard-object-class poo-clos-direct-slot-definition
        poo-clos-class poo-clos-class-precedence-list
        poo-clos-find-class poo-clos-set-find-class! poo-clos-resolve-class
        poo-clos-class-effective-slots poo-clos-find-effective-slot
        poo-clos-class-subclass? poo-clos-current-class
        poo-clos-redefine-class poo-clos-make-instances-obsolete
        poo-clos-instance? poo-clos-class-of
        poo-clos-allocate-instance poo-clos-make-instance
        poo-clos-initialize-instance poo-clos-shared-initialize
        poo-clos-reinitialize-instance poo-clos-slot-value
        poo-clos-set-slot-value! poo-clos-slot-bound? poo-clos-slot-exists?
        poo-clos-slot-missing poo-clos-slot-unbound
        poo-clos-slot-missing-generic poo-clos-slot-unbound-generic
        poo-clos-slot-makunbound! poo-clos-slot-reader-method
        poo-clos-slot-writer-method poo-clos-change-class
        poo-clos-update-instance-for-redefined-class
        poo-clos-update-instance-for-different-class
        poo-clos-allocate-instance-generic poo-clos-make-instance-generic
        poo-clos-initialize-instance-generic
        poo-clos-shared-initialize-generic
        poo-clos-reinitialize-instance-generic poo-clos-change-class-generic
        poo-clos-update-instance-for-redefined-class-generic
        poo-clos-update-instance-for-different-class-generic
        poo-clos-class-name poo-clos-set-class-name!
        poo-clos-class-name-generic poo-clos-set-class-name-generic
        poo-clos-class-generation
        poo-clos-class-direct-superclasses poo-clos-class-direct-subclasses
        poo-clos-class-direct-slots poo-clos-class-default-initargs
        poo-clos-class-documentation poo-clos-class-metaclass
        poo-clos-class-predecessor poo-clos-class-successor
        poo-clos-class-obsolete? poo-clos-instance-slot-names
        poo-clos-slot-name poo-clos-slot-allocation poo-clos-slot-initargs
        poo-clos-slot-readers poo-clos-slot-writers
        poo-clos-slot-defining-classes poo-clos-slot-storage-class
        poo-clos-specializer-kind poo-clos-specializer-object
        poo-clos-method-name poo-clos-method-qualifiers
        poo-clos-method-specializers poo-clos-method-lambda-list
        poo-clos-method-generic-function poo-clos-find-method
        poo-clos-function-keywords
        poo-clos-generic-name poo-clos-generic-methods
        poo-clos-generic-lambda-list poo-clos-generic-argument-precedence-order
        poo-clos-generic-method-combination poo-clos-generic-generation
        poo-clos-generic-documentation
        poo-clos-generic-function-class poo-clos-generic-method-class
        poo-clos-mop-extended-profile poo-clos-mop-profile-admits?
        .defclass .defgeneric .defmethod .with-slots .with-accessors
        .define-method-combination)
