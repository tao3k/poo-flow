;;; -*- Gerbil -*-
;;; Boundary: user-facing composition declaration syntax.
;;; Invariant: expands directly to core POO-native composition builders.

(import :poo-flow/src/module-system/profile-composition-builders
        :poo-flow/src/module-system/profile-composition-inline-runtime)

(export use-composition
        (import: :poo-flow/src/module-system/profile-composition-inline-runtime))

(begin-syntax
  ;; Engineering note: policy-sensitive helpers in this owner keep explicit
  ;; contracts adjacent to definitions so downstream reports stay actionable.
  ;; : (-> Any Any)
  (def (poo-flow-composition-as-marker? marker)
    (let (datum (syntax->datum marker))
      (and (symbol? datum)
           (string=? (symbol->string datum) "as"))))

  ;; : (-> Any Any)
  (def (poo-flow-composition-form-kind form)
    (match (syntax->list form)
      ([head . _] (syntax->datum head))
      (else (error "invalid use-composition form" form))))

  ;; : (-> Any Any)
  (def (poo-flow-composition-inline-module-spec module-form)
    (let (items (syntax->list module-form))
      (match items
        ([head module marker alias . profile-clauses]
         (if (and (eq? (syntax->datum head) 'use-module)
                  (poo-flow-composition-as-marker? marker))
           (list module alias profile-clauses #t)
           (match items
             ([head legacy-alias . legacy-profile-clauses]
              (if (eq? (syntax->datum head) 'use-module)
                (list legacy-alias legacy-alias legacy-profile-clauses #f)
                (error "use-composition expects inline (use-module ...)"
                       module-form)))
             (else
              (error "use-composition expects inline (use-module ...)"
                     module-form)))))
        ([head alias . profile-clauses]
         (if (eq? (syntax->datum head) 'use-module)
           (list alias alias profile-clauses #f)
           (error "use-composition expects inline (use-module ...)"
                  module-form)))
        (else
         (error "use-composition expects inline (use-module ...)"
                module-form)))))

  ;; : (-> Any Any)
  (def (poo-flow-composition-profile-exprs ctx form)
    (match (syntax->list form)
      ([head module . slots]
       (if (eq? (syntax->datum head) 'profiles)
         (map (lambda (slot)
                (with-syntax ((module module)
                              (slot slot))
                  #'(poo-flow-profile-ref module 'slot)))
              slots)
         (match slots
           ([slot]
            (if (eq? (syntax->datum head) 'profile)
              (with-syntax ((module module)
                            (slot slot))
                (list #'(poo-flow-profile-ref module 'slot)))
              (error "compose expects (profile module slot) or (profiles module slot ...)"
                     form)))
           (else
            (error "compose expects (profile module slot) or (profiles module slot ...)"
                   form)))))
      (else
       (error "compose expects (profile module slot) or (profiles module slot ...)"
              form))))

  ;; : (-> Any Any)
  (def (poo-flow-composition-clause-expr ctx clause)
    (match (syntax->list clause)
      ([head . items]
       (let (kind (syntax->datum head))
         (cond
          ((eq? kind 'compose)
           (let (profiles
                 (apply append
                        (map (lambda (item)
                               (poo-flow-composition-profile-exprs ctx item))
                             items)))
             (with-syntax (((profile-expr ...) profiles))
               #'(poo-flow-composition-clause
                  'compose
                  (list profile-expr ...)))))
          ((or (eq? kind 'graph)
               (eq? kind 'loop)
               (eq? kind 'prove)
               (eq? kind 'handoff)
               (eq? kind 'step)
               (eq? kind 'edges)
               (eq? kind 'route))
           (with-syntax ((clause-kind head)
                         ((payload-item ...) items))
             #'(poo-flow-composition-clause
                'clause-kind
                '(payload-item ...))))
          (else
           (error "unknown use-composition clause" kind)))))
      (else
       (error "invalid use-composition clause" clause))))

  ;; : (-> Any Any)
  (def (poo-flow-composition-top-compose-profile-exprs forms)
    (let loop ((rest forms) (out '()))
      (if (null? rest)
        (reverse out)
        (let ((form (car rest))
              (kind (poo-flow-composition-form-kind (car rest))))
          (cond
           ((eq? kind 'compose)
            (match (syntax->list form)
              ([head . items]
               (loop (cdr rest)
                     (append
                      (reverse
                       (apply append
                              (map (lambda (item)
                                     (poo-flow-composition-profile-exprs #f item))
                                   items)))
                      out)))
              (else
               (error "use-composition top-level compose is invalid" form))))
           ((eq? kind 'stage)
            (loop (cdr rest) out))
           (else
            (error "use-composition expects compose or stage after use-module"
                   form)))))))

  ;; : (-> Any Any)
  (def (poo-flow-composition-stage-exprs ctx forms)
    (let loop ((rest forms) (out '()))
      (if (null? rest)
        (reverse out)
        (let ((form (car rest))
              (kind (poo-flow-composition-form-kind (car rest))))
          (cond
           ((eq? kind 'stage)
            (loop (cdr rest)
                  (cons (poo-flow-composition-stage-expr ctx form) out)))
           ((eq? kind 'compose)
            (loop (cdr rest) out))
           (else
            (error "use-composition expects compose or stage after use-module"
                   form)))))))

  ;; : (-> Any Any)
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
;;         (use-module session
;;           (profile hardened
;;             :scope (session sandbox)))
;;         (stage production
;;           (compose (profile session hardened))))
;;   | result: expands to a POO Flow composition object expression
;;   | boundary: macro expansion delegates directly to composition builders
;;     %
(begin-syntax
  ;; : (-> Any Any)
  (def (poo-flow-composition-inline-use-module-syntax? form)
    (match (syntax->list form)
      ([head . _]
       (eq? (syntax->datum head) 'use-module))
      (else #f)))

  ;; : (-> Any Any)
  (def (poo-flow-composition-inline-section-slot-syntax key)
    (case key
      ((:extends extends) 'extends)
      ((:kind kind) 'kind)
      ((:scope scope) 'scope)
      ((:storage storage) 'storage)
      ((:analysis analysis) 'analysis)
      ((:publish publish) 'publish)
      ((:retention retention) 'retention)
      ((:capabilities capabilities) 'capabilities)
      ((:with with) 'hooks)
      (else key)))

  ;; : (-> Any Any)
  (def (poo-flow-composition-inline-section-pair key value)
    (let (slot (poo-flow-composition-inline-section-slot-syntax
                (syntax->datum key)))
      (case slot
        ((extends)
         (with-syntax ((slot slot)
                       (value value))
           #'(cons 'slot value)))
        ((hooks)
         (with-syntax ((slot slot)
                       ((hook ...) (syntax->list value)))
           #'(cons 'slot (list hook ...))))
        (else
         (with-syntax ((slot slot)
                       (value value))
           #'(cons 'slot 'value))))))

  ;; : (-> Any Any)
  (def (poo-flow-composition-inline-section-pairs sections)
    (let loop ((rest sections) (out '()))
      (cond
       ((null? rest) (reverse out))
       ((null? (cdr rest))
        (error "inline profile section requires a value" (car rest)))
       (else
        (loop (cddr rest)
              (cons (poo-flow-composition-inline-section-pair
                     (car rest)
                     (cadr rest))
                    out))))))

  ;; : (-> Any Any)
  (def (poo-flow-composition-inline-imported-profile-syntax module-name stx)
    (let (items (syntax->list stx))
      (match items
        ([head . rest]
         (let (kind (syntax->datum head))
           (cond
            ((eq? kind 'profiles)
             (if (null? rest)
               (error "profiles expects one or more profile slots" stx)
               (map (lambda (profile-slot)
                      (with-syntax ((module-name module-name)
                                    (profile-slot profile-slot))
                        (list #'profile-slot
                              #'(poo-flow-composition-inline-imported-profile
                                 'module-name
                                 'profile-slot))))
                    rest)))
            (else
             (poo-flow-composition-inline-profile-syntax stx)))))
        (else
         (error "use-composition inline use-module expects profile clauses"
                stx)))))

  ;; : (-> Any Any)
  (def (poo-flow-composition-inline-profile-pairs module-name imported? clauses)
    (apply append
           (map (lambda (clause)
                  (if imported?
                    (poo-flow-composition-inline-imported-profile-syntax
                     module-name
                     clause)
                    (poo-flow-composition-inline-profile-syntax clause)))
                clauses)))

  ;; : (-> Any Any)
  (def (poo-flow-composition-inline-profile-syntax stx)
    (let (items (syntax->list stx))
      (match items
        ([head . rest]
         (let (kind (syntax->datum head))
           (cond
            ((eq? kind 'profiles)
            (match rest
              ([profile-module . profile-slots]
               (map (lambda (profile-slot)
                      (with-syntax ((profile-module profile-module)
                                    (profile-slot profile-slot))
                        (list #'profile-slot
                              #'(poo-flow-profile-ref profile-module
                                                      'profile-slot))))
                    profile-slots))
              (else
               (error "profiles expects a module and one or more slots"
                      stx))))
            ((eq? kind 'profile)
            (match rest
              ([existing-profile]
               (with-syntax ((existing-profile existing-profile))
                 (list
                  (list #'existing-profile
                        #'(let ((profile-object existing-profile))
                            profile-object)))))
              ([profile-name . sections]
               (let (section-pairs
                     (poo-flow-composition-inline-section-pairs sections))
                 (with-syntax ((profile-name profile-name)
                               ((section-pair ...) section-pairs))
                   (list
                    (list #'profile-name
                          #'(poo-flow-composition-inline-profile
                             'profile-name
                             (list section-pair ...)))))))
              (else
               (error "profile expects an object or a named profile"
                      stx))))
            (else
            (error "use-composition inline use-module expects profile clauses"
                   stx)))))
        (else
         (error "use-composition inline use-module expects profile clauses"
                stx)))))

  )

;;; Boundary: use-composition is the hygienic macro facade from compact user
;;; syntax into explicit inline module/profile composition objects.
;; use-composition
;; : (-> Syntax PooFlowCompositionExpansionSyntax)
;; | doc m%
;;   Expand one inline composition declaration into a POO composition object
;;   with module bindings and stage receipts.
;;   # Examples
;;   ```scheme
;;   (use-composition ci (use-module workflow (profile default)) (stage build))
;;   ;; => poo-flow-composition-object
;;   ```
(defsyntax (use-composition stx)
  (syntax-case stx ()
    ((_ name module-form form ...)
     (if (poo-flow-composition-inline-use-module-syntax? #'module-form)
       (let* ((module-spec
               (poo-flow-composition-inline-module-spec #'module-form))
              (module-name (car module-spec))
              (alias (cadr module-spec))
              (profile-clauses (caddr module-spec))
              (imported? (cadddr module-spec))
              (profile-pairs
               (poo-flow-composition-inline-profile-pairs
                module-name
                imported?
                profile-clauses))
              (profile-names (map car profile-pairs))
              (profile-exprs (map cadr profile-pairs))
              (forms (syntax->list #'(form ...)))
              (compose-profile-exprs
               (poo-flow-composition-top-compose-profile-exprs forms))
              (stage-exprs
               (poo-flow-composition-stage-exprs stx forms)))
         (with-syntax ((alias alias)
                       ((profile-name ...) profile-names)
                       ((profile-expr ...) profile-exprs)
                       ((compose-profile-expr ...) compose-profile-exprs)
                       ((stage-expr ...) stage-exprs))
           #'(let ((alias (poo-flow-composition-inline-module
                           '(profile-name ...)
                           (list profile-expr ...))))
               (poo-flow-composition-object/profiles
                'name
                (list (poo-flow-composition-module-binding 'alias alias))
                (list compose-profile-expr ...)
                (list stage-expr ...)))))
       (error "use-composition expects inline (use-module alias ...)"
              #'module-form)))))
