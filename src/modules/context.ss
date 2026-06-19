;;; -*- Gerbil -*-
;;; Boundary: Doom-style module context predicates and phase projections.
;;; Invariant: this owner reads descriptor metadata and never loads module files.
;;; Intent: flag and phase helpers stay out of descriptor construction code.
;;; Parser policy should treat this file as the module context query owner.

(import :poo-flow/src/modules/descriptor)

(export poo-flow-module-phase-file
        poo-flow-module-hook-values
        poo-flow-module-flag-enabled?
        poo-flow-module-flags-enabled?
        poo-flow-module-active?
        poo-flow-module-depth-value
        poo-flow-module-depth-before?
        poo-flow-module-phase-order)

;; : (-> Alist Symbol Value Value)
(def (poo-flow-module-alist-ref/default alist key default-value)
  (cond
   ((null? alist) default-value)
   ((and (pair? (car alist)) (equal? (caar alist) key))
    (cdar alist))
   (else
    (poo-flow-module-alist-ref/default (cdr alist) key default-value))))

;;; Boundary: phase lookup returns metadata and never attempts file access.
;; : (-> PooModuleDescriptor Symbol [Default] MaybePhaseFile)
(def (poo-flow-module-phase-file descriptor phase . maybe-default)
  (poo-flow-module-alist-ref/default
   (poo-flow-module-phase-files descriptor)
   phase
   (if (null? maybe-default) #f (car maybe-default))))

;;; Boundary: hook lookup keeps allowed hook ids separate from runtime effects.
;; : (-> PooModuleDescriptor Symbol [HookValue])
(def (poo-flow-module-hook-values descriptor hook-id)
  (let (value
        (poo-flow-module-alist-ref/default
         (poo-flow-module-hooks descriptor)
         hook-id
         '()))
    (if (list? value) value (list value))))

;; : (-> ModuleFlag String)
(def (poo-flow-module-flag-key flag)
  (if (symbol? flag) (symbol->string flag) flag))

;; : (-> ModuleFlag Boolean)
(def (poo-flow-module-negative-flag? flag)
  (let (key (poo-flow-module-flag-key flag))
    (and (string? key)
         (> (string-length key) 0)
         (char=? (string-ref key 0) #\-))))

;; : (-> ModuleFlag ModuleFlag)
(def (poo-flow-module-positive-flag flag)
  (let (key (poo-flow-module-flag-key flag))
    (if (poo-flow-module-negative-flag? flag)
      (string->symbol
       (string-append "+" (substring key 1 (string-length key))))
      flag)))

;; : (-> ModuleFlag ModuleFlag Boolean)
(def (poo-flow-module-flag-equal? left right)
  (equal? (poo-flow-module-flag-key left)
          (poo-flow-module-flag-key right)))

;; : (-> [ModuleFlag] ModuleFlag Boolean)
(def (poo-flow-module-flag-present? flags flag)
  (cond
   ((null? flags) #f)
   ((poo-flow-module-flag-equal? (car flags) flag) #t)
   (else
    (poo-flow-module-flag-present? (cdr flags) flag))))

;;; Boundary: negative flags express absence requirements like Doom's -eglot.
;; : (-> PooModuleDescriptor ModuleFlag Boolean)
(def (poo-flow-module-flag-enabled? descriptor flag)
  (if (poo-flow-module-negative-flag? flag)
    (not (poo-flow-module-flag-present?
          (poo-flow-module-flags descriptor)
          (poo-flow-module-positive-flag flag)))
    (poo-flow-module-flag-present? (poo-flow-module-flags descriptor) flag)))

;;; Boundary: flag predicates are pure data checks over descriptor metadata.
;; : (-> PooModuleDescriptor [ModuleFlag] Boolean)
(def (poo-flow-module-flags-enabled? descriptor flags)
  (cond
   ((null? flags) #t)
   ((poo-flow-module-flag-enabled? descriptor (car flags))
    (poo-flow-module-flags-enabled? descriptor (cdr flags)))
   (else #f)))

;;; Boundary: active checks replace Doom's modulep macro with explicit data.
;; : (-> PooModuleDescriptor [ModuleFlag] Boolean)
(def (poo-flow-module-active? descriptor . required-flags)
  (and (poo-flow-module-descriptor? descriptor)
       (poo-flow-module-flags-enabled? descriptor required-flags)))

;; : (-> ModuleDepth Symbol Number)
(def (poo-flow-module-depth-part depth phase)
  (let (value
        (cond
         ((pair? depth)
          (if (eq? phase 'init) (car depth) (cdr depth)))
         ((number? depth) depth)
         (else 0)))
    (if (number? value) value 0)))

;;; Boundary: init and config order are separate but share one depth slot.
;; : (-> PooModuleDescriptor Symbol Number)
(def (poo-flow-module-depth-value descriptor phase)
  (poo-flow-module-depth-part (poo-flow-module-depth descriptor) phase))

;;; Boundary: ordering compares metadata only and preserves equal order outside.
;; : (-> PooModuleDescriptor PooModuleDescriptor Symbol Boolean)
(def (poo-flow-module-depth-before? left right phase)
  (< (poo-flow-module-depth-value left phase)
     (poo-flow-module-depth-value right phase)))

;; : (-> PooModuleDescriptor [PooModuleDescriptor] Symbol [PooModuleDescriptor])
(def (poo-flow-module-insert-by-depth module modules phase)
  (cond
   ((null? modules) (list module))
   ((poo-flow-module-depth-before? module (car modules) phase)
    (cons module modules))
   (else
    (cons (car modules)
          (poo-flow-module-insert-by-depth module (cdr modules) phase)))))

;; : (-> [PooModuleDescriptor] [PooModuleDescriptor] Symbol [PooModuleDescriptor])
(def (poo-flow-module-phase-order/add modules sorted phase)
  (if (null? modules)
    sorted
    (poo-flow-module-phase-order/add
     (cdr modules)
     (poo-flow-module-insert-by-depth (car modules) sorted phase)
     phase)))

;;; Boundary: phase order is an inspection projection and not activation order.
;; : (-> [PooModuleDescriptor] [Phase] [PooModuleDescriptor])
(def (poo-flow-module-phase-order modules . maybe-phase)
  (poo-flow-module-phase-order/add
   modules
   '()
   (if (null? maybe-phase) 'config (car maybe-phase))))
