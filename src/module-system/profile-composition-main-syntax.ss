;;; -*- Gerbil -*-
;;; Boundary: composition declaration syntax.
;;; Invariant: syntax expands to ordinary POO-native composition values.

(import :poo-flow/src/module-system/profile-composition-builders)

(export poo-flow-composition modules use-module stage)

(begin-syntax
  ;; Engineering note: policy-sensitive helpers in this owner keep explicit
  ;; contracts adjacent to definitions so downstream reports stay actionable.
  ;; : (-> Any Any)
  (def (poo-flow-composition-module-syntax binding)
    (match (syntax->list binding)
      ([head module _ alias]
       (if (eq? (syntax->datum head) 'use-module)
         (list module alias)
         (error "poo-flow-composition expects (use-module module #:as alias)"
                binding)))
      (else
       (error "poo-flow-composition expects (use-module module #:as alias)"
              binding))))

  ;; : (-> Any Any)
  (def (poo-flow-composition-modules-syntax modules-form)
    (match (syntax->list modules-form)
      ([head . bindings]
       (if (eq? (syntax->datum head) 'modules)
         (map poo-flow-composition-module-syntax bindings)
         (error "poo-flow-composition expects a (modules ...) form"
                modules-form)))
      (else
       (error "poo-flow-composition expects a (modules ...) form"
              modules-form)))))

;; poo-flow-composition
;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand a named composition form into a POO composition object with
;;   declared module bindings and stage receipts.
;;   # Examples
;;   ```scheme
;;   (poo-flow-composition ci (modules (workflow wf)) (stage build))
;;   ;; => poo-flow-composition-object
;;   ```
(defsyntax (poo-flow-composition stx)
  (syntax-case stx ()
    ((_ name modules-form stage-form ...)
     (let* ((module-pairs
             (poo-flow-composition-modules-syntax (syntax modules-form)))
            (module-names (map car module-pairs))
            (module-aliases (map cadr module-pairs)))
       (with-syntax (((module ...)
                      module-names)
                     ((alias ...)
                      module-aliases))
         #'(let ((alias module) ...)
             (poo-flow-composition-object
              'name
              (list (poo-flow-composition-module-binding 'alias module) ...)
              (list stage-form ...))))))))

;; modules
;; : (-> Syntax Syntax)
;; | doc m%
;;   Normalize module binding clauses for a composition declaration.
;;   # Examples
;;   ```scheme
;;   (modules (workflow wf) (sandbox sb))
;;   ;; => module binding list
;;   ```
(defsyntax (modules stx)
  (syntax-case stx ()
    ((_ binding ...)
     #'(list binding ...))))

;; use-module
;; : (-> Syntax Syntax)
;; | doc m%
;;   Normalize one module use clause inside composition authoring syntax.
;;   # Examples
;;   ```scheme
;;   (use-module workflow wf)
;;   ;; => module binding clause
;;   ```
(defsyntax (use-module stx)
  (syntax-case stx ()
    ((_ module _ alias)
     #'(poo-flow-composition-module-binding 'alias module))))

;; stage
;; : (-> Syntax Syntax)
;; | doc m%
;;   Normalize a composition stage into the staged receipt sequence.
;;   # Examples
;;   ```scheme
;;   (stage build)
;;   ;; => stage receipt
;;   ```
(defsyntax (stage stx)
  (syntax-case stx ()
    ((_ name clause ...)
     #'(poo-flow-composition-stage 'name (list clause ...)))))
