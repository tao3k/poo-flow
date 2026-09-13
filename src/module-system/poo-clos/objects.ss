;;; -*- Gerbil -*-
;;; Checked construction and identity-preserving generic-function evolution.

(import (only-in :clan/poo/object .o .ref .put!)
        (only-in :clan/poo/mop element?)
        (only-in :std/srfi/1 find iota)
        "types.ss")

(export poo-clos-any-specializer poo-clos-class-specializer
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
        clos-fail clos-unbound-slot-fail checked
        require-clos-generic require-clos-method
        make-synthetic-effective-method
        make-effective-method make-invocation-frame)

;;; Cached owner-local prototype avoids repeated descriptor demand in constructors.
;; : POOObject
(def ClosSpecializer. (.ref ClosSpecializer 'proto))
;; : POOObject
(def ClosLambdaList. (.ref ClosLambdaList 'proto))
;;; Methods extend one stable POO prototype regardless of generic generation.
;; : POOObject
(def ClosMethod. (.ref ClosMethod 'proto))
;; : POOObject
(def ClosMethodCombination. (.ref ClosMethodCombination 'proto))
;; : POOObject
(def ClosMethodGroup. (.ref ClosMethodGroup 'proto))
;; : POOObject
(def ClosGenericProtocol. (.ref ClosGenericProtocol 'proto))
;;; Generic clones preserve this prototype while changing methods and generation.
;; : POOObject
(def ClosGenericFunction. (.ref ClosGenericFunction 'proto))
;; : POOObject
(def ClosGenericBinding. (.ref ClosGenericBinding 'proto))
;;; Effective methods have a separate prototype from authoring descriptors.
;; : POOObject
(def ClosEffectiveMethod. (.ref ClosEffectiveMethod 'proto))
;;; Invocation frames are typed independently from reusable effective methods.
;; : POOObject
(def ClosInvocationFrame. (.ref ClosInvocationFrame 'proto))

;;; Function names use ANSI identity, including `(setf name)`.  An alist is
;;; intentional here because freshly reconstructed SETF names require `equal?`
;;; rather than symbol identity.
(def poo-clos-generic-function-registry '())

(def (poo-clos-register-generic-function! generic-source)
  (let* ((generic-value (require-clos-generic generic-source))
         (name (.ref generic-value 'identity)))
    (set! poo-clos-generic-function-registry
          (cons (cons name generic-source)
                (filter (lambda (entry) (not (equal? (car entry) name)))
                        poo-clos-generic-function-registry)))
    generic-source))

(def (poo-clos-find-generic-function name error?: (error-value #t))
  (let (entry (find (lambda (candidate) (equal? (car candidate) name))
                    poo-clos-generic-function-registry))
    (when (and (not entry) error-value)
      (clos-fail 'generic-function-not-found generic: name))
    (and entry (cdr entry))))
;;; Raised CLOS conditions share one payload-minimizing failure prototype.
;; : POOObject
(def ClosFailure. (.ref ClosFailure 'proto))
;; : POOObject
(def ClosUnboundSlotFailure. (.ref ClosUnboundSlotFailure 'proto))

;; : (-> Symbol generic: (Maybe Symbol) qualifier: (Maybe Symbol)
;;        method: (Maybe Symbol) class: (Maybe Symbol) slot: (Maybe Symbol)
;;        operation: (Maybe Symbol) Bottom)
(def (clos-fail code-value generic: (generic-value #f)
                qualifier: (qualifier-value #f) method: (method-value #f)
                class: (class-value #f) slot: (slot-value #f)
                operation: (operation-value #f))
  (raise
   (.o (:: @ ClosFailure.)
       code: code-value generic: generic-value
       qualifier: qualifier-value method: method-value
       class: class-value slot: slot-value operation: operation-value)))

;;; Failure recognition uses the native POO Type descriptor, not exception text.
;; : (-> SchemeValue Boolean)
(def (poo-clos-failure? value)
  (element? ClosFailure value))

;; : (-> SchemeValue Boolean)
(def (poo-clos-unbound-slot? value)
  (element? ClosUnboundSlotFailure value))

;; : (-> ClosUnboundSlotFailure SchemeValue)
(def (poo-clos-unbound-slot-instance condition)
  (unless (poo-clos-unbound-slot? condition)
    (clos-fail 'invalid-unbound-slot-condition))
  (.ref condition 'instance))

;; : (-> ClosClass ClosInstance Symbol Symbol Bottom)
(def (clos-unbound-slot-fail class-value instance-value slot-value
                             operation-value)
  (raise
   (.o (:: @ ClosUnboundSlotFailure.)
       code: 'slot-unbound generic: #f qualifier: #f method: #f
       class: class-value slot: slot-value operation: operation-value
       instance: instance-value)))

;; : (forall (a) (-> POOType a Symbol a))
(def (checked type value code)
  (unless (element? type value) (clos-fail code))
  value)

;;; Generic admission returns the original value to support functional pipelines.
;; : (forall (a) (-> a ClosGenericFunction))
(def (require-clos-generic value)
  (cond
   ((element? ClosGenericFunction value) value)
   ((element? ClosGenericBinding value) (.ref value 'current))
   (else (clos-fail 'invalid-generic-function))))

;;; Method admission preserves descriptor identity for replacement comparison.
;; : (forall (a) (-> a ClosMethod))
(def (require-clos-method value)
  (checked ClosMethod value 'invalid-method))

;;; The universal specializer has no target and ranks after applicable classes.
;; : (-> ClosSpecializer)
(def (poo-clos-any-specializer)
  (checked ClosSpecializer
           (.o (:: @ ClosSpecializer.) kind: 'any target: #f)
           'invalid-specializer))

;;; A CLOS class target remains a class metaobject so successor generations can
;;; participate in dispatch.  Raw native prototypes remain an explicit bridge.
;; : (-> (U ClosClass POOObject) ClosSpecializer)
(def (poo-clos-class-specializer target-value)
  (checked ClosSpecializer
           (.o (:: @ ClosSpecializer.) kind: 'class target: target-value)
           'invalid-specializer))

;;; Eql retains the Scheme value itself; dispatch applies the documented
;;; =eqv?= adaptation without serializing or canonicalizing that value.
;; : (forall (a) (-> a ClosSpecializer))
(def (poo-clos-eql-specializer value)
  (checked ClosSpecializer
           (.o (:: @ ClosSpecializer.) kind: 'eql target: value)
           'invalid-specializer))

;;; Method construction is declarative; arity agreement is checked only when a
;;; generic generation admits the method.
;; : (-> Symbol [ClosSpecializer] Procedure
;;        qualifier: MethodQualifier ClosMethod)
(def (poo-clos-method identity-value specializer-values body-value
                      qualifier: (qualifier-value 'primary)
                      lambda-list: (lambda-list-value #f))
  (checked ClosMethod
           (.o (:: @ ClosMethod.)
               identity: identity-value specializers: specializer-values
               qualifier: qualifier-value body: body-value
               lambda-list: lambda-list-value generic-function: #f
               synthetic-effective-method?: #f)
           'invalid-method))

;;; Synthetic methods are created only by the declarative combination
;;; evaluator.  They are typed method values but never enter a generic's
;;; persistent method set.
;; : (-> Thunk ClosMethod)
(def (make-synthetic-effective-method thunk)
  (unless (procedure? thunk) (clos-fail 'invalid-make-method))
  (checked ClosMethod
           (.o (:: @ ClosMethod.)
               identity: 'make-method specializers: '()
               qualifier: 'primary
               body: (lambda (_frame . _arguments) (thunk))
               lambda-list: #f generic-function: #f
               synthetic-effective-method?: #t)
           'invalid-make-method))

;; : (-> Natural Natural Boolean Boolean [InitargName] Boolean ClosLambdaList)
(def (poo-clos-lambda-list required-value optional-value rest-value key-value
                           key-values allow-other-keys-value)
  (unless (and (exact-integer? required-value) (>= required-value 0)
               (exact-integer? optional-value) (>= optional-value 0)
               (boolean? rest-value) (boolean? key-value)
               (list? key-values)
               (andmap (lambda (name)
                         (or (symbol? name) (keyword? name)))
                       key-values)
               (boolean? allow-other-keys-value)
               (or key-value (null? key-values))
               (or key-value (not allow-other-keys-value)))
    (clos-fail 'invalid-lambda-list))
  (checked ClosLambdaList
           (.o (:: @ ClosLambdaList.)
               required: required-value optional: optional-value
               rest?: rest-value key?: key-value keys: key-values
               allow-other-keys?: allow-other-keys-value)
           'invalid-lambda-list))

;; : (-> ClosLambdaList ClosLambdaList Boolean)
(def (poo-clos-lambda-lists-congruent? generic-list method-list)
  (and (= (.ref generic-list 'required) (.ref method-list 'required))
       (= (.ref generic-list 'optional) (.ref method-list 'optional))
       (eq? (or (.ref generic-list 'rest?) (.ref generic-list 'key?))
            (or (.ref method-list 'rest?) (.ref method-list 'key?)))
       (or (not (.ref generic-list 'key?))
           (andmap
            (lambda (name)
              (or (memq name (.ref method-list 'keys))
                  (.ref method-list 'allow-other-keys?)
                  (and (.ref method-list 'rest?)
                       (not (.ref method-list 'key?)))))
            (.ref generic-list 'keys)))))

;;; Method-combination construction keeps execution policy in a checked POO
;;; descriptor; the dispatch factor remains the sole invocation owner.
;; : (-> Symbol Symbol (Maybe (U Symbol Procedure)) Symbol Boolean List
;;        (Maybe Procedure) (Maybe String) ClosMethodCombination)
(def (make-method-combination identity-value kind-value operator-value
                              order-value identity-with-one-value groups-value
                              builder-value configurer-value configuration-value
                              documentation-value)
  (checked ClosMethodCombination
           (.o (:: @ ClosMethodCombination.)
               identity: identity-value kind: kind-value
               operator: operator-value order: order-value
               identity-with-one-argument?: identity-with-one-value
               groups: groups-value effective-builder: builder-value
               configurer: configurer-value configuration: configuration-value
               documentation: documentation-value)
           'invalid-method-combination))

;; : (-> ClosMethodCombination)
(def (poo-clos-standard-method-combination)
  (make-method-combination 'standard 'standard #f 'most-specific-first
                           #f '() #f #f '()
                           "ANSI standard method combination"))

;; : (-> Symbol (U Symbol Procedure) order: Symbol
;;        identity-with-one-argument?: Boolean documentation: (Maybe String)
;;        ClosMethodCombination)
(def (poo-clos-short-method-combination
      identity-value operator-value
      order: (order-value 'most-specific-first)
      identity-with-one-argument?: (identity-with-one-value #f)
      documentation: (documentation-value #f))
  (unless (and (symbol? identity-value)
               (or (symbol? operator-value) (procedure? operator-value))
               (memq order-value
                     '(most-specific-first most-specific-last))
               (boolean? identity-with-one-value)
               (or (not documentation-value) (string? documentation-value)))
    (clos-fail 'invalid-method-combination))
  (make-method-combination identity-value 'short operator-value order-value
                           identity-with-one-value '() #f #f '()
                           documentation-value))

;; : (-> Symbol List order: Symbol required?: Boolean
;;        description: (Maybe String) ClosMethodGroup)
(def (poo-clos-method-group
      identity-value matcher-values
      order: (order-value 'most-specific-first)
      required?: (required-value #f)
      description: (description-value #f))
  (checked ClosMethodGroup
           (.o (:: @ ClosMethodGroup.)
               identity: identity-value matchers: matcher-values
               order: order-value required?: required-value
               description: description-value)
           'invalid-method-group))

;; : (-> Symbol List Procedure documentation: (Maybe String)
;;        ClosMethodCombination)
(def (poo-clos-long-method-combination
      identity-value group-values builder-value
      configurer: (configurer-value #f)
      configuration: (configuration-value '())
      documentation: (documentation-value #f))
  (unless (and (symbol? identity-value) (list? group-values)
               (andmap (lambda (group) (element? ClosMethodGroup group))
                       group-values)
               (procedure? builder-value)
               (or (not configurer-value) (procedure? configurer-value))
               (list? configuration-value)
               (or (not documentation-value) (string? documentation-value)))
    (clos-fail 'invalid-method-combination))
  (make-method-combination identity-value 'long #f 'most-specific-first #f
                           group-values builder-value configurer-value
                           configuration-value documentation-value))

;;; Configuration creates a new inert descriptor; the declaration remains a
;;; reusable method-combination type and no generic owns mutable option state.
;; : (-> ClosMethodCombination SchemeValue ... ClosMethodCombination)
(def (poo-clos-configure-method-combination combination . values)
  (unless (element? ClosMethodCombination combination)
    (clos-fail 'invalid-method-combination))
  (case (.ref combination 'kind)
    ((short)
     (unless (<= (length values) 1)
       (clos-fail 'invalid-method-combination-options
                  method: (.ref combination 'identity)))
     (let (order (if (null? values)
                   (.ref combination 'order)
                   (car values)))
       (poo-clos-short-method-combination
        (.ref combination 'identity) (.ref combination 'operator)
        order: order
        identity-with-one-argument?:
        (.ref combination 'identity-with-one-argument?)
        documentation: (.ref combination 'documentation))))
    ((long)
     (let (configurer (.ref combination 'configurer))
       (unless configurer
         (clos-fail 'method-combination-does-not-accept-options
                    method: (.ref combination 'identity)))
       (let (configured (apply configurer values))
         (unless (and (element? ClosMethodCombination configured)
                      (eq? (.ref configured 'kind) 'long)
                      (eq? (.ref configured 'identity)
                           (.ref combination 'identity)))
           (clos-fail 'invalid-method-combination-configuration
                      method: (.ref combination 'identity)))
         configured)))
    (else
     (when (pair? values)
       (clos-fail 'method-combination-does-not-accept-options
                  method: (.ref combination 'identity)))
     combination)))

;;; Built-ins use Scheme operators under explicit CLOS identities.  Dispatch
;;; supplies the ANSI evaluation order and one-argument identity behavior.
;; : (-> Symbol ClosMethodCombination)
(def (poo-clos-built-in-method-combination identity-value)
  (case identity-value
    ((+) (poo-clos-short-method-combination '+ '+))
    ((and) (poo-clos-short-method-combination 'and 'and))
    ((append) (poo-clos-short-method-combination 'append 'append))
    ((list) (poo-clos-short-method-combination 'list 'list))
    ((max) (poo-clos-short-method-combination 'max 'max))
    ((min) (poo-clos-short-method-combination 'min 'min))
    ((nconc) (poo-clos-short-method-combination 'nconc 'nconc))
    ((or) (poo-clos-short-method-combination 'or 'or))
    ((progn) (poo-clos-short-method-combination 'progn 'progn))
    (else
     (clos-fail 'unknown-method-combination method: identity-value))))

;; : (forall (a) (-> a ClosMethodCombination))
(def (poo-clos-resolve-method-combination value)
  (cond
   ((element? ClosMethodCombination value) value)
   ((eq? value 'standard) (poo-clos-standard-method-combination))
   ((and (symbol? value)
         (memq value '(+ and append list max min nconc or progn)))
    (poo-clos-built-in-method-combination value))
   (else (clos-fail 'unsupported-method-combination))))

;; : (-> ClosMethodCombination SchemeValue Boolean)
(def (poo-clos-method-combination-admits-qualifier? combination qualifier)
  (case (.ref combination 'kind)
    ((standard) (if (memq qualifier '(around before primary after)) #t #f))
    ((short) (or (eq? qualifier 'around)
                 (eq? qualifier (.ref combination 'identity))))
    ((long) #t)
    (else #f)))

;;; A default protocol has no override procedures; dispatch therefore follows
;;; its closed built-in path and emits typed terminal failures.
;; : (-> ClosGenericProtocol)
(def (poo-clos-default-generic-protocol)
  (checked ClosGenericProtocol
           (.o (:: @ ClosGenericProtocol.)
               identity: 'default
               no-applicable-method: #f no-next-method: #f
               compute-applicable-methods: #f compute-effective-method: #f)
           'invalid-generic-protocol))

;; : (-> Symbol no-applicable-method: (Maybe Procedure)
;;        no-next-method: (Maybe Procedure)
;;        compute-applicable-methods: (Maybe Procedure)
;;        compute-effective-method: (Maybe Procedure) ClosGenericProtocol)
(def (poo-clos-generic-protocol
      identity-value
      no-applicable-method: (no-applicable-value #f)
      no-next-method: (no-next-value #f)
      compute-applicable-methods: (compute-applicable-value #f)
      compute-effective-method: (compute-effective-value #f))
  (checked ClosGenericProtocol
           (.o (:: @ ClosGenericProtocol.)
               identity: identity-value
               no-applicable-method: no-applicable-value
               no-next-method: no-next-value
               compute-applicable-methods: compute-applicable-value
               compute-effective-method: compute-effective-value)
           'invalid-generic-protocol))

;;; Precedence order is a true permutation: duplicates and missing positions
;;; fail before the generic POO value is constructed.
;; : (-> [Natural] Natural Boolean)
(def (permutation? values size)
  (and (= (length values) size)
       (let loop ((index 0))
         (or (= index size)
             (and (= 1 (length (filter (lambda (value) (= value index)) values)))
                  (loop (+ index 1)))))))

;; | ClosGenericFunction = POOObject
;; poo-clos-generic-function
;;   : (-> Symbol Natural Boolean (Maybe (List Natural)) Symbol ClosGenericFunction)
;;   | contract: creates generation zero only after arity, precedence, and
;;     method-combination options are admitted.
;;   | doc m%
;;   | # Examples
;;   | ```scheme
;;   | (poo-clos-generic-function
;;   |  'route 2 argument-precedence-order: '(1 0))
;;   | ```
;;   | result: immutable POO generic-function descriptor with no methods.
;; : (-> Symbol Natural Boolean (Maybe (List Natural)) Symbol
;;        ClosGenericFunction)
(def (poo-clos-generic-function identity-value required-value
                                rest?: (rest-value #f)
                                optional: (optional-value 0)
                                key?: (key-value #f)
                                keys: (key-values '())
                                allow-other-keys?:
                                (allow-other-keys-value #f)
                                argument-precedence-order:
                                (precedence-order-value #f)
                                method-combination: (combination-value 'standard)
                                protocol: (protocol-value #f)
                                documentation: (documentation-value #f)
                                generic-function-class:
                                (generic-class-value 'standard-generic-function)
                                method-class: (method-class-value 'standard-method)
                                declarations: (declaration-values '()))
  (unless (and (exact-integer? required-value) (>= required-value 0))
    (clos-fail 'invalid-required-argument-count generic: identity-value))
  (let (precedence-order
        (or precedence-order-value
            (iota required-value)))
    (unless (permutation? precedence-order required-value)
      (clos-fail 'invalid-argument-precedence-order generic: identity-value))
    (let* ((combination-object
            (poo-clos-resolve-method-combination combination-value))
           (protocol-object
            (checked ClosGenericProtocol
                     (or protocol-value (poo-clos-default-generic-protocol))
                     'invalid-generic-protocol))
           (lambda-list-value
           (poo-clos-lambda-list required-value optional-value rest-value
                                 key-value key-values
                                 allow-other-keys-value))
          (candidate
          (.o (:: @ ClosGenericFunction.)
              identity: identity-value required: required-value rest?: rest-value
              argument-precedence-order: precedence-order
              method-combination: combination-object
              methods: '() generation: 0
              lambda-list: lambda-list-value protocol: protocol-object
              documentation: documentation-value
              generic-function-class: generic-class-value
              method-class: method-class-value
              declarations: declaration-values)))
      (checked ClosGenericFunction candidate 'invalid-generic-function))))

;;; Scheme =eqv?= is the explicit kernel adaptation for CLOS =eql= values;
;;; class and universal targets preserve native POO identity with =eq?=.
;; : (-> ClosSpecializer ClosSpecializer Boolean)
(def (same-specializer? left right)
  (and (eq? (.ref left 'kind) (.ref right 'kind))
       (case (.ref left 'kind)
         ((eql) (eqv? (.ref left 'target) (.ref right 'target)))
         (else (eq? (.ref left 'target) (.ref right 'target))))))

;;; Signature agreement is positional and requires the complete list length.
;; : (-> [ClosSpecializer] [ClosSpecializer] Boolean)
(def (same-specializers? left right)
  (and (= (length left) (length right))
       (andmap same-specializer? left right)))

;;; CLOS replacement agreement includes the qualifier as well as specializers.
;; : (-> ClosMethod ClosMethod Boolean)
(def (method-agrees? left right)
  (and (eq? (.ref left 'qualifier) (.ref right 'qualifier))
       (same-specializers? (.ref left 'specializers)
                           (.ref right 'specializers))))

;; | ClosGenericFunction = POOObject
;; poo-clos-add-method
;;   : (-> ClosGenericFunction ClosMethod ClosGenericFunction)
;;   | contract: associates the method with exactly one generic function,
;;     replaces an agreeing method, and preserves generic-function identity.
;;   | doc m%
;;   | # Examples
;;   | ```scheme
;;   | (poo-clos-add-method generic method)
;;   | ```
;;   | result: the same POO generic-function with generation + 1.
;;; Removing an absent method is identity preserving; a real removal alone
;;; advances the generation.
;; : (-> ClosGenericFunction ClosMethod ClosGenericFunction)
(def (poo-clos-add-method generic-value method-value)
  (set! generic-value (require-clos-generic generic-value))
  (set! method-value (require-clos-method method-value))
  (unless (poo-clos-method-combination-admits-qualifier?
           (.ref generic-value 'method-combination)
           (.ref method-value 'qualifier))
    (clos-fail 'invalid-method-qualifier
               generic: (.ref generic-value 'identity)
               qualifier: (.ref method-value 'qualifier)
               method: (.ref method-value 'identity)))
  (unless (= (length (.ref method-value 'specializers))
             (.ref generic-value 'required))
    (clos-fail 'method-required-argument-mismatch
               generic: (.ref generic-value 'identity)
               qualifier: (.ref method-value 'qualifier)
               method: (.ref method-value 'identity)))
  (when (and (.ref method-value 'lambda-list)
             (not (poo-clos-lambda-lists-congruent?
                   (.ref generic-value 'lambda-list)
                   (.ref method-value 'lambda-list))))
    (clos-fail 'incongruent-method-lambda-list
               generic: (.ref generic-value 'identity)
               qualifier: (.ref method-value 'qualifier)
               method: (.ref method-value 'identity)))
  (let ((owner (.ref method-value 'generic-function))
        (replaced
         (filter (lambda (existing)
                   (method-agrees? method-value existing))
                 (.ref generic-value 'methods))))
    (when (and owner (not (eq? owner generic-value)))
      (clos-fail 'method-owned-by-another-generic
                 generic: (.ref generic-value 'identity)
                 qualifier: (.ref method-value 'qualifier)
                 method: (.ref method-value 'identity)))
    (for-each (lambda (existing)
                (unless (eq? existing method-value)
                  (.put! existing 'generic-function #f)))
              replaced)
    (.put! method-value 'generic-function generic-value)
    (.put! generic-value 'methods
           (cons method-value
                 (filter (lambda (existing)
                           (not (method-agrees? method-value existing)))
                         (.ref generic-value 'methods))))
    (.put! generic-value 'generation (+ 1 (.ref generic-value 'generation)))
    generic-value))

;; : (-> ClosGenericFunction ClosMethod ClosGenericFunction)
(def (poo-clos-remove-method generic-value method-value)
  (set! generic-value (require-clos-generic generic-value))
  (set! method-value (require-clos-method method-value))
  (let (remaining
        (filter (lambda (existing) (not (eq? existing method-value)))
                (.ref generic-value 'methods)))
    (if (= (length remaining) (length (.ref generic-value 'methods)))
      generic-value
      (begin
        (.put! method-value 'generic-function #f)
        (.put! generic-value 'methods remaining)
        (.put! generic-value 'generation (+ 1 (.ref generic-value 'generation)))
        generic-value))))

;; : (-> Symbol ClosGenericFunction ClosGenericBinding)
(def (poo-clos-generic-binding identity-value generic-value)
  (let (current-value (require-clos-generic generic-value))
    (unless (equal? identity-value (.ref current-value 'identity))
      (clos-fail 'generic-binding-identity-mismatch generic: identity-value))
    (poo-clos-register-generic-function!
     (checked ClosGenericBinding
              (.o (:: @ ClosGenericBinding.)
                  identity: identity-value current: current-value)
              'invalid-generic-binding))))

;; : (-> ClosGenericBinding ClosGenericFunction)
(def (poo-clos-generic-binding-current binding-value)
  (unless (element? ClosGenericBinding binding-value)
    (clos-fail 'invalid-generic-binding))
  (.ref binding-value 'current))

;; : (-> ClosGenericBinding ClosMethod ClosMethod)
(def (poo-clos-generic-binding-add-method! binding-value method-value)
  (let ((current-value (poo-clos-generic-binding-current binding-value))
        (admitted-method (require-clos-method method-value)))
    (.put! binding-value 'current
           (poo-clos-add-method current-value admitted-method))
    admitted-method))

;;; Effective-method construction validates the finished POO value so malformed
;;; qualifier lists cannot enter execution.
;; : (-> ClosGenericFunction [SchemeValue]
;;        [ClosMethod] [ClosMethod] [ClosMethod] [ClosMethod]
;;        ClosEffectiveMethod)
(def (make-effective-method generic-value argument-values around-values
                          before-values primary-values after-values
                          groups: (group-values '())
                          executor: (executor-value #f))
  (checked ClosEffectiveMethod
           (.o (:: @ ClosEffectiveMethod.)
               generic: generic-value arguments: argument-values
               around: around-values before: before-values
               primary: primary-values after: after-values
               groups: group-values executor: executor-value)
           'invalid-effective-method))

;;; Frames bind one effective method, current argument set, continuation, qualifier, and
;;; exact method descriptor into a native POO value.
;; : (-> ClosEffectiveMethod [SchemeValue] (Maybe Procedure)
;;        MethodQualifier ClosMethod ClosInvocationFrame)
(def (make-invocation-frame effective-method-value argument-values next-value
                            qualifier-value method-value)
  (checked ClosInvocationFrame
           (.o (:: @ ClosInvocationFrame.)
               effective-method: effective-method-value
               arguments: argument-values next: next-value
               qualifier: qualifier-value method: method-value)
           'invalid-invocation-frame))
