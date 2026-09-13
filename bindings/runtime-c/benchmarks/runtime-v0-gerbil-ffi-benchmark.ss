;;; Benchmark owner: this file isolates one conversion-heavy FFI control path
;;; so its receipt cannot be mistaken for the production payload data plane.

(import (only-in :std/foreign begin-ffi c-declare define-c-lambda)
        (only-in :std/iter for in-range))
(export main)

(begin-ffi (runtime-v0-status-name/native)
  (c-declare "#include \"poo_flow/runtime_v0.h\"")
  (define-c-lambda runtime-v0-status-name/native (unsigned-int) char-string
    "___return ((char*)poo_flow_runtime_v0_status_name(___arg1));"))

;;; Measurement boundary:
;;; - This executable measures the conversion-heavy control path only.
;;; - It does not claim a production payload fast path or a frozen ABI.
;; main
;;   : (-> [String] Void)
;;   | doc m%
;;       Run the fixed-size Gerbil FFI status-name conversion benchmark.
;;
;;       # Examples
;;
;;       ```scheme
;;       (main)
;;       ;; => writes a benchmark receipt and returns Void
;;       ```
;;     %
(def (main . _args)
  (let* ((iterations 100000)
         (started (real-time)))
    ;; The range iterator expands to the allocation-free specialized loop used
    ;; by this performance boundary; list materialization would pollute timing.
    (for (_ (in-range iterations))
      (unless (equal? (runtime-v0-status-name/native 0) "ok")
        (error "unexpected runtime v0 status name")))
    (let (elapsed (- (real-time) started))
      (display "schema=poo-flow.runtime-v0.gerbil-ffi-benchmark.1\n")
      (display "path=gerbil-char-string-control\n")
      (display "iterations=") (display iterations) (newline)
      (display "elapsed-seconds=") (display elapsed) (newline)
      (display "crossings=") (display iterations) (newline)
      (display "payload-zero-copy=false\n")
      (display "purpose=conversion-control-not-production-hot-path\n")
      (display "abi-v1-frozen=false\n"))))
