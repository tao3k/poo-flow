;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Core POO values for Module option configuration, schema, and validation.
;;; Product descriptors decide how these values are projected and presented.

(import (only-in :core/object-family/syntax defpoo-object-family))

(export poo-flow-module-option-config-prototype
        make-poo-flow-module-option-config
        poo-flow-module-option-config?
        poo-flow-module-option-config-id
        poo-flow-module-option-config-value
        poo-flow-module-option-config-source-module
        poo-flow-module-option-config-metadata
        poo-flow-module-option-schema-prototype
        make-poo-flow-module-option-schema
        poo-flow-module-option-schema?
        poo-flow-module-option-schema-id
        poo-flow-module-option-schema-source-module
        poo-flow-module-option-schema-type
        poo-flow-module-option-schema-rule
        poo-flow-module-option-schema-value
        poo-flow-module-option-schema-metadata
        poo-flow-module-option-validation-receipt-prototype
        make-poo-flow-module-option-validation-receipt
        poo-flow-module-option-validation-receipt?
        poo-flow-module-option-validation-receipt-id
        poo-flow-module-option-validation-receipt-source-module
        poo-flow-module-option-validation-receipt-valid?
        poo-flow-module-option-validation-receipt-code
        poo-flow-module-option-validation-receipt-messages
        poo-flow-module-option-validation-receipt-metadata)

(defpoo-object-family
  (prototype poo-flow-module-option-config-prototype
             option-config?
             poo-flow-module-option-config?)
  (constructor make-poo-flow-module-option-config
               (id-value id)
               (option-value value)
               (source-module-value source-module)
               (metadata-value metadata))
  (accessors
   (poo-flow-module-option-config-id id)
   (poo-flow-module-option-config-value value)
   (poo-flow-module-option-config-source-module source-module)
   (poo-flow-module-option-config-metadata metadata))
  (projections))

(defpoo-object-family
  (prototype poo-flow-module-option-schema-prototype
             option-schema?
             poo-flow-module-option-schema?)
  (constructor make-poo-flow-module-option-schema
               (id-value id)
               (source-module-value source-module)
               (type-value type)
               (rule-value rule)
               (schema-value value)
               (metadata-value metadata))
  (accessors
   (poo-flow-module-option-schema-id id)
   (poo-flow-module-option-schema-source-module source-module)
   (poo-flow-module-option-schema-type type)
   (poo-flow-module-option-schema-rule rule)
   (poo-flow-module-option-schema-value value)
   (poo-flow-module-option-schema-metadata metadata))
  (projections))

(defpoo-object-family
  (prototype poo-flow-module-option-validation-receipt-prototype
             option-validation-receipt?
             poo-flow-module-option-validation-receipt?)
  (constructor make-poo-flow-module-option-validation-receipt
               (id-value id)
               (source-module-value source-module)
               (valid-value valid?)
               (code-value code)
               (messages-value messages)
               (metadata-value metadata))
  (accessors
   (poo-flow-module-option-validation-receipt-id id)
   (poo-flow-module-option-validation-receipt-source-module source-module)
   (poo-flow-module-option-validation-receipt-valid? valid?)
   (poo-flow-module-option-validation-receipt-code code)
   (poo-flow-module-option-validation-receipt-messages messages)
   (poo-flow-module-option-validation-receipt-metadata metadata))
  (projections))
