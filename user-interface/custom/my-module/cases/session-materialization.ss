;;; -*- Gerbil -*-
;;; Boundary: downstream runtime materialization receipt case loaded by
;;; custom/my-module/config.ss.
;;; Invariant: this is runtime handoff data only; no synchronize, sandbox open,
;;; provider call, or IO replay happens in Scheme.

(use-module session-core
  :config
  (session-case custom-session-materialization-case
    (metadata (source . user-interface)
              (case . session-materialization))
    (objects
     (pending
      (session-materialization runtime/custom-build-request
        (project custom/project)
        (root custom/root-session)
        (session custom/build-session)
        (parents custom/root-session custom/build-system)
        (state pending)
        (pending-runtime runtime/custom-build-future)
        (sandbox-handle sandbox/custom-build-handle)
        (tokens)
        (error #f)
        (metadata (source . user-interface)
                  (case . session-materialization)
                  (declared-session-refs
                   . (custom/root-session
                      custom/build-session
                      custom/audit-session))
                  (declared-parent-session-refs
                   . (custom/root-session
                      custom/build-system
                      custom/audit-system))
                  (declared-sandbox-handle-refs
                   . (sandbox/custom-build-handle)))))
     (failed
      (session-materialization runtime/custom-audit-request
        (project custom/project)
        (root custom/root-session)
        (session custom/audit-session)
        (parents custom/root-session custom/audit-system)
        (state failed)
        (pending-runtime runtime/custom-audit-future)
        (sandbox-handle #f)
        (tokens)
        (error ((error-kind . RuntimeError)
                (message
                 . "audit materialization failed before runtime handoff")
                (recoverable? . #f)))
        (metadata (source . user-interface)
                  (case . session-materialization)
                  (declared-session-refs
                   . (custom/root-session
                      custom/build-session
                      custom/audit-session))
                  (declared-parent-session-refs
                   . (custom/root-session
                      custom/build-system
                      custom/audit-system))
                  (declared-sandbox-handle-refs
                   . (sandbox/custom-build-handle))))))
    (rows (session-materialization-row pending)
          (session-materialization-row failed))))
