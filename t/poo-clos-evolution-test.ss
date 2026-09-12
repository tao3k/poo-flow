;;; -*- Gerbil -*-
;;; POO-native CLOS class evolution, identity, and reflection conformance.

(import (only-in :std/test
                 test-suite test-case check-equal? check-exception check)
        (only-in :clan/poo/object .ref)
        "../src/module-system/poo-clos/interface.ss")

(export poo-clos-evolution-test)

(def (failure-code? code)
  (lambda (error)
    (and (poo-clos-failure? error)
         (eq? (.ref error 'code) code))))

(def poo-clos-evolution-test
  (test-suite "POO-native CLOS class evolution"
    (test-case "redefinition preserves class identity and migrates lazily"
      (let* ((updates '())
             (x-slot
              (poo-clos-direct-slot-definition 'x initargs: (list x:)))
             (y-slot
              (poo-clos-direct-slot-definition 'y initargs: (list y:)))
             (base
              (poo-clos-class
               'evolving-base direct-slots: (list x-slot)
               redefinition-update-handler:
               (lambda (instance added discarded plist)
                 (set! updates (list instance added discarded plist))
                 instance)))
             (child
              (poo-clos-class 'evolving-child
                              direct-superclasses: (list base)
                              direct-slots: (list y-slot)))
             (instance (poo-clos-make-instance child x: 10 y: 20))
             (generic
              (poo-clos-add-method
               (poo-clos-generic-function 'generation-dispatch 1)
               (poo-clos-method
                'old-base-method (list (poo-clos-class-specializer base))
                (lambda (_frame _instance) 'base-method))))
             (z-slot
              (poo-clos-direct-slot-definition
               'z initform: (lambda () 30)))
             (new-base
              (poo-clos-redefine-class
               base direct-slots: (list x-slot z-slot)))
             (new-child (poo-clos-current-class child)))
        (check (eq? new-base base) => #t)
        (check (eq? new-child child) => #t)
        (check (poo-clos-class-obsolete? base) => #f)
        (check (poo-clos-class-obsolete? child) => #f)
        (check-equal? (poo-clos-class-generation new-base) 1)
        (check-equal? (poo-clos-class-generation new-child) 1)
        (check-equal? (poo-clos-class-predecessor new-base) #f)
        (check-equal? (poo-clos-class-successor base) #f)
        (check (eq? (car (poo-clos-class-direct-superclasses new-child))
                    new-base)
               => #t)
        ;; Dispatch sees the logical generation before slot access triggers the
        ;; physical instance-state migration.
        (check-equal? (poo-clos-call generic instance) 'base-method)
        (check (eq? (poo-clos-class-of instance) new-child) => #t)
        (check-equal? (poo-clos-slot-value instance 'x) 10)
        (check-equal? (poo-clos-slot-value instance 'y) 20)
        (check-equal? (poo-clos-slot-value instance 'z) 30)
        (check (eq? (car updates) instance) => #t)
        (check-equal? (cadr updates) '(z))
        (check-equal? (caddr updates) '())
        (check-equal? (poo-clos-instance-slot-names instance) '(y x z))
        (let ((slot (poo-clos-find-effective-slot new-child 'z))
              (method (car (poo-clos-generic-methods generic))))
          (check-equal? (poo-clos-slot-name slot) 'z)
          (check-equal? (poo-clos-slot-allocation slot) 'instance)
          (check-equal? (poo-clos-method-name method) 'old-base-method)
          (check-equal? (poo-clos-method-qualifiers method) '())
          (check-equal?
           (poo-clos-specializer-kind
            (car (poo-clos-method-specializers method)))
           'class)
          (check-equal? (poo-clos-generic-name generic)
                        'generation-dispatch)
          (check-equal? (poo-clos-generic-generation generic) 1))))

    (test-case "discarded bound slots are supplied to the update hook"
      (let* ((receipt #f)
             (old-slot
              (poo-clos-direct-slot-definition 'old initargs: (list old:)))
             (new-slot
              (poo-clos-direct-slot-definition 'new initform: (lambda () 8)))
             (class-value
              (poo-clos-class
               'discarding direct-slots: (list old-slot)
               redefinition-update-handler:
               (lambda (_instance added discarded plist)
                 (set! receipt (list added discarded plist)))))
             (instance (poo-clos-make-instance class-value old: 7)))
        (poo-clos-redefine-class class-value direct-slots: (list new-slot))
        (check-equal? (poo-clos-slot-value instance 'new) 8)
        (check-equal? receipt '((new) (old) (old 7)))))

    (test-case "change-class preserves identity, common slots, and hook views"
      (let* ((receipt #f)
             (common-a
              (poo-clos-direct-slot-definition
               'common initargs: (list common:)))
             (only-a
              (poo-clos-direct-slot-definition 'only-a initargs: (list only-a:)))
             (common-b
              (poo-clos-direct-slot-definition
               'common initargs: (list common:)))
             (only-b
              (poo-clos-direct-slot-definition
               'only-b initargs: (list only-b:)
               initform: (lambda () 'default-b)))
             (class-a
              (poo-clos-class 'change-a
                              direct-slots: (list common-a only-a)))
             (class-b
              (poo-clos-class
               'change-b direct-slots: (list common-b only-b)
               different-class-update-handler:
               (lambda (previous current . initargs)
                 (set! receipt
                       (list (poo-clos-class-name
                              (poo-clos-class-of previous))
                             (poo-clos-slot-value previous 'only-a)
                             (poo-clos-class-name
                              (poo-clos-class-of current))
                             initargs))
                 current)))
             (instance
              (poo-clos-make-instance class-a common: 4 only-a: 5))
             (identity instance))
        (check (eq? (poo-clos-change-class instance class-b only-b: 9)
                    identity)
               => #t)
        (check-equal? (poo-clos-class-name (poo-clos-class-of instance))
                      'change-b)
        (check-equal? (poo-clos-slot-value instance 'common) 4)
        (check-equal? (poo-clos-slot-value instance 'only-b) 9)
        (check-equal? receipt '(change-a 5 change-b (only-b: 9)))))

    (test-case "successive redefinitions retain the exact class object"
      (let* ((class-value (poo-clos-class 'single-successor))
             (first (poo-clos-redefine-class class-value))
             (second (poo-clos-redefine-class class-value)))
        (check (eq? class-value first) => #t)
        (check (eq? first second) => #t)
        (check-equal? (poo-clos-class-generation class-value) 2)))

    (test-case "MOP-EXTENDED is a sealed read-only capability profile"
      (let (profile (poo-clos-mop-extended-profile))
        (check (poo-clos-mop-profile-admits? profile 'generic-methods) => #t)
        (check (poo-clos-mop-profile-admits? profile 'replace-native-c3)
               => #f)
        (check-equal? (.ref profile 'status) 'admitted)
        (check-equal? (.ref profile 'sealed?) #t)))

    (test-case "make-instances-obsolete preserves class identity"
      (let* ((class-value (poo-clos-class 'explicit-obsolescence))
             (instance (poo-clos-make-instance class-value))
             (reinitialized (poo-clos-make-instances-obsolete class-value)))
        (check (eq? class-value reinitialized) => #t)
        (check-equal? (poo-clos-class-generation class-value) 1)
        (check (eq? (poo-clos-class-of instance) class-value) => #t)))))
