;;; -*- Gerbil -*-
;;; Boundary: user-facing composition declaration syntax.
;;; Invariant: expands directly to core POO-native composition builders.

(import :poo-flow/src/module-system/profile-composition-builders)

(export use-composition)

(begin-syntax
  (def (poo-flow-composition-profile-exprs ctx form)
    (match (syntax->list form)
      ([head module slot]
       (if (eq? (syntax->datum head) 'profile)
         (with-syntax ((module module)
                       (slot slot))
           (list #'(poo-flow-profile-ref module 'slot)))
         (error "compose expects (profile module slot)" form)))
      ([head module . slots]
       (if (eq? (syntax->datum head) 'profiles)
         (map (lambda (slot)
                (with-syntax ((module module)
                              (slot slot))
                  #'(poo-flow-profile-ref module 'slot)))
              slots)
         (error "compose expects (profile module slot) or (profiles module slot ...)"
                form)))
      (else
       (error "compose expects (profile module slot) or (profiles module slot ...)"
              form))))

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
;;         (use-module session
;;           (profile hardened
;;             :scope (session sandbox)))
;;         (stage production
;;           (compose (profile session hardened))))
;;   | result: expands to a POO Flow composition object expression
;;   | boundary: macro expansion delegates directly to composition builders
;;     %
(import :clan/poo/object)

(def (poo-flow-composition-inline-section-slot key)
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

(def (poo-flow-composition-inline-alist-ref alist key default)
  (let (entry (assoc key alist))
    (if entry (cdr entry) default)))

(def (poo-flow-composition-inline-profile-field sections base key default)
  (poo-flow-composition-inline-alist-ref
   sections
   key
   (if base (.ref base key) default)))

(def (poo-flow-composition-inline-apply-hooks profile hooks)
  (let loop ((rest hooks) (out profile))
    (if (null? rest)
      out
      (loop (cdr rest) ((car rest) out)))))

(def (poo-flow-composition-inline-profile profile-name sections)
  (let* ((base (poo-flow-composition-inline-alist-ref sections 'extends #f))
         (hooks (poo-flow-composition-inline-alist-ref sections 'hooks '()))
         (profile
          (if base
            (.o (:extends base)
                (name profile-name)
                (extends base)
                (kind (poo-flow-composition-inline-profile-field sections
                                                                  base
                                                                  'kind
                                                                  profile-name))
                (scope (poo-flow-composition-inline-profile-field sections
                                                                   base
                                                                   'scope
                                                                   '()))
                (storage (poo-flow-composition-inline-profile-field sections
                                                                     base
                                                                     'storage
                                                                     '()))
                (analysis (poo-flow-composition-inline-profile-field sections
                                                                      base
                                                                      'analysis
                                                                      '()))
                (publish (poo-flow-composition-inline-profile-field sections
                                                                     base
                                                                     'publish
                                                                     '()))
                (retention (poo-flow-composition-inline-profile-field sections
                                                                       base
                                                                       'retention
                                                                       '()))
                (capabilities
                 (poo-flow-composition-inline-profile-field sections
                                                            base
                                                            'capabilities
                                                            '()))
                (hooks hooks)
                (runtime-executed #f)
                (source 'poo-flow.composition.inline-profile))
            (.o (name profile-name)
                (extends #f)
                (kind (poo-flow-composition-inline-alist-ref sections
                                                             'kind
                                                             profile-name))
                (scope (poo-flow-composition-inline-alist-ref sections
                                                              'scope
                                                              '()))
                (storage (poo-flow-composition-inline-alist-ref sections
                                                                'storage
                                                                '()))
                (analysis (poo-flow-composition-inline-alist-ref sections
                                                                 'analysis
                                                                 '()))
                (publish (poo-flow-composition-inline-alist-ref sections
                                                                'publish
                                                                '()))
                (retention (poo-flow-composition-inline-alist-ref sections
                                                                  'retention
                                                                  '()))
                (capabilities
                 (poo-flow-composition-inline-alist-ref sections
                                                        'capabilities
                                                        '()))
                (hooks hooks)
                (runtime-executed #f)
                (source 'poo-flow.composition.inline-profile)))))
    (poo-flow-composition-inline-apply-hooks profile hooks)))

(begin-syntax
  (def (poo-flow-composition-inline-use-module-syntax? form)
    (match (syntax->list form)
      ([head . _]
       (eq? (syntax->datum head) 'use-module))
      (else #f)))

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
               (list (list existing-profile existing-profile)))
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

(defsyntax (use-composition stx)
  (syntax-case stx ()
    ((_ name module-form stage-form ...)
     (if (poo-flow-composition-inline-use-module-syntax? #'module-form)
       (syntax-case #'module-form ()
         ((use-module alias profile-clause ...)
          (let* ((profile-pairs
                  (apply append
                         (map poo-flow-composition-inline-profile-syntax
                              (syntax->list #'(profile-clause ...)))))
                 (profile-names (map car profile-pairs))
                 (profile-exprs (map cadr profile-pairs))
                 (stage-exprs
                  (map (lambda (stage-form)
                         (poo-flow-composition-stage-expr stx stage-form))
                       (syntax->list (syntax (stage-form ...))))))
            (with-syntax (((profile-name ...) profile-names)
                          ((profile-expr ...) profile-exprs)
                          ((stage-expr ...) stage-exprs))
              #'(let ((alias (.o (profile-name profile-expr) ...)))
                  (poo-flow-composition-object
                   'name
                   (list (poo-flow-composition-module-binding 'alias alias))
                   (list stage-expr ...)))))))
       (error "use-composition expects inline (use-module alias ...)"
              #'module-form)))))
