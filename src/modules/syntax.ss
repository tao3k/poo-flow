;;; -*- Gerbil -*-
;;; Boundary: user-facing Gerbil module-system authoring forms.
;;; Invariant: macros expand to hygienic Gerbil bindings and POO values.
;;; Intent: borrow Doom-style compactness without inventing an alist/record DSL.
;;; Parser policy should treat this file as syntax over the public POO API.

(import (only-in :clan/poo/object .mix .o)
        :core/roles
        :modules/descriptor
        :modules/projection)

(export defpoo-flow-module-object-block
        poo-flow-module-option-block
        poo-flow-module-hook-block
        poo-flow-module-when
        defpoo-flow-module-set)

;;; Boundary: higher-order macro factory for hygienic POO slot blocks.
;;; The generated macro preserves caller bindings and only constructs POO values.
;;; It is not a DSL parser: keyword slots are Gerbil syntax accepted by .o.
;; : (-> Identifier Syntax)
(defrules defpoo-flow-module-object-block ()
  ((_ macro-name)
   (defrules macro-name ()
     ((_ . slots)
      (.o . slots)))))

;;; Boundary: option blocks are syntax for POO slot objects.
;;; The macro preserves keyword slots and performs no schema validation.
;;; Users may pass the result to interface schemas or module config values.
;; : (-> ModuleOptionKeywordSyntax... POOObject)
(defpoo-flow-module-object-block poo-flow-module-option-block)

;;; Boundary: hook blocks become POO objects consumed by descriptor projection.
;;; Hook payload identifiers stay quoted and are never invoked here.
;;; Each hook id owns one list of payload symbols for later runtime owners.
;; : (-> HookBlockSyntax... ModuleHooks)
(defrules poo-flow-module-hook-block ()
  ((_ (hook-id hook-value ...) ...)
   (.mix slots: (role-constant-slots
                 (list (cons 'hook-id (list 'hook-value ...)) ...))
         (.o))))

;;; Boundary: conditional module inclusion returns a module list.
;;; The condition is evaluated where the user writes the module set.
;;; No catalog lookup, activation, or source loading occurs in this helper.
;; : (-> Boolean PooModuleDescriptor... [PooModuleDescriptor])
(defrules poo-flow-module-when ()
  ((_ condition module ...)
   (if condition
     (list module ...)
     '())))

;;; Boundary: module-set syntax collects already-built POO module values.
;;; Clauses after the required modules block must evaluate to module lists.
;;; The generated catalog is a value catalog and remains activation-free.
;; : (-> ModuleSetSyntax PooModuleValueCatalogExpansion)
(defrules defpoo-flow-module-set (modules)
  ((_ binding
      (modules module ...)
      module-clause ...)
   (def binding
     (apply pooFlowModuleCatalog
            (append (list module ...)
                    module-clause ...)))))
