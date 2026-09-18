;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: thin public syntax and final lowering for profile composition.
;;; Invariant: parsing is phase-owned; expansion emits ordinary POO builders.

(import :poo-flow/src/module-system/profile-composition/builders
        :poo-flow/src/module-system/profile-composition/inline-runtime
        (only-in :poo-flow/src/module-system/profile-composition/catalog
                 poo-flow-current-composition-ref)
        (only-in :poo-flow/src/module-system/profile-composition/value
                 poo-flow-composition-select)
        (only-in :poo-flow/src/module-system/profile-composition/scenario-case
                 poo-flow-scenario-case)
        (for-syntax
         :poo-flow/src/module-system/profile-composition/declaration-syntax))

(export use-composition)

(begin-syntax
  ;; One lowering result owns the parallel syntax products required by the
  ;; final template.  Callers no longer coordinate several independent walks.
  (defclass poo-flow-composition-lowering
    (module-bindings
     module-binding-expressions
     compose-expressions
     profile-binding-expressions
     stage-expressions))

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
           #'(poo-flow-scenario-inline-imported-profile
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
               #'(poo-flow-scenario-inline-profile
                  'name
                  (list section ...)))
             (section-loop
              (cdr rest)
              (cons
               (poo-flow-composition-lower-profile-section (car rest))
               out)))))
        (else
         (error "unknown composition profile declaration mode"
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

  ;; : (-> [CompositionProfileRefSyntax] (values [Syntax] [Syntax]))
  (def (poo-flow-composition-lower-profile-refs profile-refs)
    (let loop ((rest profile-refs) (expressions '()) (bindings '()))
      (if (null? rest)
        (values (reverse expressions) (reverse bindings))
        (let (profile-ref (car rest))
          (with-syntax
              ((module (composition-profile-ref-syntax-module profile-ref))
               (slot (composition-profile-ref-syntax-slot profile-ref)))
            (loop
             (cdr rest)
             (cons (poo-flow-composition-lower-profile-ref profile-ref)
                   expressions)
             (cons #'(poo-flow-scenario-profile-binding 'module 'slot)
                   bindings)))))))

  ;; : (-> CompositionClauseSyntax Syntax)
  (def (poo-flow-composition-lower-stage-clause clause)
    (with-syntax ((kind (composition-clause-syntax-kind clause))
                  ((payload ...)
                   (composition-clause-syntax-payload clause)))
      #'(poo-flow-scenario-clause 'kind '(payload ...))))

  ;; : (-> CompositionStageSyntax Syntax)
  (def (poo-flow-composition-lower-stage stage)
    (let clause-loop
        ((rest (composition-stage-syntax-clauses stage))
         (out '()))
      (if (null? rest)
        (with-syntax
            ((stage-name (composition-stage-syntax-name stage))
             ((clause ...) (reverse out)))
          #'(poo-flow-scenario-stage
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
         (cons (poo-flow-composition-lower-stage (car rest)) out)))))

  ;; : (-> [CompositionModuleSyntax] (values [Syntax] [Syntax]))
  (def (poo-flow-composition-lower-modules modules)
    (let loop ((rest modules) (module-bindings '()) (binding-expressions '()))
      (if (null? rest)
        (values (reverse module-bindings) (reverse binding-expressions))
        (let* ((module (car rest))
               (alias (composition-module-syntax-alias module)))
          (let-values (((profile-names profile-expressions)
                        (poo-flow-composition-lower-profiles
                         (composition-module-syntax-profiles module))))
            (with-syntax
                ((alias alias)
                 ((profile-name ...) profile-names)
                 ((profile-expression ...) profile-expressions))
              (loop
               (cdr rest)
               (cons
                #'(alias
                   (poo-flow-scenario-inline-module
                    '(profile-name ...)
                    (list profile-expression ...)))
                module-bindings)
               (cons #'(poo-flow-scenario-module-binding 'alias alias)
                     binding-expressions))))))))

  ;; : (-> CompositionDeclaration PooFlowCompositionLowering)
  (def (poo-flow-composition-lower-declaration declaration)
    (let-values
        (((module-bindings module-binding-expressions)
          (poo-flow-composition-lower-modules
           (composition-declaration-modules declaration)))
         ((compose-expressions profile-binding-expressions)
          (poo-flow-composition-lower-profile-refs
           (composition-declaration-compose declaration))))
      (poo-flow-composition-lowering
       module-bindings: module-bindings
       module-binding-expressions: module-binding-expressions
       compose-expressions: compose-expressions
       profile-binding-expressions: profile-binding-expressions
       stage-expressions:
       (poo-flow-composition-lower-stages
        (composition-declaration-stages declaration)))))
  )

;;; Expand the canonical declarative composition grammar into POO-native
;;; module, profile, clause, stage, and composition builders.
;; use-composition
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       Expand a validated composition declaration into ordinary POO-native builders.
;;
;;       # Examples
;;
;;       ```scheme
;;       (use-composition application (module runtime))
;;       ;; => binds the validated application composition
;;       ```
;;     %
(defsyntax (use-composition stx)
  (syntax-case stx ()
    ((_ composition)
     (syntax/loc stx
       (poo-flow-composition-select
        (poo-flow-current-composition-ref 'composition))))
    ((_ composition-name module-form form ...)
     (let* ((declaration
             (parse-poo-flow-composition-declaration
              #'composition-name
              #'module-form
              (syntax->list #'(form ...))
              stx))
            (lowering (poo-flow-composition-lower-declaration declaration)))
         (with-syntax
             ((composition-name (composition-declaration-name declaration))
              (((alias module-expression) ...)
               (poo-flow-composition-lowering-module-bindings lowering))
              ((module-binding-expression ...)
               (poo-flow-composition-lowering-module-binding-expressions lowering))
              ((compose-expression ...)
               (poo-flow-composition-lowering-compose-expressions lowering))
              ((profile-binding-expression ...)
               (poo-flow-composition-lowering-profile-binding-expressions lowering))
              ((stage-expression ...)
               (poo-flow-composition-lowering-stage-expressions lowering)))
           (syntax/loc stx
             (let ((alias module-expression) ...)
               (poo-flow-scenario-case
                'composition-name
                (list module-binding-expression ...)
                (list compose-expression ...)
                (list stage-expression ...)
                (list profile-binding-expression ...)))))))))
