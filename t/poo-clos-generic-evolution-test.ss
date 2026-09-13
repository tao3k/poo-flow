;;; -*- Gerbil -*-
;;; POO-native ensure/reinitialize generic-function conformance.

(import (only-in :std/test
                 test-suite test-case check-equal? check-exception check)
        (only-in :clan/poo/object .ref)
        "../src/module-system/poo-clos/interface.ss")

(export poo-clos-generic-evolution-test)

(def (failure-code? code)
  (lambda (error)
    (and (poo-clos-failure? error)
         (eq? (.ref error 'code) code))))

(def poo-clos-generic-evolution-test
  (test-suite "POO-native CLOS generic evolution"
    (test-case "ensure creates an explicit dispatchable binding"
      (let (binding
            (poo-clos-ensure-generic-function
             'ensured required: 1 rest?: #t))
        (check-equal? (poo-clos-generic-name binding) 'ensured)
        (check-equal? (poo-clos-generic-generation binding) 0)
        (check-exception (poo-clos-call binding)
                         (failure-code? 'argument-count-mismatch))))

    (test-case "reinitialization preserves admitted methods atomically"
      (let* ((binding
              (poo-clos-ensure-generic-function 'configured required: 1))
             (method
              (poo-clos-method
               'configured/any (list (poo-clos-any-specializer))
               (lambda (_frame value) value))))
        (poo-clos-generic-binding-add-method! binding method)
        (let ((before (poo-clos-generic-binding-current binding))
              (next
               (poo-clos-reinitialize-generic-function!
                binding rest?: #t)))
          (check-equal? (poo-clos-call binding 'ok) 'ok)
          (check-equal? (poo-clos-generic-generation next) 2)
          (check-equal? (poo-clos-generic-methods next) (list method))
          (check (eq? before next) => #t)
          (check-exception
           (poo-clos-reinitialize-generic-function!
            binding required: 2 argument-precedence-order: '(0 1))
           (failure-code? 'method-required-argument-mismatch))
          (check (eq? (poo-clos-generic-binding-current binding) next) => #t))))

    (test-case "ensure reuses bindings and checks their identity"
      (let (binding
            (poo-clos-ensure-generic-function 'same required: 0))
        (check (eq? (poo-clos-ensure-generic-function
                     'same existing: binding optional: 1)
                    binding)
               => #t)
        (check-equal? (poo-clos-generic-generation binding) 1)
        (check-exception
         (poo-clos-ensure-generic-function 'other existing: binding)
         (failure-code? 'generic-binding-identity-mismatch))))))
