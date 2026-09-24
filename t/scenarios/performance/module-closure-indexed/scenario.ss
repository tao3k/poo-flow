;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A/B witness for the former list-indexed module closure versus the shared
;;; native hash admission index. The baseline is evidence only; it is not an
;;; alternate runtime or a public compatibility path.

(import (only-in :asp-gerbil-scheme/benchmark-api benchmark-p95-elapsed-us)
        (only-in :poo-flow/src/module-system/descriptor/interface
                 make-empty-poo-flow-module-descriptor
                 poo-flow-module-name
                 poo-flow-module-imports
                 poo-flow-module-import-configs
                 poo-flow-module-closure
                 poo-flow-module-names))

(def +sample-count+ 20)
(def +module-count+ 1000)

(def modules
  (let loop ((index 0) (values-rev '()))
    (if (= index +module-count+)
      (reverse values-rev)
      (loop (+ index 1)
            (cons
             (make-empty-poo-flow-module-descriptor
              (string->symbol (string-append "module-" (number->string index)))
              '()
              '())
             values-rev)))))

(def (baseline-member-name? value names)
  (cond
   ((null? names) #f)
   ((equal? value (car names)) #t)
   (else (baseline-member-name? value (cdr names)))))

;;; This intentionally reproduces the former list-indexed reconstruction.
(def (baseline-closure/add pending seen-names)
  (cond
   ((null? pending) '())
   ((baseline-member-name? (poo-flow-module-name (car pending)) seen-names)
    (baseline-closure/add (cdr pending) seen-names))
   (else
    (let* ((module (car pending))
           (next-seen (cons (poo-flow-module-name module) seen-names))
           (inline-modules
            (poo-flow-module-import-configs (poo-flow-module-imports module))))
      (cons module
            (append (baseline-closure/add inline-modules next-seen)
                    (baseline-closure/add (cdr pending) next-seen)))))))

(def (baseline-closure values)
  (baseline-closure/add values '()))

(def baseline-value (baseline-closure modules))
(def candidate-value (poo-flow-module-closure modules))

(unless (equal? (poo-flow-module-names baseline-value)
                (poo-flow-module-names candidate-value))
  (error "indexed module closure changed distinct-module order"))

(displayln "[module-closure-indexed] phase=warmup")
(force-output)
(baseline-closure modules)
(poo-flow-module-closure modules)

(displayln "[module-closure-indexed] phase=baseline-p95 sample-count="
           +sample-count+)
(force-output)
(def baseline-p95-us
  (benchmark-p95-elapsed-us
   +sample-count+
   (lambda () (baseline-closure modules))))

(displayln "[module-closure-indexed] phase=candidate-p95 sample-count="
           +sample-count+)
(force-output)
(def candidate-p95-us
  (benchmark-p95-elapsed-us
   +sample-count+
   (lambda () (poo-flow-module-closure modules))))

(unless (< candidate-p95-us baseline-p95-us)
  (error "shared module closure index did not improve broad traversal"
         baseline-p95-us candidate-p95-us))

(displayln "schema=poo-flow.module-closure-indexed.v1")
(displayln "sample-count=" +sample-count+)
(displayln "module-count=" +module-count+)
(displayln "baseline-p95-us=" baseline-p95-us)
(displayln "candidate-p95-us=" candidate-p95-us)
(displayln "module-order-equivalent=#t")
(displayln "accepted=#t")
