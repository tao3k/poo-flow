;;; -*- Gerbil -*-
;;; Utilities: hygienic contract declaration macros.

(import (only-in "./contracts.ss"
                 poo-flow-slot-contract-record
                 poo-flow-object-type-contract-record))

(export defcontract-family)

;; defcontract-family
;;   : (-> ContractFamilyDeclaration ContractFamilyDefinitions)
;;   | requires m%
;;       Each generated binding name is supplied explicitly by the caller.
;;       The macro does not synthesize identifiers from strings or symbols.
;;     %
;;   | warning m%
;;       This macro is a compile-time convenience only. Runtime safety still
;;       comes from the generated slot contracts and constructor gates.
;;     %
;;   | rationale m%
;;       Explicit names keep expanded Scheme inspectable by ASP, agents, and
;;       humans while removing repeated contract boilerplate from module files.
;;     %
;;   | doc m%
;;       Declare a group of slot contracts and one object type contract. The
;;       caller supplies binding names explicitly so generated Scheme remains
;;       inspectable and stable for agent repair.
;;
;;       # Examples
;;       ```scheme
;;       (defcontract-family +receipt-slots+ +receipt-contract+
;;         'receipt 'owner 'Receipt '()
;;         ((+schema-slot+ 'receipt/schema 'schema 'String 'string? string? #t '())))
;;       ;; => contract-family-bindings
;;       ```
;;     %
(defrules defcontract-family ()
  ((_ slot-list-name object-contract-name object-key owner object-kind object-metadata
      ((slot-contract-name slot-key slot value-kind predicate-key predicate required? slot-metadata) ...))
   (begin
     (def slot-contract-name
       (poo-flow-slot-contract-record
        slot-key
        object-kind
        slot
        value-kind
        predicate-key
        predicate
        required?
        slot-metadata))
     ...
     (def slot-list-name
       (list slot-contract-name ...))
     (def object-contract-name
       (poo-flow-object-type-contract-record
        object-key
        owner
        object-kind
        slot-list-name
        object-metadata)))))
