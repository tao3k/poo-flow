;;; -*- Gerbil -*-
;;; Standard CLOS instance allocation, initialization, and slot access.

(import (only-in :clan/poo/object .o .ref .slot? .put! object?)
        (only-in :clan/poo/mop element?)
        (only-in :std/misc/hash hash-ref/default)
        (only-in :std/srfi/1 filter find iota)
        "types.ss" "objects.ss" "classes.ss" "dispatch.ss"
        "instance-state.ss")

(export ClosInstanceState ClosSlotCell poo-clos-instance?
        poo-clos-class-of poo-clos-allocate-instance poo-clos-make-instance
        poo-clos-initialize-instance poo-clos-shared-initialize
        poo-clos-reinitialize-instance poo-clos-slot-value
        poo-clos-set-slot-value! poo-clos-slot-bound? poo-clos-slot-exists?
        poo-clos-slot-makunbound! poo-clos-slot-reader-method
        poo-clos-slot-missing poo-clos-slot-unbound
        poo-clos-slot-missing-generic poo-clos-slot-unbound-generic
        poo-clos-slot-writer-method poo-clos-change-class
        poo-clos-update-instance-for-redefined-class
        poo-clos-update-instance-for-different-class
        poo-clos-allocate-instance-generic poo-clos-make-instance-generic
        poo-clos-initialize-instance-generic
        poo-clos-shared-initialize-generic
        poo-clos-reinitialize-instance-generic poo-clos-change-class-generic
        poo-clos-update-instance-for-redefined-class-generic
        poo-clos-update-instance-for-different-class-generic)

;; : (-> ClosInstance [Symbol] [Symbol] [SchemeValue] ClosInstance)
(def (%poo-clos-update-instance-for-redefined-class
      instance-value added discarded property-list)
  (let* ((class-value (.ref (.ref instance-value '%poo-clos-state) 'class))
         (handler (class-handler class-value 'redefinition-update-handler)))
    (if handler
      (handler instance-value added discarded property-list)
      instance-value)))

;; : (-> ClosInstance ClosInstance SchemeValue ... ClosInstance)
(def (%poo-clos-update-instance-for-different-class
      previous-value instance-value . initargs)
  (let* ((class-value (.ref (.ref instance-value '%poo-clos-state) 'class))
         (handler (class-handler class-value 'different-class-update-handler)))
    (if handler
      (apply handler previous-value instance-value initargs)
      instance-value)))

;;; One lazy step retains cells for still-present local slots, initializes only
;;; newly added slots, then invokes the class-owned redefinition update hook.
;; : (-> ClosInstance ClosInstanceState ClosClass ClosInstanceState)
(def (migrate-instance-generation! instance-value state class-value)
  (let-values (((added discarded)
                (effective-slot-difference
                 (class-effective-slots-at-generation
                  class-value (.ref state 'generation))
                 (poo-clos-class-effective-slots class-value))))
    (let ((property-list (discarded-slot-property-list state discarded))
          (new-storage (migrated-instance-storage state class-value)))
      (.put! state 'class class-value)
      (.put! state 'generation (.ref class-value 'generation))
      (.put! state 'storage new-storage)
      (shared-initialize/list instance-value added '())
      (poo-clos-update-instance-for-redefined-class
       instance-value added discarded property-list)
      state)))

;; : (-> ClosInstance ClosInstanceState)
(def (ensure-current-instance-state! instance-value)
  (unless (poo-clos-instance? instance-value) (clos-fail 'invalid-instance))
  (let* ((state (.ref instance-value '%poo-clos-state))
         (class-value (.ref state 'class)))
    (if (= (.ref state 'generation) (.ref class-value 'generation))
      state
      (migrate-instance-generation! instance-value state class-value))))

;; : (-> ClosInstance ClosClass)
(def (poo-clos-class-of instance-value)
  (.ref (ensure-current-instance-state! instance-value) 'class))

;; : (-> ClosClass ClosInstance)
(def (%poo-clos-allocate-instance class-value . _initargs)
  (let (current-value
        (poo-clos-current-class (poo-clos-resolve-class class-value)))
    (.o (:: @ (.ref current-value 'instance-prototype))
        %poo-clos-state: (make-instance-state current-value))))

;; : (-> ClosInstance Symbol (Maybe ClosSlotCell))
(def (instance-slot-cell instance-value slot-name)
  (let* ((class-value (poo-clos-class-of instance-value))
         (slot (poo-clos-find-effective-slot class-value slot-name)))
    (and slot
         (if (eq? (.ref slot 'allocation) 'class)
           (poo-clos-class-slot-cell (.ref slot 'storage-class) slot-name)
           (hash-ref/default
            (.ref (.ref instance-value '%poo-clos-state) 'storage)
            slot-name (lambda () #f))))))

;; : (-> SchemeValue (Maybe Symbol))
(def (failure-name value)
  (cond
   ((symbol? value) value)
   ((keyword? value) (string->symbol (keyword->string value)))
   (else #f)))

;; : (-> ClosClass ClosInstance Symbol Symbol [SchemeValue] SchemeValue)
(def (call-slot-missing class-value instance-value slot-name operation args)
  (apply poo-clos-slot-missing class-value instance-value slot-name operation
         args))

;; : (-> ClosClass ClosInstance Symbol SchemeValue)
(def (call-slot-unbound class-value instance-value slot-name)
  (poo-clos-slot-unbound class-value instance-value slot-name))

;;; The standard slot protocol is expressed as ordinary mutable generic
;;; functions.  Class-owned procedure handlers remain a compatibility bridge
;;; in the default methods, not the primary extension surface.
;; : (-> ClosClass ClosInstance Symbol Symbol SchemeValue ... SchemeValue)
(def (poo-clos-slot-missing class-value instance-value slot-name operation
                            . values)
  (apply poo-clos-call poo-clos-slot-missing-generic
         class-value instance-value slot-name operation values))

;; : (-> ClosClass ClosInstance Symbol SchemeValue)
(def (poo-clos-slot-unbound class-value instance-value slot-name)
  (poo-clos-call poo-clos-slot-unbound-generic
                 class-value instance-value slot-name))

;; : ClosGenericFunction
(def poo-clos-slot-missing-generic
  (poo-clos-add-method
   (poo-clos-generic-function 'slot-missing 4 optional: 1)
   (poo-clos-method
    'slot-missing/default
    (list (poo-clos-any-specializer) (poo-clos-any-specializer)
          (poo-clos-any-specializer) (poo-clos-any-specializer))
    (lambda (_frame class-value instance-value slot-name operation . values)
      (let (handler (class-handler class-value 'slot-missing-handler))
        (if handler
          (apply handler class-value instance-value slot-name operation values)
          (clos-fail 'slot-missing class: (.ref class-value 'identity)
                     slot: slot-name operation: operation))))
    lambda-list: (poo-clos-lambda-list 4 1 #f #f '() #f))))

;; : ClosGenericFunction
(def poo-clos-slot-unbound-generic
  (poo-clos-add-method
   (poo-clos-generic-function 'slot-unbound 3)
   (poo-clos-method
    'slot-unbound/default
    (list (poo-clos-any-specializer) (poo-clos-any-specializer)
          (poo-clos-any-specializer))
    (lambda (_frame class-value instance-value slot-name)
  (let (handler (class-handler class-value 'slot-unbound-handler))
    (if handler
      (handler class-value instance-value slot-name)
          (clos-unbound-slot-fail (.ref class-value 'identity)
                                  instance-value slot-name 'slot-value))))
    lambda-list: (poo-clos-lambda-list 3 0 #f #f '() #f))))

;; | ClosInstance = POOObject
;; poo-clos-slot-value
;;   : (-> ClosInstance Symbol SchemeValue)
;;   | contract: delegates missing and unbound reads to their class hooks.
;;   | doc m%
;;   | result: the bound value or the primary value returned by a hook.
(def (poo-clos-slot-value instance-value slot-name)
  (unless (symbol? slot-name)
    (clos-fail 'invalid-slot-name slot: (failure-name slot-name)))
  (let* ((class-value (poo-clos-class-of instance-value))
         (cell (instance-slot-cell instance-value slot-name)))
    (cond
     ((not cell)
      (call-slot-missing class-value instance-value slot-name 'slot-value '()))
     ((.ref cell 'bound?) (.ref cell 'value))
     (else (call-slot-unbound class-value instance-value slot-name)))))

;; : (-> ClosInstance Symbol SchemeValue SchemeValue)
(def (poo-clos-set-slot-value! instance-value slot-name new-value)
  (unless (symbol? slot-name)
    (clos-fail 'invalid-slot-name slot: (failure-name slot-name)))
  (let* ((class-value (poo-clos-class-of instance-value))
         (cell (instance-slot-cell instance-value slot-name)))
    (if cell
      (begin
        (.put! cell 'value new-value)
        (.put! cell 'bound? #t))
      (call-slot-missing class-value instance-value slot-name
                         'setf (list new-value)))
    new-value))

;; : (-> ClosInstance Symbol Boolean)
(def (poo-clos-slot-bound? instance-value slot-name)
  (unless (symbol? slot-name)
    (clos-fail 'invalid-slot-name slot: (failure-name slot-name)))
  (let* ((class-value (poo-clos-class-of instance-value))
         (cell (instance-slot-cell instance-value slot-name)))
    (if cell
      (if (.ref cell 'bound?) #t #f)
      (if (call-slot-missing class-value instance-value slot-name
                             'slot-boundp '()) #t #f))))

;; : (-> ClosInstance Symbol Boolean)
(def (poo-clos-slot-exists? instance-value slot-name)
  (unless (symbol? slot-name)
    (clos-fail 'invalid-slot-name slot: (failure-name slot-name)))
  (if (poo-clos-find-effective-slot
       (poo-clos-class-of instance-value) slot-name) #t #f))

;; : (-> ClosInstance Symbol ClosInstance)
(def (poo-clos-slot-makunbound! instance-value slot-name)
  (unless (symbol? slot-name)
    (clos-fail 'invalid-slot-name slot: (failure-name slot-name)))
  (let* ((class-value (poo-clos-class-of instance-value))
         (cell (instance-slot-cell instance-value slot-name)))
    (if cell
      (begin
        (.put! cell 'bound? #f)
        (.put! cell 'value #f))
      (call-slot-missing class-value instance-value slot-name
                         'slot-makunbound '()))
    instance-value))

;; : (-> [SchemeValue] Boolean)
(def (initialization-argument-list? values)
  (and (list? values)
       (even? (length values))
       (andmap (lambda (index)
                 (let (name (list-ref values (* 2 index)))
                   (or (symbol? name) (keyword? name))))
               (iota (/ (length values) 2)))))

;; : (-> [SchemeValue] [SchemeValue])
(def (initialization-argument-names values)
  (map (lambda (index) (list-ref values (* 2 index)))
       (iota (/ (length values) 2))))

;; : (-> [SchemeValue] SchemeValue (values Boolean SchemeValue))
(def (initialization-argument-ref arguments name)
  (let (position
        (find (lambda (index)
                (eq? (list-ref arguments (* 2 index)) name))
              (iota (/ (length arguments) 2))))
    (if position
      (values #t (list-ref arguments (+ 1 (* 2 position))))
      (values #f #f))))

;; : (-> [SchemeValue] [SchemeValue] (values Boolean SchemeValue))
(def (slot-initialization-argument arguments names)
  (let (position
        (find (lambda (index)
                (memq (list-ref arguments (* 2 index)) names))
              (iota (/ (length arguments) 2))))
    (if position
      (values #t (list-ref arguments (+ 1 (* 2 position))))
      (values #f #f))))

;; : (-> SchemeValue Boolean)
(def (allow-other-keys-name? value)
  (or (eq? value 'allow-other-keys)
      (and (keyword? value)
           (string=? (keyword->string value) "allow-other-keys"))))

;; : (-> [SchemeValue] Boolean)
(def (allow-other-keys? values)
  (let (position
        (find (lambda (index)
                (allow-other-keys-name?
                 (list-ref values (* 2 index))))
              (iota (/ (length values) 2))))
    (and position (list-ref values (+ 1 (* 2 position))))))

;; : (forall (a) (-> a [a] [a]))
(def (adjoin/identity value values)
  (if (memq value values) values (cons value values)))

;; : (-> ClosClass ClosSpecializer Boolean)
(def (specializer-admits-class? class-value specializer)
  (case (.ref specializer 'kind)
    ((any) #t)
    ((class)
     (let (target (.ref specializer 'target))
       (and (element? ClosClass target)
            (poo-clos-class-subclass? class-value target))))
    (else #f)))

;; : (-> ClosClass ClosMethod Boolean)
(def (method-admits-class? class-value method-value)
  (let (specializers (.ref method-value 'specializers))
    (and (pair? specializers)
         (specializer-admits-class? class-value (car specializers)))))

;; : (-> ClosClass ClosMethod [Symbol] [Symbol])
(def (add-method-initargs class-value method-value names)
  (let (lambda-list-value (.ref method-value 'lambda-list))
    (if (and lambda-list-value
             (method-admits-class? class-value method-value))
      (foldl adjoin/identity names (.ref lambda-list-value 'keys))
      names)))

;; : (-> ClosClass ClosGenericFunction [Symbol] [Symbol])
(def (add-generic-initargs class-value generic-value names)
  (foldl (lambda (method-value current)
           (add-method-initargs class-value method-value current))
         names (.ref generic-value 'methods)))

;; : (-> ClosClass [SchemeValue])
(def (valid-slot-initargs class-value)
  (let (slot-names
        (foldl (lambda (slot result)
                 (foldl adjoin/identity result (.ref slot 'initargs)))
               '() (poo-clos-class-effective-slots class-value)))
    (foldl (lambda (generic-value result)
             (add-generic-initargs class-value generic-value result))
           slot-names
           (list poo-clos-initialize-instance-generic
                 poo-clos-shared-initialize-generic
                 poo-clos-reinitialize-instance-generic
                 poo-clos-update-instance-for-redefined-class-generic
                 poo-clos-update-instance-for-different-class-generic))))

;; : (-> ClosClass [SchemeValue] [SchemeValue])
(def (require-initialization-arguments class-value values)
  (unless (initialization-argument-list? values)
    (clos-fail 'malformed-initialization-arguments
               class: (.ref class-value 'identity)))
  (unless (allow-other-keys? values)
    (let* ((valid-names (valid-slot-initargs class-value))
           (invalid-name
           (find (lambda (name)
                   (and (not (allow-other-keys-name? name))
                        (not (memq name valid-names))))
                 (initialization-argument-names values))))
      (when invalid-name
        (clos-fail 'invalid-initialization-argument
                   class: (.ref class-value 'identity)
                   slot: (failure-name invalid-name)
                   operation: 'initialize-instance))))
  values)

;; : (-> ClosClass [SchemeValue] [SchemeValue])
(def (default-initialization-arguments class-value supplied-values)
  (let* ((supplied-names (initialization-argument-names supplied-values))
         (state
          (foldl
           (lambda (owner-class current)
             (foldl
              (lambda (entry inner)
                (let ((seen (car inner))
                      (defaults (cdr inner))
                      (name (car entry)))
                  (if (memq name seen)
                    inner
                    (cons (cons name seen)
                          (append defaults
                                  (list name ((cdr entry))))))))
              current (.ref owner-class 'default-initargs)))
           (cons supplied-names '())
           (poo-clos-class-precedence-list class-value))))
    (append supplied-values (cdr state))))

;; : (-> ClosInstance (U Boolean [Symbol]) [SchemeValue] ClosInstance)
(def (shared-initialize/list instance-value slot-names initargs)
  (let (class-value (poo-clos-class-of instance-value))
    (require-initialization-arguments class-value initargs)
    (for-each
     (lambda (slot)
       (let-values (((supplied? supplied-value)
                     (slot-initialization-argument
                      initargs (.ref slot 'initargs))))
         (cond
          (supplied?
           (poo-clos-set-slot-value!
            instance-value (.ref slot 'identity) supplied-value))
          ((and (or (eq? slot-names #t)
                    (memq (.ref slot 'identity) slot-names))
                (not (poo-clos-slot-bound?
                      instance-value (.ref slot 'identity)))
                (.ref slot 'initfunction))
           (poo-clos-set-slot-value!
            instance-value (.ref slot 'identity)
            ((.ref slot 'initfunction)))))))
     (poo-clos-class-effective-slots class-value))
    instance-value))

;; : (-> ClosInstance (U Boolean [Symbol]) SchemeValue ... ClosInstance)
(def (%poo-clos-shared-initialize instance-value slot-names . initargs)
  (unless (or (eq? slot-names #t)
              (and (list? slot-names) (andmap symbol? slot-names)))
    (clos-fail 'invalid-shared-initialize-slot-names))
  (shared-initialize/list instance-value slot-names initargs))

;; : (-> ClosInstance SchemeValue ... ClosInstance)
(def (%poo-clos-initialize-instance instance-value . initargs)
  (shared-initialize/list instance-value #t initargs))

;; : (-> ClosInstance SchemeValue ... ClosInstance)
(def (%poo-clos-reinitialize-instance instance-value . initargs)
  (shared-initialize/list instance-value '() initargs))

;;; =change-class= preserves the original POO object identity.  A distinct
;;; snapshot object supplies the previous-class view expected by the hook.
;; : (-> ClosInstance ClosClass SchemeValue ... ClosInstance)
(def (%poo-clos-change-class instance-value new-class-value . supplied-initargs)
  (let* ((state (ensure-current-instance-state! instance-value))
         (old-class (.ref state 'class))
         (new-class
          (poo-clos-current-class (poo-clos-resolve-class new-class-value))))
    (if (eq? old-class new-class)
      (apply poo-clos-reinitialize-instance instance-value supplied-initargs)
      (let-values (((added _discarded)
                    (class-slot-difference old-class new-class)))
        (let* ((previous-state
                (instance-state-value old-class (.ref state 'generation)
                                      (.ref state 'storage)))
               (previous-value
                (.o (:: @ (.ref old-class 'instance-prototype))
                    %poo-clos-state: previous-state))
               (new-storage (migrated-instance-storage state new-class))
               (initargs
                (default-initialization-arguments
                 new-class supplied-initargs)))
          (require-initialization-arguments new-class initargs)
          (.put! state 'class new-class)
          (.put! state 'generation (.ref new-class 'generation))
          (.put! state 'storage new-storage)
          (shared-initialize/list instance-value added initargs)
          (apply poo-clos-update-instance-for-different-class
                 previous-value instance-value initargs)
          instance-value)))))

;; | ClosClass = POOObject
;; poo-clos-make-instance
;;   : (-> ClosClass SchemeValue ... ClosInstance)
;;   | contract: defaults and validates initargs before allocating an instance
;;     whose local slots begin unbound, then performs shared initialization.
;;   | doc m%
;;   | result: the initialized identity-bearing native POO instance.
(def (%poo-clos-make-instance class-value . supplied-initargs)
  (let (current-value
        (poo-clos-current-class (poo-clos-resolve-class class-value)))
    (unless (initialization-argument-list? supplied-initargs)
      (clos-fail 'malformed-initialization-arguments
                 class: (.ref current-value 'identity)))
    (let (initargs
          (default-initialization-arguments current-value supplied-initargs))
      (require-initialization-arguments current-value initargs)
      (let (instance-value (apply poo-clos-allocate-instance
                                  current-value initargs))
      (apply poo-clos-initialize-instance instance-value initargs)
        instance-value))))

;; : (-> ClosClass Symbol Symbol ClosMethod)
(def (poo-clos-slot-reader-method class-value slot-name method-identity)
  (unless (poo-clos-find-effective-slot class-value slot-name)
    (clos-fail 'slot-missing class: (.ref class-value 'identity)
               slot: slot-name operation: 'reader-method))
  (poo-clos-method
   method-identity (list (poo-clos-class-specializer class-value))
   (lambda (_frame instance-value)
     (poo-clos-slot-value instance-value slot-name))))

;; : (-> ClosClass Symbol Symbol ClosMethod)
(def (poo-clos-slot-writer-method class-value slot-name method-identity)
  (unless (poo-clos-find-effective-slot class-value slot-name)
    (clos-fail 'slot-missing class: (.ref class-value 'identity)
               slot: slot-name operation: 'writer-method))
  (poo-clos-method
   method-identity
   (list (poo-clos-any-specializer)
         (poo-clos-class-specializer class-value))
   (lambda (_frame new-value instance-value)
     (poo-clos-set-slot-value! instance-value slot-name new-value))))

;;; Standard lifecycle entry points are ordinary POO-native generic functions.
;;; The primary methods below own the default kernel behavior; callers may add
;;; class-specialized methods through the exported generic objects without
;;; installing raw class-owned procedure hooks.
;; : (-> Symbol Natural Boolean [ClosSpecializer] Procedure
;;        ClosGenericFunction)
(def (standard-lifecycle-generic identity-value required-value rest-value
                                 specializers body-value)
  (let ((generic-value
         (poo-clos-generic-function identity-value required-value
                                    rest?: rest-value))
        (lambda-list-value
         (poo-clos-lambda-list required-value 0 rest-value #f '() #f)))
    (poo-clos-add-method
     generic-value
     (poo-clos-method identity-value specializers body-value
                      lambda-list: lambda-list-value))
    generic-value))

(def class-metaobject-specializer
  (poo-clos-class-specializer (.ref ClosClass 'proto)))
(def standard-instance-specializer
  (poo-clos-class-specializer poo-clos-standard-object-class))

(def poo-clos-allocate-instance-generic
  (standard-lifecycle-generic
   'allocate-instance 1 #t (list class-metaobject-specializer)
   (lambda (_frame class-value . initargs)
     (apply %poo-clos-allocate-instance class-value initargs))))

(def poo-clos-shared-initialize-generic
  (standard-lifecycle-generic
   'shared-initialize 2 #t
   (list standard-instance-specializer (poo-clos-any-specializer))
   (lambda (_frame instance-value slot-names . initargs)
     (apply %poo-clos-shared-initialize instance-value slot-names initargs))))

(def poo-clos-initialize-instance-generic
  (standard-lifecycle-generic
   'initialize-instance 1 #t (list standard-instance-specializer)
   (lambda (_frame instance-value . initargs)
     (apply %poo-clos-initialize-instance instance-value initargs))))

(def poo-clos-reinitialize-instance-generic
  (standard-lifecycle-generic
   'reinitialize-instance 1 #t (list standard-instance-specializer)
   (lambda (_frame instance-value . initargs)
     (apply %poo-clos-reinitialize-instance instance-value initargs))))

(def poo-clos-update-instance-for-redefined-class-generic
  (standard-lifecycle-generic
   'update-instance-for-redefined-class 4 #f
   (list standard-instance-specializer (poo-clos-any-specializer)
         (poo-clos-any-specializer) (poo-clos-any-specializer))
   (lambda (_frame instance-value added discarded property-list)
     (%poo-clos-update-instance-for-redefined-class
      instance-value added discarded property-list))))

(def poo-clos-update-instance-for-different-class-generic
  (standard-lifecycle-generic
   'update-instance-for-different-class 2 #t
   (list standard-instance-specializer standard-instance-specializer)
   (lambda (_frame previous-value instance-value . initargs)
     (apply %poo-clos-update-instance-for-different-class
            previous-value instance-value initargs))))

(def poo-clos-change-class-generic
  (standard-lifecycle-generic
   'change-class 2 #t
   (list standard-instance-specializer (poo-clos-any-specializer))
   (lambda (_frame instance-value new-class-value . initargs)
     (apply %poo-clos-change-class instance-value new-class-value initargs))))

(def poo-clos-make-instance-generic
  (standard-lifecycle-generic
   'make-instance 1 #t (list (poo-clos-any-specializer))
   (lambda (_frame class-value . initargs)
     (apply %poo-clos-make-instance class-value initargs))))

(def (poo-clos-allocate-instance . arguments)
  (apply poo-clos-call poo-clos-allocate-instance-generic arguments))
(def (poo-clos-shared-initialize . arguments)
  (apply poo-clos-call poo-clos-shared-initialize-generic arguments))
(def (poo-clos-initialize-instance . arguments)
  (apply poo-clos-call poo-clos-initialize-instance-generic arguments))
(def (poo-clos-reinitialize-instance . arguments)
  (apply poo-clos-call poo-clos-reinitialize-instance-generic arguments))
(def (poo-clos-update-instance-for-redefined-class . arguments)
  (apply poo-clos-call
         poo-clos-update-instance-for-redefined-class-generic arguments))
(def (poo-clos-update-instance-for-different-class . arguments)
  (apply poo-clos-call
         poo-clos-update-instance-for-different-class-generic arguments))
(def (poo-clos-change-class . arguments)
  (apply poo-clos-call poo-clos-change-class-generic arguments))
(def (poo-clos-make-instance . arguments)
  (apply poo-clos-call poo-clos-make-instance-generic arguments))

(for-each poo-clos-register-generic-function!
          (list poo-clos-allocate-instance-generic
                poo-clos-shared-initialize-generic
                poo-clos-initialize-instance-generic
                poo-clos-reinitialize-instance-generic
                poo-clos-update-instance-for-redefined-class-generic
                poo-clos-update-instance-for-different-class-generic
                poo-clos-change-class-generic
                poo-clos-make-instance-generic))

