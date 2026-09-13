;;; -*- Gerbil -*-
;;; POO-native CLOS class, slot, and instance lifecycle conformance.

(import (only-in :std/test
                 test-suite test-case check-equal? check-exception check)
        (only-in :clan/poo/object .ref object?)
        "../src/module-system/poo-clos/interface.ss")

(export poo-clos-lifecycle-test)

(def (failure-code? code)
  (lambda (error)
    (and (poo-clos-failure? error)
         (eq? (.ref error 'code) code))))

(def (class-identities class-value)
  (map (lambda (entry) (.ref entry 'identity))
       (poo-clos-class-precedence-list class-value)))

(def (slot-names class-value)
  (map (lambda (slot) (.ref slot 'identity))
       (poo-clos-class-effective-slots class-value)))

(def poo-clos-lifecycle-test
  (test-suite "POO-native CLOS class and instance lifecycle"
    (test-case "ANSI CPL closes a diamond and effective slot options merge"
      (let* ((root-slot
              (poo-clos-direct-slot-definition
               'payload initargs: (list root:)
               initform: (lambda () 'root)))
             (left-slot
              (poo-clos-direct-slot-definition
               'payload initargs: (list left:)))
             (right-slot
              (poo-clos-direct-slot-definition
               'payload initargs: (list right:)
               initform: (lambda () 'right)))
             (root (poo-clos-class 'root direct-slots: (list root-slot)))
             (left (poo-clos-class 'left direct-superclasses: (list root)
                                   direct-slots: (list left-slot)))
             (right (poo-clos-class 'right direct-superclasses: (list root)
                                    direct-slots: (list right-slot)))
             (leaf (poo-clos-class 'leaf
                                   direct-superclasses: (list left right)))
             (effective (poo-clos-find-effective-slot leaf 'payload))
             (instance-value (poo-clos-make-instance leaf)))
        (check-equal? (class-identities leaf)
                      '(leaf left right root standard-object))
        (check-equal? (slot-names leaf) '(payload))
        (check-equal? (.ref effective 'allocation) 'instance)
        (check-equal? (.ref effective 'initargs) (list left: right: root:))
        (check-equal? (map (lambda (entry) (.ref entry 'identity))
                           (.ref effective 'defining-classes))
                      '(left right root))
        (check-equal? (poo-clos-slot-value instance-value 'payload) 'right)
        (check (poo-clos-class-subclass? leaf root) => #t)))

    (test-case "ANSI CPL preserves the specified non-monotonic pedalo order"
      ;; Barrett et al., figure 2, is the canonical counterexample separating
      ;; the ANSI CLOS topological sort from C3.  In particular wheel-boat must
      ;; precede day-boat in pedalo even though each direct superclass orders
      ;; day-boat before wheel-boat in its own CPL.
      (let* ((boat (poo-clos-class 'boat))
             (day-boat
              (poo-clos-class 'day-boat direct-superclasses: (list boat)))
             (wheel-boat
              (poo-clos-class 'wheel-boat direct-superclasses: (list boat)))
             (engineless
              (poo-clos-class 'engineless
                              direct-superclasses: (list day-boat)))
             (pedal-wheel-boat
              (poo-clos-class
               'pedal-wheel-boat
               direct-superclasses: (list engineless wheel-boat)))
             (small-multihull
              (poo-clos-class 'small-multihull
                              direct-superclasses: (list day-boat)))
             (small-catamaran
              (poo-clos-class 'small-catamaran
                              direct-superclasses: (list small-multihull)))
             (pedalo
              (poo-clos-class
               'pedalo
               direct-superclasses: (list pedal-wheel-boat
                                           small-catamaran))))
        (check-equal?
         (class-identities pedal-wheel-boat)
         '(pedal-wheel-boat engineless day-boat wheel-boat boat
                            standard-object))
        (check-equal?
         (class-identities small-catamaran)
         '(small-catamaran small-multihull day-boat boat standard-object))
        (check-equal?
         (class-identities pedalo)
         '(pedalo pedal-wheel-boat engineless wheel-boat small-catamaran
                  small-multihull day-boat boat standard-object))))

    (test-case "explicit and default initargs precede initforms with leftmost wins"
      (let ((default-count 0)
            (initform-count 0))
        (def slot
          (poo-clos-direct-slot-definition
           'value initargs: (list first: second:)
           initform: (lambda ()
                       (set! initform-count (+ initform-count 1))
                       'from-initform)))
        (def class-value
          (poo-clos-class
           'initialized direct-slots: (list slot)
           default-initargs:
           (list (cons second:
                       (lambda ()
                         (set! default-count (+ default-count 1))
                         'from-default)))))
        (let ((explicit
               (poo-clos-make-instance class-value first: 'explicit
                                       second: 'ignored))
              (defaulted (poo-clos-make-instance class-value)))
          (check-equal? (poo-clos-slot-value explicit 'value) 'explicit)
          (check-equal? (poo-clos-slot-value defaulted 'value) 'from-default)
          (check-equal? default-count 1)
          (check-equal? initform-count 0))))

    (test-case "class names are registered ANSI class designators"
      (let* ((source (poo-clos-class 'registered-source))
             (target (poo-clos-class 'registered-target))
             (instance (poo-clos-make-instance 'registered-source)))
        (check (eq? (poo-clos-find-class 'registered-source) source) => #t)
        (check-equal? (poo-clos-find-class 'missing-class error?: #f) #f)
        (check (eq? (poo-clos-class-of instance) source) => #t)
        (check (eq? (poo-clos-change-class instance 'registered-target)
                    instance)
               => #t)
        (check (eq? (poo-clos-class-of instance) target) => #t)
        (check (eq? (poo-clos-set-find-class! source 'registered-alias)
                    source) => #t)
        (check (eq? (poo-clos-find-class 'registered-alias) source) => #t)
        (check-equal? (poo-clos-set-find-class! #f 'registered-alias) #f)
        (check-equal? (poo-clos-find-class 'registered-alias error?: #f) #f)
        (check-equal? (poo-clos-set-class-name! 'renamed-source source)
                      'renamed-source)
        (check-equal? (poo-clos-class-name source) 'renamed-source)
        ;; Naming and association are independent until FIND-CLASS is set.
        (check (eq? (poo-clos-find-class 'registered-source) source) => #t)
        (check-equal? (poo-clos-find-class 'renamed-source error?: #f) #f)
        (poo-clos-set-find-class! source 'renamed-source)
        (check (eq? (poo-clos-find-class 'renamed-source) source) => #t)
        (check-exception (poo-clos-make-instance 'missing-class)
                         (failure-code? 'class-not-found))))

    (test-case "standard lifecycle entry points are extensible generic functions"
      (let* ((slot
              (poo-clos-direct-slot-definition
               'initialized initform: (lambda () 'default)))
             (class-value
              (poo-clos-class 'custom-initialization direct-slots: (list slot)))
             (method
              (poo-clos-method
               'custom-initialize
               (list (poo-clos-class-specializer class-value))
               (lambda (frame instance-value . initargs)
                 (apply poo-clos-call-next-method
                        frame instance-value initargs)
                 (poo-clos-set-slot-value!
                  instance-value 'initialized (cadr initargs)))
               lambda-list:
               (poo-clos-lambda-list 1 0 #f #t (list custom:) #f))))
        (poo-clos-add-method poo-clos-initialize-instance-generic method)
        (let (instance (poo-clos-make-instance class-value custom: 'custom))
          (check-equal? (poo-clos-slot-value instance 'initialized) 'custom)
          (check (eq? (poo-clos-method-generic-function method)
                      poo-clos-initialize-instance-generic)
                 => #t)
          (check-equal?
           (call-with-values
            (lambda () (poo-clos-function-keywords method)) list)
           (list (list custom:) #f)))))

    (test-case "class-allocated cells are shared and a redefining subclass owns a new cell"
      (let (class-init-count 0)
        (def shared-slot
          (poo-clos-direct-slot-definition
           'counter allocation: 'class initform:
           (lambda ()
             (set! class-init-count (+ class-init-count 1))
             10)))
        (def base
          (poo-clos-class 'shared-base direct-slots: (list shared-slot)))
        (def inherited
          (poo-clos-class 'shared-child direct-superclasses: (list base)))
        (def replacement-slot
          (poo-clos-direct-slot-definition 'counter allocation: 'class))
        (def replaced
          (poo-clos-class 'replaced-child direct-superclasses: (list base)
                          direct-slots: (list replacement-slot)))
        (let ((one (poo-clos-make-instance base))
              (two (poo-clos-make-instance inherited))
              (three (poo-clos-make-instance replaced)))
          (check-equal? class-init-count 2)
          (check-equal? (poo-clos-slot-value one 'counter) 10)
          (poo-clos-set-slot-value! two 'counter 11)
          (check-equal? (poo-clos-slot-value one 'counter) 11)
          (check-equal? (poo-clos-slot-value three 'counter) 10)
          (poo-clos-set-slot-value! three 'counter 30)
          (check-equal? (poo-clos-slot-value two 'counter) 11)
          (check-equal? (poo-clos-slot-value three 'counter) 30))))

    (test-case "bound state and missing or unbound hooks have exact operations"
      (let (events '())
        (def plain-slot (poo-clos-direct-slot-definition 'plain))
        (def hooked
          (poo-clos-class
           'hooked direct-slots: (list plain-slot)
           slot-missing-handler:
           (lambda (_class _instance slot operation . values)
             (set! events (append events (list (list slot operation values))))
             (eq? operation 'slot-boundp))
           slot-unbound-handler:
           (lambda (_class _instance slot)
             (set! events (append events (list (list slot 'slot-unbound))))
             'unbound-value)))
        (let (instance-value (poo-clos-make-instance hooked))
          (check-equal? (poo-clos-slot-bound? instance-value 'plain) #f)
          (check-equal? (poo-clos-slot-value instance-value 'plain)
                        'unbound-value)
          (check-equal? (poo-clos-slot-bound? instance-value 'missing) #t)
          (check-equal? (poo-clos-slot-value instance-value 'missing) #f)
          (poo-clos-set-slot-value! instance-value 'missing 8)
          (poo-clos-slot-makunbound! instance-value 'missing)
          (check-equal?
           events
           '((plain slot-unbound)
             (missing slot-boundp ())
             (missing slot-value ())
             (missing setf (8))
             (missing slot-makunbound ()))))))

    (test-case "default hooks raise typed failures and makunbound preserves identity"
      (let* ((slot (poo-clos-direct-slot-definition 'state))
             (class-value (poo-clos-class 'plain direct-slots: (list slot)))
             (instance-value (poo-clos-allocate-instance class-value)))
        (check (object? instance-value) => #t)
        (check (poo-clos-instance? instance-value) => #t)
        (check (eq? (poo-clos-class-of instance-value) class-value) => #t)
        (check-exception (poo-clos-slot-value instance-value 'state)
                         (failure-code? 'slot-unbound))
        (check-exception (poo-clos-slot-value instance-value 'absent)
                         (failure-code? 'slot-missing))
        (poo-clos-set-slot-value! instance-value 'state #f)
        (check-equal? (poo-clos-slot-bound? instance-value 'state) #t)
        (check-equal? (poo-clos-slot-value instance-value 'state) #f)
        (check (eq? (poo-clos-slot-makunbound! instance-value 'state)
                    instance-value) => #t)
        (check-equal? (poo-clos-slot-bound? instance-value 'state) #f)))

    (test-case "unbound slot failures retain their condition subtype and instance"
      (let* ((slot (poo-clos-direct-slot-definition 'state))
             (class-value
              (poo-clos-class 'typed-unbound-slot direct-slots: (list slot)))
             (instance-value (poo-clos-allocate-instance class-value))
             (condition #f))
        (with-exception-catcher
         (lambda (failure) (set! condition failure))
         (lambda () (poo-clos-slot-value instance-value 'state)))
        (check (poo-clos-failure? condition) => #t)
        (check (poo-clos-unbound-slot? condition) => #t)
        (check (eq? (poo-clos-unbound-slot-instance condition)
                    instance-value) => #t)
        (check-equal? (.ref condition 'slot) 'state)))

    (test-case "slot-missing and slot-unbound are ordinary mutable generics"
      (let* ((slot (poo-clos-direct-slot-definition 'state))
             (class-value
              (poo-clos-class 'generic-slot-protocol
                              direct-slots: (list slot)))
             (instance-value (poo-clos-allocate-instance class-value))
             (slot-missing-method
              (poo-clos-method
               'generic-slot-protocol/missing
               (list (poo-clos-eql-specializer class-value)
                     (poo-clos-any-specializer)
                     (poo-clos-any-specializer)
                     (poo-clos-any-specializer))
               (lambda (_frame _class _instance slot-name operation . values)
                 (list slot-name operation values))
               lambda-list: (poo-clos-lambda-list 4 1 #f #f '() #f)))
             (slot-unbound-method
              (poo-clos-method
               'generic-slot-protocol/unbound
               (list (poo-clos-eql-specializer class-value)
                     (poo-clos-any-specializer)
                     (poo-clos-any-specializer))
               (lambda (_frame _class _instance slot-name)
                 (list slot-name 'unbound))
               lambda-list: (poo-clos-lambda-list 3 0 #f #f '() #f))))
        (poo-clos-add-method poo-clos-slot-missing-generic
                             slot-missing-method)
        (poo-clos-add-method poo-clos-slot-unbound-generic
                             slot-unbound-method)
        (check-equal? (poo-clos-slot-value instance-value 'absent)
                      '(absent slot-value ()))
        (check-equal? (poo-clos-slot-value instance-value 'state)
                      '(state unbound))
        (check (eq? (poo-clos-method-generic-function slot-unbound-method)
                    poo-clos-slot-unbound-generic) => #t)
        (poo-clos-remove-method poo-clos-slot-missing-generic
                                slot-missing-method)
        (poo-clos-remove-method poo-clos-slot-unbound-generic
                                slot-unbound-method)))

    (test-case "reinitialize uses initargs only while shared-initialize can rerun initforms"
      (let (init-count 0)
        (def slot
          (poo-clos-direct-slot-definition
           'state initargs: (list state:)
           initform: (lambda ()
                       (set! init-count (+ init-count 1))
                       init-count)))
        (def class-value
          (poo-clos-class 'reinitializable direct-slots: (list slot)))
        (let (instance-value (poo-clos-make-instance class-value))
          (check-equal? (poo-clos-slot-value instance-value 'state) 1)
          (poo-clos-reinitialize-instance instance-value)
          (check-equal? init-count 1)
          (poo-clos-reinitialize-instance instance-value state: 9)
          (check-equal? (poo-clos-slot-value instance-value 'state) 9)
          (poo-clos-slot-makunbound! instance-value 'state)
          (poo-clos-reinitialize-instance instance-value)
          (check-equal? (poo-clos-slot-bound? instance-value 'state) #f)
          (poo-clos-shared-initialize instance-value '(state))
          (check-equal? (poo-clos-slot-value instance-value 'state) 2))))

    (test-case "reader and writer methods participate in ordinary multiple dispatch"
      (let* ((slot
              (poo-clos-direct-slot-definition
               'name initargs: (list name:)
               readers: '(name-of) writers: '(set-name)))
             (class-value
              (poo-clos-class 'named direct-slots: (list slot)))
             (instance-value
              (poo-clos-make-instance class-value name: 'old))
             (reader
              (poo-clos-add-method
               (poo-clos-generic-function 'name-of 1)
               (poo-clos-slot-reader-method class-value 'name 'read-name)))
             (writer
              (poo-clos-add-method
               (poo-clos-generic-function 'set-name 2)
               (poo-clos-slot-writer-method class-value 'name 'write-name))))
        (check-equal? (poo-clos-call reader instance-value) 'old)
        (check-equal? (poo-clos-call writer 'new instance-value) 'new)
        (check-equal? (poo-clos-call reader instance-value) 'new)))

    (test-case "invalid declarations and initialization arguments fail before effects"
      (let (slot (poo-clos-direct-slot-definition 'only initargs: (list only:)))
        (check-exception
         (poo-clos-direct-slot-definition 'bad allocation: 'dynamic)
         (failure-code? 'invalid-slot-allocation))
        (check-exception
         (poo-clos-class 'duplicates direct-slots: (list slot slot))
         (failure-code? 'duplicate-direct-slot))
        (let (class-value
              (poo-clos-class 'strict-initargs direct-slots: (list slot)))
          (check-exception (poo-clos-make-instance class-value unknown: 1)
                           (failure-code? 'invalid-initialization-argument))
          (let (instance-value (poo-clos-make-instance class-value only: 1))
            (check (poo-clos-slot-exists? instance-value 'only) => #t)
            (check (poo-clos-slot-exists? instance-value 'missing) => #f))
          (check-exception (apply poo-clos-make-instance
                                  (list class-value only:))
                           (failure-code? 'malformed-initialization-arguments))
          (check (poo-clos-instance?
                  (poo-clos-make-instance
                   class-value unknown: 1 allow-other-keys: #t))
                 => #t)))
      (let* ((x (poo-clos-class 'precedence-x))
             (y (poo-clos-class 'precedence-y))
             (xy (poo-clos-class 'precedence-xy
                                 direct-superclasses: (list x y)))
             (yx (poo-clos-class 'precedence-yx
                                 direct-superclasses: (list y x))))
        (check-exception
         (poo-clos-class 'inconsistent
                         direct-superclasses: (list xy yx))
         (failure-code? 'inconsistent-class-precedence))))))
