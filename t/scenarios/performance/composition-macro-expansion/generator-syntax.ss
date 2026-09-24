;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: declarative fixture generator for composition expansion gates.

(import :poo-flow/src/module-system/profile-composition/interface
        (for-syntax
         (only-in :gerbil/core/expander stx-identifier)))

(export define-composition-expansion-case
        define-composition-module-index-case)

(begin-syntax
  ;; : (-> Syntax String Fixnum [Syntax])
  (def (composition-benchmark-identifiers template prefix count)
    (let loop ((index 0) (out '()))
      (if (= index count)
        (reverse out)
        (loop
         (fx1+ index)
         (cons (stx-identifier template prefix index) out))))))

;;; Emit one real use-composition form with COUNT distinct local POO profiles.
;;; The outer macro only materializes declarative syntax; use-composition still
;;; owns declaration validation and lowering on the compiler hot path.
(defsyntax (define-composition-expansion-case stx)
  (syntax-case stx ()
    ((_ binding count)
     (let (profile-count (syntax->datum #'count))
       (unless (and (fixnum? profile-count) (fx> profile-count 0))
         (raise-syntax-error
          #f
          "composition benchmark count must be a positive fixnum"
          #'count))
       (let (profile-identifiers
             (composition-benchmark-identifiers
              #'binding "profile-" profile-count))
         (with-syntax (((profile-name ...) profile-identifiers))
           #'(def binding
               (use-composition binding
                 (use-module benchmark-catalog as benchmark
                   (profile profile-name
                     :kind benchmark-profile) ...)
                 (compose
                   (profiles benchmark profile-name ...))
                 (stage verification
                   (graph composition-expansion-graph)
                   (prove profile-count-is-preserved))))))))))

;;; Exercise module-alias admission and reference lookup at scale.  Every alias
;;; is distinct, so the declaration owner's index should remain linear.
(defsyntax (define-composition-module-index-case stx)
  (syntax-case stx ()
    ((_ binding count)
     (let (module-count (syntax->datum #'count))
       (unless (and (fixnum? module-count) (fx> module-count 0))
         (raise-syntax-error
          #f
          "composition module benchmark count must be a positive fixnum"
          #'count))
       (let ((module-identifiers
              (composition-benchmark-identifiers
               #'module-source "module-" module-count))
             (alias-identifiers
              (composition-benchmark-identifiers
               #'module-alias "alias-" module-count))
             (profile-identifiers
              (composition-benchmark-identifiers
               #'module-profile "profile-" module-count)))
         (with-syntax (((module-name ...) module-identifiers)
                       ((alias ...) alias-identifiers)
                       ((profile-name ...) profile-identifiers))
           #'(def binding
               (use-composition binding
                 (modules
                  (use-module module-name as alias
                    (profile profile-name :kind benchmark-profile)) ...)
                 (compose (profile alias profile-name) ...)
                 (stage verification
                   (prove module-alias-index-is-linear))))))))))
