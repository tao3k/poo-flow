;;; -*- Gerbil -*-
;;; Boundary: reusable workloads for utilities/type-contract performance gates.
;;; Invariant: workloads measure Scheme contract operations, not gxi startup,
;;; package loading, Lean execution, or Marlin runtime work.

(import (only-in :std/srfi/1 fold iota)
        (only-in "./performance.ss"
                 poo-flow-performance-build-list)
        (only-in "../../src/utilities/contracts.ss"
                 poo-flow-slot-contract-record
                 poo-flow-object-type-contract-record
                 poo-flow-object-type-contract->alist
                 poo-flow-object-type-contract-slots
                 poo-flow-contract-check-slot!)
        (only-in "../../src/type-facts/objects.ss"
                 poo-flow-object-type-contract->type-facts
                 poo-flow-object-type-contract->lean-fact-contracts)
        (only-in "../../src/modules/session/policy.ss"
                 +poo-flow-session-policy-type-contract+
                 +poo-flow-session-tool-grant-type-contract+
                 poo-flow-session-policy-require-slots!
                 poo-flow-session-tool-grant-require-slots!))

(export type-contract-performance-slot-name
        type-contract-performance-slot-contract
        type-contract-performance-object-contract
        type-contract-performance-values
        type-contract-performance-check-slots-once
        type-contract-performance-check-slots-rounds
        type-contract-performance-object-family-check-count
        type-contract-performance-object-contract-alist-rounds
        type-contract-performance-type-facts-rounds
        type-contract-performance-lean-facts-rounds
        type-contract-performance-cached-type-facts-rounds
        type-contract-performance-session-policy-type-facts-rounds
        type-contract-performance-session-tool-grant-lean-facts-rounds
        type-contract-performance-session-policy-require-rounds
        type-contract-performance-session-tool-grant-require-rounds)

;; : (-> Integer Symbol)
(def (type-contract-performance-slot-name index)
  (string->symbol
   (string-append "contract-slot-" (number->string index))))

;; : (-> Integer PooFlowSlotContract)
(def (type-contract-performance-slot-contract index)
  (let (slot-name (type-contract-performance-slot-name index))
    (poo-flow-slot-contract-record
     (string->symbol
      (string-append "type-contract.performance/"
                     (number->string index)))
     'PooFlowTypeContractPerformanceObject
     slot-name
     'Symbol
     'symbol?
     symbol?
     #t
     (list (cons 'scenario 'type-contract-performance)
           (cons 'slot-index index)))))

;; : (-> Integer PooFlowObjectTypeContract)
(def (type-contract-performance-object-contract slot-count)
  (poo-flow-object-type-contract-record
   'type-contract/performance
   'type-contract-performance
   'PooFlowTypeContractPerformanceObject
   (poo-flow-performance-build-list
    slot-count
    type-contract-performance-slot-contract)
   '((projection . performance))))

;; : (-> Integer [Symbol])
(def (type-contract-performance-values slot-count)
  (poo-flow-performance-build-list
   slot-count
   type-contract-performance-slot-name))

;; type-contract-performance-check-slots-once
;;   : (-> PooFlowObjectTypeContract [Symbol] Integer)
;;   | doc m%
;;       Checks each slot contract against the matching symbol value once and
;;       returns the number of validated slots for the benchmark receipt.
;;
;;       # Examples
;;       ```scheme
;;       (type-contract-performance-check-slots-once
;;        (type-contract-performance-object-contract 1)
;;        (type-contract-performance-values 1))
;;       ;; => 1
;;       ```
;;     %
(def (type-contract-performance-check-slots-once object-contract values)
  (length
   (map (lambda (slot-contract value)
          (poo-flow-contract-check-slot! slot-contract value)
          slot-contract)
        (poo-flow-object-type-contract-slots object-contract)
        values)))

;; type-contract-performance-repeat
;;   : (-> Integer (-> Integer) Integer)
;;   | doc m%
;;       Executes a benchmark workload exactly `rounds` times and folds the
;;       numeric results without hiding the workload side effects.
;;
;;       # Examples
;;       ```scheme
;;       (type-contract-performance-repeat 3 (lambda () 1))
;;       ;; => 3
;;       ```
;;     %
(def (type-contract-performance-repeat rounds workload)
  (if (<= rounds 0)
    0
    (fold (lambda (_round total)
            (+ total (workload)))
          0
          (iota rounds))))

;; : (-> Integer Integer Integer)
(def (type-contract-performance-check-slots-rounds slot-count rounds)
  (let ((object-contract
         (type-contract-performance-object-contract slot-count))
        (values
         (type-contract-performance-values slot-count)))
    (type-contract-performance-repeat
     rounds
     (lambda ()
       (type-contract-performance-check-slots-once object-contract values)))))

;; : (-> Integer Integer Integer)
(def (type-contract-performance-object-family-check-count object-count
                                                          slot-count)
  (let ((object-contract
         (type-contract-performance-object-contract slot-count))
        (values
         (type-contract-performance-values slot-count)))
    (type-contract-performance-repeat
     object-count
     (lambda ()
       (type-contract-performance-check-slots-once object-contract values)))))

;; : (-> Integer Integer Integer)
(def (type-contract-performance-object-contract-alist-rounds slot-count rounds)
  (let (object-contract
        (type-contract-performance-object-contract slot-count))
    (type-contract-performance-repeat
     rounds
     (lambda ()
       (length
        (cdr (assoc 'slots
                    (poo-flow-object-type-contract->alist
                     object-contract))))))))

;; : (-> Integer Integer Integer)
(def (type-contract-performance-type-facts-rounds slot-count rounds)
  (let (object-contract
        (type-contract-performance-object-contract slot-count))
    (type-contract-performance-repeat
     rounds
     (lambda ()
       (length
        (poo-flow-object-type-contract->type-facts object-contract))))))

;; : (-> Integer Integer Integer)
(def (type-contract-performance-lean-facts-rounds slot-count rounds)
  (let (object-contract
        (type-contract-performance-object-contract slot-count))
    (type-contract-performance-repeat
     rounds
     (lambda ()
       (length
        (poo-flow-object-type-contract->lean-fact-contracts
         object-contract))))))

;;; Boundary: cached projections model agent-loop hot paths. Contract facts are
;;; immutable declaration data and should be projected once before repeated
;;; reads by doctor, observability, or runtime-handoff presentation code.
;; : (-> Integer Integer Integer)
(def (type-contract-performance-cached-type-facts-rounds slot-count rounds)
  (let (facts
        (poo-flow-object-type-contract->type-facts
         (type-contract-performance-object-contract slot-count)))
    (type-contract-performance-repeat
     rounds
     (lambda ()
       (length facts)))))

;; : (-> Integer Integer)
(def (type-contract-performance-session-policy-type-facts-rounds rounds)
  (type-contract-performance-repeat
   rounds
   (lambda ()
     (length
      (poo-flow-object-type-contract->type-facts
       +poo-flow-session-policy-type-contract+)))))

;; : (-> Integer Integer)
(def (type-contract-performance-session-tool-grant-lean-facts-rounds rounds)
  (type-contract-performance-repeat
   rounds
   (lambda ()
     (length
      (poo-flow-object-type-contract->lean-fact-contracts
       +poo-flow-session-tool-grant-type-contract+)))))

;; : (-> Integer Integer)
(def (type-contract-performance-session-policy-require-rounds rounds)
  (type-contract-performance-repeat
   rounds
   (lambda ()
     (poo-flow-session-policy-require-slots!
      'poo-flow.session.policy
      'poo-flow.modules.session.policy.tool-permission.v1
      'agent-tool-permission
      'policy/performance-tools
      'session/performance
      'deny
      '((tool-grants . ())
        (denied-tool-refs . (write-workspace-file)))
      '((fixture . type-contract-performance))
      "marlin-agent-core"
      #f)
     1)))

;; : (-> Integer Integer)
(def (type-contract-performance-session-tool-grant-require-rounds rounds)
  (type-contract-performance-repeat
   rounds
   (lambda ()
     (poo-flow-session-tool-grant-require-slots!
      'poo-flow.session.tool-grant
      'poo-flow.modules.session.tool-grant.v1
      'grant/performance-read
      'read-workspace-file
      '(read)
      '(project-workspace)
      '(agent-turn)
      '((fixture . type-contract-performance))
      #f)
     1)))
