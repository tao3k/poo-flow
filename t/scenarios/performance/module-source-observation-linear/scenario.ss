;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A/B witness for the retired recursive-append source walker versus the
;;; production tail-passing implementation.  The baseline exists only here as
;;; evidence; it is not an alternate runtime or public compatibility path.

(import (only-in :asp-gerbil-scheme/benchmark-api benchmark-p95-elapsed-us)
        (only-in :poo-flow/src/module-system/observability/module-source-observation
                 poo-flow-scheme-lexical-call-shadow-datum-observations))

(def +sample-count+ 20)
(def +nesting-depth+ 300)
(def +scope+ 'module-source-observation-linear)
(def +shadowing-definition+
  '(def (shadowed-values values)
     (values values)))

(def (nested-source depth)
  (if (zero? depth)
    +shadowing-definition+
    (list 'begin
          (nested-source (- depth 1))
          +shadowing-definition+)))

(def source-datum (nested-source +nesting-depth+))

(def (definition-form? datum)
  (and (pair? datum)
       (memq (car datum) '(def define))
       (pair? (cdr datum))
       (pair? (cadr datum))))

;;; This intentionally reproduces the former result-list reconstruction.
(def (baseline-observations datum)
  (cond
   ((not (pair? datum)) '())
   ((memq (car datum) '(quote quasiquote syntax quasisyntax)) '())
   ((definition-form? datum)
    (poo-flow-scheme-lexical-call-shadow-datum-observations +scope+ datum))
   (else
    (append (baseline-observations (car datum))
            (baseline-observations (cdr datum))))))

(def (candidate-observations datum)
  (poo-flow-scheme-lexical-call-shadow-datum-observations +scope+ datum))

(def baseline-value (baseline-observations source-datum))
(def candidate-value (candidate-observations source-datum))

(unless (equal? baseline-value candidate-value)
  (error "tail-passing source observation changed source-order semantics"
         (length baseline-value)
         (length candidate-value)))

(displayln "[module-source-observation] phase=warmup")
(force-output)
(baseline-observations source-datum)
(candidate-observations source-datum)

(displayln "[module-source-observation] phase=baseline-p95 sample-count="
           +sample-count+)
(force-output)
(def baseline-p95-us
  (benchmark-p95-elapsed-us
   +sample-count+
   (lambda () (baseline-observations source-datum))))

(displayln "[module-source-observation] phase=candidate-p95 sample-count="
           +sample-count+)
(force-output)
(def candidate-p95-us
  (benchmark-p95-elapsed-us
   +sample-count+
   (lambda () (candidate-observations source-datum))))

(unless (< candidate-p95-us baseline-p95-us)
  (error "tail-passing source observation did not improve deep traversal"
         baseline-p95-us candidate-p95-us))

(displayln "schema=poo-flow.module-source-observation-linear.v1")
(displayln "sample-count=" +sample-count+)
(displayln "nesting-depth=" +nesting-depth+)
(displayln "observation-count=" (length candidate-value))
(displayln "baseline-p95-us=" baseline-p95-us)
(displayln "candidate-p95-us=" candidate-p95-us)
(displayln "source-order-equivalent=#t")
(displayln "accepted=#t")
