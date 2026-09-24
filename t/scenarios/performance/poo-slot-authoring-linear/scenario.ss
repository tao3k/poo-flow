;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A/B witness for the retired recursive-append POO slot source walker versus
;;; the production tail-passing implementation. The baseline is evidence only;
;;; it is not a second runtime or a public compatibility path.

(import (only-in :asp-gerbil-scheme/benchmark-api benchmark-p95-elapsed-us)
        (only-in :poo-flow/src/module-system/observability/module-presentation
                 poo-flow-poo-slot-authoring-datum-bindings))

(def +sample-count+ 20)
(def +nesting-depth+ 300)

(def (nested-object depth)
  (if (zero? depth)
    '(.o leaf: leaf-value)
    (list '.o
          'depth: depth
          'child: (nested-object (- depth 1)))))

(def source-datum (nested-object +nesting-depth+))

(def (baseline-form-bindings elements)
  (cond
   ((null? elements) '())
   ((not (pair? elements)) '())
   ((and (keyword? (car elements))
         (pair? (cdr elements)))
    (cons (cons (string->symbol (keyword->string (car elements)))
                (cadr elements))
          (baseline-form-bindings (cddr elements))))
   ((and (pair? (car elements))
         (symbol? (caar elements))
         (pair? (cdar elements))
         (null? (cddar elements)))
    (cons (cons (caar elements) (cadar elements))
          (baseline-form-bindings (cdr elements))))
   (else
    (baseline-form-bindings (cdr elements)))))

;;; This intentionally reproduces the former result-list reconstruction.
(def (baseline-bindings datum)
  (cond
   ((not (pair? datum)) '())
   ((and (memq (car datum) '(quote quasiquote syntax quasisyntax))
         (pair? (cdr datum)))
    '())
   (else
    (let* ((head (car datum))
           (object-elements
            (cond
             ((eq? head '.o) (cdr datum))
             ((and (eq? head '.def) (pair? (cdr datum))) (cddr datum))
             (else '())))
           (local-bindings (baseline-form-bindings object-elements)))
      (append local-bindings
              (baseline-bindings (car datum))
              (baseline-bindings (cdr datum)))))))

(def baseline-value (baseline-bindings source-datum))
(def candidate-value
  (poo-flow-poo-slot-authoring-datum-bindings source-datum))

(unless (equal? baseline-value candidate-value)
  (error "tail-passing POO slot walk changed source-order semantics"
         (length baseline-value)
         (length candidate-value)))

(displayln "[poo-slot-authoring] phase=warmup")
(force-output)
(baseline-bindings source-datum)
(poo-flow-poo-slot-authoring-datum-bindings source-datum)

(displayln "[poo-slot-authoring] phase=baseline-p95 sample-count="
           +sample-count+)
(force-output)
(def baseline-p95-us
  (benchmark-p95-elapsed-us
   +sample-count+
   (lambda () (baseline-bindings source-datum))))

(displayln "[poo-slot-authoring] phase=candidate-p95 sample-count="
           +sample-count+)
(force-output)
(def candidate-p95-us
  (benchmark-p95-elapsed-us
   +sample-count+
   (lambda ()
     (poo-flow-poo-slot-authoring-datum-bindings source-datum))))

(unless (< candidate-p95-us baseline-p95-us)
  (error "tail-passing POO slot walk did not improve deep traversal"
         baseline-p95-us candidate-p95-us))

(displayln "schema=poo-flow.poo-slot-authoring-linear.v1")
(displayln "sample-count=" +sample-count+)
(displayln "nesting-depth=" +nesting-depth+)
(displayln "binding-count=" (length candidate-value))
(displayln "baseline-p95-us=" baseline-p95-us)
(displayln "candidate-p95-us=" candidate-p95-us)
(displayln "source-order-equivalent=#t")
(displayln "accepted=#t")
