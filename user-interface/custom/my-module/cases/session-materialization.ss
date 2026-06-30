;;; -*- Gerbil -*-
;;; Boundary: downstream runtime materialization receipt case loaded by
;;; custom/my-module/config.ss.
;;; Invariant: this is runtime handoff data only; no synchronize, sandbox open,
;;; provider call, or IO replay happens in Scheme.

(let* ((pending
        (poo-flow-session-runtime-materialization-receipt
         'runtime/custom-build-request
         'custom/project
         'custom/root-session
         'custom/build-session
         '(custom/root-session custom/build-system)
         'pending
         'runtime/custom-build-future
         'sandbox/custom-build-handle
         '()
         #f
         '((source . user-interface)
           (case . session-materialization))))
       (failed
        (poo-flow-session-runtime-materialization-receipt
         'runtime/custom-audit-request
         'custom/project
         'custom/root-session
         'custom/audit-session
         '(custom/root-session custom/audit-system)
         'failed
         'runtime/custom-audit-future
         #f
         '()
         '((error-kind . RuntimeError)
           (message . "audit materialization failed before runtime handoff")
           (recoverable? . #f))
         '((source . user-interface)
           (case . session-materialization)))))
  (list (poo-flow-session-materialization-receipt->alist pending)
        (poo-flow-session-materialization-receipt->alist failed)))
