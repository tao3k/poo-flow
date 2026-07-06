;;; -*- Gerbil -*-
;;; Boundary: composition declaration syntax.
;;; Invariant: syntax expands to ordinary POO-native composition values.

(import :poo-flow/src/module-system/profile-composition-builders)

(export poo-flow-composition modules use-module stage)

(begin-syntax
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

;; : (-> Syntax Syntax)
;;   | doc m%
;;       Build a named POO Flow composition object from module bindings and
;;       ordered stage declarations.
;;       # Examples
;;       (poo-flow-composition rag-agent
;;         (modules (use-module session-module #:as session))
;;         (stage production
;;           (compose (profile session hardened))))
;;   | result: expands to a POO-native composition object
;;   | boundary: compile-time parsing only builds data; runtime execution is explicit
;;     %
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

;; : (-> Syntax Syntax)
;;   | doc m%
;;       Group the module bindings available to a composition.
;;       # Examples
;;       (modules
;;        (use-module session-module #:as session)
;;        (use-module sandbox-module #:as sandbox))
;;   | result: expands to the ordered module binding payload
;;   | boundary: grouping does not instantiate or execute module profiles
;;     %
(defsyntax (modules stx)
  (syntax-case stx ()
    ((_ binding ...)
     #'(list binding ...))))

;; : (-> Syntax Syntax)
;;   | doc m%
;;       Bind a POO module object to a local composition alias.
;;       # Examples
;;       (use-module session-module #:as session)
;;   | result: expands to a composition module binding
;;   | boundary: alias names are preserved as data for profile selection
;;     %
(defsyntax (use-module stx)
  (syntax-case stx ()
    ((_ module _ alias)
     #'(poo-flow-composition-module-binding 'alias module))))

;; : (-> Syntax Syntax)
;;   | doc m%
;;       Declare a named composition stage with ordered policy clauses.
;;       # Examples
;;       (stage production
;;         (compose (profile session hardened))
;;         (loop #:fuel 4 #:exit done))
;;   | result: expands to a composition stage object
;;   | boundary: stage ordering is represented as data for proof and runtime gates
;;     %
(defsyntax (stage stx)
  (syntax-case stx ()
    ((_ name clause ...)
     #'(poo-flow-composition-stage 'name (list clause ...)))))
