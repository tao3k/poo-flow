;;; -*- Gerbil -*-
;;; ANSI short method combinations and generic protocol customization.

(import (only-in :std/test
                 test-suite test-case check-equal? check-exception check)
        (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop element?)
        "../src/module-system/poo-clos/interface.ss")

(export poo-clos-method-combination-test)

(def any-specializer (poo-clos-any-specializer))
(def combination-animal-class (.o))
(def combination-dog-class (.o (:: @ combination-animal-class)))
(def combination-dog (.o (:: @ combination-dog-class)))

(.define-method-combination declared-collect
  (short list)
  (order most-specific-last)
  (documentation "least-specific value first"))

(.defgeneric declared-values
  (object)
  (method-combination declared-collect))

(.defclass CombinationSyntaxEntity () ())

(.defmethod (declared-values (object CombinationSyntaxEntity))
  (qualifier declared-collect)
  'syntax-method)

(poo-clos-generic-binding-add-method!
 declared-values$poo-clos-generic
 (poo-clos-method
  'declared-animal
  (list (poo-clos-class-specializer combination-animal-class))
  (lambda (_frame _object) 'animal)
  qualifier: 'declared-collect))

(poo-clos-generic-binding-add-method!
 declared-values$poo-clos-generic
 (poo-clos-method
  'declared-dog
  (list (poo-clos-class-specializer combination-dog-class))
  (lambda (_frame _object) 'dog)
  qualifier: 'declared-collect))

(.define-method-combination declared-long
  (long)
  ((around (around))
   (primary () (required #t)))
  (let (methods (append around primary))
    (call-method (car methods) (cdr methods))))

(.defgeneric declared-long-values
  (object)
  (method-combination declared-long))

(poo-clos-generic-binding-add-method!
 declared-long-values$poo-clos-generic
 (poo-clos-method
  'declared-long-animal
  (list (poo-clos-class-specializer combination-animal-class))
  (lambda (_frame _object) 'animal)))

(poo-clos-generic-binding-add-method!
 declared-long-values$poo-clos-generic
 (poo-clos-method
  'declared-long-dog
  (list (poo-clos-class-specializer combination-dog-class))
  (lambda (frame object)
    (list 'dog (poo-clos-call-next-method frame object)))))

(.defgeneric declared-reordered-values
  (object)
  (method-combination declared-collect 'most-specific-first))

(poo-clos-generic-binding-add-method!
 declared-reordered-values$poo-clos-generic
 (poo-clos-method
  'reordered-animal
  (list (poo-clos-class-specializer combination-animal-class))
  (lambda (_frame _object) 'animal)
  qualifier: 'declared-collect))

(poo-clos-generic-binding-add-method!
 declared-reordered-values$poo-clos-generic
 (poo-clos-method
  'reordered-dog
  (list (poo-clos-class-specializer combination-dog-class))
  (lambda (_frame _object) 'dog)
  qualifier: 'declared-collect))

(.define-method-combination declared-configured-long
  (long (&optional (order 'most-specific-first) (primary-required? #t)))
  ((around (around))
   (primary () (order order) (required primary-required?)))
  (arguments
   (&whole whole object
    &optional (extra 'missing extra-supplied?)
    &key ((tag: tag) 'none tag-supplied?)))
  (generic-function active-generic)
  "Configured long-form combination"
  (let (invoke-primary
        (lambda ()
          (if (null? primary)
            'no-primary
            (call-method (car primary) (cdr primary)))))
    (let (payload
          (lambda ()
            (list (.ref active-generic 'identity)
                  (= (length whole) 4)
                  (eq? object combination-dog)
                  extra extra-supplied? tag tag-supplied?
                  (invoke-primary))))
      (if (null? around)
        (payload)
        (call-method
         (car around)
         (append (cdr around) (list (make-method (payload)))))))))

(.defgeneric configured-long-values
  (object &optional extra &key ((tag: tag)))
  (method-combination declared-configured-long 'most-specific-last #t))

(def configured-long-lambda-list
  (poo-clos-lambda-list 1 1 #f #t '(tag:) #f))

(poo-clos-generic-binding-add-method!
 configured-long-values$poo-clos-generic
 (poo-clos-method
  'configured-around
  (list (poo-clos-class-specializer combination-dog-class))
  (lambda (frame _object . _arguments)
    (list 'around (poo-clos-call-next-method frame)))
  qualifier: 'around lambda-list: configured-long-lambda-list))

(poo-clos-generic-binding-add-method!
 configured-long-values$poo-clos-generic
 (poo-clos-method
  'configured-animal
  (list (poo-clos-class-specializer combination-animal-class))
  (lambda (frame _object . _arguments)
    (list 'animal
          (if (poo-clos-next-method? frame)
            (poo-clos-call-next-method frame)
            'end)))
  lambda-list: configured-long-lambda-list))

(poo-clos-generic-binding-add-method!
 configured-long-values$poo-clos-generic
 (poo-clos-method
  'configured-dog
  (list (poo-clos-class-specializer combination-dog-class))
  (lambda (frame _object . _arguments)
    (list 'dog
          (if (poo-clos-next-method? frame)
            (poo-clos-call-next-method frame)
            'end)))
  lambda-list: configured-long-lambda-list))

(.defgeneric optional-configured-values
  (object)
  (method-combination declared-configured-long 'most-specific-first #f))

(poo-clos-generic-binding-add-method!
 optional-configured-values$poo-clos-generic
 (poo-clos-method
  'optional-configured-around
  (list (poo-clos-class-specializer combination-dog-class))
  (lambda (frame _object)
    (list 'around (poo-clos-call-next-method frame)))
  qualifier: 'around))

(def (failure-code? code)
  (lambda (error)
    (and (poo-clos-failure? error)
         (eq? (.ref error 'code) code))))

(def (constant-method identity qualifier specializer value)
  (poo-clos-method
   identity (list specializer)
   (lambda (_frame _argument)
     (if (procedure? value) (value) value))
   qualifier: qualifier))

(def (add-methods generic methods)
  (foldl (lambda (method current)
           (poo-clos-add-method current method))
         generic methods))

(def poo-clos-method-combination-test
  (test-suite "POO-native CLOS method combinations and protocol"
    (test-case "short declaration lowers to a lexical POO descriptor"
      (check (element? ClosMethodCombination declared-collect) => #t)
      (check-equal? (declared-values combination-dog) '(animal dog))
      (check-equal?
       (declared-values (poo-clos-make-instance CombinationSyntaxEntity))
       '(syntax-method)))

    (test-case "long declaration binds groups and lexical call-method"
      (check (element? ClosMethodCombination declared-long) => #t)
      (check-equal? (declared-long-values combination-dog)
                    '(dog animal)))

    (test-case "combination options configure short order without mutation"
      (check-equal? (declared-values combination-dog) '(animal dog))
      (check-equal? (declared-reordered-values combination-dog) '(dog animal))
      (check-equal? (.ref declared-collect 'order) 'most-specific-last))

    (test-case "long configuration, argument bindings, and make-method compose"
      (check-equal?
       (configured-long-values combination-dog 'extra tag: 'tagged)
       '(around
         (configured-long-values #t #t extra #t tagged #t
                                 (animal (dog end)))))
      (check-equal?
       (optional-configured-values combination-dog)
       '(around
         (optional-configured-values #f #t missing #f none #f no-primary)))
      (check-equal? (.ref declared-configured-long 'configuration) '())
      (check-exception
       (poo-clos-configure-method-combination
        declared-configured-long 'sideways #t)
       (failure-code? 'invalid-method-group))
      (let* ((required-combination
              (poo-clos-configure-method-combination
               declared-configured-long 'most-specific-first #t))
             (around-only
              (poo-clos-add-method
               (poo-clos-generic-function
                'configured-required 1
                method-combination: required-combination)
               (poo-clos-method
                'configured-required-around (list any-specializer)
                (lambda (_frame _object) 'unreachable)
                qualifier: 'around))))
        (check-exception
         (poo-clos-call around-only 'object)
         (failure-code? 'required-method-group-empty))))

    (test-case "numeric built-ins combine in admitted specificity order"
      (let* ((animal (poo-clos-class-specializer combination-animal-class))
             (dog (poo-clos-class-specializer combination-dog-class))
             (plus
              (add-methods
               (poo-clos-generic-function 'score 1 method-combination: '+)
               (list (constant-method 'animal '+ animal 3)
                     (constant-method 'dog '+ dog 7))))
             (maximum
              (add-methods
               (poo-clos-generic-function 'maximum 1
                                          method-combination: 'max)
               (list (constant-method 'animal 'max animal 3)
                     (constant-method 'dog 'max dog 7))))
             (minimum
              (add-methods
               (poo-clos-generic-function 'minimum 1
                                          method-combination: 'min)
               (list (constant-method 'animal 'min animal 3)
                     (constant-method 'dog 'min dog 7)))))
        (check-equal? (poo-clos-call plus combination-dog) 10)
        (check-equal? (poo-clos-call maximum combination-dog) 7)
        (check-equal? (poo-clos-call minimum combination-dog) 3)))

    (test-case "list order and sequence built-ins preserve their operators"
      (let* ((animal (poo-clos-class-specializer combination-animal-class))
             (dog (poo-clos-class-specializer combination-dog-class))
             (collect
              (poo-clos-short-method-combination
               'collect 'list order: 'most-specific-last))
             (listed
              (add-methods
               (poo-clos-generic-function
                'listed 1 method-combination: collect)
               (list (constant-method 'animal 'collect animal 'animal)
                     (constant-method 'dog 'collect dog 'dog))))
             (appended
              (add-methods
               (poo-clos-generic-function 'appended 1
                                          method-combination: 'append)
               (list (constant-method 'animal 'append animal '(animal))
                     (constant-method 'dog 'append dog '(dog)))))
             (concatenated
              (add-methods
               (poo-clos-generic-function 'concatenated 1
                                          method-combination: 'nconc)
               (list (constant-method 'animal 'nconc animal
                                      (lambda () (list 'animal)))
                     (constant-method 'dog 'nconc dog
                                      (lambda () (list 'dog)))))))
        (check-equal? (poo-clos-call listed combination-dog) '(animal dog))
        (check-equal? (poo-clos-call appended combination-dog) '(dog animal))
        (check-equal? (poo-clos-call concatenated combination-dog)
                      '(dog animal))))

    (test-case "and, or, and progn retain short-circuit evaluation"
      (let ((trace '())
            (animal (poo-clos-class-specializer combination-animal-class))
            (dog (poo-clos-class-specializer combination-dog-class)))
        (def (record value result)
          (lambda ()
            (set! trace (append trace (list value)))
            result))
        (let (and-generic
              (add-methods
               (poo-clos-generic-function 'all 1 method-combination: 'and)
               (list (constant-method 'animal 'and animal
                                      (record 'animal #t))
                     (constant-method 'dog 'and dog (record 'dog #f)))))
          (check-equal? (poo-clos-call and-generic combination-dog) #f)
          (check-equal? trace '(dog)))
        (set! trace '())
        (let (or-generic
              (add-methods
               (poo-clos-generic-function 'some 1 method-combination: 'or)
               (list (constant-method 'animal 'or animal
                                      (record 'animal 'fallback))
                     (constant-method 'dog 'or dog
                                      (record 'dog 'specific)))))
          (check-equal? (poo-clos-call or-generic combination-dog) 'specific)
          (check-equal? trace '(dog)))
        (set! trace '())
        (let (progn-generic
              (add-methods
               (poo-clos-generic-function 'steps 1
                                          method-combination: 'progn)
               (list (constant-method 'animal 'progn animal
                                      (record 'animal 'last))
                     (constant-method 'dog 'progn dog
                                      (record 'dog 'first)))))
          (check-equal? (poo-clos-call progn-generic combination-dog) 'last)
          (check-equal? trace '(dog animal)))))

    (test-case "one-argument identity preserves multiple values"
      (let* ((identity-combination
              (poo-clos-short-method-combination
               'identity-max 'max identity-with-one-argument?: #t))
             (method
              (poo-clos-method
               'only (list any-specializer)
               (lambda (_frame _argument) (values 3 4))
               qualifier: 'identity-max))
             (generic
              (poo-clos-add-method
               (poo-clos-generic-function
                'only 1 method-combination: identity-combination)
               method)))
        (check-equal?
         (call-with-values (lambda () (poo-clos-call generic 'value)) list)
         '(3 4))))

    (test-case "around methods cannot hide a missing primary"
      (let* ((standard-around
              (poo-clos-method
               'standard-around (list any-specializer)
               (lambda (_frame _argument) 'standard-short-circuit)
               qualifier: 'around))
             (standard
              (poo-clos-add-method
               (poo-clos-generic-function 'standard-around 1)
               standard-around))
             (short-around
              (poo-clos-method
               'short-around (list any-specializer)
               (lambda (_frame _argument) 'short-short-circuit)
               qualifier: 'around))
             (short
              (poo-clos-add-method
               (poo-clos-generic-function 'short-around 1
                                          method-combination: '+)
               short-around)))
        (check-exception (poo-clos-call standard 'value)
                         (failure-code? 'no-primary-method))
        (check-exception (poo-clos-call short 'value)
                         (failure-code? 'no-primary-method))))

    (test-case "generic protocol owns terminal and computation hooks"
      (let* ((fallback-protocol
              (poo-clos-generic-protocol
               'fallback
               no-applicable-method:
               (lambda (generic arguments)
                 (list 'missing (.ref generic 'identity) arguments))))
             (missing
              (poo-clos-generic-function
               'missing 1 protocol: fallback-protocol)))
        (check-equal? (poo-clos-call missing 'payload)
                      '(missing missing (payload))))
      (let* ((next-protocol
              (poo-clos-generic-protocol
               'next-fallback
               no-next-method:
               (lambda (generic method arguments)
                 (list (.ref generic 'identity)
                       (.ref method 'identity) arguments))))
             (terminal
              (poo-clos-method
               'terminal (list any-specializer)
               (lambda (frame argument)
                 (poo-clos-call-next-method frame argument))))
             (generic
              (poo-clos-add-method
               (poo-clos-generic-function
                'next-fallback 1 protocol: next-protocol)
               terminal)))
        (check-equal? (poo-clos-call generic 'payload)
                      '(next-fallback terminal (payload))))
      (let* ((animal (poo-clos-class-specializer combination-animal-class))
             (dog (poo-clos-class-specializer combination-dog-class))
             (reverse-protocol
              (poo-clos-generic-protocol
               'reverse
               compute-applicable-methods:
               (lambda (_generic _arguments methods) (reverse methods))))
             (generic
              (add-methods
               (poo-clos-generic-function
                'reversed 1 protocol: reverse-protocol)
               (list (constant-method 'animal 'primary animal 'animal)
                     (constant-method 'dog 'primary dog 'dog)))))
        (check-equal? (poo-clos-call generic combination-dog) 'animal)
        (check (element? ClosEffectiveMethod
                         (poo-clos-compute-effective-method
                          generic combination-dog))
               => #t)))

    (test-case "long combinations partition groups and drive explicit next chains"
      (let* ((around-group
              (poo-clos-method-group 'around '((around))))
             (primary-group
              (poo-clos-method-group 'primary '(()) required?: #t))
             (combination
              (poo-clos-long-method-combination
               'long-standard (list around-group primary-group)
               (lambda (_generic _arguments _groups)
                 (lambda (effective-method)
                   (let ((around
                          (poo-clos-effective-method-group
                           effective-method 'around))
                         (primary
                          (poo-clos-effective-method-group
                           effective-method 'primary)))
                     (let (methods (append around primary))
                       (poo-clos-call-method
                        effective-method (car methods) (cdr methods))))))))
             (animal (poo-clos-class-specializer combination-animal-class))
             (dog (poo-clos-class-specializer combination-dog-class))
             (around
              (poo-clos-method
               'around (list dog)
               (lambda (frame argument)
                 (list 'around
                       (poo-clos-call-next-method frame argument)))
               qualifier: 'around))
             (animal-primary
              (constant-method 'animal 'primary animal 'animal))
             (dog-primary
              (poo-clos-method
               'dog (list dog)
               (lambda (frame argument)
                 (list 'dog
                       (poo-clos-call-next-method frame argument)))))
             (generic
              (add-methods
               (poo-clos-generic-function
                'long-standard 1 method-combination: combination)
               (list around animal-primary dog-primary))))
        (check-equal? (poo-clos-call generic combination-dog)
                      '(around (dog animal)))
        (let (effective-method
              (poo-clos-compute-effective-method generic combination-dog))
          (check-equal?
           (map (lambda (method) (.ref method 'identity))
                (poo-clos-effective-method-group effective-method 'primary))
           '(dog animal)))))

    (test-case "long groups enforce required, claimed, and unambiguous methods"
      (let* ((required-group
              (poo-clos-method-group
               'required '((needed)) required?: #t))
             (fallback-group
              (poo-clos-method-group 'fallback '(*)))
             (required-combination
              (poo-clos-long-method-combination
               'required (list required-group fallback-group)
               (lambda (_generic _arguments _groups)
                 (lambda (_effective-method) 'unreachable))))
             (generic
              (poo-clos-add-method
               (poo-clos-generic-function
                'required 1 method-combination: required-combination)
               (constant-method
                'fallback 'fallback any-specializer 'value))))
        (check-exception
         (poo-clos-call generic 'argument)
         (failure-code? 'required-method-group-empty)))
      (let* ((primary-group (poo-clos-method-group 'primary '(())))
             (combination
              (poo-clos-long-method-combination
               'claimed (list primary-group)
               (lambda (_generic _arguments _groups)
                 (lambda (_effective-method) 'unreachable))))
             (generic
              (poo-clos-add-method
               (poo-clos-generic-function
                'claimed 1 method-combination: combination)
               (constant-method 'foreign 'foreign any-specializer 'bad))))
        (check-exception
         (poo-clos-call generic 'argument)
         (failure-code? 'invalid-method-qualifier)))
      (let* ((all-group (poo-clos-method-group 'all '(*)))
             (combination
              (poo-clos-long-method-combination
               'ambiguous (list all-group)
               (lambda (_generic _arguments _groups)
                 (lambda (_effective-method) 'unreachable))))
             (generic
              (add-methods
               (poo-clos-generic-function
                'ambiguous 1 method-combination: combination)
               (list (constant-method 'first 'first any-specializer 1)
                     (constant-method 'second 'second any-specializer 2)))))
        (check-exception
         (poo-clos-call generic 'argument)
         (failure-code? 'ambiguous-method-group-order))))

    (test-case "invalid qualifiers and protocol results fail before invocation"
      (let* ((generic
              (poo-clos-generic-function 'bad-qualifier 1
                                         method-combination: '+))
             (method
              (constant-method 'bad 'primary any-specializer 1)))
        (check-exception (poo-clos-add-method generic method)
                         (failure-code? 'invalid-method-qualifier)))
      (let* ((protocol
              (poo-clos-generic-protocol
               'invalid
               compute-effective-method:
               (lambda (_generic _arguments _methods _default) #f)))
             (generic
              (poo-clos-add-method
               (poo-clos-generic-function 'invalid 1 protocol: protocol)
               (constant-method 'method 'primary any-specializer 'value))))
        (check-exception
         (poo-clos-call generic 'argument)
         (failure-code? 'invalid-effective-method-result))))))
