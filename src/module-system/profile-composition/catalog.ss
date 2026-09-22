;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: explicit catalogs for package- and user-owned Composition values.
;;; Invariant: selection never falls back to a Module namespace or import order.

(import (only-in :clan/poo/object .o .ref object?)
        (only-in :poo-flow/src/module-system/profile-composition/identity
                 poo-flow-composition-identity-qualified-name)
        (only-in :poo-flow/src/module-system/profile-composition/value
                 poo-flow-composition?))

(export +poo-flow-composition-catalog-kind+
        poo-flow-composition-catalog
        poo-flow-composition-catalog?
        poo-flow-composition-catalog-ref
        current-poo-flow-composition-catalog
        poo-flow-current-composition-ref)

(def +poo-flow-composition-catalog-kind+
  'poo-flow.composition.catalog)

(def current-poo-flow-composition-catalog
  (make-parameter #f))

(def (poo-flow-composition-catalog? value)
  (and (object? value)
       (with-catch
        (lambda (_failure) #f)
        (lambda ()
          (eq? (.ref value 'kind)
               +poo-flow-composition-catalog-kind+)))))

(def (poo-flow-composition-catalog compositions module-names)
  (unless (list? compositions)
    (error "Composition catalog entries must be a list" compositions))
  (unless (and (list? module-names) (andmap symbol? module-names))
    (error "Composition catalog Module names must be symbols" module-names))
  (let ((index (make-hash-table))
        (selectors '()))
    (for-each
     (lambda (composition)
       (unless (poo-flow-composition? composition)
         (error "Composition catalog entry is not a Composition value"
                composition))
       (let* ((identity (.ref composition 'identity))
              (selector
               (poo-flow-composition-identity-qualified-name identity)))
         (when (memq selector module-names)
           (error "Composition selector conflicts with a Module identity"
                  selector))
         (when (hash-key? index selector)
           (error "duplicate Composition selector" selector))
         (hash-put! index selector composition)
         (set! selectors (cons selector selectors))))
     compositions)
    (let ((composition-values compositions)
          (module-name-values module-names)
          (selector-values (reverse selectors))
          (index-value index))
      (.o (kind +poo-flow-composition-catalog-kind+)
          (compositions composition-values)
          (module-names module-name-values)
          (selectors selector-values)
          (index index-value)
          (runtime-executed? #f)))))

(def (poo-flow-composition-catalog-ref catalog selector)
  (unless (poo-flow-composition-catalog? catalog)
    (error "Composition lookup requires a Composition catalog" catalog))
  (unless (symbol? selector)
    (error "Composition selector must be a symbol" selector))
  (let (composition
        (hash-get (.ref catalog 'index) selector))
    (or composition
        (error "unknown Composition selector"
               selector
               (.ref catalog 'selectors)))))

(def (poo-flow-current-composition-ref selector)
  (let (catalog (current-poo-flow-composition-catalog))
    (unless catalog
      (error "use-composition has no active Composition catalog" selector))
    (poo-flow-composition-catalog-ref catalog selector)))
