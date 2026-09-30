;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Pure Module System queries over native slots. No source file is loaded and no
;;; product-specific descriptor is admitted here.

(import (only-in :clan/poo/object .ref))

(export poo-flow-module-phase-file
        poo-flow-module-hook-values
        poo-flow-module-flag-enabled?
        poo-flow-module-flags-enabled?
        poo-flow-module-depth-value
        poo-flow-module-depth-before?
        poo-flow-module-phase-order)

(def (module-context-alist-ref/default entries key default-value)
  (let (entry (assoc key entries))
    (if entry (cdr entry) default-value)))

(def (poo-flow-module-phase-file module phase . maybe-default)
  (module-context-alist-ref/default
   (.ref module 'phase-files)
   phase
   (if (null? maybe-default) #f (car maybe-default))))

(def (poo-flow-module-hook-values module hook-id)
  (let (value
        (module-context-alist-ref/default
         (.ref module 'hooks)
         hook-id
         '()))
    (if (list? value) value (list value))))

(def (module-context-flag-key flag)
  (if (symbol? flag) (symbol->string flag) flag))

(def (module-context-negative-flag? flag)
  (let (key (module-context-flag-key flag))
    (and (string? key)
         (> (string-length key) 0)
         (char=? (string-ref key 0) #\-))))

(def (module-context-positive-flag flag)
  (let (key (module-context-flag-key flag))
    (if (module-context-negative-flag? flag)
      (string->symbol
       (string-append "+" (substring key 1 (string-length key))))
      flag)))

(def (module-context-flag-equal? left right)
  (equal? (module-context-flag-key left)
          (module-context-flag-key right)))

(def (module-context-flag-present? flags flag)
  (cond
   ((null? flags) #f)
   ((module-context-flag-equal? (car flags) flag) #t)
   (else
    (module-context-flag-present? (cdr flags) flag))))

(def (poo-flow-module-flag-enabled? module flag)
  (if (module-context-negative-flag? flag)
    (not (module-context-flag-present?
          (.ref module 'flags)
          (module-context-positive-flag flag)))
    (module-context-flag-present? (.ref module 'flags) flag)))

(def (poo-flow-module-flags-enabled? module flags)
  (cond
   ((null? flags) #t)
   ((poo-flow-module-flag-enabled? module (car flags))
    (poo-flow-module-flags-enabled? module (cdr flags)))
   (else #f)))

(def (module-context-depth-part depth phase)
  (let (value
        (cond
         ((pair? depth)
          (if (eq? phase 'init) (car depth) (cdr depth)))
         ((number? depth) depth)
         (else 0)))
    (if (number? value) value 0)))

(def (poo-flow-module-depth-value module phase)
  (module-context-depth-part (.ref module 'depth) phase))

(def (poo-flow-module-depth-before? left right phase)
  (< (poo-flow-module-depth-value left phase)
     (poo-flow-module-depth-value right phase)))

(def (module-context-insert-by-depth module modules phase)
  (cond
   ((null? modules) (list module))
   ((poo-flow-module-depth-before? module (car modules) phase)
    (cons module modules))
   (else
    (cons (car modules)
          (module-context-insert-by-depth module (cdr modules) phase)))))

;;; Equal-depth order is stable: a new item follows existing equal items.
(def (module-context-phase-order/add modules sorted phase)
  (if (null? modules)
    sorted
    (module-context-phase-order/add
     (cdr modules)
     (module-context-insert-by-depth (car modules) sorted phase)
     phase)))

(def (poo-flow-module-phase-order modules . maybe-phase)
  (module-context-phase-order/add
   modules
   '()
   (if (null? maybe-phase) 'config (car maybe-phase))))
