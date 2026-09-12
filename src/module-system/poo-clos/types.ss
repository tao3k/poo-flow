;;; -*- Gerbil -*-
;;; POO-native CLOS descriptor family.
;;;
;;; This factor owns values and validation only.  Dispatch and mutation policy
;;; remain in their dedicated factors.

(import (only-in :clan/poo/object
                 .o .ref .slot? object? compute-precedence-list!)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/sugar cut))

(export ClosSpecializer ClosLambdaList ClosMethod ClosMethodGroup ClosMethodCombination
        ClosGenericProtocol ClosGenericFunction ClosGenericBinding ClosEffectiveMethod
        ClosInvocationFrame ClosFailure ClosUnboundSlotFailure
        ClosDirectSlotDefinition
        ClosEffectiveSlotDefinition ClosClass ClosInstanceState ClosSlotCell
        ClosMopProfile clos-instance?)

(def ClosType. Type.)

(def (clos-prototype type-value kind-value)
  (.o .type: type-value kind: kind-value schema: 'v1))

(def (clos-instance? prototype candidate)
  (and (object? candidate)
       (if (memq prototype (compute-precedence-list! candidate)) #t #f)))

(def (field-valid? candidate name predicate)
  (and (.slot? candidate name) (predicate (.ref candidate name))))

(def (fields? candidate names predicates)
  (andmap (cut field-valid? candidate <> <>) names predicates))

(def (natural? value)
  (and (exact-integer? value) (>= value 0)))

(def (symbol-or-false? value)
  (or (not value) (symbol? value)))

(def (any-value? _value) #t)

(def (procedure-or-false? value)
  (or (not value) (procedure? value)))

(def (string-or-false? value)
  (or (not value) (string? value)))

(def (symbol-list? value)
  (and (list? value) (andmap symbol? value)))

(def (function-name? value)
  (or (symbol? value)
      (and (list? value) (= (length value) 2)
           (eq? (car value) 'setf) (symbol? (cadr value)))))

(def (function-name-list? value)
  (and (list? value) (andmap function-name? value)))

(def (name? value)
  (or (symbol? value) (keyword? value)))

(def (name-list? value)
  (and (list? value) (andmap name? value)))

(def (specializer-kind? value)
  (if (memq value '(any class eql)) #t #f))

(def (qualifier? value)
  (or (symbol? value)
      (and (pair? value) (andmap symbol? value))))

(def (method-combination? value)
  (and (object? value)
       (clos-instance? (.ref ClosMethodCombination 'proto) value)))

(def (generic-protocol? value)
  (and (object? value)
       (clos-instance? (.ref ClosGenericProtocol 'proto) value)))

(def (specializers? value)
  (and (list? value)
       (andmap (cut element? ClosSpecializer <>) value)))

(def (clos-lambda-list-element? candidate)
  (and (clos-instance? (.ref ClosLambdaList 'proto) candidate)
       (fields? candidate
                '(required optional rest? key? keys allow-other-keys?)
                (list natural? natural? boolean? boolean? name-list?
                      boolean?))))

;;; Lambda-list descriptors retain only the congruence and call-admission
;;; shape; lexical parameter bindings remain in hygienic method expansions.
(define-type (ClosLambdaList @ ClosType.)
  proto: (clos-prototype ClosLambdaList 'poo-clos/lambda-list)
  .element?: clos-lambda-list-element?)

(def (lambda-list-or-false? value)
  (or (not value) (element? ClosLambdaList value)))

(def (methods? value)
  (and (list? value)
       (andmap (cut element? ClosMethod <>) value)))

(def (argument-precedence-order? value)
  (and (list? value) (andmap natural? value)))

(def (clos-specializer-element? candidate)
  (and (clos-instance? (.ref ClosSpecializer 'proto) candidate)
       (fields? candidate '(kind target)
                (list specializer-kind? any-value?))
       (case (.ref candidate 'kind)
         ((any) (not (.ref candidate 'target)))
         ((class) (object? (.ref candidate 'target)))
         ((eql) #t)
         (else #f))))

;;; Boundary: a specializer records only matching identity; it never owns or
;;; mutates a class, prototype, or argument value.
(define-type (ClosSpecializer @ ClosType.)
  proto: (clos-prototype ClosSpecializer 'poo-clos/specializer)
  .element?: clos-specializer-element?)

(def (clos-method-element? candidate)
  (and (clos-instance? (.ref ClosMethod 'proto) candidate)
       (fields? candidate
                '(identity specializers qualifier body lambda-list
                           generic-function synthetic-effective-method?)
                (list function-name? specializers? qualifier? procedure?
                      lambda-list-or-false? any-value? boolean?))))

;;; Invariant: a method is executable only through a generic-owned applicable
;;; effective method; its body is not a standalone public procedure contract.
(define-type (ClosMethod @ ClosType.)
  proto: (clos-prototype ClosMethod 'poo-clos/method)
  .element?: clos-method-element?)

(def (combination-kind? value)
  (if (memq value '(standard short long)) #t #f))

(def (combination-order? value)
  (if (memq value '(most-specific-first most-specific-last)) #t #f))

(def (operator-or-false? value)
  (or (not value) (symbol? value) (procedure? value)))

(def (method-group-matcher? value)
  (or (eq? value '*) (list? value) (pair? value) (procedure? value)))

(def (method-group-matchers? value)
  (and (pair? value) (andmap method-group-matcher? value)))

(def (clos-method-group-element? candidate)
  (and (clos-instance? (.ref ClosMethodGroup 'proto) candidate)
       (fields? candidate '(identity matchers order required? description)
                (list symbol? method-group-matchers? combination-order?
                      boolean? string-or-false?))))

;;; A long-form method group owns qualifier selection, order, requirement, and
;;; reflection text without owning executable method bodies.
(define-type (ClosMethodGroup @ ClosType.)
  proto: (clos-prototype ClosMethodGroup 'poo-clos/method-group)
  .element?: clos-method-group-element?)

(def (method-groups? value)
  (and (list? value) (andmap (cut element? ClosMethodGroup <>) value)))

(def (clos-method-combination-element? candidate)
  (and (clos-instance? (.ref ClosMethodCombination 'proto) candidate)
       (fields? candidate
                '(identity kind operator order identity-with-one-argument?
                           groups effective-builder configurer configuration
                           documentation)
                (list symbol? combination-kind? operator-or-false?
                      combination-order? boolean? method-groups?
                      procedure-or-false? procedure-or-false? list?
                      string-or-false?))))

;;; A method-combination descriptor is inert POO policy data.  Dispatch owns
;;; invocation, and a long-form builder can only return a checked effective method.
(define-type (ClosMethodCombination @ ClosType.)
  proto: (clos-prototype ClosMethodCombination 'poo-clos/method-combination)
  .element?: clos-method-combination-element?)

(def (clos-generic-protocol-element? candidate)
  (and (clos-instance? (.ref ClosGenericProtocol 'proto) candidate)
       (fields? candidate
                '(identity no-applicable-method no-next-method
                           compute-applicable-methods compute-effective-method)
                (list symbol? procedure-or-false? procedure-or-false?
                      procedure-or-false? procedure-or-false?))))

;;; Generic protocol hooks are collected behind one named POO object so raw
;;; procedures never become an unowned parallel public dispatch surface.
(define-type (ClosGenericProtocol @ ClosType.)
  proto: (clos-prototype ClosGenericProtocol 'poo-clos/generic-protocol)
  .element?: clos-generic-protocol-element?)

(def (clos-generic-function-element? candidate)
  (and (clos-instance? (.ref ClosGenericFunction 'proto) candidate)
       (fields? candidate
                '(identity required rest? argument-precedence-order
                           method-combination methods generation lambda-list
                           protocol documentation generic-function-class
                           method-class declarations)
                (list function-name? natural? boolean? argument-precedence-order?
                      method-combination? methods? natural?
                      (cut element? ClosLambdaList <>) generic-protocol?
                      string-or-false? any-value? any-value? list?))))

;;; Boundary: a generic value is the stable ANSI generic-function identity;
;;; method-set generation is a mutation counter, not a replacement object.
(define-type (ClosGenericFunction @ ClosType.)
  proto: (clos-prototype ClosGenericFunction 'poo-clos/generic-function)
  .element?: clos-generic-function-element?)

(def (clos-generic-binding-element? candidate)
  (and (clos-instance? (.ref ClosGenericBinding 'proto) candidate)
       (fields? candidate '(identity current)
                (list function-name? (cut element? ClosGenericFunction <>)))))

;;; A binding is the explicit effect owner for top-level defmethod evolution;
;;; each current value remains an immutable generic generation.
(define-type (ClosGenericBinding @ ClosType.)
  proto: (clos-prototype ClosGenericBinding 'poo-clos/generic-binding)
  .element?: clos-generic-binding-element?)

(def (clos-effective-method-element? candidate)
  (and (clos-instance? (.ref ClosEffectiveMethod 'proto) candidate)
       (fields? candidate
                '(generic arguments around before primary after groups executor)
                (list (cut element? ClosGenericFunction <>) list?
                      methods? methods? methods? methods? list?
                      procedure-or-false?))))

;;; Invariant: effective methods retain qualifier-separated methods from exactly
;;; one generic generation and one argument set.
(define-type (ClosEffectiveMethod @ ClosType.)
  proto: (clos-prototype ClosEffectiveMethod 'poo-clos/effective-method)
  .element?: clos-effective-method-element?)

(def (next-method? value)
  (or (not value) (procedure? value)))

(def (clos-invocation-frame-element? candidate)
  (and (clos-instance? (.ref ClosInvocationFrame 'proto) candidate)
       (fields? candidate '(effective-method arguments next qualifier method)
                (list (cut element? ClosEffectiveMethod <>) list? next-method?
                      qualifier? (cut element? ClosMethod <>)))))

;;; Boundary: the lexical frame owns next-method continuation access; it is not
;;; a serializable or cross-runtime capability.
(define-type (ClosInvocationFrame @ ClosType.)
  proto: (clos-prototype ClosInvocationFrame 'poo-clos/invocation-frame)
  .element?: clos-invocation-frame-element?)

(def (allocation? value)
  (if (memq value '(instance class)) #t #f))

(def (clos-direct-slot-definition-element? candidate)
  (and (clos-instance? (.ref ClosDirectSlotDefinition 'proto) candidate)
       (fields? candidate
                '(identity allocation initargs initfunction readers writers
                           type-predicate documentation)
                (list symbol? allocation? name-list? procedure-or-false?
                      function-name-list? function-name-list? procedure-or-false?
                      string-or-false?))))

;;; A direct slot is an inert declaration value.  Captured initforms are
;;; represented as thunks so their lexical environment remains Scheme-owned.
(define-type (ClosDirectSlotDefinition @ ClosType.)
  proto: (clos-prototype ClosDirectSlotDefinition
                         'poo-clos/direct-slot-definition)
  .element?: clos-direct-slot-definition-element?)

(def (class-reference? value)
  (and (object? value)
       (clos-instance? (.ref ClosClass 'proto) value)))

(def (class-references? value)
  (and (list? value) (andmap class-reference? value)))

(def (class-reference-or-false? value)
  (or (not value) (class-reference? value)))

(def (clos-effective-slot-definition-element? candidate)
  (and (clos-instance? (.ref ClosEffectiveSlotDefinition 'proto) candidate)
       (fields? candidate
                '(identity allocation initargs initfunction readers writers
                           type-predicates documentation defining-classes
                           storage-class)
                (list symbol? allocation? name-list? procedure-or-false?
                      function-name-list? function-name-list? list? string-or-false?
                      class-references? class-reference?))))

;;; Effective slots are immutable projections over the native POO class CPL.
(define-type (ClosEffectiveSlotDefinition @ ClosType.)
  proto: (clos-prototype ClosEffectiveSlotDefinition
                         'poo-clos/effective-slot-definition)
  .element?: clos-effective-slot-definition-element?)

(def (direct-slot-definitions? value)
  (and (list? value)
       (andmap (cut element? ClosDirectSlotDefinition <>) value)))

(def (default-initarg-entry? value)
  (and (pair? value) (name? (car value)) (procedure? (cdr value))))

(def (default-initargs? value)
  (and (list? value) (andmap default-initarg-entry? value)))

(def (clos-class-element? candidate)
  (and (clos-instance? (.ref ClosClass 'proto) candidate)
       (fields? candidate
                '(identity direct-superclasses direct-slots default-initargs
                           generation slot-missing-handler slot-unbound-handler
                           predecessor successor direct-subclasses
                           redefinition-update-handler
                           different-class-update-handler documentation metaclass)
                (list symbol? class-references? direct-slot-definitions?
                      default-initargs? natural? procedure-or-false?
                      procedure-or-false? class-reference-or-false?
                      class-reference-or-false? class-references?
                      procedure-or-false? procedure-or-false?
                      string-or-false? any-value?))))

;;; Class metaobjects own lazy native prototypes and class-allocated storage;
;;; they do not replace gerbil-poo's inheritance or C3 implementation.
(define-type (ClosClass @ ClosType.)
  proto: (clos-prototype ClosClass 'poo-clos/class)
  .element?: clos-class-element?)

(def (clos-instance-state-element? candidate)
  (and (clos-instance? (.ref ClosInstanceState 'proto) candidate)
       (fields? candidate '(class generation storage)
                (list class-reference? natural? hash-table?))))

;;; An instance state is the explicit identity-preserving mutation boundary.
(define-type (ClosInstanceState @ ClosType.)
  proto: (clos-prototype ClosInstanceState 'poo-clos/instance-state)
  .element?: clos-instance-state-element?)

(def (clos-slot-cell-element? candidate)
  (and (clos-instance? (.ref ClosSlotCell 'proto) candidate)
       (fields? candidate '(bound? value) (list boolean? any-value?))))

;;; Slot cells distinguish an unbound slot from a slot whose value is =#f=.
(define-type (ClosSlotCell @ ClosType.)
  proto: (clos-prototype ClosSlotCell 'poo-clos/slot-cell)
  .element?: clos-slot-cell-element?)

(def (clos-mop-profile-element? candidate)
  (and (clos-instance? (.ref ClosMopProfile 'proto) candidate)
       (fields? candidate
                '(identity version status operations dependency-readers
                           customization-protocols sealed? documentation)
                (list symbol? symbol? symbol? symbol-list? symbol-list?
                      symbol-list? boolean? string-or-false?))))

;;; A MOP profile is a sealed capability inventory.  It exposes no mutable
;;; registry and therefore cannot add a second metaobject dispatch hierarchy.
(define-type (ClosMopProfile @ ClosType.)
  proto: (clos-prototype ClosMopProfile 'poo-clos/mop-profile)
  .element?: clos-mop-profile-element?)

(def (clos-failure-element? candidate)
  (and (clos-instance? (.ref ClosFailure 'proto) candidate)
       (fields? candidate '(code generic qualifier method class slot operation)
                (list symbol? any-value? any-value?
                      any-value? symbol-or-false? symbol-or-false?
                      symbol-or-false?))))

;;; Boundary: failures preserve symbolic dispatch context and never retain raw
;;; argument payloads.
(define-type (ClosFailure @ ClosType.)
  proto: (clos-prototype ClosFailure 'poo-clos/failure)
  .element?: clos-failure-element?)

(def (clos-unbound-slot-failure-element? candidate)
  (and (element? ClosFailure candidate)
       (clos-instance? (.ref ClosUnboundSlotFailure 'proto) candidate)
       (field-valid? candidate 'instance any-value?)))

;;; UNBOUND-SLOT refines the common failure carrier with the exact instance;
;;; the inherited `slot` field is its cell-error name adaptation.
(define-type (ClosUnboundSlotFailure @ ClosFailure)
  proto: (.o (:: @ (.ref ClosFailure 'proto))
             .type: ClosUnboundSlotFailure
             kind: 'poo-clos/unbound-slot schema: 'v1)
  .element?: clos-unbound-slot-failure-element?)
