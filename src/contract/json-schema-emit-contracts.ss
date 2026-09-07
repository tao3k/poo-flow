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

(import :poo-flow/src/contract/json-schema-emit-runtime)

(export #t)

;; : (-> PooFlowJsonSchemaValue PooFlowJsonSchemaAlistValue)
(def (poo-flow-json-schema-map-value-schema->alist value)
  (case (cond
         ((poo-flow-json-schema-node? value) 'node)
         ((poo-flow-json-schema-pattern-property? value) 'pattern-property)
         ((pair? value) 'pair)
         (else 'literal))
   ((node)
    (poo-flow-json-schema-node->alist value))
   ((pattern-property)
    (poo-flow-json-schema-pattern-property->alist value))
   ((pair)
    (cons (poo-flow-json-schema-map-value-schema->alist (car value))
          (poo-flow-json-schema-map-value-schema->alist (cdr value))))
   (else value)))

;; poo-flow-json-schema-property->slot-contract
;;   : (-> PooFlowJsonSchemaProperty Symbol Symbol PooFlowSlotContract)
;;   | doc m%
;;       Emit one property contract while preserving normalized schema and source
;;       property metadata for later facts and receipts.
;;     %
(def (poo-flow-json-schema-property->slot-contract property object-key object-kind)
  (let* ((slot (poo-flow-json-schema-property-name property))
         (schema (poo-flow-json-schema-property-schema property))
         (metadata
          (append
           (list
            (cons 'source 'json-schema)
            (cons 'doc (poo-flow-json-schema-property-doc property))
            (cons 'schema (poo-flow-json-schema-node->alist schema))
            (cons 'property
                  (poo-flow-json-schema-property->alist property)))
           (poo-flow-json-schema-property-metadata property))))
    (poo-flow-contract-slot
     (poo-flow-json-schema-contract-key object-key slot)
     slot
     (poo-flow-contract-value-type
      (poo-flow-json-schema-node-value-kind schema)
      (poo-flow-json-schema-node-predicate schema)
      (poo-flow-json-schema-node-value-kind schema)
      (poo-flow-json-schema-node-predicate-key schema))
     (poo-flow-json-schema-property-required? property)
     metadata)))

;; poo-flow-json-schema-object-node->object-type-contract
;;   : (-> PooFlowJsonSchemaNode Symbol Symbol Symbol PooFlowObjectTypeContract)
;;   | doc m%
;;       Emit a structural object contract from a normalized object node.
;;     %
(def (poo-flow-json-schema-object-node->object-type-contract node owner object-kind
                                                             object-key)
  (let* ((object (poo-flow-json-schema-node-value node))
         (properties
          (if (poo-flow-json-schema-object? object)
            (poo-flow-json-schema-object-properties object)
            '()))
         (slots
          (map (lambda (property)
                 (poo-flow-json-schema-property->slot-contract
                  property object-key object-kind))
               properties))
         (metadata
          (append
           (list
            (cons 'source 'json-schema)
            (cons 'schema-kind 'object)
            (cons 'additional-properties
                  (poo-flow-json-schema-map-value-schema->alist
                   (poo-flow-json-schema-object-additional-properties object)))
            (cons 'pattern-properties
                  (poo-flow-json-schema-map-value-schema->alist
                   (poo-flow-json-schema-object-pattern-properties object)))
            (cons 'normalized-schema
                  (poo-flow-json-schema-node->alist node)))
           (poo-flow-json-schema-object-metadata object)
           (poo-flow-json-schema-node-metadata node))))
    (poo-flow-native-contract
     object-key
     owner
     object-kind
     poo-flow-json-schema-contract-candidate?
     slots
     poo-flow-json-schema-contract-slot-present?
     poo-flow-json-schema-contract-slot-ref
     metadata)))

;; poo-flow-json-schema-node->object-type-contract
;;   : (-> PooFlowJsonSchemaNode Symbol Symbol Symbol PooFlowObjectTypeContract)
;;   | doc m%
;;       Emit an object contract for structural schemas and a single `value`
;;       slot contract for scalar or fallback schemas.
;;     %
(def (poo-flow-json-schema-node->object-type-contract node owner object-kind
                                                      object-key)
  (case (and (poo-flow-json-schema-node? node)
             (poo-flow-json-schema-node-kind node))
    ((object)
     (poo-flow-json-schema-object-node->object-type-contract
      node
      owner
      object-kind
      object-key))
    (else
     (poo-flow-native-contract
      object-key
      owner
      object-kind
      poo-flow-json-schema-contract-candidate?
      (list
       (poo-flow-contract-slot
        (poo-flow-json-schema-contract-key object-key 'value)
        'value
        (poo-flow-contract-value-type
         (poo-flow-json-schema-node-value-kind node)
         (poo-flow-json-schema-node-predicate node)
         (poo-flow-json-schema-node-value-kind node)
         (poo-flow-json-schema-node-predicate-key node))
        #t
        (list
         (cons 'source 'json-schema)
         (cons 'schema (poo-flow-json-schema-node->alist node)))))
      poo-flow-json-schema-contract-slot-present?
      poo-flow-json-schema-contract-slot-ref
      (list
       (cons 'source 'json-schema)
       (cons 'schema-kind (poo-flow-json-schema-node-kind node))
       (cons 'normalized-schema (poo-flow-json-schema-node->alist node)))))))
