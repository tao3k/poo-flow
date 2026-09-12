;;; -*- Gerbil -*-
;;; Clause ledger completeness and profile-separation checks.

(import (only-in :std/test test-suite test-case check-equal? check)
        (only-in :clan/poo/object .ref)
        (only-in :std/srfi/1 filter foldl)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in "../../../src/module-system/observability/module-presentation.ss"
                 poo-flow-poo-slot-authoring-datum-observations
                 poo-flow-poo-slot-authoring-file-observations
                 poo-flow-poo-slot-authoring-diagnostics)
        "clause-ledger.ss")

(export poo-clos-clause-ledger-test)

(def (unique-symbols? values)
  (= (length values)
     (length (foldl (lambda (value result)
                      (if (memq value result) result (cons value result)))
                    '() values))))

(def (scheme-files directory predicate)
  (map (lambda (name) (path-expand name directory))
       (filter (lambda (name)
                 (and (string-suffix? ".ss" name) (predicate name)))
               (directory-files directory))))

(def (poo-clos-owned-sources)
  (append
   (scheme-files "src/module-system/poo-clos" (lambda (_name) #t))
   (scheme-files "t"
                 (lambda (name) (string-prefix? "poo-clos-" name)))
   (scheme-files "t/qualification/poo-clos" (lambda (_name) #t))))

(def (poo-clos-authoring-diagnostics path)
  (poo-flow-poo-slot-authoring-diagnostics
   (poo-flow-poo-slot-authoring-file-observations 'poo-clos path)))

(def poo-clos-clause-ledger-test
  (test-suite "POO-native CLOS executable clause ledger"
    (test-case "semantic clause rows remain explicit and structurally valid"
      (let (required (poo-clos-required-ansi-rows))
        (check (> (length required) 30) => #t)
        (check-equal? (.ref (car required) 'id) 'C43-class-metaobjects)
        (check (andmap poo-clos-ledger-row-valid? required) => #t)
        (check (unique-symbols?
                (map (lambda (row) (.ref row 'id)) required)) => #t)))
    (test-case "the CLHS Objects Dictionary is exhaustive and fail-closed"
      (let* ((operators (poo-clos-required-ansi-operators))
             (names (map (lambda (row) (.ref row 'id)) operators))
             (open (poo-clos-open-required-ansi-rows)))
        (check-equal? (length operators) 41)
        (check (andmap poo-clos-operator-row-valid? operators) => #t)
        (check-equal?
         names
         '(function-keywords ensure-generic-function allocate-instance
           reinitialize-instance shared-initialize
           update-instance-for-different-class
           update-instance-for-redefined-class change-class slot-boundp
           slot-exists-p slot-makunbound slot-missing slot-unbound slot-value
           method-qualifiers no-applicable-method no-next-method remove-method
           make-instance make-instances-obsolete make-load-form
           make-load-form-saving-slots with-accessors with-slots defclass
           defgeneric defmethod find-class next-method-p
           call-method/make-method call-next-method compute-applicable-methods
           define-method-combination find-method add-method initialize-instance
           class-name (setf class-name) class-of unbound-slot
           unbound-slot-instance))
        (check-equal? open '())))
    (test-case "all CLOS-owned POO slot initializers pass the source gate"
      (check-equal?
       (apply append (map poo-clos-authoring-diagnostics
                          (poo-clos-owned-sources)))
       '()))
    (test-case "the source gate rejects the observed lazy self-slot leak shape"
      (let (diagnostics
            (poo-flow-poo-slot-authoring-diagnostics
             (poo-flow-poo-slot-authoring-datum-observations
              'poo-clos
              '(def (operator status-name)
                 (.o status: status)))))
        (check (pair? diagnostics) => #t)
        (check-equal? (cdr (assoc 'code (car diagnostics)))
                      'poo-slot-initializer-shadows-slot)
        (check-equal? (cdr (assoc 'slot (car diagnostics))) 'status)))
    (test-case "MOP evidence remains outside the ANSI acceptance denominator"
      (let (extended
            (filter (lambda (row) (eq? (.ref row 'profile) 'mop-extended))
                    poo-clos-clause-ledger))
        (check-equal? (length extended) 1)
        (check (not (memq (car extended) (poo-clos-required-ansi-rows)))
               => #t)))))
