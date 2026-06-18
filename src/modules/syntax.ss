;;; -*- Gerbil -*-
;;; Boundary: user-facing module-system macro sugar.
;;; Invariant: macros expand to inspectable descriptor or catalog data only.
;;; Intent: borrow Doom-style authoring compactness without hidden runtime work.
;;; Parser policy should treat this file as syntax over the public data API.

(import (only-in :clan/poo/object .o)
        :modules/projection)

(export poo-module-option-block
        poo-module-hook-block
        poo-module-when
        defpoo-module-set)

;;; Boundary: option blocks are syntax for POO slot objects.
;;; The macro preserves keyword slots and performs no schema validation.
;;; Users may pass the result to interface schemas or module config values.
;; POOObject <- ModuleOptionKeywordSyntax...
(defrules poo-module-option-block ()
  ((_ option ...)
   (.o option ...)))

;;; Boundary: hook blocks become alist data consumed by descriptor metadata.
;;; Hook payloads stay quoted by caller syntax and are never invoked here.
;;; Each hook id owns one list of payload forms for later runtime owners.
;; ModuleHooks <- HookBlockSyntax...
(defrules poo-module-hook-block ()
  ((_ (hook-id hook-value ...) ...)
   (list (cons 'hook-id (list 'hook-value ...)) ...)))

;;; Boundary: conditional module inclusion returns a module list.
;;; The condition is evaluated where the user writes the module set.
;;; No catalog lookup, activation, or source loading occurs in this helper.
;; [PooModuleDescriptor] <- Boolean PooModuleDescriptor...
(defrules poo-module-when ()
  ((_ condition module ...)
   (if condition
     (list module ...)
     '())))

;;; Boundary: module-set syntax collects already-built module values.
;;; Clauses after the required modules block must evaluate to module lists.
;;; The generated catalog is a value catalog and remains activation-free.
;; PooModuleValueCatalogExpansion <- ModuleSetSyntax
(defrules defpoo-module-set (modules)
  ((_ binding
      (modules module ...)
      module-clause ...)
   (def binding
     (apply pooModuleCatalog
            (append (list module ...)
                    module-clause ...)))))
