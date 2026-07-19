;;; -*- Gerbil -*-
;;; Boundary: shared compile-time validation and expansion for fixed receipt
;;; projections; domain owners retain their public declaration syntax.
;;; Invariant: expansion is bounded by declaration size and produces ordinary
;;; procedures that evaluate local bindings once before ABI serialization.

(export defpoo-static-receipt-projection)

(begin-syntax
  (def (poo-flow-projection-bound-identifier-member? identifier identifiers)
    (and (pair? identifiers)
         (or (bound-identifier=? identifier (car identifiers))
             (poo-flow-projection-bound-identifier-member?
              identifier
              (cdr identifiers)))))

  (def (poo-flow-projection-duplicate-identifier identifiers-stx)
    (let loop ((identifiers (syntax->list identifiers-stx)))
      (and (pair? identifiers)
           (let (identifier (car identifiers))
             (if (poo-flow-projection-bound-identifier-member?
                  identifier
                  (cdr identifiers))
               identifier
               (loop (cdr identifiers)))))))

  (def (poo-flow-projection-duplicate-key keys-stx)
    (let loop ((keys (syntax->list keys-stx)) (seen '()))
      (and (pair? keys)
           (let* ((key-stx (car keys))
                  (key (syntax->datum key-stx)))
             (if (memq key seen)
               key-stx
               (loop (cdr keys) (cons key seen)))))))

  (def (poo-flow-projection-validate!
        stx arguments-stx bindings-stx keys-stx)
    (let ((duplicate-argument
           (poo-flow-projection-duplicate-identifier arguments-stx))
          (duplicate-binding
           (poo-flow-projection-duplicate-identifier bindings-stx))
          (duplicate-key
           (poo-flow-projection-duplicate-key keys-stx)))
      (cond
       (duplicate-argument
        (raise-syntax-error
         #f
         "duplicate static receipt projection argument"
         stx
         duplicate-argument))
       (duplicate-binding
        (raise-syntax-error
         #f
         "duplicate static receipt projection binding"
         stx
         duplicate-binding))
       (duplicate-key
       (raise-syntax-error
         #f
         "duplicate static receipt projection field key"
         stx
         duplicate-key))))))

;; defpoo-static-receipt-projection
;; : (-> Syntax Syntax)
;; | doc m%
;;   Validate a normalized static receipt declaration and expand it to one
;;   ordinary constructor procedure. Field keys must be quoted identifiers.
  (defsyntax (defpoo-static-receipt-projection stx)
  (syntax-case stx (guard bindings fields quote)
    ((_ constructor (argument ...)
        (guard guard-expr fallback-expr)
        (bindings ((binding-name binding-expr) ...))
        (fields (((quote field-key) field-expr) ...)))
     (and (identifier? #'constructor)
          (identifier-list? #'(argument ...))
          (identifier-list? #'(binding-name ...))
          (identifier-list? #'(field-key ...)))
     (begin
       (poo-flow-projection-validate!
        stx
        #'(argument ...)
        #'(binding-name ...)
        #'(field-key ...))
       #'(def (constructor argument ...)
           (if guard-expr
             (let* ((binding-name binding-expr) ...)
               (list (cons 'field-key field-expr) ...))
             fallback-expr))))
    ((_ constructor (argument ...)
        (bindings ((binding-name binding-expr) ...))
        (fields (((quote field-key) field-expr) ...)))
     (and (identifier? #'constructor)
          (identifier-list? #'(argument ...))
          (identifier-list? #'(binding-name ...))
          (identifier-list? #'(field-key ...)))
     (begin
       (poo-flow-projection-validate!
        stx
        #'(argument ...)
        #'(binding-name ...)
        #'(field-key ...))
       #'(def (constructor argument ...)
           (let* ((binding-name binding-expr) ...)
             (list (cons 'field-key field-expr) ...)))))
    (_
     (raise-syntax-error
      #f
      "invalid static receipt projection declaration"
      stx))))
