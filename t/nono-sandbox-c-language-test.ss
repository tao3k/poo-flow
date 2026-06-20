;;; -*- Gerbil -*-
;;; Boundary: C language tests prove the nono-sandbox binding is compiler-visible.
;;; Invariant: the probe checks headers and signatures but never links or applies nono.

(import (only-in :std/test
                 check
                 check-eq?
                 check-equal?
                 check-false
                 check-not-equal?
                 check-output
                 check-true
                 run-tests!
                 test-case
                 test-error
                 test-suite)
        (only-in :std/misc/process run-process)
        :poo-flow/src/modules/nono-sandbox/c-binding)

(export nono-sandbox-c-language-test)

;;; The compile probe is deliberately syntax-only: success means C can consume
;;; our adapter header, nono's generated header, constants, structs, and
;;; function declarations without needing a platform sandbox or native link step.
;; : (-> Unit String)
(def (run-nono-c-binding-compile-probe)
  (run-process (nono-c-binding-compile-probe-command)
               stderr-redirection: #t))

(def nono-sandbox-c-language-test
  (test-suite "nono-sandbox C language binding"
    (test-case "C compiler accepts POO Flow nono binding probe"
      (let* ((descriptor (make-nono-c-binding-descriptor))
             (contract (nono-c-binding-descriptor->contract descriptor)))
        (check-equal? (cdr (assoc 'adapter-header contract))
                      "poo_flow_nono_binding.h")
        (check-equal? (cdr (assoc 'adapter-include-ref contract))
                      "bindings/nono-c/poo_flow_nono_binding.h")
        (check-equal? (cdr (assoc 'probe-ref contract))
                      "bindings/nono-c/poo_flow_nono_binding_probe.c")
        (check-equal? (run-nono-c-binding-compile-probe) "")))))

(run-tests! nono-sandbox-c-language-test)
