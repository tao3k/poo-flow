;;; -*- Gerbil -*-
;;; Smoke file executed by `poo-flow run` for functional flow validation.

(import :poo-flow/src/core/api)

(def args (cddr (command-line)))
(def input (if (null? args) 3 (string->number (car args))))
(def runner (make-runner (make-local-eager-strategy)
                         (make-request-only-adapter)))
(def flow
  (flow-then 'cli-smoke
             (flow-arr 'inc (lambda (x) (+ x 1)) 'number 'number)
             (flow-arr 'double (lambda (x) (* x 2)) 'number 'number)))
(def result (runner-run runner flow input))

(display "poo-flow-run:")
(write (run-result-value result))
(newline)
