;;; -*- Gerbil -*-
;;; Read-only class and instance reflection over POO metaobjects.

(import (only-in :clan/poo/object .ref)
        (only-in :clan/poo/mop element?)
        (only-in :std/srfi/1 find)
        "types.ss" "objects.ss" "classes.ss" "lifecycle.ss" "dispatch.ss")

(export poo-clos-class-name poo-clos-set-class-name!
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
        poo-clos-generic-function-class poo-clos-generic-method-class)

;; : (forall (a) (-> [a] [a]))
(def (copy-list values) (map (lambda (value) value) values))

;; : (-> SchemeValue ClosClass)
(def (require-class value)
  (unless (element? ClosClass value) (clos-fail 'invalid-class))
  value)

;; : (forall (a) (-> Type a Symbol a))
(def (require-metaobject type value code)
  (unless (element? type value) (clos-fail code))
  value)

;; : ClosGenericFunction
(def poo-clos-class-name-generic
  (poo-clos-add-method
   (poo-clos-generic-function 'class-name 1)
   (poo-clos-method
    'class-name/default (list (poo-clos-any-specializer))
    (lambda (_frame class-value)
      (.ref (require-class class-value) 'identity))
    lambda-list: (poo-clos-lambda-list 1 0 #f #f '() #f))))

;; : ClosGenericFunction
(def poo-clos-set-class-name-generic
  (poo-clos-add-method
   (poo-clos-generic-function '(setf class-name) 2)
   (poo-clos-method
    'set-class-name/default
    (list (poo-clos-any-specializer) (poo-clos-any-specializer))
    (lambda (_frame new-name class-value)
      (%poo-clos-set-class-name! new-name class-value))
    lambda-list: (poo-clos-lambda-list 2 0 #f #f '() #f))))

;; : (-> ClosClass Symbol)
(def (poo-clos-class-name class-value)
  (poo-clos-call poo-clos-class-name-generic class-value))

;; : (-> Symbol ClosClass Symbol)
(def (poo-clos-set-class-name! new-name class-value)
  (poo-clos-call poo-clos-set-class-name-generic new-name class-value))

;; : (-> ClosClass Natural)
(def (poo-clos-class-generation class-value)
  (.ref (require-class class-value) 'generation))

;; : (-> ClosClass [ClosClass])
(def (poo-clos-class-direct-superclasses class-value)
  (copy-list (.ref (require-class class-value) 'direct-superclasses)))

;; : (-> ClosClass [ClosClass])
(def (poo-clos-class-direct-subclasses class-value)
  (copy-list (.ref (require-class class-value) 'direct-subclasses)))

;; : (-> ClosClass [ClosDirectSlotDefinition])
(def (poo-clos-class-direct-slots class-value)
  (copy-list (.ref (require-class class-value) 'direct-slots)))

;; : (-> ClosClass [Pair])
(def (poo-clos-class-default-initargs class-value)
  (copy-list (.ref (require-class class-value) 'default-initargs)))

(def (poo-clos-class-documentation class-value)
  (.ref (require-class class-value) 'documentation))

(def (poo-clos-class-metaclass class-value)
  (.ref (require-class class-value) 'metaclass))

;; : (-> ClosClass (Maybe ClosClass))
(def (poo-clos-class-predecessor class-value)
  (.ref (require-class class-value) 'predecessor))

;; : (-> ClosClass (Maybe ClosClass))
(def (poo-clos-class-successor class-value)
  (.ref (require-class class-value) 'successor))

;; : (-> ClosClass Boolean)
(def (poo-clos-class-obsolete? class-value)
  (if (poo-clos-class-successor class-value) #t #f))

;; : (-> ClosInstance [Symbol])
(def (poo-clos-instance-slot-names instance-value)
  (map (lambda (slot) (.ref slot 'identity))
       (poo-clos-class-effective-slots
       (poo-clos-class-of instance-value))))

;; : (-> ClosEffectiveSlotDefinition Symbol)
(def (poo-clos-slot-name slot-value)
  (.ref (require-metaobject ClosEffectiveSlotDefinition slot-value
                            'invalid-effective-slot-definition)
        'identity))

;; : (-> ClosEffectiveSlotDefinition SlotAllocation)
(def (poo-clos-slot-allocation slot-value)
  (.ref (require-metaobject ClosEffectiveSlotDefinition slot-value
                            'invalid-effective-slot-definition)
        'allocation))

;; : (-> ClosEffectiveSlotDefinition [InitargName])
(def (poo-clos-slot-initargs slot-value)
  (copy-list
   (.ref (require-metaobject ClosEffectiveSlotDefinition slot-value
                             'invalid-effective-slot-definition)
         'initargs)))

;; : (-> ClosEffectiveSlotDefinition [Symbol])
(def (poo-clos-slot-readers slot-value)
  (copy-list
   (.ref (require-metaobject ClosEffectiveSlotDefinition slot-value
                             'invalid-effective-slot-definition)
         'readers)))

;; : (-> ClosEffectiveSlotDefinition [Symbol])
(def (poo-clos-slot-writers slot-value)
  (copy-list
   (.ref (require-metaobject ClosEffectiveSlotDefinition slot-value
                             'invalid-effective-slot-definition)
         'writers)))

;; : (-> ClosEffectiveSlotDefinition [ClosClass])
(def (poo-clos-slot-defining-classes slot-value)
  (copy-list
   (.ref (require-metaobject ClosEffectiveSlotDefinition slot-value
                             'invalid-effective-slot-definition)
         'defining-classes)))

;; : (-> ClosEffectiveSlotDefinition ClosClass)
(def (poo-clos-slot-storage-class slot-value)
  (.ref (require-metaobject ClosEffectiveSlotDefinition slot-value
                            'invalid-effective-slot-definition)
        'storage-class))

;; : (-> ClosSpecializer Symbol)
(def (poo-clos-specializer-kind specializer-value)
  (.ref (require-metaobject ClosSpecializer specializer-value
                            'invalid-specializer)
        'kind))

;; : (-> ClosSpecializer SchemeValue)
(def (poo-clos-specializer-object specializer-value)
  (.ref (require-metaobject ClosSpecializer specializer-value
                            'invalid-specializer)
        'target))

;; : (-> ClosMethod Symbol)
(def (poo-clos-method-name method-value)
  (.ref (require-metaobject ClosMethod method-value 'invalid-method) 'identity))

;; : (-> ClosMethod [MethodQualifier])
(def (poo-clos-method-qualifiers method-value)
  (let (qualifier (.ref (require-metaobject ClosMethod method-value
                                             'invalid-method)
                         'qualifier))
    (cond
     ((eq? qualifier 'primary) '())
     ((list? qualifier) (copy-list qualifier))
     (else (list qualifier)))))

;; : (-> ClosMethod [ClosSpecializer])
(def (poo-clos-method-specializers method-value)
  (copy-list
   (.ref (require-metaobject ClosMethod method-value 'invalid-method)
         'specializers)))

;; : (-> ClosMethod (Maybe ClosLambdaList))
(def (poo-clos-method-lambda-list method-value)
  (.ref (require-metaobject ClosMethod method-value 'invalid-method)
        'lambda-list))

;; : (-> ClosMethod (Maybe ClosGenericFunction))
(def (poo-clos-method-generic-function method-value)
  (.ref (require-metaobject ClosMethod method-value 'invalid-method)
        'generic-function))

;; : (-> ClosMethod (values [InitargName] Boolean))
(def (poo-clos-function-keywords method-value)
  (let (lambda-list-value
        (poo-clos-method-lambda-list method-value))
    (if lambda-list-value
      (values (copy-list (.ref lambda-list-value 'keys))
              (.ref lambda-list-value 'allow-other-keys?))
      (values '() #f))))

;; : (-> [ClosSpecializer] [ClosSpecializer] Boolean)
(def (same-reflected-specializers? left right)
  (and (= (length left) (length right))
       (andmap
        (lambda (left-value right-value)
          (and (eq? (.ref left-value 'kind) (.ref right-value 'kind))
               (case (.ref left-value 'kind)
                 ((eql) (eqv? (.ref left-value 'target)
                              (.ref right-value 'target)))
                 (else (eq? (.ref left-value 'target)
                            (.ref right-value 'target))))))
        left right)))

;; : (-> GenericSource List [ClosSpecializer] Boolean (Maybe ClosMethod))
(def (poo-clos-find-method generic-source qualifiers specializers
                           error?: (error-value #t))
  (let* ((generic-value (require-clos-generic generic-source))
         (internal-qualifier
          (cond
           ((null? qualifiers) 'primary)
           ((null? (cdr qualifiers)) (car qualifiers))
           (else qualifiers)))
         (method
          (find (lambda (candidate)
                  (and (equal? (.ref candidate 'qualifier)
                               internal-qualifier)
                       (same-reflected-specializers?
                        (.ref candidate 'specializers) specializers)))
                (.ref generic-value 'methods))))
    (when (and (not method) error-value)
      (clos-fail 'method-not-found generic: (.ref generic-value 'identity)
                 qualifier: qualifiers))
    method))

;; : (-> GenericSource ClosGenericFunction)
(def (reflection-generic generic-source)
  (require-clos-generic generic-source))

;; : (-> GenericSource Symbol)
(def (poo-clos-generic-name generic-source)
  (.ref (reflection-generic generic-source) 'identity))

;; : (-> GenericSource [ClosMethod])
(def (poo-clos-generic-methods generic-source)
  (copy-list (.ref (reflection-generic generic-source) 'methods)))

;; : (-> GenericSource ClosLambdaList)
(def (poo-clos-generic-lambda-list generic-source)
  (.ref (reflection-generic generic-source) 'lambda-list))

;; : (-> GenericSource [Natural])
(def (poo-clos-generic-argument-precedence-order generic-source)
  (copy-list
   (.ref (reflection-generic generic-source) 'argument-precedence-order)))

;; : (-> GenericSource ClosMethodCombination)
(def (poo-clos-generic-method-combination generic-source)
  (.ref (reflection-generic generic-source) 'method-combination))

;; : (-> GenericSource Natural)
(def (poo-clos-generic-generation generic-source)
  (.ref (reflection-generic generic-source) 'generation))

(def (poo-clos-generic-documentation generic-source)
  (.ref (reflection-generic generic-source) 'documentation))

(def (poo-clos-generic-function-class generic-source)
  (.ref (reflection-generic generic-source) 'generic-function-class))

(def (poo-clos-generic-method-class generic-source)
  (.ref (reflection-generic generic-source) 'method-class))
