;;; -*- Gerbil -*-
;;; CLOS specializer, multi-dispatch, and standard-combination conformance.

(import (only-in :std/test
                 test-suite test-case check-equal? check-exception check)
        (only-in :clan/poo/object .o .ref)
        "../src/module-system/poo-clos/interface.ss")

(export poo-clos-dispatch-test)

(def any-specializer (poo-clos-any-specializer))
(def animal-class (.o))
(def dog-class (.o (:: @ animal-class)))
(def cat-class (.o (:: @ animal-class)))
(def dog (.o (:: @ dog-class)))
(def cat (.o (:: @ cat-class)))

(def (failure-code? code)
  (lambda (error)
    (and (poo-clos-failure? error)
         (eq? (.ref error 'code) code))))

(def (primary-method identity specializers value)
  (poo-clos-method identity specializers
                   (lambda (_frame . _arguments) value)))

(def poo-clos-dispatch-test
  (test-suite "POO-native CLOS multi-dispatch conformance"
    (test-case "class and any specializers participate in multi-argument dispatch"
      (let* ((generic (poo-clos-generic-function 'meet 2))
             (generic
              (poo-clos-add-method
               generic
               (primary-method
                'animal-animal
                (list (poo-clos-class-specializer animal-class)
                      (poo-clos-class-specializer animal-class))
                'animal-animal)))
             (generic
              (poo-clos-add-method
               generic
               (primary-method
                'dog-any
                (list (poo-clos-class-specializer dog-class) any-specializer)
                'dog-any)))
             (generic
              (poo-clos-add-method
               generic
               (primary-method
                'animal-cat
                (list (poo-clos-class-specializer animal-class)
                      (poo-clos-class-specializer cat-class))
                'animal-cat))))
        (check-equal? (poo-clos-call generic dog dog) 'dog-any)
        (check-equal? (poo-clos-call generic dog cat) 'dog-any)
        (let (second-first
              (poo-clos-generic-function
               'meet-second-first 2 argument-precedence-order: '(1 0)))
          (let loop ((methods (.ref generic 'methods)) (result second-first))
            (if (null? methods)
              (check-equal? (poo-clos-call result dog cat) 'animal-cat)
              (loop (cdr methods)
                    (let (method (car methods))
                      (poo-clos-add-method
                       result
                       (poo-clos-method
                        (.ref method 'identity) (.ref method 'specializers)
                        (.ref method 'body)
                        qualifier: (.ref method 'qualifier)
                        lambda-list: (.ref method 'lambda-list))))))))))

    (test-case "eql specializers are more specific than class specializers"
      (let* ((generic (poo-clos-generic-function 'feed 1))
             (generic
              (poo-clos-add-method
               generic
               (primary-method
                'dog (list (poo-clos-class-specializer dog-class)) 'dog)))
             (generic
              (poo-clos-add-method
               generic
               (primary-method
                'this-dog (list (poo-clos-eql-specializer dog)) 'this-dog))))
        (check-equal?
         (map (lambda (method) (.ref method 'identity))
              (poo-clos-compute-applicable-methods generic dog))
         '(this-dog dog))
        (check-equal? (poo-clos-call generic dog) 'this-dog)
        (check-equal? (poo-clos-call generic (.o (:: @ dog-class))) 'dog)))

    (test-case "standard qualifier order and lexical next are preserved"
      (let ((trace '())
            (base-generic (poo-clos-generic-function 'render 1)))
        (def (record value)
          (set! trace (append trace (list value))))
        (def (method identity specializer qualifier body)
          (poo-clos-method identity (list specializer) body
                           qualifier: qualifier))
        (def (around-dog frame _dog)
          (record 'around-dog-enter)
          (let (value (poo-clos-call-next-method frame))
            (record 'around-dog-exit)
            value))
        (def (before-animal _frame _animal) (record 'before-animal))
        (def (before-dog _frame _dog) (record 'before-dog))
        (def (primary-animal _frame _animal)
          (record 'primary-animal)
          'animal)
        (def (primary-dog frame replacement)
          (record 'primary-dog)
          (poo-clos-call-next-method frame replacement))
        (def (after-animal _frame _animal) (record 'after-animal))
        (def (after-dog _frame _dog) (record 'after-dog))
        (let* ((animal (poo-clos-class-specializer animal-class))
               (dog-specializer (poo-clos-class-specializer dog-class))
               (generic
                (foldl
                 (lambda (method generic)
                   (poo-clos-add-method generic method))
                 base-generic
                 (list
                  (method 'around-dog dog-specializer 'around around-dog)
                  (method 'before-animal animal 'before before-animal)
                  (method 'before-dog dog-specializer 'before before-dog)
                  (method 'primary-animal animal 'primary primary-animal)
                  (method 'primary-dog dog-specializer 'primary primary-dog)
                  (method 'after-animal animal 'after after-animal)
                  (method 'after-dog dog-specializer 'after after-dog)))))
          (check-equal? (poo-clos-call generic dog) 'animal)
          (check-equal?
           trace
           '(around-dog-enter before-dog before-animal
             primary-dog primary-animal after-animal after-dog
             around-dog-exit)))))

    (test-case "replacement arguments retain the exact applicable method set"
      (def (delegate frame _value)
        (poo-clos-call-next-method frame cat))
      (def (terminal _frame _value) 'terminal)
      (let* ((generic (poo-clos-generic-function 'replacement 1))
             (generic
              (poo-clos-add-method
               generic
               (poo-clos-method
                'animal (list (poo-clos-class-specializer animal-class))
                terminal)))
             (generic
              (poo-clos-add-method
               generic
               (poo-clos-method
                'dog (list (poo-clos-class-specializer dog-class))
                delegate))))
        (check-exception (poo-clos-call generic dog)
                         (failure-code? 'changed-applicable-methods))))

    (test-case "rest arguments and multiple values survive effective invocation"
      (def (many _frame _required . rest)
        (apply values rest))
      (let* ((generic (poo-clos-generic-function 'many 1 rest?: #t))
             (generic
              (poo-clos-add-method
               generic
               (poo-clos-method 'many (list any-specializer) many))))
        (check-equal?
         (call-with-values (lambda () (poo-clos-call generic 'x 1 2 3)) list)
         '(1 2 3))))

    (test-case "same qualifier and specializers replace the prior method"
      (let* ((generic (poo-clos-generic-function 'replace 1))
             (specializers (list any-specializer))
             (old (primary-method 'old specializers 'old))
             (new (primary-method 'new specializers 'new))
             (with-old (poo-clos-add-method generic old))
             (with-new (poo-clos-add-method with-old new)))
        (check (eq? generic with-old) => #t)
        (check (eq? with-old with-new) => #t)
        (check-equal? (poo-clos-call with-new 1) 'new)
        (check-equal? (.ref with-new 'generation) 2)
        (check-equal? (length (.ref with-new 'methods)) 1)
        (let (without-new (poo-clos-remove-method with-new new))
          (check-equal? (.ref without-new 'generation) 3)
          (check-equal? (.ref without-new 'methods) '())
          (check-exception (poo-clos-call without-new 1)
                           (failure-code? 'no-applicable-method)))))

    (test-case "a method has one generic owner and find-method uses ANSI qualifiers"
      (let* ((specializers (list any-specializer))
             (method (primary-method 'owned specializers 'owned))
             (first (poo-clos-generic-function 'first-owner 1))
             (second (poo-clos-generic-function 'second-owner 1)))
        (poo-clos-add-method first method)
        (check (eq? (poo-clos-method-generic-function method) first) => #t)
        (check-equal? (poo-clos-method-qualifiers method) '())
        (check (eq? (poo-clos-find-method first '() specializers) method) => #t)
        (check-equal?
         (poo-clos-find-method first '(before) specializers error?: #f) #f)
        (check-exception
         (poo-clos-add-method second method)
         (failure-code? 'method-owned-by-another-generic))
        (poo-clos-remove-method first method)
        (check-equal? (poo-clos-method-generic-function method) #f)
        (check (eq? (poo-clos-add-method second method) second) => #t)))

    (test-case "applicable methods extend keyword admission"
      (let* ((method-list
              (poo-clos-lambda-list 1 0 #f #t (list extra:) #f))
             (method
              (poo-clos-method
               'method-key (list any-specializer)
               (lambda (_frame _required . tail) tail)
               lambda-list: method-list))
             (generic
              (poo-clos-add-method
               (poo-clos-generic-function 'method-keys 1 rest?: #t)
               method)))
        (check-equal? (poo-clos-call generic 'value extra: 9)
                      (list extra: 9))
        (check-exception (poo-clos-call generic 'value unknown: 9)
                         (failure-code? 'invalid-keyword-argument))))

    (test-case "no-applicable-method precedes keyword validation"
      (let* ((protocol
              (poo-clos-generic-protocol
               'no-app-first
               no-applicable-method:
               (lambda (_generic _arguments) 'no-applicable)))
             (generic
              (poo-clos-generic-function
               'no-app-first 1 key?: #t keys: '(known)
               protocol: protocol)))
        (check-equal? (poo-clos-call generic 'value unknown: 1)
                      'no-applicable)))

    (test-case "terminal protocol functions are ordinary mutable generics"
      (let* ((target (poo-clos-generic-function 'terminal-target 1))
             (no-applicable
              (poo-clos-method
               'terminal-target/no-applicable
               (list (poo-clos-eql-specializer target))
               (lambda (_frame generic . arguments)
                 (list (.ref generic 'identity) arguments))
               lambda-list: (poo-clos-lambda-list 1 0 #t #f '() #f)))
             (terminal
              (poo-clos-method
               'terminal-target/primary (list any-specializer)
               (lambda (frame _value)
                 (poo-clos-call-next-method frame))))
             (no-next
              (poo-clos-method
               'terminal-target/no-next
               (list (poo-clos-eql-specializer target) any-specializer)
               (lambda (_frame generic method . arguments)
                 (list (.ref generic 'identity)
                       (.ref method 'identity) arguments))
               lambda-list: (poo-clos-lambda-list 2 0 #t #f '() #f))))
        (poo-clos-add-method poo-clos-no-applicable-method-generic
                             no-applicable)
        (check-equal? (poo-clos-call target 'absent)
                      '(terminal-target (absent)))
        (poo-clos-add-method target terminal)
        (poo-clos-add-method poo-clos-no-next-method-generic no-next)
        (check-equal? (poo-clos-call target 'present)
                      '(terminal-target terminal-target/primary (present)))
        (check (eq? (poo-clos-method-generic-function no-applicable)
                    poo-clos-no-applicable-method-generic) => #t)
        (poo-clos-remove-method poo-clos-no-applicable-method-generic
                                no-applicable)
        (poo-clos-remove-method poo-clos-no-next-method-generic no-next)))

    (test-case "typed failures close invalid and inapplicable calls"
      (check-exception
       (poo-clos-generic-function
        'bad-order 2 argument-precedence-order: '(0 0))
       (failure-code? 'invalid-argument-precedence-order))
      (let (generic (poo-clos-generic-function 'missing 1))
        (check-exception (poo-clos-call generic dog)
                         (failure-code? 'no-applicable-method))
        (check-exception (poo-clos-call generic)
                         (failure-code? 'argument-count-mismatch)))
      (let* ((generic (poo-clos-generic-function 'only-before 1))
             (method
              (poo-clos-method
               'before (list any-specializer)
               (lambda (_frame _value) (void)) qualifier: 'before)))
        (check-exception
         (poo-clos-call (poo-clos-add-method generic method) 1)
         (failure-code? 'no-primary-method)))
      (let* ((generic (poo-clos-generic-function 'no-next 1))
             (method
              (poo-clos-method
               'terminal (list any-specializer)
               (lambda (frame _value)
                 (poo-clos-call-next-method frame)))))
        (check-exception
         (poo-clos-call (poo-clos-add-method generic method) 1)
         (failure-code? 'no-next-method))))))
