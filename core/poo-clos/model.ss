;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: validate ordinary POO values against CLOS class slot metadata.
;;; These are pure model values, not mutable CLOS lifecycle instances.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :std/list/list every)
        (only-in :core/poo-clos/types clos-instance?)
        (only-in :core/poo-clos/classes poo-clos-class-effective-slots))
(export poo-clos-model-prototype poo-clos-model-validation-failure
        poo-clos-model? poo-clos-check-model)

(def (poo-clos-model-prototype class-value)
  (.ref class-value 'instance-prototype))

(def (poo-clos-model-diagnostic-value value)
  (cond
   ((or (symbol? value) (keyword? value) (string? value)
        (number? value) (boolean? value) (char? value)) value)
   ((object? value) 'poo-object)
   ((pair? value) 'pair)
   ((vector? value) 'vector)
   ((procedure? value) 'procedure)
   (else 'opaque-value)))

;;; Return the first bounded diagnostic without forcing unrelated lazy slots.
(def (poo-clos-model-validation-failure class-value candidate)
  (cond
   ((not (object? candidate)) '(candidate-not-poo-object))
   ((not (clos-instance? (poo-clos-model-prototype class-value) candidate))
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
                      (poo-clos-model-diagnostic-value value))))
            => values)
           (else (loop (cdr slots))))))))))

(def (poo-clos-model? class-value candidate)
  (not (poo-clos-model-validation-failure class-value candidate)))

(def (poo-clos-check-model class-value candidate)
  (let (failure (poo-clos-model-validation-failure class-value candidate))
    (when failure
      (error "invalid POO model" (.ref class-value 'identity) failure))
    candidate))
