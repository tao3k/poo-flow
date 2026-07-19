(import :clan/poo/object
        :poo-flow/src/build-api/process-memory-guard)

(def +default-max-rss-bytes+ (* 1024 1024 1024))
(def +default-timeout-seconds+ 120)

(def (environment-positive-number name default-value)
  (let* ((raw (getenv name))
         (value (and raw (string->number raw))))
    (if (and value (> value 0)) value default-value)))

(def (required-environment name)
  (let (value (getenv name))
    (unless (and value (> (string-length value) 0))
      (error "Bundle v1 benchmark guard environment is required" name))
    value))

(def (run-guard)
  (let* ((gxi (required-environment "POO_FLOW_BUNDLE_V1_GXI"))
         (benchmark
          (required-environment "POO_FLOW_BUNDLE_V1_BENCHMARK"))
         (max-rss
          (environment-positive-number
           "POO_FLOW_BUNDLE_V1_MAX_RSS_BYTES"
           +default-max-rss-bytes+))
         (timeout
          (environment-positive-number
           "POO_FLOW_BUNDLE_V1_TIMEOUT_SECONDS"
           +default-timeout-seconds+))
         (receipt
          (poo-flow-process-memory-guard-run
           'bundle-v1-foreign-arena-benchmark
           max-rss
           timeout
           (list gxi benchmark))))
    (display "POO_FLOW_BUILD_GUARD_RECEIPT ")
    (write (poo-flow-process-memory-guard-receipt->alist receipt))
    (newline)
    (exit (.ref receipt 'exit-code))))

(run-guard)
