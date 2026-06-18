;;; -*- Gerbil -*-
;;; Boundary: C language tests prove the nono binding is compiler-visible.
;;; Invariant: the probe checks headers and signatures but never links or applies nono.

(import :std/test
        (only-in :std/misc/process run-process)
        :extensions/agent-sandbox-nono)

(export agent-sandbox-nono-c-language-test)

;;; The compile probe is deliberately syntax-only: success means C can consume
;;; our adapter header, nono's generated header, constants, structs, and
;;; function declarations without needing a platform sandbox or native link step.
;; String <- Unit
(def (run-nono-c-binding-compile-probe)
  (run-process '("sh" ".bin/check-nono-c-binding")
               stderr-redirection: #t))

(def agent-sandbox-nono-c-language-test
  (test-suite "nono C language binding"
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

(run-tests! agent-sandbox-nono-c-language-test)
