;;; -*- Gerbil -*-
;;; Boundary: Doom-style module context predicates and phase projections.
;;; Invariant: this owner reads descriptor metadata and never loads module files.
;;; Intent: flag and phase helpers stay out of descriptor construction code.
;;; Parser policy should treat this file as the module context query owner.

(import :modules/descriptor)

(export poo-module-phase-file
        poo-module-hook-values
        poo-module-flag-enabled?
        poo-module-flags-enabled?
        poo-module-active?
        poo-module-depth-value
        poo-module-depth-before?
        poo-module-phase-order)

;; Value <- Alist Symbol Value
(def (poo-module-alist-ref/default alist key default-value)
  (cond
   ((null? alist) default-value)
   ((and (pair? (car alist)) (equal? (caar alist) key))
    (cdar alist))
   (else
    (poo-module-alist-ref/default (cdr alist) key default-value))))

;;; Boundary: phase lookup returns metadata and never attempts file access.
;; MaybePhaseFile <- PooModuleDescriptor Symbol [Default]
(def (poo-module-phase-file descriptor phase . maybe-default)
  (poo-module-alist-ref/default
   (poo-module-phase-files descriptor)
   phase
   (if (null? maybe-default) #f (car maybe-default))))

;;; Boundary: hook lookup keeps allowed hook ids separate from runtime effects.
;; [HookValue] <- PooModuleDescriptor Symbol
(def (poo-module-hook-values descriptor hook-id)
  (let (value
        (poo-module-alist-ref/default
         (poo-module-hooks descriptor)
         hook-id
         '()))
    (if (list? value) value (list value))))

;; String <- ModuleFlag
(def (poo-module-flag-key flag)
  (if (symbol? flag) (symbol->string flag) flag))

;; Boolean <- ModuleFlag
(def (poo-module-negative-flag? flag)
  (let (key (poo-module-flag-key flag))
    (and (string? key)
         (> (string-length key) 0)
         (char=? (string-ref key 0) #\-))))

;; ModuleFlag <- ModuleFlag
(def (poo-module-positive-flag flag)
  (let (key (poo-module-flag-key flag))
    (if (poo-module-negative-flag? flag)
      (string->symbol
       (string-append "+" (substring key 1 (string-length key))))
      flag)))

;; Boolean <- ModuleFlag ModuleFlag
(def (poo-module-flag-equal? left right)
  (equal? (poo-module-flag-key left)
          (poo-module-flag-key right)))

;; Boolean <- [ModuleFlag] ModuleFlag
(def (poo-module-flag-present? flags flag)
  (cond
   ((null? flags) #f)
   ((poo-module-flag-equal? (car flags) flag) #t)
   (else
    (poo-module-flag-present? (cdr flags) flag))))

;;; Boundary: negative flags express absence requirements like Doom's -eglot.
;; Boolean <- PooModuleDescriptor ModuleFlag
(def (poo-module-flag-enabled? descriptor flag)
  (if (poo-module-negative-flag? flag)
    (not (poo-module-flag-present?
          (poo-module-flags descriptor)
          (poo-module-positive-flag flag)))
    (poo-module-flag-present? (poo-module-flags descriptor) flag)))

;;; Boundary: flag predicates are pure data checks over descriptor metadata.
;; Boolean <- PooModuleDescriptor [ModuleFlag]
(def (poo-module-flags-enabled? descriptor flags)
  (cond
   ((null? flags) #t)
   ((poo-module-flag-enabled? descriptor (car flags))
    (poo-module-flags-enabled? descriptor (cdr flags)))
   (else #f)))

;;; Boundary: active checks replace Doom's modulep macro with explicit data.
;; Boolean <- PooModuleDescriptor [ModuleFlag]
(def (poo-module-active? descriptor . required-flags)
  (and (poo-module-descriptor? descriptor)
       (poo-module-flags-enabled? descriptor required-flags)))

;; Number <- ModuleDepth Symbol
(def (poo-module-depth-part depth phase)
  (let (value
        (cond
         ((pair? depth)
          (if (eq? phase 'init) (car depth) (cdr depth)))
         ((number? depth) depth)
         (else 0)))
    (if (number? value) value 0)))

;;; Boundary: init and config order are separate but share one depth slot.
;; Number <- PooModuleDescriptor Symbol
(def (poo-module-depth-value descriptor phase)
  (poo-module-depth-part (poo-module-depth descriptor) phase))

;;; Boundary: ordering compares metadata only and preserves equal order outside.
;; Boolean <- PooModuleDescriptor PooModuleDescriptor Symbol
(def (poo-module-depth-before? left right phase)
  (< (poo-module-depth-value left phase)
     (poo-module-depth-value right phase)))

;; [PooModuleDescriptor] <- PooModuleDescriptor [PooModuleDescriptor] Symbol
(def (poo-module-insert-by-depth module modules phase)
  (cond
   ((null? modules) (list module))
   ((poo-module-depth-before? module (car modules) phase)
    (cons module modules))
   (else
    (cons (car modules)
          (poo-module-insert-by-depth module (cdr modules) phase)))))

;; [PooModuleDescriptor] <- [PooModuleDescriptor] [PooModuleDescriptor] Symbol
(def (poo-module-phase-order/add modules sorted phase)
  (if (null? modules)
    sorted
    (poo-module-phase-order/add
     (cdr modules)
     (poo-module-insert-by-depth (car modules) sorted phase)
     phase)))

;;; Boundary: phase order is an inspection projection and not activation order.
;; [PooModuleDescriptor] <- [PooModuleDescriptor] [Phase]
(def (poo-module-phase-order modules . maybe-phase)
  (poo-module-phase-order/add
   modules
   '()
   (if (null? maybe-phase) 'config (car maybe-phase))))
