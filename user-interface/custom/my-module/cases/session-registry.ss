;;; -*- Gerbil -*-
;;; Boundary: downstream session registry case loaded by
;;; custom/my-module/config.ss.
;;; Invariant: registry rows describe project/root/child address space only;
;;; Scheme does not retain live runtime state.

(let* ((root-session
        (poo-flow-session-value
         'custom/root-session
         (list (poo-flow-session-chunk
                'request
                'user
                "Coordinate build, audit, and release sessions."))
         (poo-flow-session-lineage 'custom/root-session '() 'root)
         (poo-flow-session-placement 'agent/nono)
         '((source . user-interface)
           (case . session-registry))))
       (build-session
        (poo-flow-session-value
         'custom/build-session
         (list (poo-flow-session-chunk
                'build
                'assistant
                "Run build verification."))
         (poo-flow-session-lineage
          'custom/build-session
          '(custom/root-session)
          'child-agent)
         (poo-flow-session-placement 'agent/nono)))
       (audit-session
        (poo-flow-session-value
         'custom/audit-session
         (list (poo-flow-session-chunk
                'audit
                'assistant
                "Audit build verification."))
         (poo-flow-session-lineage
          'custom/audit-session
          '(custom/root-session)
          'child-agent)
         (poo-flow-session-placement 'agent/nono)))
       (root-entry
        (poo-flow-session-registry-entry
         root-session
         'agent/root
         '(channel/root-build channel/audit-root)
         '((isolation . ((mode . root)))
           (durable . ((policy-id . durable/custom-project)
                       (valid? . #t))))
         '((source . user-interface)
           (case . session-registry))))
       (build-entry
        (poo-flow-session-registry-entry
         build-session
         'agent/build
         '(channel/build-root channel/build-audit)
         '((context . ((allowed-session-refs . (custom/root-session))))
           (history . ((allowed-records . (record/last-failure))))
           (sharing . ((project-workspace (access . read)
                                          (accounting . custom/root-session))))
           (resource . ((capability-refs . (project-workspace build-cache))))
           (durable . ((policy-id . durable/custom-project)
                       (valid? . #t))))))
       (audit-entry
        (poo-flow-session-registry-entry
         audit-session
         'agent/audit
         '(channel/build-audit channel/audit-root)
         '((context . ((allowed-session-refs . (custom/root-session
                                                custom/build-session))))
           (history . ((allowed-records . (record/last-failure))))
           (sharing . ((project-workspace (access . read)
                                          (accounting . custom/root-session))))
           (resource . ((capability-refs . (project-workspace))))
           (durable . ((policy-id . durable/custom-project)
                       (valid? . #t))))))
       (registry
        (poo-flow-session-registry-receipt
         'custom/project
         '(custom/root-session)
         '(custom/build-session custom/audit-session)
         'custom/root-session
         (list root-entry build-entry audit-entry)
         '((source . user-interface)
           (case . session-registry)))))
  registry)
