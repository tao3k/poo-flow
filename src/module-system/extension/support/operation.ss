;;; -*- Gerbil -*-

;;; Boundary: native POO extension-operation prototypes and dispatch.
;;; Each operation family owns application and batching behavior as slots;
;;; graph merge helpers remain pure values in support/merge.ss.

(import :gerbil/gambit
        (only-in :clan/poo/object .mix .o .ref)
        (only-in :clan/poo/mop .defgeneric)
        :poo-flow/src/module-system/extension/support/data
        :poo-flow/src/module-system/extension/support/merge)

(export poo-flow-module-extension-operation-prototype
        poo-flow-module-extension-slot-override-prototype
        poo-flow-module-extension-slot-append-prototype
        poo-flow-module-extension-slot-prepend-prototype
        poo-flow-module-extension-slot-remove-prototype
        poo-flow-module-extension-node-extend-prototype
        poo-flow-module-extension-node-remove-prototype
        poo-flow-module-extension-slot-override
        poo-flow-module-extension-slot-append
        poo-flow-module-extension-slot-prepend
        poo-flow-module-extension-slot-remove
        poo-flow-module-extension-node-extend
        poo-flow-module-extension-node-remove
        poo-flow-module-extension-apply-operation
        poo-flow-module-extension-operation-state
        poo-flow-module-extension-local-operation?
        poo-flow-module-extension-node-extend-operation?
        poo-flow-module-extension-slot-append-operation?
        poo-flow-module-extension-flush-slot-append
        poo-flow-module-extension-coalesce-slot-appends)

;;; Ordinary operation application flushes pending batches before invoking the
;;; receiver-owned method. Specialized prototypes replace only this stage slot.
;; : (-> PooModuleExtensionOperation PooModuleExtensionOperationState PooModuleExtensionOperationState)
(def (poo-flow-module-extension-stage-operation operation state)
  (match state
    ([current pending-node-extends pending-slot-overrides]
     [(poo-flow-module-extension-operation-apply
       operation
       (poo-flow-module-extension-flush-pending current
                                                pending-node-extends
                                                pending-slot-overrides))
      '()
      '()])))

;;; Node extension batches preserve encounter order until the merge boundary.
;; : (-> PooModuleExtensionOperation PooModuleExtensionOperationState PooModuleExtensionOperationState)
(def (poo-flow-module-extension-stage-node-extend operation state)
  (match state
    ([current pending-node-extends pending-slot-overrides]
     [current
      (cons (poo-flow-module-extension-operation-node operation)
            pending-node-extends)
      pending-slot-overrides])))

;;; Slot overrides batch as key/value rows and use the common deterministic
;;; slot merge only when an operation family requires a flush.
;; : (-> PooModuleExtensionOperation PooModuleExtensionOperationState PooModuleExtensionOperationState)
(def (poo-flow-module-extension-stage-slot-override operation state)
  (match state
    ([current pending-node-extends pending-slot-overrides]
     [current
      pending-node-extends
      (cons (cons (poo-flow-module-extension-operation-slot operation)
                  (poo-flow-module-extension-operation-value operation))
            pending-slot-overrides)])))

;;; The base prototype supplies total identity behavior and common semantic
;;; facets. Concrete operation prototypes refine `.apply` and, when batchable,
;;; `.stage`; adding a family therefore does not extend a central action switch.
(def poo-flow-module-extension-operation-prototype
  (.o (:: self)
      kind: poo-flow-module-extension-operation-kind
      action: 'identity
      local?: #f
      node-extend?: #f
      slot-append?: #f
      (.apply (lambda (node) node))
      (.stage
       (lambda (state)
         (poo-flow-module-extension-stage-operation self state)))))

;; : PooModuleExtensionOperationPrototype
(def poo-flow-module-extension-slot-override-prototype
  (.o (:: self poo-flow-module-extension-operation-prototype)
      action: 'slot-override
      local?: #t
      (.apply
       (lambda (node)
         (poo-flow-module-extension-replace-node
          node
          (poo-flow-module-extension-alist-set
           (poo-flow-module-extension-node-slots node)
           (poo-flow-module-extension-operation-slot self)
           (poo-flow-module-extension-operation-value self))
          (poo-flow-module-extension-node-children node))))
      (.stage
       (lambda (state)
         (poo-flow-module-extension-stage-slot-override self state)))))

;; : PooModuleExtensionOperationPrototype
(def poo-flow-module-extension-slot-append-prototype
  (.o (:: self poo-flow-module-extension-operation-prototype)
      action: 'slot-append
      local?: #t
      slot-append?: #t
      (.apply
       (lambda (node)
         (poo-flow-module-extension-apply-slot-list-op node self #t)))))

;; : PooModuleExtensionOperationPrototype
(def poo-flow-module-extension-slot-prepend-prototype
  (.o (:: self poo-flow-module-extension-operation-prototype)
      action: 'slot-prepend
      local?: #t
      (.apply
       (lambda (node)
         (poo-flow-module-extension-apply-slot-list-op node self #f)))))

;; : PooModuleExtensionOperationPrototype
(def poo-flow-module-extension-slot-remove-prototype
  (.o (:: self poo-flow-module-extension-operation-prototype)
      action: 'slot-remove
      local?: #t
      (.apply
       (lambda (node)
         (let* ((slot (poo-flow-module-extension-operation-slot self))
                (current
                 (poo-flow-module-extension-list-value
                  (poo-flow-module-extension-alist-ref/default
                   (poo-flow-module-extension-node-slots node) slot '())))
                (removed
                 (poo-flow-module-extension-list-value
                  (poo-flow-module-extension-operation-value self))))
           (poo-flow-module-extension-replace-node
            node
            (poo-flow-module-extension-alist-set
             (poo-flow-module-extension-node-slots node)
             slot
             (poo-flow-module-extension-remove-elements current removed))
            (poo-flow-module-extension-node-children node)))))))

;; : PooModuleExtensionOperationPrototype
(def poo-flow-module-extension-node-extend-prototype
  (.o (:: self poo-flow-module-extension-operation-prototype)
      action: 'node-extend
      node-extend?: #t
      (.apply
       (lambda (node)
         (poo-flow-module-extension-replace-node
          node
          (poo-flow-module-extension-node-slots node)
          (poo-flow-module-extension-children-merge-one
           (poo-flow-module-extension-node-children node)
           (poo-flow-module-extension-operation-node self)))))
      (.stage
       (lambda (state)
         (poo-flow-module-extension-stage-node-extend self state)))))

;; : PooModuleExtensionOperationPrototype
(def poo-flow-module-extension-node-remove-prototype
  (.o (:: self poo-flow-module-extension-operation-prototype)
      action: 'node-remove
      (.apply
       (lambda (node)
         (poo-flow-module-extension-replace-node
          node
          (poo-flow-module-extension-node-slots node)
          (poo-flow-module-extension-children-remove
           (poo-flow-module-extension-node-children node)
           (poo-flow-module-extension-operation-target self)))))))

;;; Dynamic payloads are constant defaults on a static operation prototype.
;;; This preserves inspectable slots without rebuilding method closures per row.
;; : (-> PooModuleExtensionOperationPrototype MaybeSymbol PooModuleSlotValue MaybePooModuleExtensionNode MaybeSymbol PooModuleExtensionOperation)
(def (poo-flow-module-extension-operation-instance prototype slot value node target)
  (.mix prototype
    defaults: (list (cons 'slot slot)
                    (cons 'value value)
                    (cons 'node node)
                    (cons 'target target))))

;; : (-> Symbol PooModuleSlotValue PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-override slot value)
  (poo-flow-module-extension-operation-instance
   poo-flow-module-extension-slot-override-prototype slot value #f #f))

;; : (-> Symbol [PooModuleSlotValue] PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-append slot values)
  (poo-flow-module-extension-operation-instance
   poo-flow-module-extension-slot-append-prototype slot values #f #f))

;; : (-> Symbol [PooModuleSlotValue] PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-prepend slot values)
  (poo-flow-module-extension-operation-instance
   poo-flow-module-extension-slot-prepend-prototype slot values #f #f))

;; : (-> Symbol [PooModuleSlotValue] PooModuleExtensionOperation)
(def (poo-flow-module-extension-slot-remove slot values)
  (poo-flow-module-extension-operation-instance
   poo-flow-module-extension-slot-remove-prototype slot values #f #f))

;; : (-> PooModuleExtensionNode PooModuleExtensionOperation)
(def (poo-flow-module-extension-node-extend node)
  (poo-flow-module-extension-operation-instance
   poo-flow-module-extension-node-extend-prototype #f #f node #f))

;; : (-> Symbol PooModuleExtensionOperation)
(def (poo-flow-module-extension-node-remove target)
  (poo-flow-module-extension-operation-instance
   poo-flow-module-extension-node-remove-prototype #f #f #f target))

;;; Apply dispatch is supplied by the concrete operation prototype.
;; : (-> PooModuleExtensionOperation PooModuleExtensionNode PooModuleExtensionNode)
(.defgeneric (poo-flow-module-extension-operation-apply operation node)
  slot: .apply)

;;; Public order remains node-first while semantic dispatch stays receiver-first.
;; : (-> PooModuleExtensionNode PooModuleExtensionOperation PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-operation node operation)
  (poo-flow-module-extension-operation-apply operation node))

;;; Batch-state dispatch is likewise owned by operation prototypes.
;; : (-> PooModuleExtensionOperation PooModuleExtensionOperationState PooModuleExtensionOperationState)
(.defgeneric (poo-flow-module-extension-operation-state operation state)
  slot: .stage)

;; : (-> PooModuleExtensionOperation Boolean)
(def (poo-flow-module-extension-local-operation? operation)
  (.ref operation 'local?))

;; : (-> PooModuleExtensionOperation Boolean)
(def (poo-flow-module-extension-node-extend-operation? operation)
  (.ref operation 'node-extend?))

;; : (-> PooModuleExtensionOperation Boolean)
(def (poo-flow-module-extension-slot-append-operation? operation)
  (.ref operation 'slot-append?))

;; : (forall (a) (-> [a] [a] [a]))
;; : (-> [PooModuleSlotValue] [PooModuleSlotValue] [PooModuleSlotValue])
(def (poo-flow-module-extension-slot-values/rev-onto values tail)
  (foldl cons tail values))

;;; Emit the pending slot append batch when coalescing changes families.
;; : (-> Boolean MaybeSymbol [PooModuleSlotValue] [PooModuleExtensionOperation] [PooModuleExtensionOperation])
(def (poo-flow-module-extension-flush-slot-append pending? slot reversed-values output)
  (if pending?
    (cons (poo-flow-module-extension-slot-append
           slot
           (reverse reversed-values))
          output)
    output))

;; poo-flow-module-extension-coalesce-slot-appends
;;   : (-> [PooModuleExtensionOperation] [PooModuleExtensionOperation])
;;   | doc m%
;;       Adjacent appends for one slot collapse before generic application.
;;       Other operation families remain opaque and retain prototype order.
;;
;;       # Examples
;;       ```scheme
;;       (poo-flow-module-extension-coalesce-slot-appends operations)
;;       ;; => ordered operations with adjacent same-slot appends combined
;;       ```
;;     %
(def (poo-flow-module-extension-coalesce-slot-appends operations)
  (let loop ((remaining operations)
             (pending? #f)
             (pending-slot #f)
             (pending-values '())
             (output '()))
    (if (null? remaining)
      (reverse
       (poo-flow-module-extension-flush-slot-append pending?
                                                    pending-slot
                                                    pending-values
                                                    output))
      (let (operation (car remaining))
        (if (poo-flow-module-extension-slot-append-operation? operation)
          (let* ((slot (poo-flow-module-extension-operation-slot operation))
                 (values
                  (poo-flow-module-extension-list-value
                   (poo-flow-module-extension-operation-value operation))))
            (if (and pending? (equal? pending-slot slot))
              (loop (cdr remaining)
                    #t
                    pending-slot
                    (poo-flow-module-extension-slot-values/rev-onto
                     values pending-values)
                    output)
              (loop (cdr remaining)
                    #t
                    slot
                    (reverse values)
                    (poo-flow-module-extension-flush-slot-append
                     pending? pending-slot pending-values output))))
          (loop (cdr remaining)
                #f
                #f
                '()
                (cons operation
                      (poo-flow-module-extension-flush-slot-append
                       pending? pending-slot pending-values output))))))))
