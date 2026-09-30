;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Hygienic syntax for selecting existing Core Module profiles.

(import (only-in :clan/poo/object .ref)
        (only-in :core/profile-composition/profile-bundle
                 poo-flow-select-module-profiles))

(export use-module)

;;; The default instance is the Module definition identity itself; `as`
;;; introduces a distinct identity.
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
