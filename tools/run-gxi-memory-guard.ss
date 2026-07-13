;;; -*- Gerbil -*-
(import :gerbil/gambit
        :clan/poo/object
        :poo-flow/src/cli-support/process-memory-guard)

(def args (cddr (command-line)))
(unless (>= (length args) 3)
  (displayln "usage: gxi tools/run-gxi-memory-guard.ss MAX_RSS_MIB TIMEOUT_SECONDS TEST [ARG ...]")
  (exit 64))

(def max-rss-mib (string->number (car args)))
(def timeout-seconds (string->number (cadr args)))
(def test-file (caddr args))
(def receipt
  (poo-flow-process-memory-guard-run
   'gxi-test (* max-rss-mib 1024 1024) timeout-seconds
   (append (list "gxi" test-file) (cdddr args))))

(write (poo-flow-process-memory-guard-receipt->alist receipt))
(newline)
(exit (.ref receipt 'exit-code))
