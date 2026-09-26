;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Pure POO values governed by existing CLOS class and effective-slot metadata.
;;; These are snapshots, not mutable CLOS lifecycle instances.
(import (only-in :clan/poo/object .o .ref .slot? object? compute-precedence-list!)
        (only-in :std/list/list every)
        (only-in :core/poo-clos/classes
                 poo-clos-class poo-clos-direct-slot-definition
                 poo-clos-class-effective-slots))
(export poo-clos-class poo-clos-direct-slot-definition
        poo-flow-model-prototype poo-flow-model-validation-failure
        poo-flow-model? poo-flow-check-model)

(def (poo-flow-model-prototype class-value)
  (.ref class-value 'instance-prototype))

(def (poo-flow-model-diagnostic-value value)
  (cond
   ((or (symbol? value) (keyword? value) (string? value)
        (number? value) (boolean? value) (char? value)) value)
   ((object? value) 'poo-object)
   ((pair? value) 'pair)
   ((vector? value) 'vector)
   ((procedure? value) 'procedure)
   (else 'opaque-value)))

;;; Return the first bounded validation diagnostic, or #f when the candidate is
;;; valid.  The result stays source-oriented so an atomic test reports the
;;; class/slot boundary without forcing unrelated lazy slots.
(def (poo-flow-model-validation-failure class-value candidate)
  (cond
   ((not (object? candidate)) '(candidate-not-poo-object))
   ((not (memq (poo-flow-model-prototype class-value)
               (compute-precedence-list! candidate)))
    '(prototype-ancestry-mismatch))
   (else
    (let loop ((slots (poo-clos-class-effective-slots class-value)))
      (if (null? slots)
        #f
        (let* ((slot (car slots))
               (name (.ref slot 'identity)))
          (cond
           ((not (eq? (.ref slot 'allocation) 'instance))
            (list 'non-instance-slot name))
           ((not (.slot? candidate name))
            (list 'missing-slot name))
           ((let (value (.ref candidate name))
              (if (every (lambda (predicate) (predicate value))
                         (.ref slot 'type-predicates))
                #f
                (list 'type-predicate-failed name
                      (poo-flow-model-diagnostic-value value))))
            => values)
           (else (loop (cdr slots))))))))))

(def (poo-flow-model? class-value candidate)
  (not (poo-flow-model-validation-failure class-value candidate)))

(def (poo-flow-check-model class-value candidate)
  (let (failure (poo-flow-model-validation-failure class-value candidate))
    (when failure
      (error "invalid POO model" (.ref class-value 'identity) failure))
    candidate))
