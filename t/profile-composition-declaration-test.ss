;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: atomic tests for the compile-time use-composition declaration owner.

(import :std/test
        (only-in :gerbil/expander datum->syntax)
        :poo-flow/src/module-system/profile-composition/declaration-syntax)

(export profile-composition-declaration-test)

(def (composition-declaration-error-message module-datum . maybe-form-data)
  (let* ((module-form (datum->syntax #f module-datum))
         (forms
          (if (null? maybe-form-data)
            '()
            (map (lambda (form) (datum->syntax #f form))
                 (car maybe-form-data)))))
    (with-exception-catcher
     (lambda (exn)
       (call-with-output-string
        (lambda (port) (display-exception exn port))))
     (lambda ()
       (parse-poo-flow-composition-declaration
        (datum->syntax #f 'invalid-composition)
        module-form
        forms
        module-form)
       #f))))

(defrule (check-declaration-error category module-datum form ...)
  (check-equal?
   (integer?
    (string-contains
     (composition-declaration-error-message
      module-datum
      (list form ...))
     category))
   #t))

(def profile-composition-declaration-test
  (test-suite
   "profile composition declaration"
   (test-case
    "valid multi-module declaration retains source order"
    (let* ((source
            '(modules
              (use-module github as github (profile workflow))
              (use-module sdlc as sdlc (profile nasa))))
           (source-syntax (datum->syntax #f source))
           (declaration
            (parse-poo-flow-composition-declaration
             (datum->syntax #f 'github-workflow)
             source-syntax
             (map (lambda (form) (datum->syntax #f form))
                  '((compose
                     (profile github workflow)
                     (profile sdlc nasa))
                    (stage verify (prove nasa-gates))))
             source-syntax)))
      (check-equal? (length (composition-declaration-modules declaration)) 2)
      (check-equal? (length (composition-declaration-compose declaration)) 2)
      (check-equal? (length (composition-declaration-stages declaration)) 1)))
   (test-case
    "non-canonical module grammar is rejected"
    (check-declaration-error
     "composition-invalid-module-form"
     '(module artifact)))
   (test-case
    "duplicate profiles are rejected by the module index"
    (check-declaration-error
     "composition-duplicate-profile"
     '(use-module artifact-catalog as artifact
        (profile report :kind report)
        (profile report :kind report))))
   (test-case
    "duplicate module aliases are rejected by the binding-aware index"
    (check-declaration-error
     "composition-duplicate-module-alias"
     '(modules
       (use-module github as workflow (profile build))
       (use-module sdlc as workflow (profile nasa)))))
   (test-case
    "compose references require a declared alias"
    (check-declaration-error
     "composition-invalid-compose-clause"
     '(use-module github as github (profile workflow))
     '(compose (profile missing workflow))))
   (test-case
    "duplicate stages are rejected by the stage index"
    (check-declaration-error
     "composition-duplicate-stage"
     '(use-module github as github (profile workflow))
     '(compose (profile github workflow))
     '(stage verify (prove first))
     '(stage verify (prove second))))
   (test-case
    "empty composition bodies are rejected"
    (check-declaration-error
     "composition-missing-profile-operand"
     '(use-module artifact-catalog as artifact)))
   (test-case
    "stage-only composition bodies are rejected"
    (check-declaration-error
     "composition-missing-profile-operand"
     '(use-module artifact-catalog as artifact)
     '(stage production
       (graph artifact-publish-graph)
       (prove audit-before-publish))))))
