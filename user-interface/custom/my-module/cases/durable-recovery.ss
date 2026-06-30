;;; -*- Gerbil -*-
;;; Boundary: downstream durable recovery scenario case loaded by
;;; custom/my-module/config.ss.
;;; Invariant: this is crash/replay/repair handoff data only; Scheme does not
;;; replay event logs, claim leases, repair state, or run workflow commands.

(let* ((durable-policy
        (poo-flow-durable-policy
         'durable/custom-recovery
         'objects.shared.durable
         '((journal-owner . runtime/fact-log)
           (checkpoint-store . runtime/checkpoint-store)
           (resume-identity . session-id)
           (repair-mode . rebuild)
           (action-classes . (replayable idempotent compensatable)))))
       (runtime-store
        (poo-flow-durable-runtime-store-contract
         'runtime-store/custom-project
         'marlin-runtime-store
         durable-policy
         '((metadata . ((source . user-interface)
                        (case . durable-recovery))))))
       (runtime-store-receipt
        (poo-flow-durable-runtime-store-contract->receipt
         runtime-store
         '((project-id . custom/project)
           (root-session-id . custom/root-session)
           (session-id . custom/audit-session))))
       (memory-intent
        (poo-flow-session-memory-intent
         'memory/recovery-context
         'memory/durable-project
         'project
         '("last-40-turns")
         'review-only))
       (memory-job
        (poo-flow-memory-recall-job-receipt
         'memory-job/custom-recovery-context
         'custom/project
         'custom/root-session
         'custom/audit-session
         'agent/audit
         poo-flow-memory-core-default-catalog
         memory-intent
         (list (cons 'durable-policy durable-policy)
               (cons 'source-watermark 'turn/40)
               (cons 'target-watermark 'memory/index/40)
               (cons 'metadata '((source . user-interface)
                                 (case . durable-recovery))))))
       (session-graph-row
        '((kind . poo-flow.session.agent-graph)
          (project-id . custom/project)
          (root-session-ref . custom/root-session)
          (agent-ids . (agent/build agent/audit))
          (session-ids . (custom/root-session custom/build-session
                         custom/audit-session))
          (lineage-edge-pairs . ((custom/root-session . custom/build-session)
                                 (custom/root-session . custom/audit-session)))
          (runtime-executed . #f)))
       (communication-rows
        '(((kind . poo-flow.session.communication-receipt)
           (project-id . custom/project)
           (relation-kind . sibling)
           (source-session-id . custom/build-session)
           (target-session-id . custom/audit-session)
           (source-agent-id . agent/build)
           (target-agent-id . agent/audit)
           (channel-id . channel/build-audit)
           (valid? . #t)
           (runtime-executed . #f))))
       (workflow-task-rows
        '(((kind . poo-flow.workflow.cicd.check-receipt)
           (check . build)
           (durable-task-id . workflow/custom-build)
           (action-class . idempotent)
           (checkpoint-ref workflow-cicd-check build)
           (compensation-refs)
           (sandbox-refs agent/nono)
           (valid? . #t)
           (runtime-executed . #f))))
       (scenario
        (poo-flow-durable-recovery-scenario
         'recovery-scenario/custom-build-audit
         'custom/project
         'custom/root-session
         'custom/audit-session
         runtime-store-receipt
         session-graph-row
         communication-rows
         (poo-flow-memory-durable-job-receipts->alists (list memory-job))
         workflow-task-rows
         '(agent/nono)
         '((metadata . ((source . user-interface)
                        (case . durable-recovery)))))))
  (poo-flow-durable-recovery-scenario->alist scenario))
