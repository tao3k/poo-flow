;;; -*- Gerbil -*-
;;; Boundary: proof-backed AI agent lifecycle gate objects.
;;; Invariant: gates are POO-native; alists appear only as Lean facts.

(import (only-in :clan/poo/object .o .ref object?))

(export poo-flow-agent-lifecycle-gate-kind
        poo-flow-agent-lifecycle-receipt-kind
        poo-flow-agent-lifecycle-gate-fact-keys
        poo-flow-agent-lifecycle-receipt
        pooFlowAgentLifecycleReceipt
        poo-flow-agent-lifecycle-gate
        pooFlowAgentLifecycleGate
        poo-flow-agent-lifecycle-receipt?
        poo-flow-agent-lifecycle-gate?
        poo-flow-agent-lifecycle-gate-name
        poo-flow-agent-lifecycle-gate-accepted?
        poo-flow-agent-lifecycle-gate->lean-facts
        poo-flow-agent-lifecycle-lean-fact-contract-complete?)

;; : (-> Unit PooFlowAgentLifecycleGateKind)
(def poo-flow-agent-lifecycle-gate-kind
  "poo-flow.modules.agent-lifecycle.gate.v1")

;; : (-> Unit PooFlowAgentLifecycleReceiptKind)
(def poo-flow-agent-lifecycle-receipt-kind
  "poo-flow.modules.agent-lifecycle.receipt.v1")

;; : (-> Unit PooFlowAgentLifecycleLeanFactKeySet)
(def poo-flow-agent-lifecycle-gate-fact-keys
  '(ai.lifecycle/public-policy
    ai.session/created
    ai.session/parent-bound
    ai.sandbox/attached
    ai.sandbox/scope-contained
    ai.tool/permissions-contained
    ai.loop/start-guarded
    ai.loop/exit-defined
    ai.loop/handoff-guarded
    ai.subagent/parented
    ai.topology/scope-order-sound
    ai.topology/tool-scope-sound
    ai.topology/loop-transition-sound
    ai.topology/subagent-session-sound
    ai.dependency/closed
    ai.receipt/tested
    ai.receipt/has-proof
    ai.receipt/observability-clean
    ai.counterexample/rejected
    ai.lifecycle/reusable-policy-surface
    ai.lifecycle/experimental))

;;; Receipt predicates stay local to this owner so lifecycle gate validation can
;;; distinguish a missing receipt from a receipt that explicitly rejects safety.
;; : (-> PooFlowAgentLifecycleReceiptCandidate Boolean)
(def (poo-flow-agent-lifecycle-receipt? value)
  (and (object? value)
       (equal? (.ref value 'kind)
               poo-flow-agent-lifecycle-receipt-kind)))

;; : (-> PooFlowAgentLifecycleReceipt Symbol PooFlowAgentLifecycleReceiptSlotValue)
(def (poo-flow-agent-lifecycle-receipt-slot receipt key)
  (.ref receipt key))

;;; Optional receipt access is intentionally private. Missing receipt facts
;;; project to false values instead of becoming partial public accessors.
;; : (-> PooFlowAgentLifecycleReceiptCandidate Symbol PooFlowAgentLifecycleReceiptSlotValue PooFlowAgentLifecycleReceiptSlotValue)
(def (poo-flow-agent-lifecycle-receipt-slot/default receipt key default-value)
  (if (poo-flow-agent-lifecycle-receipt? receipt)
    (poo-flow-agent-lifecycle-receipt-slot receipt key)
    default-value))

;; : (-> PooFlowAgentLifecycleReceiptSlotValue Boolean)
(def (poo-flow-agent-lifecycle-non-empty-list? value)
  (and (list? value) (not (null? value))))

;; poo-flow-agent-lifecycle-receipt
;;   : (-> Symbol Symbol Symbol [Symbol] [Symbol] [Symbol] [Symbol] Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean POOObject)
;;   | contract: POO receipt for session/sandbox/loop/subagent policy gates
;; : (-> Symbol Symbol Symbol [Symbol] [Symbol] [Symbol] [Symbol] Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean POOObject)
(def (poo-flow-agent-lifecycle-receipt session-id
                                       sandbox-profile-ref
                                       loop-policy-ref
                                       subagent-refs
                                       tool-capability-refs
                                       test-receipts
                                       proof-receipts
                                       session-created?
                                       parent-session-bound?
                                       sandbox-attached?
                                       sandbox-scope-contained?
                                       tool-permissions-contained?
                                       loop-start-guarded?
                                       loop-exit-defined?
                                       loop-handoff-guarded?
                                       subagents-parented?
                                       dependency-closed?
                                       observability-clean?
                                       counterexample-rejected?)
  (.o kind: poo-flow-agent-lifecycle-receipt-kind
      lifecycle-receipt-session-id: session-id
      lifecycle-receipt-sandbox-profile-ref: sandbox-profile-ref
      lifecycle-receipt-loop-policy-ref: loop-policy-ref
      lifecycle-receipt-subagent-refs: subagent-refs
      lifecycle-receipt-tool-capability-refs: tool-capability-refs
      lifecycle-receipt-test-receipts: test-receipts
      lifecycle-receipt-proof-receipts: proof-receipts
      lifecycle-receipt-session-created: session-created?
      lifecycle-receipt-parent-session-bound: parent-session-bound?
      lifecycle-receipt-sandbox-attached: sandbox-attached?
      lifecycle-receipt-sandbox-scope-contained: sandbox-scope-contained?
      lifecycle-receipt-tool-permissions-contained: tool-permissions-contained?
      lifecycle-receipt-loop-start-guarded: loop-start-guarded?
      lifecycle-receipt-loop-exit-defined: loop-exit-defined?
      lifecycle-receipt-loop-handoff-guarded: loop-handoff-guarded?
      lifecycle-receipt-subagents-parented: subagents-parented?
      lifecycle-receipt-dependency-closed: dependency-closed?
      lifecycle-receipt-observability-clean: observability-clean?
      lifecycle-receipt-counterexample-rejected: counterexample-rejected?))

;; : (-> Symbol Symbol Symbol [Symbol] [Symbol] [Symbol] [Symbol] Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean Boolean POOObject)
(def (pooFlowAgentLifecycleReceipt session-id
                                   sandbox-profile-ref
                                   loop-policy-ref
                                   subagent-refs
                                   tool-capability-refs
                                   test-receipts
                                   proof-receipts
                                   session-created?
                                   parent-session-bound?
                                   sandbox-attached?
                                   sandbox-scope-contained?
                                   tool-permissions-contained?
                                   loop-start-guarded?
                                   loop-exit-defined?
                                   loop-handoff-guarded?
                                   subagents-parented?
                                   dependency-closed?
                                   observability-clean?
                                   counterexample-rejected?)
  (poo-flow-agent-lifecycle-receipt
   session-id
   sandbox-profile-ref
   loop-policy-ref
   subagent-refs
   tool-capability-refs
   test-receipts
   proof-receipts
   session-created?
   parent-session-bound?
   sandbox-attached?
   sandbox-scope-contained?
   tool-permissions-contained?
   loop-start-guarded?
   loop-exit-defined?
   loop-handoff-guarded?
   subagents-parented?
   dependency-closed?
   observability-clean?
   counterexample-rejected?))

;; poo-flow-agent-lifecycle-gate
;;   : (-> Symbol Symbol POOObject Alist POOObject)
;;   | contract: constructs a POO-native lifecycle proof gate
;; : (-> Symbol Symbol POOObject Alist POOObject)
(def (poo-flow-agent-lifecycle-gate name status receipt metadata)
  (.o kind: poo-flow-agent-lifecycle-gate-kind
      lifecycle-gate-name: name
      lifecycle-gate-status: status
      lifecycle-gate-receipt: receipt
      lifecycle-gate-metadata: metadata))

;; : (-> Symbol Symbol POOObject Alist POOObject)
(def (pooFlowAgentLifecycleGate name status receipt metadata)
  (poo-flow-agent-lifecycle-gate name status receipt metadata))

;; : (-> PooFlowAgentLifecycleGateCandidate Boolean)
(def (poo-flow-agent-lifecycle-gate? value)
  (and (object? value)
       (equal? (.ref value 'kind)
               poo-flow-agent-lifecycle-gate-kind)))

;; : (-> PooFlowAgentLifecycleGate Symbol PooFlowAgentLifecycleGateSlotValue)
(def (poo-flow-agent-lifecycle-gate-slot gate key)
  (.ref gate key))

;; : (-> PooFlowAgentLifecycleGate Symbol)
(def (poo-flow-agent-lifecycle-gate-name gate)
  (poo-flow-agent-lifecycle-gate-slot gate 'lifecycle-gate-name))

;; : (-> PooFlowAgentLifecycleGate PooFlowAgentLifecycleReceiptCandidate)
(def (poo-flow-agent-lifecycle-gate-receipt gate)
  (poo-flow-agent-lifecycle-gate-slot gate 'lifecycle-gate-receipt))

;;; Acceptance is the prevention boundary for agent-authored lifecycle policy.
;;; A proof receipt alone is insufficient: the public surface also requires
;;; session lineage, sandbox scope, tool permissions, loop guards, subagent
;;; parentage, dependency closure, observability, and rejected bad cases.
;; : (-> PooFlowAgentLifecycleGate Boolean)
(def (poo-flow-agent-lifecycle-gate-accepted? gate)
  (let* ((status
          (poo-flow-agent-lifecycle-gate-slot gate 'lifecycle-gate-status))
         (receipt (poo-flow-agent-lifecycle-gate-receipt gate))
         (test-receipts
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-test-receipts
           '()))
         (proof-receipts
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-proof-receipts
           '())))
    (and (eq? status 'public)
         (poo-flow-agent-lifecycle-receipt? receipt)
         (poo-flow-agent-lifecycle-non-empty-list? test-receipts)
         (poo-flow-agent-lifecycle-non-empty-list? proof-receipts)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-session-created)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-parent-session-bound)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-sandbox-attached)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-sandbox-scope-contained)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-tool-permissions-contained)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-loop-start-guarded)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-loop-exit-defined)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-loop-handoff-guarded)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-subagents-parented)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-dependency-closed)
         (poo-flow-agent-lifecycle-receipt-slot
          receipt
          'lifecycle-receipt-observability-clean)
         (poo-flow-agent-lifecycle-receipt-slot
         receipt
         'lifecycle-receipt-counterexample-rejected))))

;;; Lean fact projection is the only alist boundary. Callers author and extend
;;; POO gates; the proof layer receives stable fact rows that mirror the gate.
;; : (-> PooFlowAgentLifecycleGate Alist)
(def (poo-flow-agent-lifecycle-gate->lean-facts gate)
  (let* ((status
          (poo-flow-agent-lifecycle-gate-slot gate 'lifecycle-gate-status))
         (receipt (poo-flow-agent-lifecycle-gate-receipt gate))
         (test-receipts
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-test-receipts
           '()))
         (proof-receipts
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-proof-receipts
           '()))
         (public? (eq? status 'public))
         (tested?
          (poo-flow-agent-lifecycle-non-empty-list? test-receipts))
         (proof-backed?
          (poo-flow-agent-lifecycle-non-empty-list? proof-receipts))
         (session-created?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-session-created
           #f))
         (parent-session-bound?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-parent-session-bound
           #f))
         (sandbox-attached?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-sandbox-attached
           #f))
         (sandbox-scope-contained?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-sandbox-scope-contained
           #f))
         (tool-permissions-contained?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-tool-permissions-contained
           #f))
         (loop-start-guarded?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-loop-start-guarded
           #f))
         (loop-exit-defined?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-loop-exit-defined
           #f))
         (loop-handoff-guarded?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-loop-handoff-guarded
           #f))
         (subagents-parented?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-subagents-parented
           #f))
         (dependency-closed?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-dependency-closed
           #f))
         (observability-clean?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-observability-clean
           #f))
         (counterexample-rejected?
          (poo-flow-agent-lifecycle-receipt-slot/default
           receipt
           'lifecycle-receipt-counterexample-rejected
           #f)))
    (list
     (cons 'ai.lifecycle/public-policy public?)
     (cons 'ai.session/created session-created?)
     (cons 'ai.session/parent-bound parent-session-bound?)
     (cons 'ai.sandbox/attached sandbox-attached?)
     (cons 'ai.sandbox/scope-contained sandbox-scope-contained?)
     (cons 'ai.tool/permissions-contained tool-permissions-contained?)
     (cons 'ai.loop/start-guarded loop-start-guarded?)
     (cons 'ai.loop/exit-defined loop-exit-defined?)
     (cons 'ai.loop/handoff-guarded loop-handoff-guarded?)
     (cons 'ai.subagent/parented subagents-parented?)
     (cons 'ai.topology/scope-order-sound sandbox-scope-contained?)
     (cons 'ai.topology/tool-scope-sound
           (and sandbox-scope-contained?
                tool-permissions-contained?))
     (cons 'ai.topology/loop-transition-sound
           (and loop-start-guarded?
                loop-exit-defined?
                loop-handoff-guarded?))
     (cons 'ai.topology/subagent-session-sound
           (and parent-session-bound?
                subagents-parented?))
     (cons 'ai.dependency/closed dependency-closed?)
     (cons 'ai.receipt/tested tested?)
     (cons 'ai.receipt/has-proof proof-backed?)
     (cons 'ai.receipt/observability-clean observability-clean?)
     (cons 'ai.counterexample/rejected counterexample-rejected?)
     (cons 'ai.lifecycle/reusable-policy-surface
           (and public?
                tested?
                proof-backed?
                session-created?
                parent-session-bound?
                sandbox-attached?
                sandbox-scope-contained?
                tool-permissions-contained?
                loop-start-guarded?
                loop-exit-defined?
                loop-handoff-guarded?
                subagents-parented?
                dependency-closed?
                observability-clean?
                counterexample-rejected?))
     (cons 'ai.lifecycle/experimental
           (eq? status 'experimental)))))

;; : (-> Alist Boolean)
(def (poo-flow-agent-lifecycle-lean-fact-contract-complete? facts)
  (and (andmap (lambda (key)
                 (and (assq key facts) #t))
               poo-flow-agent-lifecycle-gate-fact-keys)
       (andmap (lambda (fact)
                 (and (pair? fact)
                      (memq (car fact)
                            poo-flow-agent-lifecycle-gate-fact-keys)
                      #t))
               facts)))
