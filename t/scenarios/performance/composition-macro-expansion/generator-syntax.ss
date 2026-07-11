;;; -*- Gerbil -*-
;;; Boundary: declarative fixture generator for composition expansion gates.

(import :poo-flow/src/module-system/profile-composition
        (for-syntax :std/stxutil))

(export define-composition-expansion-case)

(begin-syntax
  ;; : (-> Syntax Fixnum [Syntax])
  (def (composition-benchmark-profile-identifiers template count)
    (let loop ((index 0) (out '()))
      (if (= index count)
        (reverse out)
        (loop
         (fx1+ index)
         (cons (stx-identifier template "profile-" index) out))))))

;;; Emit one real use-composition form with COUNT distinct local POO profiles.
;;; The outer macro only materializes declarative syntax; use-composition still
;;; owns grammar validation, planning, and lowering on the compiler hot path.
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
             (composition-benchmark-profile-identifiers
              #'binding profile-count))
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
