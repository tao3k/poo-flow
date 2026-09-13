;;; -*- Gerbil -*-
;;; Hygienic CLOS declaration lowering and lambda-list conformance.

(import (only-in :std/test
                 test-suite test-case check-equal? check-exception check)
        (only-in :std/srfi/13 string-contains)
        (only-in :clan/poo/object .ref)
        (only-in :gerbil/expander datum->syntax)
        (only-in :gerbil/gambit
                 call-with-output-string display-exception
                 with-exception-catcher)
        (only-in "../src/module-system/poo-clos/declaration-ir.ss"
                 parse-poo-clos-class-declaration-ir
                 parse-poo-clos-generic-declaration-ir)
        "../src/module-system/poo-clos/interface.ss")

(export poo-clos-syntax-test)

(def (failure-code? code)
  (lambda (error)
    (and (poo-clos-failure? error)
         (eq? (.ref error 'code) code))))

(def (syntax-error-message thunk)
  (with-exception-catcher
   (lambda (error)
     (call-with-output-string
      (lambda (port) (display-exception error port))))
   (lambda () (thunk) #f)))

(def (class-syntax-error slot-data . option-data)
  (let ((name (datum->syntax #f 'InvalidClass))
        (supers (datum->syntax #f '()))
        (slots (datum->syntax #f slot-data))
        (options (map (lambda (datum) (datum->syntax #f datum)) option-data)))
    (syntax-error-message
     (lambda ()
       (parse-poo-clos-class-declaration-ir
        name supers slots options name)))))

(def (generic-syntax-error lambda-list-data . option-data)
  (let ((name (datum->syntax #f 'invalid-generic))
        (lambda-list (datum->syntax #f lambda-list-data))
        (options (map (lambda (datum) (datum->syntax #f datum)) option-data)))
    (syntax-error-message
     (lambda ()
       (parse-poo-clos-generic-declaration-ir
        name lambda-list options name)))))

(.defgeneric entity-name (object))
(.defgeneric set-entity-name (new-value object))

(.defclass SyntaxEntity ()
  ((name (initarg name:)
         (initform 'unnamed)
         (accessor entity-name set-entity-name))))

(.defclass SyntaxPerson (SyntaxEntity)
  ((role (initarg role:) (initform 'user)))
  (default-initargs (name: 'default-person))
  (documentation "Syntax person class")
  (metaclass 'standard-class))

(.defgeneric describe-syntax
  (object &optional prefix &key ((punctuation: punctuation)))
  (argument-precedence-order object)
  (method-combination standard)
  (documentation "Describe syntax objects")
  (generic-function-class standard-generic-function)
  (method-class standard-method)
  (declare (optimize speed)))

(.defmethod (describe-syntax
  (object SyntaxEntity)
   &optional (prefix "entity" prefix-supplied?)
   &key ((punctuation: punctuation) "." punctuation-supplied?))
  (list prefix
        (entity-name object)
        punctuation
        prefix-supplied?
        punctuation-supplied?))

(.defmethod (describe-syntax
  (object SyntaxPerson)
   &optional (prefix "person" prefix-supplied?)
   &key ((punctuation: punctuation) "!" punctuation-supplied?)
   &aux (label 'person))
  (let (parent-result (call-next-method))
    (list label
          parent-result
          prefix
          punctuation
          prefix-supplied?
          punctuation-supplied?
          (next-method-p))))

(.defgeneric inline-described (object)
  (method ((object SyntaxEntity))
    (list 'inline (entity-name object))))

(.defclass StandardAccessorEntity ()
  ((value (initform 1) (accessor standard-value))))

(.defgeneric (setf explicit-name) (new-value object))
(.defmethod ((setf explicit-name) new-value (object SyntaxEntity))
  (poo-clos-set-slot-value! object 'name new-value))

(def poo-clos-syntax-test
  (test-suite "hygienic POO-native CLOS declarations"
    (test-case "defclass lowers slots, defaults, and accessor methods"
      (let (person (poo-clos-make-instance SyntaxPerson role: 'admin))
        (check (poo-clos-instance? person) => #t)
        (check-equal? (entity-name person) 'default-person)
        (check-equal? (poo-clos-slot-value person 'role) 'admin)
        (check-equal? (poo-clos-class-documentation SyntaxPerson)
                      "Syntax person class")
        (check-equal? (poo-clos-class-metaclass SyntaxPerson) 'standard-class)
        (check-equal? (set-entity-name 'renamed person) 'renamed)
        (check-equal? (entity-name person) 'renamed)))

    (test-case "defmethod binds optional, key, supplied-p, aux, and lexical next"
      (let (person (poo-clos-make-instance SyntaxPerson name: 'Ada))
        (check-equal?
         (describe-syntax person)
         '(person ("entity" Ada "." #f #f) "person" "!" #f #f #t))
        (check-equal?
         (describe-syntax person "Dr" punctuation: "?")
         '(person ("Dr" Ada "?" #t #t) "Dr" "?" #t #t #t))))

    (test-case "defgeneric installs inline methods"
      (let (entity (poo-clos-make-instance SyntaxEntity name: 'inline-name))
        (check-equal? (inline-described entity) '(inline inline-name))))

    (test-case "one-name accessors install ANSI reader and SETF writer"
      (let (entity (poo-clos-make-instance StandardAccessorEntity))
        (check-equal? (standard-value entity) 1)
        (check-equal? (poo-clos-setf 'standard-value 2 entity) 2)
        (check-equal? (standard-value entity) 2)
        (check
         (if (poo-clos-find-generic-function
              '(setf standard-value) error?: #f) #t #f)
         => #t)))

    (test-case "SETF function names are valid generic declarations"
      (let (entity (poo-clos-make-instance SyntaxEntity name: 'before))
        (check-equal? (poo-clos-setf 'explicit-name 'after entity) 'after)
        (check-equal? (entity-name entity) 'after)))

    (test-case "generic binding preserves identity across generations"
      (check-equal?
       (.ref (poo-clos-generic-binding-current
              describe-syntax$poo-clos-generic)
             'generation)
       2)
      (check-equal?
       (length
        (.ref (poo-clos-generic-binding-current
               describe-syntax$poo-clos-generic)
              'methods))
       2)
      (check-equal? (poo-clos-generic-documentation
                     describe-syntax$poo-clos-generic)
                    "Describe syntax objects")
      (check-equal? (poo-clos-generic-function-class
                     describe-syntax$poo-clos-generic)
                    'standard-generic-function)
      (check-equal? (poo-clos-generic-method-class
                     describe-syntax$poo-clos-generic)
                    'standard-method))

    (test-case "with-slots and with-accessors are live mutable places"
      (let ((person (poo-clos-make-instance SyntaxPerson name: 'first))
            (standard (poo-clos-make-instance StandardAccessorEntity)))
        (check-equal?
         (.with-slots (name (role-value role)) person
           (let (before name)
             (set! name 'second)
             (set! role-value 'admin)
             (list before name role-value)))
         '(first second admin))
        (check-equal?
         (.with-accessors ((observed entity-name)) person
           (let (before observed)
             (set-entity-name 'third person)
             (list before observed)))
         '(second third))
        (check-equal?
         (.with-accessors ((observed standard-value)) standard
           (let (before observed)
             (set! observed 9)
             (list before observed)))
         '(1 9))
        (check-equal? (standard-value standard) 9)))

    (test-case "runtime congruence rejects a method before binding mutation"
      (let* ((binding
              (poo-clos-generic-binding
               'strict
               (poo-clos-generic-function 'strict 1 optional: 1)))
             (generation
              (.ref (poo-clos-generic-binding-current binding) 'generation))
             (method
              (poo-clos-method
               'strict (list (poo-clos-any-specializer))
               (lambda (_frame _required) 'bad)
               lambda-list:
               (poo-clos-lambda-list 1 0 #f #f '() #f))))
        (check-exception
         (poo-clos-generic-binding-add-method! binding method)
         (failure-code? 'incongruent-method-lambda-list))
        (check-equal?
         (.ref (poo-clos-generic-binding-current binding) 'generation)
         generation)))

    (test-case "unknown keyword calls fail before method execution"
      (let (person (poo-clos-make-instance SyntaxPerson name: 'Ada))
        (check-exception
         (describe-syntax person "Dr" unknown: 1)
         (failure-code? 'invalid-keyword-argument))
        (check-exception
         (describe-syntax person "Dr" unknown: 1 allow-other-keys: #f)
         (failure-code? 'invalid-keyword-argument))
        (check-equal?
         (describe-syntax person "Dr" unknown: 1 allow-other-keys: #t)
         '(person ("Dr" Ada "." #t #f) "Dr" "!" #t #f #t))))

    (test-case "declaration IR rejects duplicates, unknown clauses, and bad order"
      (check
       (integer?
        (string-contains
         (class-syntax-error '((slot) (slot)))
         "poo-clos-duplicate-slot"))
       => #t)
      (check
       (integer?
        (string-contains
         (class-syntax-error '((slot (mystery value))))
         "poo-clos-unknown-slot-option"))
       => #t)
      (check
       (integer?
        (string-contains
         (generic-syntax-error '(value &key key &optional late))
         "poo-clos-invalid-lambda-list-order"))
       => #t)
      (check
       (integer?
        (string-contains
         (generic-syntax-error '(value value))
         "poo-clos-duplicate-lambda-variable"))
       => #t))))
