;;; -*- Gerbil -*-
;;; Contract: executable admission evidence for the pinned gerbil-poo surface.
;;; This test exercises upstream mechanics directly; it does not introduce a
;;; POO Flow object, dispatch, precedence, or inherited-computation adapter.

(import (only-in :std/test
                 check-equal?
                 check-exception
                 run-tests!
                 test-case
                 test-suite)
        (only-in :clan/poo/object
                 $computed-slot-spec
                 .@
                 .all-slots
                 .call
                 .cc
                 .def
                 .extend
                 .get
                 .mix
                 .o
                 .ref
                 .slot?
                 NoApplicableMethod?)
        (only-in :clan/poo/mop
                 .defgeneric
                 Type
                 Type.
                 TypeError?
                 define-type
                 element?
                 validate))

(export gerbil-poo-operation-admission-test)

;;; The generic selects behavior from a native Type descriptor.  The project
;;; does not copy method lookup or add a registry around the descriptor.
(.defgeneric (admission-project descriptor value)
  slot: .admission-project)

(define-type (AdmissionSymbol @ Type.)
  .element?: symbol?
  .admission-project: symbol->string)

(def gerbil-poo-operation-admission-test
  (test-suite
   "pinned gerbil-poo operation admission"

   (test-case "constructs, projects, calls, and clones native objects"
     (.def base-value
       (identity 'base)
       (render (lambda (suffix) (cons identity suffix))))
     (let (clone (.cc base-value identity: 'clone))
       (check-equal? (.ref base-value 'identity) 'base)
       (check-equal? (.get clone identity) 'clone)
       (check-equal? (.@ clone identity) 'clone)
       (check-equal? (.call clone render '(tail)) '(clone tail))
       (check-equal? (.slot? clone 'render) #t)
       (check-equal? (length (.all-slots clone)) 2)))

   (test-case "preserves C3 super order and lazy slot caching"
     (let ((b-evaluations 0)
           (c-evaluations 0))
       (let* ((a (.o (responsibility '(a))))
              (b
               (.extend
                a
                (cons
                 'responsibility
                 ($computed-slot-spec
                  (lambda (_self inherited)
                    (set! b-evaluations (1+ b-evaluations))
                    (cons 'b (inherited)))))))
              (c
               (.extend
                a
                (cons
                 'responsibility
                 ($computed-slot-spec
                  (lambda (_self inherited)
                    (set! c-evaluations (1+ c-evaluations))
                    (cons 'c (inherited)))))))
              (d (.mix b c)))
         (check-equal? (.ref d 'responsibility) '(b c a))
         (check-equal? (.ref d 'responsibility) '(b c a))
         (check-equal? b-evaluations 1)
         (check-equal? c-evaluations 1))))

   (test-case "dispatches validation and projection through a Type descriptor"
     (check-equal? (element? Type AdmissionSymbol) #t)
     (check-equal? (validate AdmissionSymbol 'flow) 'flow)
     (check-equal? (admission-project AdmissionSymbol 'flow) "flow")
     (check-exception (validate AdmissionSymbol 42) TypeError?))

   (test-case "preserves native missing-method failure"
     (check-exception
      (admission-project (.o) 'flow)
      NoApplicableMethod?))

   (test-case "preserves native invalid-precedence failure"
     (let* ((x (.o))
            (y (.o))
            (xy (.mix x y))
            (yx (.mix y x))
            (inconsistent (.mix xy yx)))
       (check-exception (.slot? inconsistent 'identity) true)))))

(run-tests! gerbil-poo-operation-admission-test)
