;;; -*- Gerbil -*-
;;; Two-phase functional load forms for POO-native CLOS objects.
;;;
;;; Common Lisp hands creation and initialization forms to the file compiler,
;;; which substitutes reconstructed objects for literal source objects.  The
;;; Scheme adaptation keeps the same two-phase dependency boundary without a
;;; raw data DSL: a creation form is a thunk, and an initialization form is a
;;; procedure accepting an optional reference resolver.

(import (only-in :clan/poo/object .ref)
        (only-in :std/srfi/1 filter filter-map foldl)
        "types.ss" "objects.ss" "classes.ss" "lifecycle.ss"
        "dispatch.ss")

(export poo-clos-make-load-form poo-clos-make-load-form-generic
        poo-clos-make-load-form-saving-slots)

(def +poo-clos-unsupplied-slot-names+ (cons 'poo-clos 'unsupplied-slot-names))

;; : (-> [SchemeValue] Boolean)
(def (unique-symbol-list? values)
  (and (list? values)
       (if (foldl (lambda (value seen)
                    (and seen (symbol? value) (not (memq value seen))
                         (cons value seen)))
                  '() values)
         #t #f)))

;;; Local slots are effective instance-allocated slots.  Shared class cells do
;;; not belong to an individual object's default saved state.
;; : (-> ClosInstance [Symbol])
(def (local-slot-names object)
  (map (lambda (slot) (.ref slot 'identity))
       (filter
        (lambda (slot) (eq? (.ref slot 'allocation) 'instance))
        (poo-clos-class-effective-slots (poo-clos-class-of object)))))

;; : (-> ClosInstance [Symbol] Unit)
(def (validate-saved-slot-names object names)
  (unless (unique-symbol-list? names)
    (clos-fail 'invalid-load-form-slot-names operation: 'make-load-form))
  (for-each
   (lambda (name)
     (unless (poo-clos-slot-exists? object name)
       (clos-fail 'invalid-load-form-slot
                  slot: name operation: 'make-load-form)))
   names))

;;; Bound values are captured now, just as literals embedded in an ANSI
;;; initialization form are captured when MAKE-LOAD-FORM is called.  Unbound
;;; slots are omitted, so allocation leaves them uninitialized.
;; : (-> ClosInstance [Symbol] [(Pair Symbol SchemeValue)])
(def (saved-bound-slot-values object names)
  (filter-map
   (lambda (name)
     (and (poo-clos-slot-bound? object name)
          (cons name (poo-clos-slot-value object name))))
   names))

;;; The creation thunk uses ALLOCATE-INSTANCE and therefore never executes
;;; slot initforms.  The initialization procedure may be called with a resolver
;;; that maps old object references to already-created equivalents, closing
;;; circular object graphs without creation-form cycles.
;; : (-> ClosInstance slot-names: (Maybe [Symbol]) environment: SchemeValue
;;        (values Thunk (case-lambda (-> ClosInstance)
;;                                   ((-> SchemeValue SchemeValue)
;;                                    -> ClosInstance))))
(def (poo-clos-make-load-form-saving-slots
      object
      slot-names: (requested-names +poo-clos-unsupplied-slot-names+)
      environment: (_environment #f))
  (unless (poo-clos-instance? object)
    (clos-fail 'invalid-instance operation: 'make-load-form-saving-slots))
  (let* ((class (poo-clos-class-of object))
         (names
          (if (eq? requested-names +poo-clos-unsupplied-slot-names+)
            (local-slot-names object)
            requested-names)))
    (unless (list? names)
      (clos-fail 'invalid-load-form-slot-names
                 operation: 'make-load-form-saving-slots))
    (validate-saved-slot-names object names)
    (let ((saved (saved-bound-slot-values object names))
          (loaded #f))
      (def (creation-form)
        (let (created (poo-clos-allocate-instance class))
          (set! loaded created)
          created))
      (def (initialize-form resolver)
        (unless loaded
          (clos-fail 'load-form-not-created
                     operation: 'make-load-form-saving-slots))
        (unless (procedure? resolver)
          (clos-fail 'invalid-load-reference-resolver
                     operation: 'make-load-form-saving-slots))
        (for-each
         (lambda (entry)
           (poo-clos-set-slot-value!
            loaded (car entry) (resolver (cdr entry))))
         saved)
        loaded)
      (values
       creation-form
       (case-lambda
        (() (initialize-form (lambda (value) value)))
        ((resolver) (initialize-form resolver)))))))

(def make-load-form-lambda-list
  (poo-clos-lambda-list 1 1 #f #f '() #f))

;;; The ANSI default for ordinary standard objects is an error.  Programs opt
;;; in by adding a class-specialized method, normally delegating to the saving-
;;; slots helper above.
(def make-load-form-default-method
  (poo-clos-method
   'make-load-form/default
   (list (poo-clos-any-specializer))
   (lambda (_frame _object . _environment)
     (clos-fail 'make-load-form-unavailable operation: 'make-load-form))
   lambda-list: make-load-form-lambda-list))

;;; A class has a proper name only while FIND-CLASS maps that name back to the
;;; same class object.  The returned creation thunk resolves by name at load
;;; time rather than retaining the source class as the result.
;; : ClosSpecializer
(def make-load-form-class-specializer
  (poo-clos-class-specializer (.ref ClosClass 'proto)))

;; : (-> ClosClass Thunk)
(def (proper-class-creation-form class)
  (let (name (.ref class 'identity))
    (unless (and (symbol? name)
                 (eq? (poo-clos-find-class name error?: #f) class))
      (clos-fail 'class-has-no-proper-name
                 class: name operation: 'make-load-form))
    (lambda () (poo-clos-find-class name))))

;; : ClosMethod
(def make-load-form-class-method
  (poo-clos-method
   'make-load-form/class
   (list make-load-form-class-specializer)
   (lambda (_frame class . _environment)
     (proper-class-creation-form class))
   lambda-list: make-load-form-lambda-list))

(def poo-clos-make-load-form-generic
  (poo-clos-add-method
   (poo-clos-add-method
    (poo-clos-generic-function 'make-load-form 1 optional: 1)
    make-load-form-default-method)
   make-load-form-class-method))

(poo-clos-register-generic-function! poo-clos-make-load-form-generic)

;; : (-> ClosObject (Maybe SchemeValue)
;;        (values CreationForm (Maybe InitializationForm)))
(def (poo-clos-make-load-form object . environment)
  (apply poo-clos-call
         poo-clos-make-load-form-generic (cons object environment)))
