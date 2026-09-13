;;; -*- Gerbil -*-
;;; POO-native CLOS classes and direct/effective slot projection.

(import (only-in :clan/poo/object .o .ref .put!)
        (only-in :clan/poo/mop element?)
        (only-in :std/misc/hash hash-ref/default hash-remove!)
        (only-in :std/srfi/1 find filter filter-map foldl)
        "types.ss" "objects.ss")

(export ClosDirectSlotDefinition ClosEffectiveSlotDefinition ClosClass
        poo-clos-standard-object-class poo-clos-direct-slot-definition
        poo-clos-class poo-clos-class-precedence-list
        poo-clos-find-class poo-clos-set-find-class! poo-clos-resolve-class
        poo-clos-class-effective-slots poo-clos-find-effective-slot
        poo-clos-class-subclass? poo-clos-class-specializer
        poo-clos-class-slot-cell poo-clos-current-class
        %poo-clos-make-class-generation %poo-clos-reinitialize-class!
        %poo-clos-set-class-name!)

;; : POOObject
(def ClosDirectSlotDefinition. (.ref ClosDirectSlotDefinition 'proto))
;; : POOObject
(def ClosEffectiveSlotDefinition. (.ref ClosEffectiveSlotDefinition 'proto))
;; : POOObject
(def ClosClass. (.ref ClosClass 'proto))
;; : POOObject
(def ClosSlotCell. (.ref ClosSlotCell 'proto))

(def +poo-clos-no-initform+ (cons 'poo-clos 'no-initform))

;;; The ANSI class-name namespace is process-local and identity keyed.  Lexical
;;; `.defclass` bindings remain ordinary POO values, while symbolic class
;;; designators resolve through this single registry.
(def poo-clos-class-registry (make-hash-table-eq))

;; : (-> Symbol Boolean (Maybe ClosClass))
(def (poo-clos-find-class name error?: (error-value #t)
                          environment: (_environment-value #f))
  (unless (symbol? name) (clos-fail 'invalid-class-name class: name))
  (let (class-value
        (hash-ref/default poo-clos-class-registry name (lambda () #f)))
    (when (and (not class-value) error-value)
      (clos-fail 'class-not-found class: name operation: 'find-class))
    class-value))

;;; FIND-CLASS owns the symbol-to-class association independently from the
;;; class object's name.  A false new value removes only that association.
;; : (-> (Maybe ClosClass) Symbol error?: Boolean environment: Any
;;        (Maybe ClosClass))
(def (poo-clos-set-find-class! new-class name error?: (_error-value #t)
                               environment: (_environment-value #f))
  (unless (symbol? name) (clos-fail 'invalid-class-name class: name))
  (unless (or (not new-class) (element? ClosClass new-class))
    (clos-fail 'invalid-class class: new-class operation: 'setf-find-class))
  (if new-class
    (hash-put! poo-clos-class-registry name new-class)
    (hash-remove! poo-clos-class-registry name))
  new-class)

;; : (-> Symbol ClosClass Symbol)
(def (%poo-clos-set-class-name! new-name class-value)
  (unless (symbol? new-name)
    (clos-fail 'invalid-class-name operation: 'setf-class-name))
  (unless (element? ClosClass class-value) (clos-fail 'invalid-class))
  (.put! class-value 'identity new-name)
  new-name)

;; : (-> (U Symbol ClosClass) ClosClass)
(def (poo-clos-resolve-class value)
  (cond
   ((element? ClosClass value) value)
   ((symbol? value) (poo-clos-find-class value))
   (else (clos-fail 'invalid-class class: value))))

;; : (-> SchemeValue Boolean)
(def (initarg-name? value)
  (or (symbol? value) (keyword? value)))

(def (function-name? value)
  (or (symbol? value)
      (and (list? value) (= (length value) 2)
           (eq? (car value) 'setf) (symbol? (cadr value)))))

;; : (-> [SchemeValue] [SchemeValue])
(def (unique/identity values)
  (reverse
   (foldl (lambda (value result)
            (if (memq value result) result (cons value result)))
          '() values)))

;; : (-> [SchemeValue] Boolean)
(def (unique-identities? values)
  (= (length values) (length (unique/identity values))))

;; | ClosDirectSlotDefinition = POOObject
;; poo-clos-direct-slot-definition
;;   : (-> Symbol allocation: SlotAllocation initargs: [InitargName]
;;         initform: (Maybe Thunk) readers: [Symbol] writers: [Symbol]
;;         type-predicate: (Maybe Procedure) documentation: (Maybe String)
;;         ClosDirectSlotDefinition)
;;   | contract: captures one direct slot declaration without evaluating its
;;     optional initform thunk.
;;   | doc m%
;;   | result: an immutable POO direct-slot metaobject.
(def (poo-clos-direct-slot-definition
      identity-value allocation: (allocation-value 'instance)
      initargs: (initarg-values '())
      initform: (initform-value +poo-clos-no-initform+)
      readers: (reader-values '()) writers: (writer-values '())
      type-predicate: (type-predicate-value #f)
      documentation: (documentation-value #f))
  (unless (symbol? identity-value)
    (clos-fail 'invalid-slot-name slot: identity-value))
  (unless (memq allocation-value '(instance class))
    (clos-fail 'invalid-slot-allocation slot: identity-value))
  (unless (and (list? initarg-values) (andmap initarg-name? initarg-values))
    (clos-fail 'invalid-slot-initargs slot: identity-value))
  (unless (and (list? reader-values) (andmap function-name? reader-values)
               (list? writer-values) (andmap function-name? writer-values))
    (clos-fail 'invalid-slot-accessors slot: identity-value))
  (unless (or (eq? initform-value +poo-clos-no-initform+)
              (procedure? initform-value))
    (clos-fail 'invalid-slot-initform slot: identity-value))
  (unless (or (not type-predicate-value) (procedure? type-predicate-value))
    (clos-fail 'invalid-slot-type-predicate slot: identity-value))
  (unless (or (not documentation-value) (string? documentation-value))
    (clos-fail 'invalid-slot-documentation slot: identity-value))
  (checked
   ClosDirectSlotDefinition
   (.o (:: @ ClosDirectSlotDefinition.)
       identity: identity-value allocation: allocation-value
       initargs: (unique/identity initarg-values)
       initfunction: (if (eq? initform-value +poo-clos-no-initform+)
                       #f initform-value)
       readers: (unique/identity reader-values)
       writers: (unique/identity writer-values)
       type-predicate: type-predicate-value
       documentation: documentation-value)
   'invalid-direct-slot-definition))

;; : (-> SchemeValue Boolean)
(def (default-initarg-entry? value)
  (and (pair? value) (initarg-name? (car value)) (procedure? (cdr value))))

;; : (-> [SchemeValue] [Pair])
(def (require-default-initargs values)
  (unless (and (list? values) (andmap default-initarg-entry? values))
    (clos-fail 'invalid-default-initargs))
  (unless (unique-identities? (map car values))
    (clos-fail 'duplicate-default-initarg))
  values)

;; : (-> [ClosDirectSlotDefinition] [ClosDirectSlotDefinition])
(def (require-direct-slots values)
  (unless (and (list? values)
               (andmap (lambda (value)
                         (element? ClosDirectSlotDefinition value))
                       values))
    (clos-fail 'invalid-direct-slots))
  (unless (unique-identities? (map (lambda (slot) (.ref slot 'identity)) values))
    (clos-fail 'duplicate-direct-slot))
  values)

;; : (-> [ClosClass] [ClosClass])
(def (require-direct-superclasses values)
  (unless (and (list? values)
               (andmap (lambda (value) (element? ClosClass value)) values))
    (clos-fail 'invalid-direct-superclasses))
  (unless (unique-identities? values)
    (clos-fail 'duplicate-direct-superclass))
  values)

;; : (-> ClosClass [POOObject] POOObject)
(def (instance-prototype-value class-value superclass-prototypes)
  (.o (:: @ superclass-prototypes) %poo-clos-class: class-value))

;; : (-> ClosClass POOObject)
(def (class-instance-prototype class-value)
  (.ref class-value 'instance-prototype))

;; : (-> ClosClass [ClosClass])
(def (class-direct-superclasses class-value)
  (.ref class-value 'direct-superclasses))

;; poo-clos-current-class
;;   : (-> ClosClass ClosClass)
;;   | contract: follows only single-assignment successor edges and never
;;     recomputes or substitutes native POO C3 precedence.
;;   | doc m%
;;       `poo-clos-current-class` follows a finite historical chain.
;;
;;       # Examples
;;       ```scheme
;;       (poo-clos-current-class historical-class)
;;       ;; => current-class
;;       ```
;;
;;       result: the final reachable class generation.
;;     %
(def (poo-clos-current-class class-value)
  (unless (element? ClosClass class-value) (clos-fail 'invalid-class))
  class-value)

;; : (-> ClosClass POOObject)
(def (make-instance-prototype class-value)
  (let (superclass-prototypes
        (map class-instance-prototype
             (class-direct-superclasses class-value)))
    (instance-prototype-value class-value superclass-prototypes)))

;;; ANSI Common Lisp 4.3.5 defines the CLOS CPL as a topological sort over the
;;; union of every reachable class's local precedence order.  Its ambiguity
;;; rule chooses the candidate having a direct subclass rightmost in the CPL
;;; accumulated so far.  This is deliberately not C3: the native POO prototype
;;; may retain C3 for ordinary POO lookup, while every CLOS semantic consumer
;;; reads this independently computed logical CPL.

;; : (-> [ClosClass] [Pair])
(def (adjacent-precedence-pairs classes)
  (if (or (null? classes) (null? (cdr classes)))
    '()
    (cons (cons (car classes) (cadr classes))
          (adjacent-precedence-pairs (cdr classes)))))

;; : (forall (a) (-> [a] [a] [a]))
(def (enqueue-reversed values rear)
  (foldl cons rear values))

;; : (-> ClosClass [ClosClass])
(def (reachable-classes class-value)
  ;; This is a two-list graph queue.  It preserves breadth-first source order
  ;; without repeatedly copying the pending frontier with append.
  (let walk ((front (list class-value)) (rear '()) (seen '()))
    (cond
     ((null? front)
      (if (null? rear)
        (reverse seen)
        (walk (reverse rear) '() seen)))
     ((memq (car front) seen)
      (walk (cdr front) rear seen))
     (else
      (let (candidate (car front))
        (walk (cdr front)
              (enqueue-reversed (.ref candidate 'direct-superclasses) rear)
              (cons candidate seen)))))))

;; : (-> [ClosClass] [Pair])
(def (precedence-constraints classes)
  (apply append
         (map (lambda (candidate)
                (adjacent-precedence-pairs
                 (cons candidate (.ref candidate 'direct-superclasses))))
              classes)))

;; : (-> ClosClass [Pair] Boolean)
(def (class-has-predecessor? class-value constraints)
  (if (find (lambda (constraint)
              (eq? (cdr constraint) class-value))
            constraints)
    #t #f))

;; : (-> [ClosClass] [ClosClass] (Maybe ClosClass))
(def (select-ambiguous-class candidates result)
  ;; `result` is accumulated in reverse, so its head is precisely the
  ;; rightmost class in the logical CPL constructed so far.
  (let loop ((owners result))
    (and (pair? owners)
         (or (find (lambda (superclass)
                     (if (memq superclass candidates) #t #f))
                   (.ref (car owners) 'direct-superclasses))
             (loop (cdr owners))))))

;; : (-> ClosClass [ClosClass])
(def (compute-class-precedence-list class-value)
  (let* ((classes (reachable-classes class-value))
         (initial-constraints (precedence-constraints classes)))
    (let loop ((remaining classes)
               (constraints initial-constraints)
               (result '()))
      (if (null? remaining)
        (reverse result)
        (let* ((candidates
                (filter (lambda (candidate)
                          (not (class-has-predecessor?
                                candidate constraints)))
                        remaining))
               (next
                (cond
                 ((null? candidates) #f)
                 ((null? (cdr candidates)) (car candidates))
                 (else (select-ambiguous-class candidates result)))))
          (unless next
            (clos-fail 'inconsistent-class-precedence
                       class: (.ref class-value 'identity)))
          (loop (filter (lambda (candidate) (not (eq? candidate next)))
                        remaining)
                (filter (lambda (constraint)
                          (not (eq? (car constraint) next)))
                        constraints)
                (cons next result)))))))

;; : (-> ClosClass Symbol [Pair])
(def (slot-descriptions class-value slot-name)
  (filter-map
   (lambda (owner-class)
     (let (direct-slot
           (find (lambda (candidate)
                   (eq? (.ref candidate 'identity) slot-name))
                 (.ref owner-class 'direct-slots)))
       (and direct-slot (cons owner-class direct-slot))))
   (.ref class-value 'class-precedence-list)))

;; : (-> [Pair] Symbol (Maybe SchemeValue))
(def (first-slot-option descriptions option)
  (let (description
        (find (lambda (entry) (.ref (cdr entry) option)) descriptions))
    (and description (.ref (cdr description) option))))

;; : (-> [Pair] Symbol [SchemeValue])
(def (merged-slot-list descriptions option)
  (unique/identity
   (apply append
          (map (lambda (entry) (.ref (cdr entry) option)) descriptions))))

;; : (-> ClosClass Symbol ClosEffectiveSlotDefinition)
(def (compute-effective-slot class-value slot-name)
  (let* ((descriptions (slot-descriptions class-value slot-name))
         (most-specific (car descriptions))
         (most-specific-slot (cdr most-specific))
         (allocation-value (.ref most-specific-slot 'allocation))
         (initfunction-value
          (first-slot-option descriptions 'initfunction))
         (documentation-value
          (first-slot-option descriptions 'documentation))
         (type-predicate-values
          (filter-map (lambda (entry) (.ref (cdr entry) 'type-predicate))
                      descriptions)))
    (checked
     ClosEffectiveSlotDefinition
     (.o (:: @ ClosEffectiveSlotDefinition.)
         identity: slot-name allocation: allocation-value
         initargs: (merged-slot-list descriptions 'initargs)
         initfunction: initfunction-value
         readers: (merged-slot-list descriptions 'readers)
         writers: (merged-slot-list descriptions 'writers)
         type-predicates: type-predicate-values
         documentation: documentation-value
         defining-classes: (map car descriptions)
         storage-class: (car most-specific))
     'invalid-effective-slot-definition)))

;; : (-> ClosClass [ClosEffectiveSlotDefinition])
(def (compute-effective-slots class-value)
  (let (slot-names
        (unique/identity
         (apply append
                (map (lambda (owner-class)
                       (map (lambda (slot) (.ref slot 'identity))
                            (.ref owner-class 'direct-slots)))
                     (.ref class-value 'class-precedence-list)))))
    (map (lambda (slot-name)
           (compute-effective-slot class-value slot-name))
         slot-names)))

;; : (-> ClosSlotCell)
(def (make-slot-cell)
  (checked ClosSlotCell
           (.o (:: @ ClosSlotCell.) bound?: #f value: #f)
           'invalid-slot-cell))

;; : (-> ClosClass Symbol ClosSlotCell)
(def (poo-clos-class-slot-cell class-value slot-name)
  (let* ((storage (.ref class-value 'class-storage))
         (existing (hash-ref/default storage slot-name (lambda () #f))))
    (or existing
        (let (cell (make-slot-cell))
          (hash-put! storage slot-name cell)
          cell))))

;; : (-> ClosClass ClosClass)
(def (initialize-direct-class-slots! class-value)
  (for-each
   (lambda (slot)
     (when (and (eq? (.ref slot 'allocation) 'class)
                (eq? (.ref slot 'storage-class) class-value))
       (let ((cell (poo-clos-class-slot-cell
                    class-value (.ref slot 'identity)))
             (initfunction (.ref slot 'initfunction)))
         (when (and initfunction (not (.ref cell 'bound?)))
           (.put! cell 'value (initfunction))
           (.put! cell 'bound? #t)))))
   (.ref class-value 'effective-slots))
  class-value)

;; | ClosClass = POOObject
;; %poo-clos-make-class-generation
;;   : (-> Symbol [ClosClass] [ClosDirectSlotDefinition] [Pair] Natural
;;        (Maybe Procedure) (Maybe Procedure) (Maybe ClosClass)
;;        (Maybe Procedure) (Maybe Procedure) ClosClass)
;;   | contract: validates and finalizes one native-POO class generation before
;;     registering its direct dependency edges.
;;   | doc m%
;;       `%poo-clos-make-class-generation` is the checked internal constructor.
;;
;;       # Examples
;;       ```scheme
;;       (%poo-clos-make-class-generation 'root '() '() '() 0
;;                                        #f #f #f #f #f)
;;       ;; => class-generation
;;       ```
;;
;;       result: a complete class generation with an ANSI CLOS logical CPL and
;;       effective slots over a native POO prototype.
;;     %
(def (%poo-clos-make-class-generation
      identity-value superclass-values direct-slot-values
      default-initarg-values generation-value
      slot-missing-handler-value slot-unbound-handler-value
      predecessor-value redefinition-handler-value different-handler-value)
  (unless (symbol? identity-value)
    (clos-fail 'invalid-class-name class: identity-value))
  (let ((superclass-values (require-direct-superclasses superclass-values))
        (direct-slot-values (require-direct-slots direct-slot-values))
        (default-initarg-values
         (require-default-initargs default-initarg-values)))
  (unless (and (exact-integer? generation-value) (>= generation-value 0))
    (clos-fail 'invalid-class-generation class: identity-value))
  (unless (or (not predecessor-value) (element? ClosClass predecessor-value))
    (clos-fail 'invalid-class-predecessor class: identity-value))
  (unless (or (not slot-missing-handler-value)
              (procedure? slot-missing-handler-value))
    (clos-fail 'invalid-slot-missing-handler class: identity-value))
  (unless (or (not slot-unbound-handler-value)
              (procedure? slot-unbound-handler-value))
    (clos-fail 'invalid-slot-unbound-handler class: identity-value))
  (unless (or (not redefinition-handler-value)
              (procedure? redefinition-handler-value))
    (clos-fail 'invalid-redefinition-update-handler class: identity-value))
  (unless (or (not different-handler-value)
              (procedure? different-handler-value))
    (clos-fail 'invalid-different-class-update-handler class: identity-value))
  (let (candidate
        (.o (:: self ClosClass.)
            identity: identity-value
            direct-superclasses: superclass-values
            direct-slots: direct-slot-values
            default-initargs: default-initarg-values
            generation: generation-value
            slot-missing-handler: slot-missing-handler-value
            slot-unbound-handler: slot-unbound-handler-value
            predecessor: predecessor-value successor: #f
            direct-subclasses: '()
            layout-history: '()
            redefinition-update-handler: redefinition-handler-value
            different-class-update-handler: different-handler-value
            documentation: #f metaclass: 'standard-class
            class-storage: (make-hash-table-eq)
            instance-prototype: (make-instance-prototype self)
            class-precedence-list: (compute-class-precedence-list self)
            effective-slots: (compute-effective-slots self)))
    (let (class-value
          (initialize-direct-class-slots!
           (checked ClosClass candidate 'invalid-class)))
      (for-each
       (lambda (superclass)
         (.put! superclass 'direct-subclasses
                (cons class-value (.ref superclass 'direct-subclasses))))
       superclass-values)
      class-value))))

;;; Redefinition preserves the class metaobject identity required by ANSI
;;; Common Lisp 4.3.6.  Historical effective-slot projections remain inert
;;; layout evidence for lazy instance migration; they are not class objects and
;;; cannot participate in dispatch or inheritance.
;; : (-> ClosClass [ClosClass] [ClosDirectSlotDefinition] [Pair]
;;        (Maybe Procedure) (Maybe Procedure) (Maybe Procedure)
;;        (Maybe Procedure) ClosClass)
(def (%poo-clos-reinitialize-class!
      class-value superclass-values direct-slot-values default-initarg-values
      slot-missing-handler-value slot-unbound-handler-value
      redefinition-handler-value different-handler-value)
  (unless (element? ClosClass class-value) (clos-fail 'invalid-class))
  (let ((superclass-values (require-direct-superclasses superclass-values))
        (direct-slot-values (require-direct-slots direct-slot-values))
        (default-initarg-values
         (require-default-initargs default-initarg-values)))
    (for-each
     (lambda (superclass)
       (.put! superclass 'direct-subclasses
              (filter (lambda (candidate) (not (eq? candidate class-value)))
                      (.ref superclass 'direct-subclasses))))
     (.ref class-value 'direct-superclasses))
    (let ((old-generation (.ref class-value 'generation))
          (old-effective-slots (.ref class-value 'effective-slots)))
      (.put! class-value 'layout-history
             (cons (.o generation: old-generation
                       effective-slots: old-effective-slots)
                   (.ref class-value 'layout-history))))
    (.put! class-value 'direct-superclasses superclass-values)
    (.put! class-value 'direct-slots direct-slot-values)
    (.put! class-value 'default-initargs default-initarg-values)
    (.put! class-value 'slot-missing-handler slot-missing-handler-value)
    (.put! class-value 'slot-unbound-handler slot-unbound-handler-value)
    (.put! class-value 'redefinition-update-handler redefinition-handler-value)
    (.put! class-value 'different-class-update-handler different-handler-value)
    (.put! class-value 'generation (+ 1 (.ref class-value 'generation)))
    (.put! class-value 'predecessor #f)
    (.put! class-value 'successor #f)
    (.put! class-value 'instance-prototype
           (make-instance-prototype class-value))
    (.put! class-value 'class-precedence-list
           (compute-class-precedence-list class-value))
    (.put! class-value 'effective-slots
           (compute-effective-slots class-value))
    (for-each
     (lambda (superclass)
       (.put! superclass 'direct-subclasses
              (cons class-value (.ref superclass 'direct-subclasses))))
     superclass-values)
    (initialize-direct-class-slots! class-value)))

;;; The root class contributes no slots; all ordinary classes with an omitted
;;; superclass list inherit from this exact class and native POO prototype.
(def poo-clos-standard-object-class
  (%poo-clos-make-class-generation
   'standard-object '() '() '() 0 #f #f #f #f #f))

(hash-put! poo-clos-class-registry 'standard-object
           poo-clos-standard-object-class)

;; | ClosClass = POOObject
;; poo-clos-class
;;   : (-> Symbol direct-superclasses: [ClosClass]
;;         direct-slots: [ClosDirectSlotDefinition]
;;         default-initargs: [Pair] slot-missing-handler: (Maybe Procedure)
;;         slot-unbound-handler: (Maybe Procedure) ClosClass)
;;   | contract: creates one finalized class generation whose instance
;;     prototype is lowered to native POO inheritance while CLOS semantics use
;;     the independently computed ANSI class precedence list.
;;   | doc m%
;;   | result: a POO class metaobject with lazy effective slots.
(def (poo-clos-class
      identity-value direct-superclasses: (superclass-values #f)
      direct-slots: (direct-slot-values '())
      default-initargs: (default-initarg-values '())
      slot-missing-handler: (slot-missing-handler-value #f)
      slot-unbound-handler: (slot-unbound-handler-value #f)
      redefinition-update-handler: (redefinition-handler-value #f)
      different-class-update-handler: (different-handler-value #f)
      documentation: (documentation-value #f)
      metaclass: (metaclass-value 'standard-class))
  (unless (or (not documentation-value) (string? documentation-value))
    (clos-fail 'invalid-class-documentation class: identity-value))
  (let (class-value
        (%poo-clos-make-class-generation
         identity-value
         (map poo-clos-resolve-class
              (or superclass-values (list poo-clos-standard-object-class)))
         direct-slot-values default-initarg-values 0
         slot-missing-handler-value slot-unbound-handler-value #f
         redefinition-handler-value different-handler-value))
    (.put! class-value 'documentation documentation-value)
    (.put! class-value 'metaclass metaclass-value)
    (hash-put! poo-clos-class-registry identity-value class-value)
    class-value))

;; : (-> ClosClass [ClosClass])
(def (poo-clos-class-precedence-list class-value)
  (unless (element? ClosClass class-value) (clos-fail 'invalid-class))
  (.ref class-value 'class-precedence-list))

;; : (-> ClosClass [ClosEffectiveSlotDefinition])
(def (poo-clos-class-effective-slots class-value)
  (unless (element? ClosClass class-value) (clos-fail 'invalid-class))
  (.ref class-value 'effective-slots))

;; : (-> ClosClass Symbol (Maybe ClosEffectiveSlotDefinition))
(def (poo-clos-find-effective-slot class-value slot-name)
  (find (lambda (slot) (eq? (.ref slot 'identity) slot-name))
        (poo-clos-class-effective-slots class-value)))

;; : (-> ClosClass ClosClass Boolean)
(def (poo-clos-class-subclass? class-value superclass-value)
  (and (element? ClosClass class-value)
       (element? ClosClass superclass-value)
       (if (memq (poo-clos-current-class superclass-value)
                 (poo-clos-class-precedence-list
                  (poo-clos-current-class class-value))) #t #f)))
