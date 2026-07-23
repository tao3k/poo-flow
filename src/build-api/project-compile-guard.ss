;;; -*- Gerbil -*-
;;; Boundary: observe one canonical Building Framework project compile.

(export poo-flow-project-compile-guard-config
        poo-flow-project-compile-guarded!
        poo-flow-project-compile-receipt->alist
        poo-flow-project-compile-receipt->json-object
        poo-flow-project-compile-receipt->json-string)

(import :clan/poo/object
        :gerbil/gambit
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-trim-both)
        (only-in :std/text/json
                 json-object->string
                 write-json-sort-keys?)
        "../cli-support/project-build.ss"
        "./process-memory-guard.ss")

(import (only-in :gslph/src/building/std-builder
                 adaptive-execution-window-result?)
        (only-in :gslph/src/building/observability
                 build-adaptive-execution-windows->json-object
                 build-adaptive-execution-window-diagnostics->json-object))

(def +poo-flow-project-compile-guard-schema+
  'poo-flow.project-compile-guard.v1)

(def +poo-flow-project-compile-minimum-max-rss-bytes+
  (* 768 1024 1024))

(def +poo-flow-project-compile-default-memory-share-denominator+ 2)
(def +poo-flow-project-compile-default-sample-seconds+ 0.25)

(def (poo-flow-project-compile-positive-integer-from-env name fallback)
  (let* ((raw (getenv name #f))
         (value (and raw (string->number raw))))
    (if (and (exact-integer? value) (> value 0)) value fallback)))

(def (poo-flow-project-compile-optional-timeout-from-env name)
  (let* ((raw (getenv name #f))
         (value (and raw (string->number raw))))
    (cond
     ((not raw) #f)
     ((and (exact-integer? value) (= value 0)) #f)
     ((and (exact-integer? value) (> value 0)) value)
     (else
      (error "optional build timeout must be a non-negative integer"
             name raw)))))

(def (poo-flow-project-compile-real-from-env name fallback)
  (let* ((raw (getenv name #f))
         (value (and raw (string->number raw))))
    (if (and (real? value) (> value 0)) value fallback)))

(def (poo-flow-project-compile-command-positive-integer argv)
  (with-catch
   (lambda (_error) #f)
   (lambda ()
     (let (status 0)
       (let* ((output
               (run-process
                argv
                stderr-redirection: #t
                check-status:
                (lambda (exit-status _settings)
                  (set! status exit-status))))
              (value (string->number (string-trim-both output))))
         (and (= status 0)
              (exact-integer? value)
              (> value 0)
              value))))))

(def +poo-flow-project-compile-headroom-share-denominator+ 16)
(def +poo-flow-project-compile-runnable-limit-per-cpu+ 2)

(def (poo-flow-project-compile-logical-cpu-count)
  (poo-flow-project-compile-positive-integer-from-env
   "POO_FLOW_BUILD_LOGICAL_CPU_COUNT"
   (max 1 (##cpu-count))))

(def (poo-flow-project-compile-configured-worker-count
      logical-cpu-count)
  (min
   logical-cpu-count
   (or (poo-flow-project-compile-positive-integer-from-env
        "GERBIL_BUILD_CORES" #f)
       (poo-flow-project-compile-positive-integer-from-env
        "CARGO_BUILD_JOBS" #f)
       (poo-flow-project-compile-positive-integer-from-env
        "NUM_JOBS" #f)
       logical-cpu-count)))

(def (poo-flow-project-compile-runnable-process-count)
  (or (poo-flow-project-compile-positive-integer-from-env
       "POO_FLOW_BUILD_RUNNABLE_PROCESSES" #f)
      (poo-flow-project-compile-command-positive-integer
       (list
        "sh" "-c"
        "ps -axo state= 2>/dev/null | awk '$1 ~ /^R/ {n++} END {print n+0}'"))
      1))

(def (poo-flow-project-compile-darwin-available-memory-percent)
  (poo-flow-project-compile-command-positive-integer
   (list
    "sh" "-c"
    "if command -v memory_pressure >/dev/null 2>&1; then memory_pressure -Q 2>/dev/null | awk '/System-wide memory free percentage:/ {gsub(/%/, \"\", $NF); print $NF; exit}'; fi")))

(def (poo-flow-project-compile-linux-available-memory-bytes)
  (poo-flow-project-compile-command-positive-integer
   (list
    "sh" "-c"
    "if test -r /proc/meminfo; then awk '/^MemAvailable:/ {printf \"%.0f\\n\", $2 * 1024; exit}' /proc/meminfo; fi")))

(def (poo-flow-project-compile-available-memory-bytes system-memory-bytes)
  (or (poo-flow-project-compile-positive-integer-from-env
       "POO_FLOW_BUILD_AVAILABLE_MEMORY_BYTES" #f)
      (poo-flow-project-compile-linux-available-memory-bytes)
      (let (percent
            (poo-flow-project-compile-darwin-available-memory-percent))
        (and percent
             (quotient (* system-memory-bytes percent) 100)))
      system-memory-bytes))

(def (poo-flow-project-compile-default-rss-headroom-bytes
      system-memory-bytes)
  (max +poo-flow-project-compile-minimum-max-rss-bytes+
       (quotient
        system-memory-bytes
        +poo-flow-project-compile-headroom-share-denominator+)))

(def (poo-flow-project-compile-admission-advisories
      logical-cpu-count runnable-process-count)
  (if (> runnable-process-count
         (* logical-cpu-count
            +poo-flow-project-compile-runnable-limit-per-cpu+))
    '(runnable-saturation)
    '()))

(def (poo-flow-project-compile-admission-reasons
      available-memory-bytes rss-headroom-bytes
      baseline-rss-bytes requested-max-rss-bytes)
  (append
   (if (< available-memory-bytes
          (+ rss-headroom-bytes
             +poo-flow-project-compile-minimum-max-rss-bytes+))
     '(insufficient-memory-headroom)
     '())
   (if (<= requested-max-rss-bytes
           (+ baseline-rss-bytes
              +poo-flow-project-compile-minimum-max-rss-bytes+))
     '(insufficient-requested-rss-cap)
     '())))

(def (poo-flow-project-compile-system-memory-bytes)
  (or (poo-flow-project-compile-positive-integer-from-env
       "POO_FLOW_BUILD_SYSTEM_MEMORY_BYTES" #f)
      (poo-flow-project-compile-command-positive-integer
       (list "sysctl" "-n" "hw.memsize"))
      (let ((pages
             (poo-flow-project-compile-command-positive-integer
              (list "getconf" "_PHYS_PAGES")))
            (page-size
             (poo-flow-project-compile-command-positive-integer
              (list "getconf" "PAGE_SIZE"))))
        (and pages page-size (* pages page-size)))
      (* 8 +poo-flow-project-compile-minimum-max-rss-bytes+)))

(def (poo-flow-project-compile-adaptive-max-rss-bytes system-memory-bytes)
  (max +poo-flow-project-compile-minimum-max-rss-bytes+
       (quotient
        system-memory-bytes
        +poo-flow-project-compile-default-memory-share-denominator+)))

(def (poo-flow-project-compile-guard-config _options)
  (let* ((system-memory-bytes
          (poo-flow-project-compile-system-memory-bytes))
         (logical-cpu-count
          (poo-flow-project-compile-logical-cpu-count))
         (runnable-process-count
          (poo-flow-project-compile-runnable-process-count))
         (available-memory-bytes
          (poo-flow-project-compile-available-memory-bytes
           system-memory-bytes))
         (rss-headroom-bytes
          (poo-flow-project-compile-positive-integer-from-env
           "POO_FLOW_BUILD_RSS_HEADROOM_BYTES"
           (poo-flow-project-compile-default-rss-headroom-bytes
            system-memory-bytes)))
         (baseline-rss-bytes
          (poo-flow-project-compile-positive-integer-from-env
           "POO_FLOW_BUILD_BASELINE_RSS_BYTES"
           (max 1 (poo-flow-current-process-memory-bytes))))
         (allocatable-memory-bytes
          (max 1 (- available-memory-bytes
                    rss-headroom-bytes)))
         (requested-max-rss-bytes
          (poo-flow-project-compile-positive-integer-from-env
           "POO_FLOW_BUILD_MAX_RSS_BYTES"
           (poo-flow-project-compile-adaptive-max-rss-bytes
            system-memory-bytes)))
         (requested-allocatable-memory-bytes
          (max 0 (- requested-max-rss-bytes
                    baseline-rss-bytes)))
         (admitted-memory-bytes
          (min allocatable-memory-bytes
               requested-allocatable-memory-bytes))
         (max-rss-bytes
          (+ baseline-rss-bytes
             admitted-memory-bytes))
         (timeout-seconds
          (poo-flow-project-compile-optional-timeout-from-env
           "POO_FLOW_BUILD_TOTAL_TIMEOUT_SECONDS"))
         (sample-seconds
          (poo-flow-project-compile-real-from-env
           "POO_FLOW_BUILD_GUARD_SAMPLE_SECONDS"
           +poo-flow-project-compile-default-sample-seconds+))
         (configured-worker-count
          (poo-flow-project-compile-configured-worker-count
           logical-cpu-count))
         (memory-worker-capacity
          (max 1
               (quotient admitted-memory-bytes
                         +poo-flow-project-compile-minimum-max-rss-bytes+)))
         (runnable-worker-capacity
          (max 1
               (- (* logical-cpu-count 2)
                  runnable-process-count)))
         (worker-count
          (min configured-worker-count
               memory-worker-capacity
               runnable-worker-capacity))
         (admission-advisories
          (poo-flow-project-compile-admission-advisories
           logical-cpu-count
           runnable-process-count))
         (admission-reasons
          (poo-flow-project-compile-admission-reasons
           available-memory-bytes
           rss-headroom-bytes
           baseline-rss-bytes
           requested-max-rss-bytes))
         (admission-outcome
          (if (null? admission-reasons)
            'ready
            'blocked-host-pressure))
         (execution-policy 'adaptive)
         (request-labels (poo-flow-project-build-stage-labels)))
    (let ((request-labels-value request-labels)
          (execution-policy-value execution-policy)
          (logical-cpu-count-value logical-cpu-count)
          (runnable-process-count-value runnable-process-count)
          (available-memory-bytes-value available-memory-bytes)
          (rss-headroom-bytes-value rss-headroom-bytes)
          (baseline-rss-bytes-value baseline-rss-bytes)
          (allocatable-memory-bytes-value allocatable-memory-bytes)
          (requested-max-rss-bytes-value requested-max-rss-bytes)
          (admitted-memory-bytes-value admitted-memory-bytes)
          (configured-worker-count-value configured-worker-count)
          (memory-worker-capacity-value memory-worker-capacity)
          (runnable-worker-capacity-value runnable-worker-capacity)
          (worker-count-value worker-count)
          (admission-outcome-value admission-outcome)
          (admission-advisories-value admission-advisories)
          (admission-reasons-value admission-reasons)
          (system-memory-bytes-value system-memory-bytes)
          (max-rss-bytes-value max-rss-bytes)
          (timeout-seconds-value timeout-seconds)
          (sample-seconds-value sample-seconds))
      (.o (schema +poo-flow-project-compile-guard-schema+)
          (kind 'project-compile-guard-config)
          (build-owner 'gslph-building-framework)
          (build-mode 'standard-gerbil-make-project)
          (execution-policy execution-policy-value)
          (logical-cpu-count logical-cpu-count-value)
          (runnable-process-count runnable-process-count-value)
          (available-memory-bytes available-memory-bytes-value)
          (rss-headroom-bytes rss-headroom-bytes-value)
          (baseline-rss-bytes baseline-rss-bytes-value)
          (allocatable-memory-bytes allocatable-memory-bytes-value)
          (requested-max-rss-bytes requested-max-rss-bytes-value)
          (admitted-memory-bytes admitted-memory-bytes-value)
          (configured-worker-count configured-worker-count-value)
          (memory-worker-capacity memory-worker-capacity-value)
          (runnable-worker-capacity runnable-worker-capacity-value)
          (worker-count worker-count-value)
          (admission-outcome admission-outcome-value)
          (admission-advisories admission-advisories-value)
          (admission-reasons admission-reasons-value)
          (request-labels request-labels-value)
          (system-memory-bytes system-memory-bytes-value)
          (max-rss-bytes max-rss-bytes-value)
          (timeout-seconds timeout-seconds-value)
          (sample-seconds sample-seconds-value)))))

(def (poo-flow-project-compile-receipt->alist receipt)
  (map (lambda (slot) (cons slot (.ref receipt slot)))
       '(schema outcome build-owner build-mode execution-policy request-labels
                admission-outcome admission-advisories admission-reasons
                logical-cpu-count
                runnable-process-count available-memory-bytes
                rss-headroom-bytes baseline-rss-bytes
                allocatable-memory-bytes requested-max-rss-bytes
                admitted-memory-bytes configured-worker-count
                memory-worker-capacity runnable-worker-capacity worker-count
                system-memory-bytes max-rss-bytes peak-rss-bytes
                elapsed-ms timeout-ms)))

(def (poo-flow-project-compile-alist-ref rows key fallback)
  (let (entry (assq key rows))
    (if entry (cdr entry) fallback)))

(def (poo-flow-project-compile-stage-adaptive-execution->json-object stage)
  (let (result (poo-flow-project-compile-alist-ref stage 'result #f))
    (if (adaptive-execution-window-result? result)
      (build-adaptive-execution-windows->json-object result)
      #f)))

(def (poo-flow-project-compile-stage-adaptive-diagnostics->json-object stage)
  (let (result (poo-flow-project-compile-alist-ref stage 'result #f))
    (if (adaptive-execution-window-result? result)
      (build-adaptive-execution-window-diagnostics->json-object result)
      #f)))

(def (poo-flow-project-compile-stage-summary->json-object stage)
  (hash
   ("label"
    (poo-flow-project-compile-alist-ref stage 'label ""))
   ("kind"
    (poo-flow-process-memory-guard-json-value
     (poo-flow-project-compile-alist-ref stage 'kind 'unknown)))
   ("status"
    (poo-flow-process-memory-guard-json-value
     (poo-flow-project-compile-alist-ref stage 'status 'unknown)))
   ("description"
    (poo-flow-project-compile-alist-ref stage 'description ""))
   ("elapsed-jiffies"
    (poo-flow-project-compile-alist-ref stage 'elapsed-jiffies 0))
   ("adaptive-execution"
    (poo-flow-project-compile-stage-adaptive-execution->json-object stage))
   ("adaptive-diagnostics"
    (poo-flow-project-compile-stage-adaptive-diagnostics->json-object stage))))

(def (poo-flow-project-compile-build-summary->json-object summary)
  (hash
   ("schema" "gslph.build-plan-receipts-summary.v1")
   ("version" (poo-flow-project-compile-alist-ref summary 'version 1))
   ("stage-count"
    (poo-flow-project-compile-alist-ref summary 'stage-count 0))
   ("compiled-stage-count"
    (poo-flow-project-compile-alist-ref summary 'compiled 0))
   ("skipped-stage-count"
    (poo-flow-project-compile-alist-ref summary 'skipped 0))
   ("elapsed-jiffies"
    (poo-flow-project-compile-alist-ref summary 'elapsed-jiffies 0))
   ("active-stages"
    (map poo-flow-project-compile-stage-summary->json-object
         (poo-flow-project-compile-alist-ref
          summary 'active-stages '())))))

(def (poo-flow-project-compile-receipt->json-object receipt)
  (hash
   ("kind" "poo-flow.project-compile-guard.v1")
   ("schema"
    (poo-flow-process-memory-guard-json-value (.ref receipt 'schema)))
   ("version" 1)
   ("outcome"
    (poo-flow-process-memory-guard-json-value (.ref receipt 'outcome)))
   ("build-owner"
    (poo-flow-process-memory-guard-json-value (.ref receipt 'build-owner)))
   ("build-mode"
    (poo-flow-process-memory-guard-json-value (.ref receipt 'build-mode)))
   ("execution-policy"
    (poo-flow-process-memory-guard-json-value
     (.ref receipt 'execution-policy)))
   ("request-labels"
    (poo-flow-process-memory-guard-json-value (.ref receipt 'request-labels)))
   ("admission-outcome"
    (poo-flow-process-memory-guard-json-value
     (.ref receipt 'admission-outcome)))
   ("admission-advisories"
    (poo-flow-process-memory-guard-json-value
     (.ref receipt 'admission-advisories)))
   ("admission-reasons"
    (poo-flow-process-memory-guard-json-value
     (.ref receipt 'admission-reasons)))
   ("logical-cpu-count" (.ref receipt 'logical-cpu-count))
   ("runnable-process-count" (.ref receipt 'runnable-process-count))
   ("available-memory-bytes" (.ref receipt 'available-memory-bytes))
   ("rss-headroom-bytes" (.ref receipt 'rss-headroom-bytes))
   ("baseline-rss-bytes" (.ref receipt 'baseline-rss-bytes))
   ("allocatable-memory-bytes" (.ref receipt 'allocatable-memory-bytes))
   ("requested-max-rss-bytes" (.ref receipt 'requested-max-rss-bytes))
   ("admitted-memory-bytes" (.ref receipt 'admitted-memory-bytes))
   ("configured-worker-count" (.ref receipt 'configured-worker-count))
   ("memory-worker-capacity" (.ref receipt 'memory-worker-capacity))
   ("runnable-worker-capacity" (.ref receipt 'runnable-worker-capacity))
   ("worker-count" (.ref receipt 'worker-count))
   ("system-memory-bytes" (.ref receipt 'system-memory-bytes))
   ("max-rss-bytes" (.ref receipt 'max-rss-bytes))
   ("peak-rss-bytes" (.ref receipt 'peak-rss-bytes))
   ("elapsed-ms" (.ref receipt 'elapsed-ms))
   ("timeout-ms" (.ref receipt 'timeout-ms))
   ("build-summary"
    (poo-flow-project-compile-build-summary->json-object
     (.ref receipt 'build)))))

(def (poo-flow-project-compile-receipt->json-string receipt)
  (parameterize ((write-json-sort-keys? #t))
    (json-object->string
     (poo-flow-project-compile-receipt->json-object receipt))))

(def (poo-flow-project-compile-receipt-emit! receipt)
  (display "POO_FLOW_PROJECT_BUILD_RECEIPT " (current-error-port))
  (display (poo-flow-project-compile-receipt->json-string receipt)
           (current-error-port))
  (newline (current-error-port))
  (force-output (current-error-port)))

(def (poo-flow-project-compile-blocked-receipt config)
  (.o (schema +poo-flow-project-compile-guard-schema+)
      (kind 'project-compile-receipt)
      (outcome 'blocked-host-pressure)
      (build-owner (.ref config 'build-owner))
      (build-mode (.ref config 'build-mode))
      (execution-policy (.ref config 'execution-policy))
      (request-labels (.ref config 'request-labels))
      (admission-outcome (.ref config 'admission-outcome))
      (admission-advisories (.ref config 'admission-advisories))
      (admission-reasons (.ref config 'admission-reasons))
      (logical-cpu-count (.ref config 'logical-cpu-count))
      (runnable-process-count (.ref config 'runnable-process-count))
      (available-memory-bytes (.ref config 'available-memory-bytes))
      (rss-headroom-bytes (.ref config 'rss-headroom-bytes))
      (baseline-rss-bytes (.ref config 'baseline-rss-bytes))
      (allocatable-memory-bytes (.ref config 'allocatable-memory-bytes))
      (requested-max-rss-bytes (.ref config 'requested-max-rss-bytes))
      (admitted-memory-bytes (.ref config 'admitted-memory-bytes))
      (configured-worker-count (.ref config 'configured-worker-count))
      (memory-worker-capacity (.ref config 'memory-worker-capacity))
      (runnable-worker-capacity (.ref config 'runnable-worker-capacity))
      (worker-count (.ref config 'worker-count))
      (system-memory-bytes (.ref config 'system-memory-bytes))
      (max-rss-bytes (.ref config 'max-rss-bytes))
      (peak-rss-bytes 0)
      (elapsed-ms 0)
      (timeout-ms #f)
      (build '())))

(def (poo-flow-project-compile-with-adaptive-environment options config)
  (let* ((bindings
          (list
           (cons "GERBIL_BUILD_CORES"
                 (number->string (.ref config 'worker-count)))
           (cons "POO_FLOW_BUILD_MAX_RSS_BYTES"
                 (number->string (.ref config 'max-rss-bytes)))
           (cons "POO_FLOW_BUILD_RSS_HEADROOM_BYTES" "0")))
         (previous
          (map (lambda (entry)
                 (cons (car entry) (getenv (car entry) #f)))
               bindings)))
    (dynamic-wind
      (lambda ()
        (for-each
         (lambda (entry) (setenv (car entry) (cdr entry)))
         bindings))
      (lambda () (poo-flow-project-compile! options))
      (lambda ()
        (for-each
         (lambda (entry)
           (setenv (car entry) (or (cdr entry) "")))
         previous)))))

(def (poo-flow-project-compile-guarded! options)
  (let (config (poo-flow-project-compile-guard-config options))
    (unless (eq? (.ref config 'admission-outcome) 'ready)
      (let (receipt (poo-flow-project-compile-blocked-receipt config))
        (poo-flow-project-compile-receipt-emit! receipt)
        (error "POO Flow project compile blocked by host pressure"
               (.ref config 'admission-reasons))))
    (let* ((guard
          (poo-flow-current-process-memory-guard-start!
           '(compile building-framework-project)
           (.ref config 'max-rss-bytes)
           (.ref config 'timeout-seconds)
           (.ref config 'sample-seconds)))
         (stopped? #f)
         (guard-receipt #f))
    (letrec ((stop!
              (lambda ()
                (unless stopped?
                  (set! guard-receipt
                        (poo-flow-current-process-memory-guard-stop! guard))
                  (set! stopped? #t))
                guard-receipt)))
      (dynamic-wind
        (lambda () #!void)
        (lambda ()
          (let* ((build-receipt
                  (poo-flow-project-compile-with-adaptive-environment
                   options config))
                 (completed-guard-receipt (stop!)))
            (let (receipt
                  (.o (schema +poo-flow-project-compile-guard-schema+)
                      (kind 'project-compile-receipt)
                      (outcome 'completed)
                      (build-owner (.ref config 'build-owner))
                      (build-mode (.ref config 'build-mode))
                      (execution-policy (.ref config 'execution-policy))
                      (request-labels (.ref config 'request-labels))
                      (admission-outcome (.ref config 'admission-outcome))
                      (admission-advisories
                       (.ref config 'admission-advisories))
                      (admission-reasons (.ref config 'admission-reasons))
                      (logical-cpu-count (.ref config 'logical-cpu-count))
                      (runnable-process-count
                       (.ref config 'runnable-process-count))
                      (available-memory-bytes
                       (.ref config 'available-memory-bytes))
                      (rss-headroom-bytes
                       (.ref config 'rss-headroom-bytes))
                      (baseline-rss-bytes
                       (.ref config 'baseline-rss-bytes))
                      (allocatable-memory-bytes
                       (.ref config 'allocatable-memory-bytes))
                      (requested-max-rss-bytes
                       (.ref config 'requested-max-rss-bytes))
                      (admitted-memory-bytes
                       (.ref config 'admitted-memory-bytes))
                      (configured-worker-count
                       (.ref config 'configured-worker-count))
                      (memory-worker-capacity
                       (.ref config 'memory-worker-capacity))
                      (runnable-worker-capacity
                       (.ref config 'runnable-worker-capacity))
                      (worker-count (.ref config 'worker-count))
                      (system-memory-bytes
                       (.ref config 'system-memory-bytes))
                      (max-rss-bytes (.ref config 'max-rss-bytes))
                      (peak-rss-bytes
                       (.ref completed-guard-receipt 'peak-rss-bytes))
                      (elapsed-ms
                       (.ref completed-guard-receipt 'elapsed-ms))
                      (timeout-ms (.ref completed-guard-receipt 'timeout-ms))
                      (build build-receipt)
                      (guard completed-guard-receipt)))
              (poo-flow-project-compile-receipt-emit! receipt)
              receipt)))
        (lambda () (stop!)))))))
