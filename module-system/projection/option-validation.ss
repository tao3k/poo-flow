;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Pure option validation over Core Module POO values. Descriptor-specific
;;; schema discovery remains with the product adapter.

(import (only-in :core/module-system/config poo-flow-module-kind=?)
        :core/module-system/projection/option-objects)

(export poo-flow-module-find-schema
        poo-flow-module-missing-schema-receipt
        poo-flow-module-option-schema-validation-receipt
        poo-flow-module-options-validate)

(def (poo-flow-module-find-schema schemas option-id-value)
  (find (lambda (schema)
          (poo-flow-module-kind=? (poo-flow-module-option-schema-id schema)
                                  option-id-value))
        schemas))

(def (poo-flow-module-missing-schema-receipt config)
  (make-poo-flow-module-option-validation-receipt
   (poo-flow-module-option-config-id config)
   (poo-flow-module-option-config-source-module config)
   #f
   'missing-schema
   '("option schema is not declared")
   '()))

(def (poo-flow-module-option-schema-valid? schema config)
  (if (eq? (poo-flow-module-option-schema-rule schema) 'constant)
    (equal? (poo-flow-module-option-config-value config)
            (poo-flow-module-option-schema-value schema))
    #t))

(def (poo-flow-module-option-schema-validation-receipt schema config)
  (if (poo-flow-module-option-schema-valid? schema config)
    (make-poo-flow-module-option-validation-receipt
     (poo-flow-module-option-config-id config)
     (poo-flow-module-option-config-source-module config)
     #t
     'ok
     '()
     (poo-flow-module-option-schema-metadata schema))
    (make-poo-flow-module-option-validation-receipt
     (poo-flow-module-option-config-id config)
     (poo-flow-module-option-config-source-module config)
     #f
     'constant-mismatch
     '("option value does not match constant schema")
     (poo-flow-module-option-schema-metadata schema))))

;; Preserve input order while traversing only once; schema-ref is supplied by
;; the owner of the concrete Module Interface or descriptor.
(def (poo-flow-module-options-validate schema-ref configs)
  (let loop ((remaining configs) (receipts-rev '()))
    (if (null? remaining)
      (reverse receipts-rev)
      (let* ((config (car remaining))
             (schema (schema-ref (poo-flow-module-option-config-id config))))
        (loop (cdr remaining)
              (cons (if schema
                      (poo-flow-module-option-schema-validation-receipt
                       schema config)
                      (poo-flow-module-missing-schema-receipt config))
                    receipts-rev))))))
