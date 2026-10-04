;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Source identity is inert POO metadata. Discovery and activation belong to
;;; the consuming product, not to this Core owner.

(import (only-in :clan/poo/object .o)
        (only-in :core/object-family/syntax defpoo-object-family))

(export poo-flow-module-source-ref-prototype
        make-poo-flow-module-source-ref
        poo-flow-module-source-ref?
        poo-flow-module-source-ref-kind
        poo-flow-module-source-ref-value
        poo-flow-module-source-ref-metadata
        make-poo-flow-module-local-source
        make-poo-flow-module-package-source
        make-poo-flow-module-standard-library-source
        make-poo-flow-module-registry-source
        make-poo-flow-module-generated-source
        poo-flow-module-source-ref=?
        poo-flow-module-source-ref->alist)

(defpoo-object-family
  (prototype poo-flow-module-source-ref-prototype
             module-source-ref?
             poo-flow-module-source-ref?)
  (constructor make-poo-flow-module-source-ref
               (kind-value kind)
               (value-value value)
               (metadata-value metadata))
  (accessors
   (poo-flow-module-source-ref-kind kind)
   (poo-flow-module-source-ref-value value)
   (poo-flow-module-source-ref-metadata metadata))
  (projections))

(def (make-poo-flow-module-local-source path)
  (make-poo-flow-module-source-ref 'local path '()))

(def (make-poo-flow-module-package-source package-name)
  (make-poo-flow-module-source-ref 'package package-name '()))

(def (make-poo-flow-module-standard-library-source module-name)
  (make-poo-flow-module-source-ref 'standard-library module-name
                                   (list (cons 'library 'standard))))

(def (make-poo-flow-module-registry-source registry-name)
  (make-poo-flow-module-source-ref 'registry registry-name '()))

(def (make-poo-flow-module-generated-source module-name)
  (make-poo-flow-module-source-ref 'generated module-name '()))

;;; Metadata records provenance, but resolver identity is kind plus value.
(def (poo-flow-module-source-ref=? left right)
  (and (eq? (poo-flow-module-source-ref-kind left)
            (poo-flow-module-source-ref-kind right))
       (equal? (poo-flow-module-source-ref-value left)
               (poo-flow-module-source-ref-value right))))

;;; Alists are produced only at an inspection boundary.
(def (poo-flow-module-source-ref->alist source-ref)
  (list (cons 'kind (poo-flow-module-source-ref-kind source-ref))
        (cons 'value (poo-flow-module-source-ref-value source-ref))
        (cons 'metadata (poo-flow-module-source-ref-metadata source-ref))))
