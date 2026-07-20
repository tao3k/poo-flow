;;; -*- Gerbil -*-
;;; Boundary: thin public syntax and final lowering for profile composition.
;;; Invariant: parsing is phase-owned; expansion emits ordinary POO builders.

(import :poo-flow/src/module-system/profile-composition-builders
        :poo-flow/src/module-system/profile-composition-inline-runtime
        (for-syntax
         :poo-flow/src/module-system/profile-composition-syntax-plan))

(export use-composition)

(begin-syntax
  ;; : (-> CompositionProfileSectionSyntax Syntax)
  (def (poo-flow-composition-lower-profile-section section)
    (let ((slot (composition-profile-section-syntax-slot section))
          (value (composition-profile-section-syntax-value section)))
      (case slot
        ((extends)
         (with-syntax ((value value))
           #'(cons 'extends value)))
        ((hooks)
         (with-syntax (((hook ...) (syntax->list value)))
           #'(cons 'hooks (list hook ...))))
        (else
         (with-syntax ((slot slot)
                       (value value))
           #'(cons 'slot 'value))))))

  ;; : (-> CompositionProfileSyntax Syntax)
  (def (poo-flow-composition-lower-profile profile)
    (let ((name (composition-profile-syntax-name profile))
          (module-name
           (composition-profile-syntax-module-name profile)))
      (case (composition-profile-syntax-mode profile)
        ((imported)
         (with-syntax ((name name)
                       (module-name module-name))
           #'(poo-flow-composition-inline-imported-profile
              'module-name
              'name)))
        ((existing)
         (composition-profile-syntax-value profile))
        ((local)
         (let section-loop
             ((rest (composition-profile-syntax-sections profile))
              (out '()))
           (if (null? rest)
             (with-syntax ((name name)
                           ((section ...) (reverse out)))
               #'(poo-flow-composition-inline-profile
                  'name
                  (list section ...)))
             (section-loop
              (cdr rest)
              (cons
               (poo-flow-composition-lower-profile-section (car rest))
               out)))))
        (else
         (error "unknown composition profile plan mode"
                (composition-profile-syntax-mode profile))))))

  ;; : (-> [CompositionProfileSyntax] (values [Syntax] [Syntax]))
  (def (poo-flow-composition-lower-profiles profiles)
    (let loop ((rest profiles) (names '()) (expressions '()))
      (if (null? rest)
        (values (reverse names) (reverse expressions))
        (let (profile (car rest))
          (loop
           (cdr rest)
           (cons (composition-profile-syntax-name profile) names)
           (cons
            (poo-flow-composition-lower-profile profile)
            expressions))))))

  ;; : (-> CompositionProfileRefSyntax Syntax)
  (def (poo-flow-composition-lower-profile-ref profile-ref)
    (with-syntax
        ((module-name
          (composition-profile-ref-syntax-module profile-ref))
         (profile-name
          (composition-profile-ref-syntax-slot profile-ref)))
      #'(poo-flow-profile-ref module-name 'profile-name)))

  ;; : (-> [CompositionProfileRefSyntax] [Syntax])
  (def (poo-flow-composition-lower-profile-refs profile-refs)
    (let loop ((rest profile-refs) (out '()))
      (if (null? rest)
        (reverse out)
        (loop
         (cdr rest)
         (cons
          (poo-flow-composition-lower-profile-ref (car rest))
          out)))))

  ;; : (-> CompositionClauseSyntax Syntax)
  (def (poo-flow-composition-lower-stage-clause clause)
    (with-syntax ((kind (composition-clause-syntax-kind clause))
                  ((payload ...)
                   (composition-clause-syntax-payload clause)))
      #'(poo-flow-composition-clause 'kind '(payload ...))))

  ;; : (-> CompositionStageSyntax Syntax)
  (def (poo-flow-composition-lower-stage stage)
    (let clause-loop
        ((rest (composition-stage-syntax-clauses stage))
         (out '()))
      (if (null? rest)
        (with-syntax
            ((stage-name (composition-stage-syntax-name stage))
             ((clause ...) (reverse out)))
          #'(poo-flow-composition-stage
             'stage-name
             (list clause ...)))
        (clause-loop
         (cdr rest)
         (cons
          (poo-flow-composition-lower-stage-clause (car rest))
          out)))))

  ;; : (-> [CompositionStageSyntax] [Syntax])
  (def (poo-flow-composition-lower-stages stages)
    (let loop ((rest stages) (out '()))
      (if (null? rest)
        (reverse out)
        (loop
         (cdr rest)
         (cons (poo-flow-composition-lower-stage (car rest)) out))))))

;;; Expand the canonical declarative composition grammar into POO-native
;;; module, profile, clause, stage, and composition builders.
;; : (-> Syntax Syntax)
(defsyntax (use-composition stx)
  (syntax-case stx ()
    ((_ composition-name module-form form ...)
     (let* ((plan
             (parse-poo-flow-composition-syntax-plan
              #'composition-name
              #'module-form
              (syntax->list #'(form ...))
              stx))
            (alias (composition-syntax-plan-alias plan))
            (profile-refs (composition-syntax-plan-compose plan))
            (compose-expressions
             (poo-flow-composition-lower-profile-refs profile-refs))
            (profile-binding-expressions
             (map
              (lambda (profile-ref)
                (with-syntax
                    ((module
                      (composition-profile-ref-syntax-module profile-ref))
                     (slot
                      (composition-profile-ref-syntax-slot profile-ref)))
                  #'(poo-flow-composition-profile-binding 'module 'slot)))
              profile-refs))
            (stage-expressions
             (poo-flow-composition-lower-stages
              (composition-syntax-plan-stages plan))))
       (let-values (((profile-names profile-expressions)
                     (poo-flow-composition-lower-profiles
                      (composition-syntax-plan-profiles plan))))
         (with-syntax
             ((composition-name (composition-syntax-plan-name plan))
              (alias alias)
              ((profile-name ...) profile-names)
              ((profile-expression ...) profile-expressions)
              ((compose-expression ...) compose-expressions)
              ((profile-binding-expression ...)
               profile-binding-expressions)
              ((stage-expression ...) stage-expressions))
           (syntax/loc stx
             (let ((alias
                    (poo-flow-composition-inline-module
                     '(profile-name ...)
                     (list profile-expression ...))))
               (poo-flow-composition-object/profile-bindings
                'composition-name
                (list
                 (poo-flow-composition-module-binding 'alias alias))
                (list compose-expression ...)
                (list stage-expression ...)
                (list profile-binding-expression ...))))))))))
