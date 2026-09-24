;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A/B witness for the retired per-import name-list scan versus the production
;;; shared native hash index. The baseline is evidence only; it is not an
;;; alternate runtime or public compatibility path.

(import (only-in :asp-gerbil-scheme/benchmark-api benchmark-p95-elapsed-us)
        (only-in :poo-flow/src/module-system/descriptor/interface
                 make-empty-poo-flow-module-descriptor
                 poo-flow-module-name
                 poo-flow-module-imports
                 poo-flow-module-import-profile
                 poo-flow-module-missing-imports))

(def +sample-count+ 20)
(def +module-count+ 1000)
(def +shared-import+ 'module-999)

(def modules
  (let loop ((index 0) (values-rev '()))
    (if (= index +module-count+)
      (reverse values-rev)
      (loop (+ index 1)
            (cons
             (make-empty-poo-flow-module-descriptor
              (string->symbol (string-append "module-" (number->string index)))
              (if (= index (- +module-count+ 1))
                '()
                (list +shared-import+))
              '())
             values-rev)))))

(def available-names (map poo-flow-module-name modules))

(def (baseline-member-name? value names)
  (cond
   ((null? names) #f)
   ((equal? value (car names)) #t)
   (else (baseline-member-name? value (cdr names)))))

(def (baseline-named-import? import-value)
  (let (profile (poo-flow-module-import-profile import-value))
    (or (symbol? profile) (string? profile))))

(def (baseline-missing-for module-name imports)
  (cond
   ((null? imports) '())
   ((not (baseline-named-import? (car imports)))
    (baseline-missing-for module-name (cdr imports)))
   ((baseline-member-name?
     (poo-flow-module-import-profile (car imports))
     available-names)
    (baseline-missing-for module-name (cdr imports)))
   (else
    (cons (list (cons 'module module-name)
                (cons 'import
                      (poo-flow-module-import-profile (car imports))))
          (baseline-missing-for module-name (cdr imports))))))

(def (baseline-missing modules)
  (foldr append
         '()
         (map (lambda (module)
                (baseline-missing-for
                 (poo-flow-module-name module)
                 (poo-flow-module-imports module)))
              modules)))

(def baseline-value (baseline-missing modules))
(def candidate-value (poo-flow-module-missing-imports modules))

(unless (equal? baseline-value candidate-value)
  (error "indexed import validation changed diagnostic semantics"
         baseline-value candidate-value))

(displayln "[module-import-validation-indexed] phase=warmup")
(force-output)
(baseline-missing modules)
(poo-flow-module-missing-imports modules)

(displayln "[module-import-validation-indexed] phase=baseline-p95 sample-count="
           +sample-count+)
(force-output)
(def baseline-p95-us
  (benchmark-p95-elapsed-us
   +sample-count+
   (lambda () (baseline-missing modules))))

(displayln "[module-import-validation-indexed] phase=candidate-p95 sample-count="
           +sample-count+)
(force-output)
(def candidate-p95-us
  (benchmark-p95-elapsed-us
   +sample-count+
   (lambda () (poo-flow-module-missing-imports modules))))

(unless (< candidate-p95-us baseline-p95-us)
  (error "shared import name index did not improve dense validation"
         baseline-p95-us candidate-p95-us))

(displayln "schema=poo-flow.module-import-validation-indexed.v1")
(displayln "sample-count=" +sample-count+)
(displayln "module-count=" +module-count+)
(displayln "baseline-p95-us=" baseline-p95-us)
(displayln "candidate-p95-us=" candidate-p95-us)
(displayln "diagnostics-equivalent=#t")
(displayln "accepted=#t")
