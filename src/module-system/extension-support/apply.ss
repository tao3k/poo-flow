;;; -*- Gerbil -*-
;;; Boundary: extension contribution coalescing and fixed-point application.

(import (only-in :clan/poo/object
                 .o
                 .ref
                 object?)
        (only-in :std/sugar foldl)
        :poo-flow/src/module-system/extension-support/data
        :poo-flow/src/module-system/extension-support/merge)

(export poo-flow-module-extension-apply-operations
        poo-flow-module-extension-local-operation?
        poo-flow-module-extension-local-operations?
        poo-flow-module-extension-reverse-onto
        poo-flow-module-extension-flush-coalesced
        poo-flow-module-extension-coalesce-local-contributions
        poo-flow-module-extension-apply-contribution
        poo-flow-module-extension-apply-contributions/coalesced
        poo-flow-module-extension-apply-contributions
        poo-flow-module-extension-node-snapshot
        poo-flow-module-extension-fixed-point-step
        poo-flow-module-extension-fixed-point)

;; : (-> PooModuleExtensionNode [PooModuleExtensionOperation] PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-operations node operations)
  (match (foldl poo-flow-module-extension-operation-state
                [node '() '()]
                (poo-flow-module-extension-coalesce-slot-appends operations))
    ([current pending-node-extends pending-slot-overrides]
     (poo-flow-module-extension-flush-pending current
                                              pending-node-extends
                                              pending-slot-overrides))))

;; : (-> PooModuleExtensionOperation Boolean)
(def (poo-flow-module-extension-local-operation? operation)
  (let (action (poo-flow-module-extension-operation-action operation))
    (or (eq? action 'slot-override)
        (eq? action 'slot-append)
        (eq? action 'slot-prepend)
        (eq? action 'slot-remove))))

;; : (-> [PooModuleExtensionOperation] Boolean)
(def (poo-flow-module-extension-local-operations? operations)
  (andmap poo-flow-module-extension-local-operation? operations))

;; : (forall (a) (-> (List a) (List a) (List a)))
(def (poo-flow-module-extension-reverse-onto values tail)
  (foldl cons tail values))

;; : (-> Boolean MaybeSymbol [PooModuleExtensionOperation] [PooModuleExtensionContribution] [PooModuleExtensionContribution])
(def (poo-flow-module-extension-flush-coalesced pending? target reversed-operations output)
  (if pending?
    (cons (poo-flow-module-extension-contribution
           target
           (reverse reversed-operations))
          output)
    output))

;; : (-> PooModuleExtensionCoalesceState PooModuleExtensionContribution PooModuleExtensionCoalesceState)
(def (poo-flow-module-extension-coalesce-contribution-state state contribution)
  (match state
    ([pending? pending-target pending-operations output]
     (let ((target
            (poo-flow-module-extension-contribution-target contribution))
           (operations
            (poo-flow-module-extension-contribution-operations contribution)))
       (if (poo-flow-module-extension-local-operations? operations)
         (if (and pending? (equal? pending-target target))
           [#t
            pending-target
            (poo-flow-module-extension-reverse-onto operations
                                                    pending-operations)
            output]
           [#t
            target
            (reverse operations)
            (poo-flow-module-extension-flush-coalesced pending?
                                                       pending-target
                                                       pending-operations
                                                       output)])
         [#f
          #f
          '()
          (cons contribution
                (poo-flow-module-extension-flush-coalesced
                 pending?
                 pending-target
                 pending-operations
                 output))])))))

;; : (-> PooModuleExtensionCoalesceState [PooModuleExtensionContribution])
(def (poo-flow-module-extension-coalesce-state-output state)
  (match state
    ([pending? pending-target pending-operations output]
     (reverse
      (poo-flow-module-extension-flush-coalesced pending?
                                                 pending-target
                                                 pending-operations
                                                 output)))))

;; poo-flow-module-extension-coalesce-local-contributions
;;   : (-> (List PooModuleExtensionContribution) (List PooModuleExtensionContribution))
;;   | doc m%
;;       `poo-flow-module-extension-coalesce-local-contributions contributions`
;;       combines adjacent local contributions for the same target so fixed
;;       point extension passes apply one compact operation batch per target.
;;
;;       # Examples
;;       ```scheme
;;       (map (lambda (contribution)
;;              (list (poo-flow-module-extension-contribution-target contribution)
;;                    (map poo-flow-module-extension-operation-action
;;                         (poo-flow-module-extension-contribution-operations
;;                          contribution))))
;;            (poo-flow-module-extension-coalesce-local-contributions
;;             (list
;;              (poo-flow-module-extension-contribution
;;               'root
;;               (list (poo-flow-module-extension-slot-override 'mode 'strict)))
;;              (poo-flow-module-extension-contribution
;;               'root
;;               (list (poo-flow-module-extension-slot-append 'features
;;                                                           '(extra)))))))
;;       ;; => ((root (slot-override slot-append)))
;;       ```
;;     %
(def (poo-flow-module-extension-coalesce-local-contributions contributions)
  (poo-flow-module-extension-coalesce-state-output
   (foldl poo-flow-module-extension-coalesce-contribution-state
          [#f #f '() '()]
          contributions)))

;;; Contribution application recurses through children after the current target
;;; has been patched, which keeps parent and child updates in one graph walk.
;; : (-> PooModuleExtensionNode PooModuleExtensionContribution PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contribution node contribution)
  (let* ((target (poo-flow-module-extension-contribution-target contribution))
         (current
          (if (equal? target (poo-flow-module-extension-node-identity node))
            (poo-flow-module-extension-apply-operations
             node
             (poo-flow-module-extension-contribution-operations contribution))
            node)))
    (poo-flow-module-extension-replace-node
     current
     (poo-flow-module-extension-node-slots current)
     (map (lambda (child)
            (poo-flow-module-extension-apply-contribution child contribution))
          (poo-flow-module-extension-node-children current)))))

;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contributions/coalesced node contributions)
  (foldl (lambda (contribution current)
           (poo-flow-module-extension-apply-contribution current contribution))
         node
         contributions))

;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] PooModuleExtensionNode)
(def (poo-flow-module-extension-apply-contributions node contributions)
  (poo-flow-module-extension-apply-contributions/coalesced
   node
   (poo-flow-module-extension-coalesce-local-contributions contributions)))

;;; Snapshot comparison keeps fixed-point convergence structural and independent
;;; of POO object identity or lazy slot internals.
;; : (-> PooModuleExtensionNode PooModuleExtensionSnapshot)
;; | PooModuleExtensionSnapshot = List
(def (poo-flow-module-extension-node-snapshot node)
  (list (poo-flow-module-extension-node-identity node)
        (poo-flow-module-extension-node-slots node)
        (map poo-flow-module-extension-node-snapshot
             (poo-flow-module-extension-node-children node))))

;;; Fixed-point stepping is isolated so policy can see bounded recursion without
;;; mistaking it for a general-purpose list transform.
;; : (-> PooModuleExtensionNode [PooModuleExtensionContribution] Integer PooModuleExtensionResult)
(def (poo-flow-module-extension-fixed-point-step current contributions iteration)
  (let (next (poo-flow-module-extension-apply-contributions current contributions))
    (cond
     ((equal? (poo-flow-module-extension-node-snapshot current)
              (poo-flow-module-extension-node-snapshot next))
      (poo-flow-module-extension-result next iteration #t))
     ((>= iteration 16)
      (poo-flow-module-extension-result next iteration #f))
     (else
      (poo-flow-module-extension-fixed-point-step
       next
       contributions
       (+ iteration 1))))))

;; poo-flow-module-extension-fixed-point
;;   : (-> PooModuleExtensionNode [PooModuleExtensionContribution] PooModuleExtensionResult)
;;   | contract: applies extension contributions until the graph snapshot is stable
;;   | warning: stops after 16 iterations and marks the result unstable
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (poo-flow-module-extension-fixed-point root contributions)
;;       ;; => extension result with root, iteration count, and stable? flag
;;       ```
;;     %
(def (poo-flow-module-extension-fixed-point base contributions)
  (poo-flow-module-extension-fixed-point-step base contributions 0))
