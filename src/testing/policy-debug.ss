;;; -*- Gerbil -*-
;;; Boundary: Harness policy diagnostics for the POO Flow package test surface.
;;; Invariant: this owner observes parser-backed findings and never changes them.

(import :gerbil/gambit
        (only-in :gslph/src/policy/gxtest-report
                 policy-report)
        (only-in :gslph/src/types/facade
                 type-finding-details
                 type-finding-path
                 type-finding-rule-id))

(export poo-flow-policy-debug-report!)

;;; Missing typed documentation and forall targets are compact enough for the
;;; normal receipt. Other policy rules retain their native diagnostic details.
;; : (-> Hash Value)
(def (poo-flow-policy-debug-targets details)
  (let ((missing-docs (hash-get details 'typedDocMissingTargets))
        (missing-foralls (hash-get details 'typedForallMissingTargets))
        (repair-targets (hash-get details 'repairTargets)))
    (if (or missing-docs missing-foralls)
      `((typedDocMissingTargets . ,missing-docs)
        (typedForallMissingTargets . ,missing-foralls))
      `((repairTargets . ,repair-targets)))))

;; : (-> TypeFinding Unit)
(def (poo-flow-policy-debug-finding! finding)
  (display "|poo-flow-policy-debug rule=")
  (display (type-finding-rule-id finding))
  (display " path=")
  (display (type-finding-path finding))
  (display " targets=")
  (write
   (poo-flow-policy-debug-targets
    (type-finding-details finding)))
  (newline))

;; : (-> [String] Integer)
(def (poo-flow-policy-debug-report! files)
  (let* ((report (policy-report "." files))
         (findings (or (hash-get report 'findings) '())))
    (for-each poo-flow-policy-debug-finding! findings)
    (force-output)
    (if (null? findings) 0 1)))
