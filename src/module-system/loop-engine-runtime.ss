;;; -*- Gerbil -*-
;;; Boundary: loop-engine runtime handoff projection for module-system config.
;;; Invariant: this owner emits Marlin handoff data and never executes runtime work.

(import (only-in :poo-flow/src/core/agent-harness
                 make-poo-flow-runtime-snapshot
                 poo-flow-runtime-snapshot->alist)
        (only-in :poo-flow/src/core/runtime-protocol
                 +runtime-request-schema+)
        (only-in :poo-flow/src/core/runtime-command-descriptor
                 runtime-command-fields->manifest)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-default-sandbox-profiles)
        (only-in :poo-flow/src/modules/funflow/config
                 poo-flow-funflow-workflow-agreement)
        (only-in :poo-flow/src/module-system/sandbox-backend-capability-catalog
                 poo-flow-user-config-sandbox-backend-capability-registry)
        :poo-flow/src/module-system/base
        :poo-flow/src/module-system/sandbox-profile-catalog
        :poo-flow/src/module-system/workflow-cicd-config
        :poo-flow/src/module-system/loop-engine-core
        :poo-flow/src/module-system/loop-engine-proof-abi
        :poo-flow/src/module-system/loop-engine-runtime-base
        :poo-flow/src/module-system/loop-engine-runtime-capability
        :poo-flow/src/module-system/runtime-projection-syntax
        :poo-flow/src/module-system/loop-engine-runtime-agent
        (only-in :poo-flow/src/module-system/loop-engine-runtime-intent
                 poo-flow-user-loop-engine-intent-runtime-action-kind
                 poo-flow-user-loop-engine-intent-runtime-envelope
                 poo-flow-user-loop-engine-intent-runtime-command-manifest
                 poo-flow-user-loop-engine-intent-proof-manifest
                 poo-flow-user-loop-engine-intent-runtime-snapshot
                 poo-flow-user-loop-engine-intent-lineage-receipt
                 poo-flow-user-loop-engine-intent-selector-receipt
                 poo-flow-user-loop-engine-intent-resource-dispatch-receipt
                 poo-flow-user-loop-engine-intent-memory-receipt
                 poo-flow-user-loop-engine-intent-compression-receipt)
        :poo-flow/src/module-system/loop-engine-result-contract
        :poo-flow/src/utilities/functional)

(export make-loop-engine-capability-receipt
        loop-engine-capability-receipt?
        loop-engine-capability-receipt-backend
        loop-engine-capability-receipt-backend-kind
        loop-engine-capability-receipt-backend-capabilities
        loop-engine-capability-receipt-supported-backends
        loop-engine-capability-receipt-valid?
        loop-engine-capability-receipt-diagnostics
        loop-engine-capability-receipt-isolation
        loop-engine-capability-receipt-required
        loop-engine-capability-receipt-optional
        loop-engine-capability-receipt-unsupported-behavior
        loop-engine-capability-receipt-sandbox-ref
        loop-engine-capability-receipt-session-ref
        loop-engine-capability-receipt->alist
        poo-flow-user-loop-engine-primary-agent
        poo-flow-user-loop-engine-intent-status
        poo-flow-user-loop-engine-intent-operation-kind
        poo-flow-user-loop-engine-intent-result-contract
        poo-flow-user-loop-engine-result-contract-valid?
        poo-flow-user-loop-engine-result-contract-diagnostics
        poo-flow-user-loop-engine-intent-role-result-contract
        poo-flow-user-loop-engine-intent-operation-result-contract
        poo-flow-user-loop-engine-intent-agent-profiles
        poo-flow-user-loop-engine-intent-agent-harnesses
        poo-flow-user-loop-engine-intent-agent-sessions
        poo-flow-user-loop-engine-intent-session-agent-graph
        poo-flow-user-loop-engine-intent-session-agent-topology-trace
        poo-flow-user-loop-engine-intent-agent-operation
        poo-flow-user-loop-engine-intent-delegated-operation
        poo-flow-user-loop-engine-intent-dispatch-receipt
        poo-flow-user-loop-engine-intent-runtime-command-manifest
        poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
        poo-flow-user-loop-engine-intent-proof-manifest
        +poo-flow-loop-engine-proof-abi-version+
        +poo-flow-loop-engine-proof-obligation-tags+
        +poo-flow-loop-engine-proof-obligations+
        +poo-flow-loop-engine-proof-obligation-count+
        +poo-flow-loop-engine-proof-required-obligation-mask+
        +poo-flow-loop-engine-proof-abi-tag-width+
        poo-flow-loop-engine-proof-obligation
        poo-flow-loop-engine-proof-obligation-mask
        poo-flow-loop-engine-proof-c-abi
        poo-flow-loop-engine-proof-manifest
        poo-flow-user-loop-engine-intent-runtime-capability-descriptor
        poo-flow-user-loop-engine-intent-policy-profile-packet
        poo-flow-user-loop-engine-intent-runtime-action-packet
        poo-flow-user-loop-engine-intent-runtime-receipt-batch-template
        poo-flow-user-loop-engine-intent-workflow-agreement
        poo-flow-user-loop-engine-intent-runtime-envelope
        poo-flow-user-loop-engine-intent-runtime-handoff-facts
        poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
        poo-flow-user-loop-engine-intent-runtime-snapshot
        poo-flow-user-loop-engine-capability-receipt-ref
        poo-flow-user-loop-engine-capability-receipt->alist
        poo-flow-user-loop-engine-intent-workflow-run
        poo-flow-user-loop-engine-intent-runtime-intent
        poo-flow-user-loop-engine-intent-policy)

;;; Runtime capability descriptors are report-only pressure-relief packets. They
;;; give runtime authors a narrow contract before any policy/action packet is
;;; validated or executed.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-runtime-capability-descriptor
  (intent)
  (bindings ())
  (fields
   (('kind 'runtime-capability-descriptor)
    ('contract
     +poo-flow-user-loop-engine-runtime-capability-descriptor-contract+)
    ('runtime-id "marlin-agent-core")
    ('runtime-language 'rust)
    ('runtime-owner "marlin-agent-core")
    ('transport-class 'manifest)
    ('abi-id 'poo-flow.loop-engine.runtime-pressure-relief)
    ('abi-version 1)
    ('exported-symbols '())
    ('supported-policy-families
     '(queue-policy continuation-policy tool-batch-policy
       model-route-policy evidence-policy failure-policy memory-policy
       human-gate-policy self-evolution-policy))
    ('supported-action-kinds
     '(run observe quiet-skip ask-owner self-repair fallback handoff
           validate-only))
    ('supported-receipt-contracts
     +poo-flow-user-loop-engine-receipt-contracts+)
    ('runtime-packet-contracts
     +poo-flow-user-loop-engine-runtime-packet-contracts+)
    ('max-action-batch-size 1)
    ('supports-epoch-backing? #f)
    ('supports-borrowed-bytes? #f)
    ('supports-durable-leases? #f)
    ('supports-readiness-gates? #t)
    ('runtime-executed? #f)
    ('runtime-executed #f))))

;;; Policy profile packets flatten POO-derived policy rows into a runtime-facing
;;; contract. Marlin should not need to reconstruct slot inheritance or user UI
;;; concepts to understand these facts.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-policy-profile-packet
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))))
  (fields
   (('kind 'policy-profile-packet)
    ('contract
     +poo-flow-user-loop-engine-policy-profile-packet-contract+)
    ('profile-id
     (poo-flow-user-loop-engine-runtime-id use-case-name
                                           "policy-profile"))
    ('policy-epoch
     (poo-flow-user-loop-engine-runtime-id use-case-name
                                           "policy-epoch"))
    ('source-refs (list use-case-name))
    ('policy-families
     '(queue-policy continuation-policy tool-batch-policy
       model-route-policy evidence-policy failure-policy memory-policy
       human-gate-policy self-evolution-policy projection-policy))
    ('queue-policy
     '((steering-drain-policy . drain-one)
       (follow-up-drain-policy . drain-one)
       (prioritize-steering . #t)))
    ('continuation-policy
     '((allow-accept . #t)
       (allow-deny . #t)
       (allow-defer . #t)
       (allow-rewrite . #t)
       (require-decision-receipt . #t)))
    ('tool-batch-policy
     (list
      (cons 'execution-mode 'sequential)
      (cons 'force-sequential #t)
      (cons 'require-all-tools-to-terminate #t)
      (cons 'require-before-after-hook-receipts #t)
      (cons 'resource-policy
            (poo-flow-user-loop-engine-intent-ref
             intent
             'resource-policy
             '()))))
    ('model-route-policy
     '((allow-model-override . #f)
       (require-route-receipt . #t)
       (require-no-live-llm-receipt . #f)
       (allow-context-transform . #t)))
    ('evidence-policy
     (list
      (cons 'capture-events #t)
      (cons 'capture-node-receipts #t)
      (cons 'capture-tool-receipts #t)
      (cons 'capture-content-receipts #t)
      (cons 'capture-trace #t)
      (cons 'replayable #t)
      (cons 'observability
            (poo-flow-user-loop-engine-intent-ref
             intent
             'observability
             '()))))
    ('failure-policy
     '((classify-failure . #t)
       (allow-retry . #t)
       (allow-repair-graph . #t)
       (escalate-unknown-to-human . #t)))
    ('memory-policy
     (list
      (cons 'declared-policies
            (poo-flow-user-loop-engine-intent-ref
             intent
             'memory-policies
             '()))
      (cons 'require-contract-validated #t)
      (cons 'allow-cross-project-memory #f)
      (cons 'require-source-anchor #t)))
    ('human-gate-policy
     (list
      (cons 'human-audit
            (poo-flow-user-loop-engine-intent-ref
             intent
             'human-audit
             '()))
      (cons 'require-for-permission-escalation #t)
      (cons 'require-for-policy-change #t)
      (cons 'require-for-cross-project-memory #t)
      (cons 'require-for-unverified-root-cause #t)))
    ('self-evolution-policy
     (list
      (cons 'spec-evolution-reviews
            (poo-flow-user-loop-engine-intent-ref
             intent
             'spec-evolution-reviews
             '()))
      (cons 'require-failure-observation-receipt #t)
      (cons 'require-root-cause-receipt #t)
      (cons 'require-intervention-receipt #t)
      (cons 'require-progress-receipt #t)
      (cons 'allow-policy-update #f)))
    ('projection-policy
     '((privacy-class . public-safe-projection)
       (public-private-check . projection-boundary)
       (runtime-executed . #f)))
    ('privacy-class 'public-safe-projection)
    ('diagnostics '())
    ('runtime-executed? #f)
    ('runtime-executed #f))))

;; poo-flow-user-loop-engine-intent-runtime-action-kind
;; : (-> Alist Symbol)
;; | doc m%
;;   Choose the inert runtime action kind from declared human audit policy.
;;   # Examples
;;   ```scheme
;;   (poo-flow-user-loop-engine-intent-runtime-action-kind intent)
;;   ;; => run or ask-owner
;;   ```
;;; Action packets are executable intent, not execution. They make gate and
;;; readiness outcomes explicit before Marlin receives the request.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-runtime-action-packet
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (action-kind
     (poo-flow-user-loop-engine-intent-runtime-action-kind intent))
    (sandbox-agreement
     (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement intent))))
  (fields
   (('kind 'runtime-action-packet)
    ('contract
     +poo-flow-user-loop-engine-runtime-action-packet-contract+)
    ('packet-id
     (poo-flow-user-loop-engine-runtime-id use-case-name "action-packet"))
    ('request-id
     (poo-flow-user-loop-engine-runtime-id use-case-name "request"))
    ('profile-id
     (poo-flow-user-loop-engine-runtime-id use-case-name
                                           "policy-profile"))
    ('policy-epoch
     (poo-flow-user-loop-engine-runtime-id use-case-name
                                           "policy-epoch"))
    ('action-kind action-kind)
    ('graph-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "graph"))
    ('policy-scope use-case-name)
    ('root-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "root"))
    ('candidate-refs
     (poo-flow-user-loop-engine-use-case-names intent))
    ('gate-state
     (list
      (cons 'status
            (poo-flow-user-loop-engine-intent-status intent))
      (cons 'human-audit
            (poo-flow-user-loop-engine-intent-ref
             intent
             'human-audit
             '()))
      (cons 'sandbox-handoff-ready?
            (poo-flow-user-loop-engine-intent-ref
             sandbox-agreement
             'handoff-ready?
             #f))))
    ('required-capabilities
     (poo-flow-user-loop-engine-intent-ref
      (poo-flow-user-loop-engine-intent-ref
       intent
       'capability-policy
       '())
      'required
      '()))
    ('readiness-requirements
     (list
      (list
       (cons 'kind 'runtime-abi-readiness-requirement)
       (cons 'abi-id 'poo-flow.loop-engine.runtime-pressure-relief)
       (cons 'abi-version 1)
       (cons 'required-symbols '())
       (cons 'runtime-executed #f))))
    ('readiness-receipts
     (list
      (list
       (cons 'kind 'runtime-abi-readiness-receipt)
       (cons 'abi-id 'poo-flow.loop-engine.runtime-pressure-relief)
       (cons 'abi-version 1)
       (cons 'required-symbol-count 0)
       (cons 'available-symbol-count 0)
       (cons 'matched-symbol-count 0)
       (cons 'missing-symbols '())
       (cons 'status 'ready)
       (cons 'runtime-executed #f))))
    ('evidence-refs
     '(lineage-receipt selector-receipt resource-dispatch-receipt
       capability-receipt memory-receipt compression-receipt))
    ('idempotency-key
     (poo-flow-user-loop-engine-runtime-id use-case-name "idempotency"))
    ('watermark
     (poo-flow-user-loop-engine-runtime-id use-case-name "watermark"))
    ('lease-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "lease"))
    ('conflict-policy 'diagnostic-first)
    ('budget-ref
     (poo-flow-user-loop-engine-intent-ref intent 'budget '()))
    ('privacy-class 'public-safe-projection)
    ('fallback-policy
     (poo-flow-user-loop-engine-intent-ref
      (poo-flow-user-loop-engine-intent-ref intent 'selector-policy '())
      'fallback
      #f))
    ('diagnostics '())
    ('runtime-executed? #f)
    ('runtime-executed #f))))

;;; Receipt batches are templates until a runtime-owned receipt reports actual
;;; execution. Scheme keeps accepted/rejected packet ids empty.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-runtime-receipt-batch-template
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))))
  (fields
   (('kind 'runtime-receipt-batch)
    ('contract
     +poo-flow-user-loop-engine-runtime-receipt-batch-contract+)
    ('runtime-id "marlin-agent-core")
    ('batch-id
     (poo-flow-user-loop-engine-runtime-id use-case-name "receipt-batch"))
    ('received-packet-ids '())
    ('accepted-packet-ids '())
    ('rejected-packet-ids '())
    ('action-receipts '())
    ('capability-receipts '())
    ('readiness-receipts '())
    ('lease-receipts '())
    ('telemetry-refs '())
    ('watermark
     (poo-flow-user-loop-engine-runtime-id use-case-name "watermark"))
    ('status 'not-executed)
    ('diagnostics '())
    ('runtime-executed? #f)
    ('runtime-executed #f))))

;;; Runtime envelopes are the largest loop-engine handoff object. They carry
;;; workflow, sandbox, and operation facts as inert request data for Marlin.
;; poo-flow-user-loop-engine-intent-runtime-envelope
;; : (-> Alist Alist)
;; | doc m%
;;   Build the Marlin-owned loop-engine runtime request envelope.
;;   # Examples
;;   ```scheme
;;   (poo-flow-user-loop-engine-intent-runtime-envelope intent)
;;   ;; => runtime request alist
;;   ```
;;; The command manifest is inert stdout adapter data; it serializes the whole
;;; loop-engine envelope without launching Marlin from Scheme.
;; poo-flow-user-loop-engine-intent-runtime-command-manifest
;; : (-> Alist Alist)
;; | doc m%
;;   Serialize the loop-engine envelope as a runtime command manifest.
;;   # Examples
;;   ```scheme
;;   (poo-flow-user-loop-engine-intent-runtime-command-manifest intent)
;;   ;; => runtime command manifest alist
;;   ```
;;; Summaries keep presentation tables small while retaining the descriptor ids
;;; that let agents correlate the full manifest when needed.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
  (intent)
  (bindings
   ((manifest
     (poo-flow-user-loop-engine-intent-runtime-command-manifest intent))))
  (fields
   (('kind 'runtime-command-manifest-summary)
    ('contract +poo-flow-user-loop-engine-runtime-command-contract+)
    ('schema
     (poo-flow-user-loop-engine-intent-ref manifest 'schema #f))
    ('request-schema
     (poo-flow-user-loop-engine-intent-ref manifest 'request-schema #f))
    ('operation
     (poo-flow-user-loop-engine-intent-ref manifest 'operation #f))
    ('request-id
     (poo-flow-user-loop-engine-intent-ref manifest 'request-id #f))
    ('artifact-handle
     (poo-flow-user-loop-engine-intent-ref manifest 'artifact-handle #f))
    ('runtime-owner "marlin-agent-core")
    ('object-families
     +poo-flow-user-loop-engine-runtime-object-families+)
    ('receipt-contracts
     +poo-flow-user-loop-engine-receipt-contracts+)
    ('runtime-packet-contracts
     +poo-flow-user-loop-engine-runtime-packet-contracts+)
    ('argv
     (poo-flow-user-loop-engine-intent-ref manifest 'argv '()))
    ('runtime-executed #f))))

;;; Proof manifests keep the Lean/AXLE boundary small: Scheme normalizes the
;;; user-interface configuration into named obligations, while Lean proves the
;;; obligations instead of modelling the whole Scheme runtime.
;; poo-flow-user-loop-engine-intent-proof-manifest
;; : (-> Alist Alist)
;; | doc m%
;;   Project runtime command manifest identity into loop-engine proof obligations.
;;   # Examples
;;   ```scheme
;;   (poo-flow-user-loop-engine-intent-proof-manifest intent)
;;   ;; => proof manifest alist
;;   ```
;;; Runtime snapshots expose the sandbox agreement as the handoff readiness
;;; source of truth. This prevents a loop from looking ready when a sandbox
;;; profile is unresolved or only available as an invalid runtime summary.
;; poo-flow-user-loop-engine-intent-runtime-snapshot
;; : (-> Alist Alist)
;; | doc m%
;;   Build the bounded runtime snapshot used by presentation and handoff gates.
;;   # Examples
;;   ```scheme
;;   (poo-flow-user-loop-engine-intent-runtime-snapshot intent)
;;   ;; => runtime snapshot alist
;;   ```
;;; Lineage receipts are OpenRath-inspired session facts. They make parent
;;; session refs and lineage export intent visible before Marlin runs anything.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-lineage-receipt
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (lineage-policy
     (poo-flow-user-loop-engine-intent-ref intent 'lineage-policy '()))))
  (fields
   (('kind 'lineage-receipt)
    ('contract 'poo-flow.loop-engine.lineage-receipt.v1)
    ('session-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
    ('parent-session-refs
     (poo-flow-user-loop-engine-intent-ref
      lineage-policy
      'parent-session-refs
      '()))
    ('lineage-kind
     (poo-flow-user-loop-engine-intent-ref
      lineage-policy
      'lineage-kind
      'loop-root))
    ('lineage-operator
     (poo-flow-user-loop-engine-intent-ref
      lineage-policy
      'lineage-operator
      'loop-engine-profile))
    ('journal
     (poo-flow-user-loop-engine-intent-ref
      lineage-policy
      'journal
      'report-only))
    ('export
     (poo-flow-user-loop-engine-intent-ref lineage-policy 'export 'jsonl))
    ('policy lineage-policy)
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;;; Selector receipts keep branch choice report-only. Candidate scoring and
;;; routing remain runtime work for Marlin or a model-backed executor.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-selector-receipt
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (selector-policy
     (poo-flow-user-loop-engine-intent-ref intent 'selector-policy '()))
    (selected-branch
     (poo-flow-user-loop-engine-intent-ref
      selector-policy
      'selected-branch
      #f))))
  (fields
   (('kind 'selector-receipt)
    ('contract 'poo-flow.loop-engine.selector-receipt.v1)
    ('session-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
    ('candidates
     (poo-flow-user-loop-engine-intent-ref
      selector-policy
      'candidates
      (poo-flow-user-loop-engine-use-case-names intent)))
    ('judge-inputs
     (poo-flow-user-loop-engine-intent-ref
      selector-policy
      'judge-inputs
      '()))
    ('fallback
     (poo-flow-user-loop-engine-intent-ref selector-policy 'fallback #f))
    ('selected-branch
     (if selected-branch selected-branch use-case-name))
    ('policy selector-policy)
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;;; Resource dispatch receipts project OpenRath-style resource-key collision
;;; facts. They do not schedule or run tool calls in Scheme.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-resource-dispatch-receipt
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (resource-policy
     (poo-flow-user-loop-engine-intent-ref intent 'resource-policy '()))))
  (fields
   (('kind 'resource-dispatch-receipt)
    ('contract 'poo-flow.loop-engine.resource-dispatch-receipt.v1)
    ('dispatch-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "dispatch"))
    ('tool-refs
     (poo-flow-user-loop-engine-intent-ref resource-policy 'tool-refs '()))
    ('resource-keys
     (poo-flow-user-loop-engine-intent-ref
      resource-policy
      'resource-keys
      '()))
    ('collision-classes
     (poo-flow-user-loop-engine-intent-ref
      resource-policy
      'collision-classes
      '()))
    ('dispatch-groups
     (poo-flow-user-loop-engine-intent-ref
      resource-policy
      'dispatch-groups
      '()))
    ('policy resource-policy)
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;;; Memory receipts declare recall and commit policy without reading, ranking,
;;; writing, or retaining memory in Scheme. Marlin owns the memory store.
;; : (-> [Alist] Symbol Alist)
(import :poo-flow/src/module-system/loop-engine-runtime-projection)

;; : (-> [Alist] [Symbol] [Symbol])
;; : (-> [Alist] [Symbol])
;;; Memory receipt binds the selected use-case to one declared policy and leaves
;;; recall, commit, retention, and store mutation to the Marlin execution layer.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-memory-receipt
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (memory-policies
     (poo-flow-user-loop-engine-intent-ref intent 'memory-policies '()))
    (memory-policy
     (poo-flow-user-loop-engine-memory-policy-for-use-case
      memory-policies
      use-case-name))))
  (fields
   (('kind 'memory-receipt)
    ('contract 'poo-flow.loop-engine.memory-receipt.v1)
    ('selected-use-case use-case-name)
    ('policy-count (length memory-policies))
    ('available-use-cases
     (poo-flow-user-loop-engine-memory-policy-use-cases memory-policies))
    ('selected-policy-found? (not (null? memory-policy)))
    ('use-case
     (poo-flow-user-loop-engine-intent-ref memory-policy 'use-case #f))
    ('store
     (poo-flow-user-loop-engine-intent-ref memory-policy 'store #f))
    ('state-path
     (poo-flow-user-loop-engine-intent-ref memory-policy 'state-path #f))
    ('scope
     (poo-flow-user-loop-engine-intent-ref memory-policy 'scope #f))
    ('recall
     (poo-flow-user-loop-engine-intent-ref memory-policy 'recall '()))
    ('commit
     (poo-flow-user-loop-engine-intent-ref memory-policy 'commit '()))
    ('ranking
     (poo-flow-user-loop-engine-intent-ref memory-policy 'ranking #f))
    ('retention
     (poo-flow-user-loop-engine-intent-ref
      memory-policy
      'retention
      'report-only))
    ('policy memory-policy)
    ('policies memory-policies)
    ('session-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;;; Compression receipts describe the handoff shape for transcript/session
;;; compaction. Scheme never summarizes, mutates, or creates sessions here.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-compression-receipt
  (intent)
  (bindings
   ((use-case-name
     (poo-flow-user-loop-engine-intent-use-case-name intent))
    (compression-policy
     (poo-flow-user-loop-engine-intent-ref
      intent
      'compression-policy
      '()))))
  (fields
   (('kind 'compression-receipt)
    ('contract 'poo-flow.loop-engine.compression-receipt.v1)
    ('strategy
     (poo-flow-user-loop-engine-intent-ref compression-policy 'strategy #f))
    ('trigger
     (poo-flow-user-loop-engine-intent-ref compression-policy 'trigger #f))
    ('summary-format
     (poo-flow-user-loop-engine-intent-ref
      compression-policy
      'summary-format
      #f))
    ('lineage-kind
     (poo-flow-user-loop-engine-intent-ref
      compression-policy
      'lineage-kind
      'compressed-session))
    ('retention
     (poo-flow-user-loop-engine-intent-ref
      compression-policy
      'retention
      'report-only))
    ('policy compression-policy)
    ('source-session-ref
     (poo-flow-user-loop-engine-runtime-id use-case-name "session"))
    ('compressed-session-ref
     (poo-flow-user-loop-engine-runtime-id
      use-case-name
      "compressed-session"))
    ('runtime-owner "marlin-agent-core")
    ('runtime-executed #f))))

;;; Handoff facts are the single report row tying loop-engine policy,
;;; workflow-run projections, sandbox evidence, and runtime command manifests.
;; : (-> Alist Alist)
(defpoo-runtime-receipt-projection
  poo-flow-user-loop-engine-intent-runtime-handoff-facts
  (intent)
  (bindings
   ((runtime-handoff
     (poo-flow-user-loop-engine-intent-ref
      intent
      'runtime-handoff
      'loop-governor-marlin-runtime-manifest))
    (capability-receipt
     (poo-flow-user-loop-engine-capability-receipt->alist
      (poo-flow-user-loop-engine-intent-capability-receipt intent)))))
  (fields
   (('kind 'loop-engine-runtime-handoff)
    ('contract 'poo-flow.loop-governor.runtime-handoff.v1)
    ('runtime-owner "marlin-agent-core")
    ('runtime-handoff runtime-handoff)
    ('handoff-contracts +poo-flow-user-loop-engine-handoff-contracts+)
    ('runtime-command-contract
     +poo-flow-user-loop-engine-runtime-command-contract+)
    ('object-families
     +poo-flow-user-loop-engine-runtime-object-families+)
    ('receipt-contracts
     +poo-flow-user-loop-engine-receipt-contracts+)
    ('runtime-packet-contracts
     +poo-flow-user-loop-engine-runtime-packet-contracts+)
    ('runtime-capability-descriptor
     (poo-flow-user-loop-engine-intent-runtime-capability-descriptor
      intent))
    ('policy-profile-packet
     (poo-flow-user-loop-engine-intent-policy-profile-packet intent))
    ('runtime-action-packets
     (list (poo-flow-user-loop-engine-intent-runtime-action-packet intent)))
    ('runtime-receipt-batch-template
     (poo-flow-user-loop-engine-intent-runtime-receipt-batch-template
      intent))
    ('workflow-ref
     (poo-flow-user-loop-engine-intent-workflow-ref intent))
    ('workflow-agreement
     (poo-flow-user-loop-engine-intent-workflow-agreement intent))
    ('result-contract
     (poo-flow-user-loop-engine-intent-result-contract intent))
    ('agent-profiles
     (poo-flow-user-loop-engine-intent-agent-profiles intent))
    ('agent-harnesses
     (poo-flow-user-loop-engine-intent-agent-harnesses intent))
    ('agent-sessions
     (poo-flow-user-loop-engine-intent-agent-sessions intent))
    ('session-agent-graph
     (poo-flow-user-loop-engine-intent-session-agent-graph intent))
    ('session-agent-topology-trace
     (poo-flow-user-loop-engine-intent-session-agent-topology-trace
      intent))
    ('lineage-receipt
     (poo-flow-user-loop-engine-intent-lineage-receipt intent))
    ('selector-receipt
     (poo-flow-user-loop-engine-intent-selector-receipt intent))
    ('resource-dispatch-receipt
     (poo-flow-user-loop-engine-intent-resource-dispatch-receipt
      intent))
    ('capability-receipt capability-receipt)
    ('memory-receipt
     (poo-flow-user-loop-engine-intent-memory-receipt intent))
    ('compression-receipt
     (poo-flow-user-loop-engine-intent-compression-receipt intent))
    ('session-selector-receipts
     (poo-flow-user-loop-engine-intent-ref
      intent
      'session-selector-receipts
      '()))
    ('session-materialization-receipts
     (poo-flow-user-loop-engine-intent-ref
      intent
      'session-materialization-receipts
      '()))
    ('policy-extension-receipts
     (poo-flow-user-loop-engine-intent-ref
      intent
      'policy-extension-receipts
      '()))
    ('spec-evolution-reviews
     (poo-flow-user-loop-engine-intent-ref
      intent
      'spec-evolution-reviews
      '()))
    ('spec-evolution-human-audit-review-items
     (poo-flow-user-loop-engine-intent-ref
      intent
      'spec-evolution-human-audit-review-items
      '()))
    ('spec-evolution-runtime-manifest-rows
     (poo-flow-user-loop-engine-intent-ref
      intent
      'spec-evolution-runtime-manifest-rows
      '()))
    ('runtime-command-manifest
     (poo-flow-user-loop-engine-intent-runtime-command-manifest intent))
    ('runtime-command-manifest-summary
     (poo-flow-user-loop-engine-intent-runtime-command-manifest-summary
      intent))
    ('proof-manifest
     (poo-flow-user-loop-engine-intent-proof-manifest intent))
    ('sandbox
     (poo-flow-user-loop-engine-intent-ref intent 'sandbox '()))
    ('sandbox-profile-refs
     (poo-flow-user-loop-engine-intent-ref
      intent
      'sandbox-profile-refs
      '()))
    ('sandbox-runtime-summaries
     (poo-flow-user-loop-engine-intent-ref
      intent
      'sandbox-runtime-summaries
      '()))
    ('sandbox-handoff-summaries
     (poo-flow-user-loop-engine-intent-ref
      intent
      'sandbox-handoff-summaries
      '()))
    ('sandbox-handoff-agreement
     (poo-flow-user-loop-engine-intent-sandbox-handoff-agreement
      intent))
    ('sandbox-unresolved-profile-refs
     (poo-flow-user-loop-engine-intent-ref
      intent
      'sandbox-unresolved-profile-refs
      '()))
    ('lineage-policy
     (poo-flow-user-loop-engine-intent-ref intent 'lineage-policy '()))
    ('selector-policy
     (poo-flow-user-loop-engine-intent-ref intent 'selector-policy '()))
    ('resource-policy
     (poo-flow-user-loop-engine-intent-ref intent 'resource-policy '()))
    ('capability-policy
     (poo-flow-user-loop-engine-intent-ref
      intent
      'capability-policy
      '()))
    ('memory-policies
     (poo-flow-user-loop-engine-intent-ref
      intent
      'memory-policies
      '()))
    ('compression-policy
     (poo-flow-user-loop-engine-intent-ref
      intent
      'compression-policy
      '()))
    ('runtime
     (poo-flow-user-loop-engine-intent-ref intent 'runtime '()))
    ('descriptor-realized? #f)
    ('runtime-executed #f))))

;;; Runtime projections are the bundled receipt surface for one loop intent.
;;; Keeping these rows together prevents presentation code from recomputing
;;; workflow, dispatch, operation, manifest, and snapshot facts independently.
;; : (-> Alist Alist)
;;; Presentation modules use this extractor to expose repeated loop-engine
;;; slots without learning the shape of each runtime projection row.
;; : (-> [Alist] Symbol [Value])
;;; Loop-engine intents are the workflow-facing surface for configuring the
;;; governor node graph from init.ss. The result is report-only contract data.
;; : (-> PooUserModuleSelection Boolean)
;;; Boundary: user loop engine context profile catalog is the policy-visible
;;; edge for module-system, loop behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> [Value] [PooSandboxProfile])
;;; Boundary: user loop engine context workflow check maps is the policy-
;;; visible edge for module-system, loop behavior, keeping validation, lookup,
;;; or projection responsibilities centralized for callers.
;; : (-> [Value] [PooFlowCicdCheckMap])
;;; Boundary: user loop engine context backend capability registry is the
;;; static OpenRath-style capability vocabulary selected by enabled modules.
;; : (-> [Value] PooSandboxBackendCapabilityRegistry)
;; : (-> PooUserModuleSelection Alist Alist)
;; : (-> Alist [PooSandboxProfile] [PooFlowCicdCheckMap] PooSandboxBackendCapabilityRegistry Alist)
;; : (-> PooUserModuleSelection [PooSandboxProfile] MaybeAlist)
;;; Loop engine intents are collected with a recursive add/fold shape so module
;;; selection order becomes the handoff order for later runtime descriptors.
;; : (-> [PooUserModuleSelection] [PooSandboxProfile] [PooFlowCicdCheckMap] [Alist])
;; : (-> (-> PooUserModuleSelection MaybeAlist) [PooUserModuleSelection] [Alist] [Alist])
;; : (-> (-> PooUserModuleSelection MaybeAlist) [PooUserModuleSelection] [Alist])
;; : (-> PooUserModuleSelection [PooSandboxProfile] [PooFlowCicdCheckMap] MaybeAlist)
;;; Config-level loop-engine intents let workflow docs and tests show the real
;;; governor configuration result from `:workflow` without starting a loop.
;; : (-> PooUserConfig [Alist])
