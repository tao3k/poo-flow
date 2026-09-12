;;; -*- Gerbil -*-
;;; POO-native CLOS instance state and generation migration values.

(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :clan/poo/mop element?)
        (only-in :std/misc/hash hash-ref/default)
        (only-in :std/srfi/1 filter find foldl)
        "types.ss" "objects.ss" "classes.ss")

(export poo-clos-instance?
        make-slot-cell instance-state-value class-generation
        instance-allocated-slot? effective-slot-identity make-instance-state
        class-handler instance-slot-names effective-instance-slot-names
        effective-slot-difference class-slot-difference
        class-effective-slots-at-generation discarded-slot-property-list
        migrated-instance-storage)

;; : POOObject
(def ClosInstanceState. (.ref ClosInstanceState 'proto))
;; : POOObject
(def ClosSlotCell. (.ref ClosSlotCell 'proto))

;; : (-> ClosSlotCell)
(def (make-slot-cell)
  (checked ClosSlotCell
           (.o (:: @ ClosSlotCell.) bound?: #f value: #f)
           'invalid-slot-cell))

;; : (-> ClosClass Natural HashTable ClosInstanceState)
(def (instance-state-value class-value generation-value storage-value)
  (checked ClosInstanceState
           (.o (:: @ ClosInstanceState.)
               class: class-value generation: generation-value
               storage: storage-value)
           'invalid-instance-state))

;; : (-> ClosClass Natural)
(def (class-generation class-value)
  (.ref class-value 'generation))

;; : (-> ClosEffectiveSlotDefinition Boolean)
(def (instance-allocated-slot? slot)
  (eq? (.ref slot 'allocation) 'instance))

;; : (-> ClosEffectiveSlotDefinition Symbol)
(def (effective-slot-identity slot)
  (.ref slot 'identity))

;; : (-> ClosClass ClosInstanceState)
(def (make-instance-state class-value)
  (let ((storage-value (make-hash-table-eq))
        (generation-value (class-generation class-value)))
    (for-each
     (lambda (slot)
       (when (instance-allocated-slot? slot)
         (hash-put! storage-value
                    (effective-slot-identity slot) (make-slot-cell))))
     (poo-clos-class-effective-slots class-value))
    (instance-state-value class-value generation-value storage-value)))

;; : (-> SchemeValue Boolean)
(def (poo-clos-instance? value)
  (and (object? value)
       (.slot? value '%poo-clos-state)
       (element? ClosInstanceState (.ref value '%poo-clos-state))))

;; : (-> ClosClass Symbol (Maybe Procedure))
(def (class-handler class-value handler-slot)
  (let (owner
        (find (lambda (candidate) (.ref candidate handler-slot))
              (poo-clos-class-precedence-list class-value)))
    (and owner (.ref owner handler-slot))))

;; : (-> ClosClass [Symbol])
(def (instance-slot-names class-value)
  (map effective-slot-identity
       (filter instance-allocated-slot?
               (poo-clos-class-effective-slots class-value))))

;; : (-> [ClosEffectiveSlotDefinition] [Symbol])
(def (effective-instance-slot-names slots)
  (map effective-slot-identity (filter instance-allocated-slot? slots)))

;; : (-> [ClosEffectiveSlotDefinition] [ClosEffectiveSlotDefinition]
;;        (values [Symbol] [Symbol]))
(def (effective-slot-difference old-slots new-slots)
  (let ((old-names (effective-instance-slot-names old-slots))
        (new-names (effective-instance-slot-names new-slots)))
    (values (filter (lambda (name) (not (memq name old-names))) new-names)
            (filter (lambda (name) (not (memq name new-names))) old-names))))

;; : (-> ClosClass ClosClass (values [Symbol] [Symbol]))
(def (class-slot-difference old-class new-class)
  (effective-slot-difference (poo-clos-class-effective-slots old-class)
                             (poo-clos-class-effective-slots new-class)))

;; : (-> ClosClass Natural [ClosEffectiveSlotDefinition])
(def (class-effective-slots-at-generation class-value generation-value)
  (if (= generation-value (.ref class-value 'generation))
    (poo-clos-class-effective-slots class-value)
    (let (layout
          (find (lambda (candidate)
                  (= (.ref candidate 'generation) generation-value))
                (.ref class-value 'layout-history)))
      (unless layout
        (clos-fail 'missing-class-layout
                   class: (.ref class-value 'identity)
                   operation: 'update-instance-for-redefined-class))
      (.ref layout 'effective-slots))))

;; : (-> ClosInstanceState [Symbol] [SchemeValue])
(def (discarded-slot-property-list state discarded)
  (foldl
   (lambda (slot-name result)
     (let (cell
           (hash-ref/default (.ref state 'storage) slot-name (lambda () #f)))
       (if (and cell (.ref cell 'bound?))
         (append result (list slot-name (.ref cell 'value)))
         result)))
   '() discarded))

;; : (-> ClosInstanceState ClosClass HashTable)
(def (migrated-instance-storage state new-class)
  (let (new-storage (make-hash-table-eq))
    (for-each
     (lambda (slot)
       (when (instance-allocated-slot? slot)
         (let* ((slot-name (effective-slot-identity slot))
                (old-cell
                 (hash-ref/default (.ref state 'storage)
                                   slot-name (lambda () #f))))
           (hash-put! new-storage slot-name (or old-cell (make-slot-cell))))))
     (poo-clos-class-effective-slots new-class))
    new-storage))


