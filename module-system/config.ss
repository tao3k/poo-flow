;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Native Module System interface configuration. Product identity and policy are
;;; supplied by the caller; Core owns the schema index and option vocabulary.
(import (only-in :clan/poo/object .all-slots .o .ref .slot? object?)
        (only-in :clan/poo/mop validate)
        (only-in :core/module-system/types ModuleAuthoringProfileContract))

(export poo-flow-module-kind=?
        poo-flow-module-object-ref/default
        poo-flow-module-object->alist
        poo-flow-module-interface-schema-index
        make-module-interface
        poo-flow-module-interface-id
        poo-flow-module-interface-schemas
        poo-flow-module-interface-schema-spec
        poo-flow-module-interface-authoring
        poo-flow-module-interface-metadata
        poo-flow-string-required
        poo-flow-string-constant
        poo-flow-string-default
        poo-flow-string-optional
        poo-flow-option-policy
        poo-flow-option-append
        poo-flow-option-override
        poo-flow-option-conflict)

(def (poo-flow-module-kind=? value expected)
  (cond
   ((and (string? value) (string? expected))
    (string=? value expected))
   (else (equal? value expected))))

(def (poo-flow-module-object-ref/default object slot-name default-value)
  (if (and (object? object) (.slot? object slot-name))
    (.ref object slot-name)
    default-value))

(def (poo-flow-module-object->alist/rev object slot-names rows-rev)
  (if (null? slot-names)
    rows-rev
    (poo-flow-module-object->alist/rev
     object (cdr slot-names)
     (cons (cons (car slot-names) (.ref object (car slot-names))) rows-rev))))

(def (poo-flow-module-object->alist value)
  (cond
   ((object? value)
    (reverse (poo-flow-module-object->alist/rev value (.all-slots value) '())))
   ((list? value) value)
   (else '())))

(def (poo-flow-module-interface-schema-index schema-object)
  (let (index (make-hash-table))
    (when (object? schema-object)
      (for-each
       (lambda (slot-name)
         (let (option-id
               (if (symbol? slot-name)
                 (symbol->string slot-name)
                 slot-name))
           (when (hash-key? index option-id)
             (error "duplicate normalized Module Interface schema id"
                    option-id))
           (hash-put! index option-id (.ref schema-object slot-name))))
       (.all-slots schema-object)))
    index))

(def (make-module-interface prototype interface-id-value schema-object
                            metadata-value authoring-value)
  (let (admitted-authoring
        (validate ModuleAuthoringProfileContract authoring-value))
    (.o (:: @ (list prototype))
        id: interface-id-value
        schemas: schema-object
        authoring: admitted-authoring
        metadata: metadata-value)))

(def (poo-flow-module-interface-id interface)
  (.ref interface 'id))

(def (poo-flow-module-interface-schemas interface)
  (.ref interface 'schemas))

(def (poo-flow-module-interface-schema-spec interface option-id)
  (let (index (.ref interface 'schema-index))
    (and (hash-table? index)
         (hash-get index option-id))))

(def (poo-flow-module-interface-authoring interface)
  (.ref interface 'authoring))

(def (poo-flow-module-interface-metadata interface)
  (.ref interface 'metadata))

(def (poo-flow-string-required)
  (.o type: 'String))

(def (poo-flow-string-constant constant-value)
  (.o type: 'String constant: constant-value))

(def (poo-flow-string-default default-value)
  (.o type: 'String default: default-value))

(def (poo-flow-string-optional)
  (.o type: 'String optional?: #t))

(def (poo-flow-option-policy value-type policy-rule default-value metadata-value)
  (.o type: value-type policy: policy-rule
      default: default-value metadata: metadata-value))

(def (poo-flow-option-append value-type default-value)
  (poo-flow-option-policy value-type 'append default-value '()))

(def (poo-flow-option-override value-type default-value)
  (poo-flow-option-policy value-type 'override default-value '()))

(def (poo-flow-option-conflict value-type)
  (.o type: value-type policy: 'conflict))
