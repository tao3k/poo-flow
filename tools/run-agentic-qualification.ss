;;; -*- Gerbil -*-
(import :gerbil/gambit
        :clan/poo/object
        :poo-flow/src/qualification/runner)

(def args (cddr (command-line)))
(unless (= (length args) 2)
  (displayln "usage: gxi tools/run-agentic-qualification.ss MODE SOURCE_REVISION")
  (exit 64))

(def mode (string->symbol (car args)))
(def revision (cadr args))
(unless (memq mode '(focused release))
  (displayln "MODE must be focused or release")
  (exit 64))

(def registry (poo-flow-agentic-control-plane-gate-registry))
(def run (poo-flow-qualification-run registry revision mode))
(def verification (poo-flow-qualification-verify-run registry run))
(write (list (cons 'run (poo-flow-qualification-run-receipt->alist run))
             (cons 'verification
                   (poo-flow-qualification-verification-receipt->alist
                    verification))))
(newline)
(exit (if (.ref verification 'accepted?) 0 1))
