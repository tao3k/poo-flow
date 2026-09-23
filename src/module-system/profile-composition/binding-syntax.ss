;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: the two approved hygienic bindings around value-level Profile
;;; selection and composition.  Neither macro parses a composition expression.

(import (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/module-system/profile-composition/profile-bundle
                 poo-flow-select-module-profiles
                 poo-flow-profile-bundle-root))

(export use-module user-composition)

;;; Select existing exports from one semantic Module.  The default instance is
;;; the Module definition identity itself; `as` introduces a distinct identity.
(defsyntax (use-module stx)
  (syntax-case stx ()
    ((_ module-name marker instance-name profile-name ...)
     (and (identifier? #'module-name)
          (identifier? #'marker)
          (eq? (syntax->datum #'marker) 'as)
          (identifier? #'instance-name)
          (pair? (syntax->list #'(profile-name ...)))
          (andmap identifier? (syntax->list #'(profile-name ...))))
     (syntax/loc stx
       (poo-flow-select-module-profiles
        module-name
        'instance-name
        '(profile-name ...))))
    ((_ module-name profile-name ...)
     (and (identifier? #'module-name)
          (pair? (syntax->list #'(profile-name ...)))
          (andmap identifier? (syntax->list #'(profile-name ...))))
     (syntax/loc stx
       (poo-flow-select-module-profiles
        module-name
        (.ref module-name 'identity)
        '(profile-name ...))))
    (_
     (raise-syntax-error
      #f
      "use-module expects (use-module module [as instance] profile ...)"
      stx))))

;;; Bind one untouched value expression once and project the declared stable
;;; identity at the explicit Scenario root boundary.
(defsyntax (user-composition stx)
  (syntax-case stx ()
    ((_ composition-name composition-expression)
     (identifier? #'composition-name)
     (syntax/loc stx
       (def composition-name
         (poo-flow-profile-bundle-root
          'composition-name
          composition-expression))))
    (_
     (raise-syntax-error
      #f
      "user-composition expects one identifier and one value expression"
      stx))))
