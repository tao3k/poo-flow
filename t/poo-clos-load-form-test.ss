;;; -*- Gerbil -*-
;;; Two-phase CLOS load forms, proper class names, and circular references.

(import (only-in :std/test
                 test-suite test-case check-equal? check-exception check)
        (only-in :clan/poo/object .ref)
        "../src/module-system/poo-clos/interface.ss")

(export poo-clos-load-form-test)

(def load-form-initform-count 0)

(.defclass LoadFormEntity ()
  ((name
    (initform
     (begin
       (set! load-form-initform-count (+ load-form-initform-count 1))
       'from-initform)))
   (link)
   (spare)))

(.defclass NonLoadableEntity () ())

(def load-form-method-lambda-list
  (poo-clos-lambda-list 1 1 #f #f '() #f))

(def load-form-entity-method
  (poo-clos-method
   'make-load-form/load-form-entity
   (list (poo-clos-class-specializer LoadFormEntity))
   (lambda (_frame object . environment)
     (poo-clos-make-load-form-saving-slots
      object environment: (and (pair? environment) (car environment))))
   lambda-list: load-form-method-lambda-list))

(poo-clos-add-method poo-clos-make-load-form-generic load-form-entity-method)

(def (failure-code? code)
  (lambda (error)
    (and (poo-clos-failure? error)
         (eq? (.ref error 'code) code))))

(def poo-clos-load-form-test
  (test-suite "POO-native CLOS two-phase load forms"
    (test-case "saving slots allocates without initforms and closes a self cycle"
      (set! load-form-initform-count 0)
      (let (source (poo-clos-make-instance LoadFormEntity))
        (poo-clos-set-slot-value! source 'name 'saved)
        (poo-clos-set-slot-value! source 'link source)
        (check-equal? load-form-initform-count 1)
        (let* ((forms
                (call-with-values
                 (lambda () (poo-clos-make-load-form source 'environment))
                 list))
               (creation-form (car forms))
               (initialization-form (cadr forms)))
          (check-equal? (length forms) 2)
          (check-exception
           (initialization-form)
           (failure-code? 'load-form-not-created))
          (let (loaded (creation-form))
            (check-equal? load-form-initform-count 1)
            (check (poo-clos-slot-bound? loaded 'name) => #f)
            (check (poo-clos-slot-bound? loaded 'spare) => #f)
            (check
             (eq? (initialization-form
                   (lambda (value) (if (eq? value source) loaded value)))
                  loaded)
             => #t)
            (check-equal? (poo-clos-slot-value loaded 'name) 'saved)
            (check (eq? (poo-clos-slot-value loaded 'link) loaded) => #t)
            (check (poo-clos-slot-bound? loaded 'spare) => #f)))))

    (test-case "an explicit slot list preserves only selected bound slots"
      (let (source (poo-clos-make-instance LoadFormEntity))
        (poo-clos-set-slot-value! source 'name 'selected)
        (poo-clos-set-slot-value! source 'link 'not-selected)
        (let* ((forms
                (call-with-values
                 (lambda ()
                   (poo-clos-make-load-form-saving-slots
                    source slot-names: '(name) environment: 'ignored))
                 list))
               (loaded ((car forms))))
          ((cadr forms))
          (check-equal? (poo-clos-slot-value loaded 'name) 'selected)
          (check (poo-clos-slot-bound? loaded 'link) => #f)
          (check (poo-clos-slot-bound? loaded 'spare) => #f))))

    (test-case "invalid slot requests fail before either form is published"
      (let (source (poo-clos-make-instance LoadFormEntity))
        (check-exception
         (poo-clos-make-load-form-saving-slots
          source slot-names: '(name name))
         (failure-code? 'invalid-load-form-slot-names))
        (check-exception
         (poo-clos-make-load-form-saving-slots
          source slot-names: '(unknown))
         (failure-code? 'invalid-load-form-slot))))

    (test-case "make-load-form is extensible and rejects its ANSI default"
      (let (source (poo-clos-make-instance LoadFormEntity))
        (check-equal?
         (length
          (call-with-values
           (lambda () (poo-clos-make-load-form source)) list))
         2))
      (check-exception
       (poo-clos-make-load-form (poo-clos-make-instance NonLoadableEntity))
       (failure-code? 'make-load-form-unavailable)))

    (test-case "class creation forms resolve only proper FIND-CLASS names"
      (let* ((forms
              (call-with-values
               (lambda () (poo-clos-make-load-form LoadFormEntity)) list))
             (creation-form (car forms)))
        (check-equal? (length forms) 1)
        (check (eq? (creation-form) LoadFormEntity) => #t))
      (let (temporary (poo-clos-class 'TemporaryLoadFormClass))
        (poo-clos-set-find-class! #f 'TemporaryLoadFormClass)
        (check-exception
         (poo-clos-make-load-form temporary)
         (failure-code? 'class-has-no-proper-name))
        (poo-clos-set-find-class! temporary 'TemporaryLoadFormClass)
        (check
         (eq? (poo-clos-find-class 'TemporaryLoadFormClass) temporary)
         => #t)))))
