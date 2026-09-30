;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Source-neutral, ordered POO collection composition. Filesystem discovery,
;;; source admission, and module role policy belong to the consuming product.

(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/list/list any every))

(export poo-flow-module-source-collection-prototype
        poo-flow-module-source-collection?
        poo-flow-module-source-collection-identity
        poo-flow-module-source-collection-locate
        poo-flow-module-load-path-prototype
        make-poo-flow-module-load-path
        extend-poo-flow-module-load-path
        poo-flow-module-load-path?
        poo-flow-module-load-path-identity
        poo-flow-module-load-path-collections
        poo-flow-module-load-path-locate)

(def poo-flow-module-source-collection-prototype
  (.o (module-source-collection? #t)))

(def (poo-flow-module-source-collection? value)
  (and (object? value)
       (.slot? value 'module-source-collection?)
       (.ref value 'module-source-collection?)
       (.slot? value 'identity)
       (symbol? (.ref value 'identity))
       (.slot? value 'locate)
       (procedure? (.ref value 'locate))))

(def (poo-flow-module-source-collection-identity collection)
  (.ref collection 'identity))

(def (poo-flow-module-source-collection-locate collection module-key)
  ((.ref collection 'locate) collection module-key '(interface)))

(def poo-flow-module-load-path-prototype
  (.o (module-load-path? #t)))

(def (poo-flow-module-load-path? value)
  (and (object? value)
       (.slot? value 'module-load-path?)
       (.ref value 'module-load-path?)
       (.slot? value 'identity)
       (symbol? (.ref value 'identity))
       (.slot? value 'collections)
       (list? (.ref value 'collections))
       (every poo-flow-module-source-collection?
              (.ref value 'collections))))

(def (poo-flow-module-load-path-identity load-path)
  (.ref load-path 'identity))

(def (poo-flow-module-load-path-collections load-path)
  (.ref load-path 'collections))

(def (poo-flow-module-load-path-valid! load-path)
  (unless (poo-flow-module-load-path? load-path)
    (error "invalid POO Flow module load path" load-path))
  (let ((seen (make-hash-table))
        (identities
         (map poo-flow-module-source-collection-identity
              (poo-flow-module-load-path-collections load-path))))
    (for-each
     (lambda (identity)
       (when (hash-key? seen identity)
         (error "duplicate POO Flow module source collection" identities))
       (hash-put! seen identity #t))
     identities))
  load-path)

(def (make-poo-flow-module-load-path identity-value collections-value)
  (poo-flow-module-load-path-valid!
   (.o (:: @ poo-flow-module-load-path-prototype)
       (identity identity-value)
       (collections collections-value))))

;;; Appended collections have lower priority. No mutable global load path.
(def (extend-poo-flow-module-load-path base identity-value collections-value)
  (unless (poo-flow-module-load-path? base)
    (error "module load path extension requires a valid base" base))
  (poo-flow-module-load-path-valid!
   (.o (:: @ base)
       (identity identity-value)
       (collections
        (append (poo-flow-module-load-path-collections base)
                collections-value)))))

(def (poo-flow-module-load-path-locate load-path module-key)
  (or (any (lambda (collection)
             (let (source-refs
                   (poo-flow-module-source-collection-locate
                    collection module-key))
               (and (pair? source-refs) source-refs)))
           (poo-flow-module-load-path-collections load-path))
      '()))
