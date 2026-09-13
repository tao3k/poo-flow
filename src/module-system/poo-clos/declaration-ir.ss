;;; -*- Gerbil -*-
;;; Stable phase-owned facade for POO-native CLOS declaration parsing.

(import "declaration-ir-core.ss"
        "class-declaration-ir.ss"
        "method-combination-declaration-ir.ss")

(export parse-poo-clos-class-declaration-ir
        parse-poo-clos-generic-declaration-ir
        parse-poo-clos-method-declaration-ir
        parse-poo-clos-method-combination-declaration-ir
        parse-poo-clos-long-method-combination-declaration-ir
        clos-class-declaration-ir-name clos-class-declaration-ir-supers
        clos-class-declaration-ir-slots clos-class-declaration-ir-default-initargs
        clos-class-declaration-ir-slot-missing
        clos-class-declaration-ir-slot-unbound
        clos-class-declaration-ir-documentation
        clos-class-declaration-ir-metaclass
        clos-slot-declaration-ir-name clos-slot-declaration-ir-allocation
        clos-slot-declaration-ir-initargs clos-slot-declaration-ir-initform
        clos-slot-declaration-ir-readers clos-slot-declaration-ir-writers
        clos-slot-declaration-ir-type-predicate
        clos-slot-declaration-ir-documentation
        clos-generic-declaration-ir-name clos-generic-declaration-ir-lambda-list
        clos-generic-declaration-ir-argument-precedence-order
        clos-generic-declaration-ir-method-combination
        clos-generic-declaration-ir-documentation
        clos-generic-declaration-ir-generic-function-class
        clos-generic-declaration-ir-method-class
        clos-generic-declaration-ir-declarations
        clos-generic-declaration-ir-methods
        clos-method-combination-reference-declaration-ir-name
        clos-method-combination-reference-declaration-ir-arguments
        clos-method-declaration-ir-name clos-method-declaration-ir-qualifier
        clos-method-declaration-ir-lambda-list clos-method-declaration-ir-body
        clos-method-combination-declaration-ir-name
        clos-method-combination-declaration-ir-operator
        clos-method-combination-declaration-ir-order
        clos-method-combination-declaration-ir-identity-with-one-argument
        clos-method-combination-declaration-ir-documentation
        clos-long-method-combination-declaration-ir-name
        clos-long-method-combination-declaration-ir-lambda-list
        clos-long-method-combination-declaration-ir-groups
        clos-long-method-combination-declaration-ir-arguments
        clos-long-method-combination-declaration-ir-arguments-whole
        clos-long-method-combination-declaration-ir-generic-function
        clos-long-method-combination-declaration-ir-declarations
        clos-long-method-combination-declaration-ir-documentation
        clos-long-method-combination-declaration-ir-body
        clos-method-group-declaration-ir-name
        clos-method-group-declaration-ir-matchers
        clos-method-group-declaration-ir-order
        clos-method-group-declaration-ir-required
        clos-method-group-declaration-ir-description
        clos-lambda-declaration-ir-required clos-lambda-declaration-ir-optional
        clos-lambda-declaration-ir-rest clos-lambda-declaration-ir-keys
        clos-lambda-declaration-ir-allow-other-keys
        clos-lambda-declaration-ir-aux
        clos-parameter-declaration-ir-variable clos-parameter-declaration-ir-kind
        clos-parameter-declaration-ir-target
        clos-optional-declaration-ir-variable clos-optional-declaration-ir-initform
        clos-optional-declaration-ir-supplied
        clos-key-declaration-ir-name clos-key-declaration-ir-variable
        clos-key-declaration-ir-initform clos-key-declaration-ir-supplied
        clos-aux-declaration-ir-variable clos-aux-declaration-ir-initform)

