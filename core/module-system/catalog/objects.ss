;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; An immutable ordered Module Catalog of constructed POO Modules. Lookup
;;; observes SourceRef identity only; it never loads or activates a source.

(import (only-in :clan/poo/object .ref)
        (only-in :core/object-family/syntax defpoo-object-family)
        :core/module-system/source/objects)

(export poo-flow-module-catalog-entry-prototype
        make-poo-flow-module-catalog-entry
        poo-flow-module-catalog-entry?
        poo-flow-module-catalog-entry-source
        poo-flow-module-catalog-entry-module
        poo-flow-module-catalog-entry->alist
        poo-flow-module-catalog-prototype
        make-poo-flow-module-catalog
        poo-flow-module-catalog?
        poo-flow-module-catalog-name
        poo-flow-module-catalog-entries
        poo-flow-module-catalog-source-refs
        poo-flow-module-catalog-modules
        poo-flow-module-catalog-add
        poo-flow-module-catalog-find-source
        resolve-poo-flow-module-source/default
        poo-flow-module-catalog->alist)

(defpoo-object-family
  (prototype poo-flow-module-catalog-entry-prototype
             catalog-entry?
             poo-flow-module-catalog-entry?)
  (constructor make-poo-flow-module-catalog-entry
               (source-value source)
               (module-value module))
  (accessors
   (poo-flow-module-catalog-entry-source source)
   (poo-flow-module-catalog-entry-module module))
  (projections))

(def (poo-flow-module-catalog-entry->alist entry)
  (list
   (cons 'source
         (poo-flow-module-source-ref->alist
          (poo-flow-module-catalog-entry-source entry)))
   (cons 'module
         (.ref (poo-flow-module-catalog-entry-module entry) 'name))))

(defpoo-object-family
  (prototype poo-flow-module-catalog-prototype
             catalog?
             poo-flow-module-catalog?)
  (constructor make-poo-flow-module-catalog
               (name-value name)
               (entries-value entries))
  (accessors
   (poo-flow-module-catalog-name name)
   (poo-flow-module-catalog-entries entries))
  (projections))

(def (poo-flow-module-catalog-source-refs catalog)
  (map poo-flow-module-catalog-entry-source
       (poo-flow-module-catalog-entries catalog)))

(def (poo-flow-module-catalog-modules catalog)
  (map poo-flow-module-catalog-entry-module
       (poo-flow-module-catalog-entries catalog)))

(def (poo-flow-module-catalog-add catalog entry)
  (make-poo-flow-module-catalog
   (poo-flow-module-catalog-name catalog)
   (append (poo-flow-module-catalog-entries catalog)
           (list entry))))

;;; First matching SourceRef wins; metadata does not affect identity.
(def (module-catalog-find-source-in entries source-ref)
  (cond
   ((null? entries) #f)
   ((poo-flow-module-source-ref=?
     (poo-flow-module-catalog-entry-source (car entries))
     source-ref)
    (car entries))
   (else
    (module-catalog-find-source-in (cdr entries) source-ref))))

(def (poo-flow-module-catalog-find-source catalog source-ref)
  (module-catalog-find-source-in
   (poo-flow-module-catalog-entries catalog)
   source-ref))

(def (resolve-poo-flow-module-source/default catalog source-ref default)
  (let (entry (poo-flow-module-catalog-find-source catalog source-ref))
    (if entry
      (poo-flow-module-catalog-entry-module entry)
      default)))

(def (poo-flow-module-catalog->alist catalog)
  (list
   (cons 'name (poo-flow-module-catalog-name catalog))
   (cons 'entries
         (map poo-flow-module-catalog-entry->alist
              (poo-flow-module-catalog-entries catalog)))))
