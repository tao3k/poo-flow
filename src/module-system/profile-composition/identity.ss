;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: POO-native identities for public Composition values.
;;; Invariant: Composition and Module namespaces are disjoint before lowering.

(import (only-in :clan/poo/object .o .ref object?))

(export +poo-flow-composition-identity-kind+
        poo-flow-official-composition-identity
        poo-flow-user-composition-identity
        poo-flow-composition-identity?
        poo-flow-composition-identity-namespace
        poo-flow-composition-identity-local-name
        poo-flow-composition-identity-qualified-name
        poo-flow-composition-identity-official?)

(def +poo-flow-composition-identity-kind+
  'poo-flow.composition.identity)

(def (poo-flow-composition-non-empty-symbol? value)
  (and (symbol? value)
       (> (string-length (symbol->string value)) 0)))

(def (poo-flow-composition-require-name value label)
  (unless (poo-flow-composition-non-empty-symbol? value)
    (error label "must be a non-empty symbol" value)))

(def (poo-flow-composition-qualified-name namespace local-name)
  (string->symbol
   (string-append (symbol->string namespace)
                  "/"
                  (symbol->string local-name))))

(def (poo-flow-composition-name-member? name names)
  (let loop ((rest names))
    (and (pair? rest)
         (or (eq? name (car rest))
             (loop (cdr rest))))))

(def (poo-flow-make-composition-identity namespace local-name official?)
  ;; POO slot bodies are evaluated in object scope. Capture constructor
  ;; arguments under distinct names so a slot never resolves itself while the
  ;; object is being initialized.
  (let ((namespace-value namespace)
        (local-name-value local-name)
        (official-value official?))
    (.o (kind +poo-flow-composition-identity-kind+)
        (namespace namespace-value)
        (local-name local-name-value)
        (qualified-name
         (if official-value
           local-name-value
           (poo-flow-composition-qualified-name
            namespace-value local-name-value)))
        (official? official-value)
        (runtime-executed #f))))

;;; Official package Compositions own an unqualified public selector. Package
;;; admission is responsible for ensuring that official names are unique.
(def (poo-flow-official-composition-identity name)
  (poo-flow-composition-require-name name
                                     "official Composition name")
  (poo-flow-make-composition-identity name name #t))

;;; User Compositions are always qualified. Their namespace cannot shadow an
;;; admitted Module namespace or any package-reserved Composition selector.
(def (poo-flow-user-composition-identity
      namespace local-name module-names reserved-composition-names)
  (poo-flow-composition-require-name namespace
                                     "user Composition namespace")
  (poo-flow-composition-require-name local-name
                                     "user Composition local name")
  (when (poo-flow-composition-name-member?
         namespace reserved-composition-names)
    (error "user Composition namespace is reserved" namespace))
  (when (poo-flow-composition-name-member? namespace module-names)
    (error "Composition namespace conflicts with a Module namespace"
           namespace))
  (poo-flow-make-composition-identity namespace local-name #f))

(def (poo-flow-composition-identity? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            +poo-flow-composition-identity-kind+)))

(def (poo-flow-composition-identity-namespace identity)
  (.ref identity 'namespace))

(def (poo-flow-composition-identity-local-name identity)
  (.ref identity 'local-name))

(def (poo-flow-composition-identity-qualified-name identity)
  (.ref identity 'qualified-name))

(def (poo-flow-composition-identity-official? identity)
  (.ref identity 'official?))
