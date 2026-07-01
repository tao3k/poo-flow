;;; -*- Gerbil -*-
;;; Boundary: downstream durable memory job case loaded by
;;; custom/my-module/config.ss.
;;; Invariant: this is durable job handoff data only; Scheme does not recall,
;;; commit, consolidate, persist, or repair memory stores.

(use-module session-core
  :config
  (session-case custom-session-memory-durable-case
    (metadata (source . user-interface)
              (case . session-memory-durable))
    (objects
     (durable-policy
      (poo-flow-durable-policy
       'durable/custom-memory
       'objects.shared.memory
       '((journal-owner . runtime/fact-log)
         (checkpoint-store . runtime/checkpoint-store)
         (resume-identity . session-id)
         (repair-mode . rebuild)
         (action-classes . (replayable idempotent compensatable)))))
     (parent-summary
      (session-memory-intent parent-summary
        (store memory/durable-project)
        (scope parent-summary)
        (recall parent-summary)
        (commit review-only)
        (metadata (source . user-interface)
                  (case . session-memory-durable))))
     (child-write-back
      (session-memory-intent child-write-back
        (store memory/durable-project)
        (scope current-session)
        (recall)
        (commit append)
        (metadata (source . user-interface)
                  (case . session-memory-durable))))
     (bounded-transcript
      (session-memory-intent bounded-transcript
        (store memory/durable-project)
        (scope project)
        (recall "last-40-turns")
        (commit review-only)
        (metadata (source . user-interface)
                  (case . session-memory-durable))))
     (durable-options
      (list (cons 'durable-policy durable-policy)
            (cons 'source-watermark 'turn/40)
            (cons 'target-watermark 'memory/index/40)
            (cons 'usage-counter 1)
            (cons 'metadata '((source . user-interface)
                              (case . session-memory-durable)))))
     (jobs
      (list
       (poo-flow-memory-recall-job-receipt
        'memory-job/custom-parent-summary
        'custom/project
        'custom/root-session
        'custom/audit-session
        'agent/audit
        poo-flow-memory-core-default-catalog
        parent-summary
        durable-options)
       (poo-flow-memory-write-job-receipt
        'memory-job/custom-child-write-back
        'custom/project
        'custom/root-session
        'custom/audit-session
        'agent/audit
        poo-flow-memory-core-default-catalog
        child-write-back
        durable-options)
       (poo-flow-memory-recall-job-receipt
        'memory-job/custom-bounded-transcript
        'custom/project
        'custom/root-session
        'custom/audit-session
        'agent/audit
        poo-flow-memory-core-default-catalog
        bounded-transcript
        durable-options)
       (poo-flow-memory-consolidation-job-receipt
        'memory-job/custom-consolidate
        'custom/project
        'custom/root-session
        'custom/audit-session
        #f
        poo-flow-memory-core-default-catalog
        bounded-transcript
        durable-options)
       (poo-flow-memory-stale-source-job-receipt
        'memory-job/custom-stale-source
        'custom/project
        'custom/root-session
        'custom/audit-session
        #f
        poo-flow-memory-core-default-catalog
        bounded-transcript
        (cons (cons 'stale-source? #t) durable-options))
       (poo-flow-memory-repair-job-receipt
        'memory-job/custom-repair
        'custom/project
        'custom/root-session
        'custom/audit-session
        #f
        poo-flow-memory-core-default-catalog
        bounded-transcript
        (cons (cons 'job-state 'repair-required) durable-options)))))
    (rows)
    (row-groups (poo-flow-memory-durable-job-receipts->alists jobs))))
