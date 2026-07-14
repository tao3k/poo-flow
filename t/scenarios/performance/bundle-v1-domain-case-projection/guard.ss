(import :clan/poo/object
        :poo-flow/src/build-api/process-memory-guard)

(def receipt
  (poo-flow-process-memory-guard-run
   "Bundle v1 Domain Case projection benchmark"
   (* 768 1024 1024)
   120
   (list
    "gxi"
    "t/scenarios/performance/bundle-v1-domain-case-projection/benchmark.ss")
   .05))

(display "POO_FLOW_BUNDLE_V1_PROJECTION_GUARD_RECEIPT ")
(write (poo-flow-process-memory-guard-receipt->alist receipt))
(newline)

(unless (= (.ref receipt 'exit-code) 0)
  (error "Bundle v1 Domain Case projection benchmark guard failed"
         (poo-flow-process-memory-guard-receipt->alist receipt)))
