;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A/B witness for repeated projected-schema scans versus the derived index
;;; owned by the public POO Module Interface. The baseline is evidence only;
;;; it is not an alternate runtime or public compatibility path.

(import (only-in :asp-gerbil-scheme/benchmark-api benchmark-p95-elapsed-us)
        (only-in :clan/poo/object .o .ref object<-alist)
        (only-in :poo-flow/src/module-system/interface
                 poo-flow-module-interface
                 poo-flow-module-interface-schema-spec)
        (only-in :poo-flow/src/module-system/descriptor/interface
                 poo-flow-modules)
        (only-in :poo-flow/src/module-system/projection/options
                 poo-flow-module-option-schemas
                 poo-flow-module-option-schema-id
                 poo-flow-module-option-schema-value
                 poo-flow-module-find-schema))

(def +sample-count+ 20)
(def +schema-count+ 1000)

(def schema-rows
  (let loop ((index 0) (rows-rev '()))
    (if (= index +schema-count+)
      (reverse rows-rev)
      (loop (+ index 1)
            (cons
             (cons
              (string->symbol
               (string-append "option-" (number->string index)))
              (.o type: 'Integer constant: index))
             rows-rev)))))

(def interface
  (poo-flow-module-interface
   "IndexedSchemaProfile"
   (object<-alist schema-rows)
   '((owner . "poo-flow"))))

(def module
  (poo-flow-modules interface (.o id: 'indexed-schema config: (.o))))

(def schemas (poo-flow-module-option-schemas module))
(def option-ids (map poo-flow-module-option-schema-id schemas))

(def (baseline-values)
  (map (lambda (option-id)
         (poo-flow-module-option-schema-value
          (poo-flow-module-find-schema schemas option-id)))
       option-ids))

(def (candidate-values)
  (map (lambda (option-id)
         (.ref (poo-flow-module-interface-schema-spec interface option-id)
               'constant))
       option-ids))

(def baseline-value (baseline-values))
(def candidate-value (candidate-values))

(unless (equal? baseline-value candidate-value)
  (error "Interface schema index changed lookup semantics"))

(displayln "[module-interface-schema-indexed] phase=warmup")
(force-output)
(baseline-values)
(candidate-values)

(displayln "[module-interface-schema-indexed] phase=baseline-p95 sample-count="
           +sample-count+)
(force-output)
(def baseline-p95-us
  (benchmark-p95-elapsed-us +sample-count+ baseline-values))

(displayln "[module-interface-schema-indexed] phase=candidate-p95 sample-count="
           +sample-count+)
(force-output)
(def candidate-p95-us
  (benchmark-p95-elapsed-us +sample-count+ candidate-values))

(unless (< candidate-p95-us baseline-p95-us)
  (error "Interface schema index did not improve repeated lookup"
         baseline-p95-us candidate-p95-us))

(displayln "schema=poo-flow.module-interface-schema-indexed.v1")
(displayln "sample-count=" +sample-count+)
(displayln "schema-count=" +schema-count+)
(displayln "baseline-p95-us=" baseline-p95-us)
(displayln "candidate-p95-us=" candidate-p95-us)
(displayln "lookup-values-equivalent=#t")
(displayln "accepted=#t")
