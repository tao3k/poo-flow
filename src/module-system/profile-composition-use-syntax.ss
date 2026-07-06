;;; -*- Gerbil -*-
;;; Boundary: user-facing composition declaration syntax.
;;; Invariant: expands directly to core POO-native composition builders.

(import :poo-flow/src/module-system/profile-composition-builders
        (only-in :poo-flow/src/module-system/profile-composition-profile-syntax
                 poo-flow-composition-profile-module))

(export use-composition)

(begin-syntax
  (def (poo-flow-composition-module-syntax binding)
    (match (syntax->list binding)
      ([head module _ alias]
       (let (kind (syntax->datum head))
         (cond
          ((eq? kind 'use-module)
           (list module alias))
          ((eq? kind 'use-profile)
           (with-syntax ((profile-name module))
             (list #'(poo-flow-composition-profile-module profile-name)
                   alias)))
          (else
           (error
            "use-composition expects (use-module module #:as alias) or (use-profile profile #:as alias)"
            binding)))))
      (else
       (error
        "use-composition expects (use-module module #:as alias) or (use-profile profile #:as alias)"
        binding))))

  (def (poo-flow-composition-modules-syntax modules-form)
    (match (syntax->list modules-form)
      ([head . bindings]
       (if (eq? (syntax->datum head) 'modules)
         (map poo-flow-composition-module-syntax bindings)
         (error "use-composition expects a (modules ...) form"
                modules-form)))
      (else
       (error "use-composition expects a (modules ...) form"
              modules-form))))

  (def (poo-flow-composition-profile-expr ctx form)
    (match (syntax->list form)
      ([head module slot]
       (if (eq? (syntax->datum head) 'profile)
         (with-syntax ((module module)
                       (slot slot))
           #'(poo-flow-profile-ref module 'slot))
         (error "compose expects (profile module slot)" form)))
      (else
       (error "compose expects (profile module slot)" form))))

  (def (poo-flow-composition-clause-expr ctx clause)
    (match (syntax->list clause)
      ([head . items]
       (let (kind (syntax->datum head))
         (cond
          ((eq? kind 'compose)
           (let (profiles
                 (map (lambda (item)
                        (poo-flow-composition-profile-expr ctx item))
                      items))
             (with-syntax (((profile-expr ...) profiles))
               #'(poo-flow-composition-clause
                  'compose
                  (list profile-expr ...)))))
          ((or (eq? kind 'graph)
               (eq? kind 'loop)
               (eq? kind 'prove)
               (eq? kind 'handoff))
           (with-syntax ((clause-kind head)
                         ((payload-item ...) items))
             #'(poo-flow-composition-clause
                'clause-kind
                '(payload-item ...))))
          (else
           (error "unknown use-composition clause" kind)))))
      (else
       (error "invalid use-composition clause" clause))))

  (def (poo-flow-composition-stage-expr ctx stage-form)
    (match (syntax->list stage-form)
      ([head stage-name . clauses]
       (if (eq? (syntax->datum head) 'stage)
         (let (clause-exprs
               (map (lambda (clause)
                      (poo-flow-composition-clause-expr ctx clause))
                    clauses))
           (with-syntax ((stage-name stage-name)
                         ((clause-expr ...) clause-exprs))
             #'(poo-flow-composition-stage
                'stage-name
                (list clause-expr ...))))
         (error "use-composition expects (stage name ...)" stage-form)))
      (else
       (error "use-composition expects (stage name ...)" stage-form)))))

;; : (-> Syntax Syntax)
;;   | doc m%
;;       Build a user-facing composition value while keeping expansion
;;       semantics in the core module-system package. The surrounding loader
;;       or caller owns the binding.
;;       # Examples
;;       (use-composition rag-agent
;;         (modules (use-module session-module #:as session))
;;         (stage production
;;           (compose (profile session hardened))))
;;   | result: expands to a POO Flow composition object expression
;;   | boundary: macro expansion delegates directly to composition builders
;;     %
(defsyntax (use-composition stx)
  (syntax-case stx ()
    ((_ name modules-form stage-form ...)
     (let* ((module-pairs
             (poo-flow-composition-modules-syntax (syntax modules-form)))
            (module-names (map car module-pairs))
            (module-aliases (map cadr module-pairs))
            (stage-exprs
             (map (lambda (stage-form)
                    (poo-flow-composition-stage-expr stx stage-form))
                  (syntax->list (syntax (stage-form ...))))))
       (with-syntax (((module ...) module-names)
                     ((alias ...) module-aliases)
                     ((stage-expr ...) stage-exprs))
         #'(let ((alias module) ...)
             (poo-flow-composition-object
              'name
              (list (poo-flow-composition-module-binding 'alias module) ...)
              (list stage-expr ...))))))))
