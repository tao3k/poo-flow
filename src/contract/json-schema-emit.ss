;;; -*- Gerbil -*-
;;; Contract: emit POO Flow object contracts from normalized JSON Schema IR.
;;; Optimization boundary: this module builds predicate closures once while
;;; emitting contracts; value validation reuses those closures without walking
;;; the normalized schema again.

(import (only-in :clan/poo/object
                 .alist
                 .ref
                 .slot?
                 object?)
        (only-in :std/pregexp
                 pregexp
                 pregexp-match)
        (only-in "../module-system/contract-schema.ss"
                 poo-flow-contract-slot
                 poo-flow-contract-value-type
                 poo-flow-native-contract)
        (only-in "../utilities/functional.ss"
                 poo-flow-all?
                 poo-flow-find
                 poo-flow-predicate-and
                 poo-flow-predicate-or
                 poo-flow-predicate-exactly-one)
        (only-in "./json-schema-constraints.ss"
                 poo-flow-json-schema-apply-node-constraints)
        (only-in "./functional.ss"
                 poo-flow-contract-key->string
                 poo-flow-contract-all?
                 poo-flow-contract-json-object?
                 poo-flow-contract-member?
                 poo-flow-contract-project-list
                 poo-flow-contract-filter-map)
        (only-in "./json-schema-ir.ss"
                 poo-flow-json-schema-node?
                 poo-flow-json-schema-node-kind
                 poo-flow-json-schema-node-value
                 poo-flow-json-schema-node-metadata
                 poo-flow-json-schema-node->alist
                 poo-flow-json-schema-property-name
                 poo-flow-json-schema-property-schema
                 poo-flow-json-schema-property-required?
                 poo-flow-json-schema-property-doc
                 poo-flow-json-schema-property-metadata
                 poo-flow-json-schema-property->alist
                 poo-flow-json-schema-object?
                 poo-flow-json-schema-object-properties
                 poo-flow-json-schema-object-additional-properties
                 poo-flow-json-schema-object-pattern-properties
                 poo-flow-json-schema-object-metadata
                 poo-flow-json-schema-pattern-property?
                 poo-flow-json-schema-pattern-property->alist))

(import (only-in :std/srfi/1 find every filter-map))

(export poo-flow-json-schema-any?
        poo-flow-json-schema-null?
        poo-flow-json-schema-json-object-value?
        poo-flow-json-schema-json-array-value?
        poo-flow-json-schema-integer-value?
        poo-flow-json-schema-symbol-string
        poo-flow-json-schema-contract-key
        poo-flow-json-schema-node-value-kind
        poo-flow-json-schema-node-predicate-key
        poo-flow-json-schema-node-predicate
        poo-flow-json-schema-property->slot-contract
        poo-flow-json-schema-object-node->object-type-contract
        poo-flow-json-schema-node->object-type-contract)

(import :poo-flow/src/contract/json-schema-emit-runtime
        :poo-flow/src/contract/json-schema-emit-contracts)
