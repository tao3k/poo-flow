(import (only-in :clan/poo/object .o)
        :poo-flow/src/module-system/loop-engine-session-agent-graph
        :poo-flow/src/modules/session/objects-handoff)

(def (fact-ref facts key)
  (let ((cell (assq key facts)))
    (and cell (cdr cell))))

(def (check-equal! actual expected label)
  (unless (equal? actual expected)
    (error "check failed" label actual expected)))

(def (check-lean-fact-contract! contracts facts label)
  (check-equal!
   (poo-flow-lean-fact-contract-complete? contracts facts)
   #t
   label))

(def (check-static-handoff-boundary!)
  (let* ((handoff
          (.o kind: 'poo-flow.session.handoff
              schema: 'poo-flow.session.handoff.v1
              source: 'poo-flow-session-presentation
              session-id: "session-1"
              chunk-count: 2
              placement-profile-ref: "profile/default"
              placement-resolved?: #t
              placement-diagnostics: '()
              runtime-owner: "marlin-agent-core"
              handoff-required: #t
              runtime-executed: #f
              runtime-parses-scheme-source: #f
              scheme-manufactures-runtime-handlers: #f
              metadata: (poo-flow-session-topology->handoff-metadata
                         (.o agent-registered?: #t
                             subagent-registered?: #t
                             channel-authorized?: #t))))
         (facts (poo-flow-session-handoff->lean-facts handoff)))
    (check-lean-fact-contract!
     poo-flow-session-handoff-lean-fact-key-contracts
     facts
     'session-handoff-lean-fact-contract)
    (check-equal!
     (fact-ref facts 'session.lifecycle/chunk-present)
     #t
     'chunk-present)
    (check-equal!
     (fact-ref facts 'session.lifecycle/placement-resolved)
     #t
     'placement-resolved)
    (check-equal!
     (fact-ref facts 'session.lifecycle/placement-missing-profile)
     #f
     'placement-missing-profile)
    (check-equal!
     (fact-ref facts 'session.lifecycle/runtime-summary-present)
     #t
     'runtime-summary-present)
    (check-equal!
     (fact-ref facts 'session.lifecycle/handoff-receipt-present)
     #t
     'handoff-receipt-present)
    (check-equal!
     (fact-ref facts 'session.lifecycle/runtime-executed-false)
     #t
     'runtime-executed-false)
    (check-equal!
     (fact-ref facts 'session.lifecycle/handoff-required-true)
     #t
     'handoff-required-true)
    (check-equal!
     (fact-ref facts 'session.lifecycle/runtime-owner-marlin)
     #t
     'runtime-owner-marlin)
    (check-equal!
     (fact-ref facts 'session.lifecycle/runtime-parses-scheme-source-false)
     #t
     'runtime-parses-scheme-source-false)
    (check-equal!
     (fact-ref facts 'session.lifecycle/scheme-manufactures-runtime-handlers-false)
     #t
     'scheme-manufactures-runtime-handlers-false)
    (check-equal!
     (fact-ref facts 'scenario.bridge/s3-handoff-receipt)
     #t
     'scenario-bridge-s3-handoff-receipt)
    (check-equal!
     (fact-ref facts 'scenario.bridge/s11-agent-registered)
     #t
     'scenario-bridge-s11-agent-registered)
    (check-equal!
     (fact-ref facts 'scenario.bridge/s11-subagent-registered)
     #t
     'scenario-bridge-s11-subagent-registered)
    (check-equal!
     (fact-ref facts 'scenario.bridge/s11-channel-authorized)
     #t
     'scenario-bridge-s11-channel-authorized)
    (check-equal!
     (fact-ref facts 'scenario.bridge/s14-placement-missing-profile)
     #f
     'scenario-bridge-s14-placement-missing-profile)))

(def (check-missing-profile-diagnostics!)
  (let* ((handoff
          (.o kind: 'poo-flow.session.handoff
              schema: 'poo-flow.session.handoff.v1
              source: 'poo-flow-session-presentation
              session-id: "session-2"
              chunk-count: 1
              placement-profile-ref: #f
              placement-resolved?: #f
              placement-diagnostics: '(missing-profile)
              runtime-owner: "marlin-agent-core"
              handoff-required: #t
              runtime-executed: #f
              runtime-parses-scheme-source: #f
              scheme-manufactures-runtime-handlers: #f
              metadata: '()))
         (facts (poo-flow-session-handoff->lean-facts handoff)))
    (check-lean-fact-contract!
     poo-flow-session-handoff-lean-fact-key-contracts
     facts
     'missing-profile-lean-fact-contract)
    (check-equal!
     (fact-ref facts 'session.lifecycle/placement-resolved)
     #f
     'missing-profile-placement-resolved)
    (check-equal!
     (fact-ref facts 'session.lifecycle/placement-missing-profile)
     #t
     'missing-profile-diagnostic)
    (check-equal!
     (fact-ref facts 'scenario.bridge/s14-placement-missing-profile)
     #t
     'scenario-bridge-missing-profile)))

(def (check-topology-channel-denial!)
  (let* ((handoff
          (.o kind: 'poo-flow.session.handoff
              schema: 'poo-flow.session.handoff.v1
              source: 'poo-flow-session-presentation
              session-id: "session-3"
              chunk-count: 1
              placement-profile-ref: "profile/default"
              placement-resolved?: #t
              placement-diagnostics: '()
              runtime-owner: "marlin-agent-core"
              handoff-required: #t
              runtime-executed: #f
              runtime-parses-scheme-source: #f
              scheme-manufactures-runtime-handlers: #f
              metadata: (poo-flow-session-topology->handoff-metadata
                         (.o agent-registered?: #t
                             subagent-registered?: #t
                             channel-authorized?: #f))))
         (facts (poo-flow-session-handoff->lean-facts handoff)))
    (check-lean-fact-contract!
     poo-flow-session-handoff-lean-fact-key-contracts
     facts
     'topology-denial-lean-fact-contract)
    (check-equal!
     (fact-ref facts 'scenario.bridge/s11-agent-registered)
     #t
     'topology-denial-agent-registered)
    (check-equal!
     (fact-ref facts 'scenario.bridge/s11-subagent-registered)
     #t
     'topology-denial-subagent-registered)
    (check-equal!
     (fact-ref facts 'scenario.bridge/s11-channel-authorized)
     #f
     'topology-denial-channel-authorized)))

(def (check-ui-scenario-lean-facts!)
  (let* ((facts
          (poo-flow-ui-scenario->lean-facts
           (.o use-case-declared?: #t
               profile-declared?: #t
               governor-configured?: #t
               lineage-policy-done?: #t
               selector-policy-done?: #t
               resource-policy-done?: #t
               capability-policy-done?: #t
               memory-policy-done?: #t
               compression-policy-done?: #t
               strategy-plan-done?: #t
               local-validation-done?: #t
               runtime-manifest-done?: #t
               marlin-handoff-done?: #t
               l1-report-done?: #t
               scenario-matrix-done?: #t
               scenario-benchmark-done?: #t
               performance-fixture-bound?: #t))))
    (check-lean-fact-contract!
     poo-flow-ui-scenario-lean-fact-key-contracts
     facts
     'ui-scenario-lean-fact-contract)
    (check-equal!
     (fact-ref facts 'ui.scenario/strategy-plan-done)
     #t
     'ui-scenario-strategy-plan-done)
    (check-equal!
     (fact-ref facts 'ui.scenario/runtime-manifest-done)
     #t
     'ui-scenario-runtime-manifest-done)
    (check-equal!
     (fact-ref facts 'ui.scenario/scenario-benchmark-done)
     #t
     'ui-scenario-benchmark-done)
    (check-equal!
     (fact-ref facts 'ui.failure/runtime-manifest-missing-memory-policy)
     #f
     'ui-scenario-runtime-memory-not-missing)
    (check-equal!
     (fact-ref facts 'ui.failure/benchmark-missing-performance-fixture)
     #f
     'ui-scenario-fixture-not-missing)))

(def (check-ui-scenario-denial-lean-facts!)
  (let* ((facts
          (poo-flow-ui-scenario->lean-facts
           (.o use-case-declared?: #t
               profile-declared?: #t
               governor-configured?: #t
               lineage-policy-done?: #t
               selector-policy-done?: #f
               resource-policy-done?: #t
               capability-policy-done?: #t
               memory-policy-done?: #f
               compression-policy-done?: #f
               strategy-plan-done?: #f
               local-validation-done?: #f
               runtime-manifest-done?: #f
               marlin-handoff-done?: #f
               l1-report-done?: #f
               scenario-matrix-done?: #f
               scenario-benchmark-done?: #f
               performance-fixture-bound?: #f))))
    (check-lean-fact-contract!
     poo-flow-ui-scenario-lean-fact-key-contracts
     facts
     'ui-denial-lean-fact-contract)
    (check-equal!
     (fact-ref facts 'ui.scenario/selector-policy-done)
     #f
     'ui-denial-selector-policy-done)
    (check-equal!
     (fact-ref facts 'ui.failure/strategy-missing-selector-policy)
     #t
     'ui-denial-strategy-missing-selector)
    (check-equal!
     (fact-ref facts 'ui.failure/runtime-manifest-missing-memory-policy)
     #t
     'ui-denial-runtime-missing-memory)
    (check-equal!
     (fact-ref facts 'ui.failure/runtime-manifest-missing-compression-policy)
     #t
     'ui-denial-runtime-missing-compression)
    (check-equal!
     (fact-ref facts 'ui.failure/handoff-missing-runtime-manifest)
     #t
     'ui-denial-handoff-missing-runtime)
    (check-equal!
     (fact-ref facts 'ui.failure/benchmark-missing-performance-fixture)
     #t
     'ui-denial-benchmark-missing-fixture)))

(def (check-loop-engine-agent-graph-topology-metadata!)
  (let* ((graph
          (poo-flow-user-loop-engine-intent-session-agent-graph
           '((use-case . s11-agent-topology)
             (agent-judges . ((planner . planner-agent)
                              (builder . builder-agent))))))
         (metadata (fact-ref graph 'metadata)))
    (check-equal!
     (fact-ref metadata 'agent-registered)
     #t
     'loop-engine-agent-registered)
    (check-equal!
     (fact-ref metadata 'subagent-registered)
     #t
     'loop-engine-subagent-registered)
    (check-equal!
     (fact-ref metadata 'channel-authorized)
     #t
     'loop-engine-channel-authorized)
    (check-equal!
     (fact-ref graph 'communication-channel-receipt-count)
     2
     'loop-engine-channel-receipt-count)))

(check-static-handoff-boundary!)
(check-missing-profile-diagnostics!)
(check-topology-channel-denial!)
(check-ui-scenario-lean-facts!)
(check-ui-scenario-denial-lean-facts!)
(check-loop-engine-agent-graph-topology-metadata!)
