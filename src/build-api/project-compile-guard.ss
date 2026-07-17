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
         (max-rss-bytes
          (poo-flow-project-compile-positive-integer-from-env
           "POO_FLOW_BUILD_MAX_RSS_BYTES"
           (poo-flow-project-compile-adaptive-max-rss-bytes
            system-memory-bytes)))
         (timeout-seconds
          (poo-flow-project-compile-optional-timeout-from-env
           "POO_FLOW_BUILD_TOTAL_TIMEOUT_SECONDS"))
         (sample-seconds
          (poo-flow-project-compile-real-from-env
           "POO_FLOW_BUILD_GUARD_SAMPLE_SECONDS"
           +poo-flow-project-compile-default-sample-seconds+))
         (execution-policy
          (if (poo-flow-project-compile-positive-integer-from-env
               "POO_FLOW_BUILD_MAX_RSS_BYTES" #f)
            'adaptive
            'topology))
         (request-labels (poo-flow-project-build-stage-labels)))
    (let ((request-labels-value request-labels)
          (execution-policy-value execution-policy)
          (system-memory-bytes-value system-memory-bytes)
          (max-rss-bytes-value max-rss-bytes)
          (timeout-seconds-value timeout-seconds)
          (sample-seconds-value sample-seconds))
      (.o (schema +poo-flow-project-compile-guard-schema+)
          (kind 'project-compile-guard-config)
          (build-owner 'gslph-building-framework)
          (build-mode 'standard-gerbil-make-project)
          (execution-policy execution-policy-value)
          (request-labels request-labels-value)
          (system-memory-bytes system-memory-bytes-value)
          (max-rss-bytes max-rss-bytes-value)
          (timeout-seconds timeout-seconds-value)
          (sample-seconds sample-seconds-value)))))

(def (poo-flow-project-compile-receipt->alist receipt)
  (map (lambda (slot) (cons slot (.ref receipt slot)))
       '(schema outcome build-owner build-mode execution-policy request-labels
                system-memory-bytes max-rss-bytes peak-rss-bytes
                elapsed-ms timeout-ms)))

(def (poo-flow-project-compile-alist-ref rows key fallback)
  (let (entry (assq key rows))
    (if entry (cdr entry) fallback)))

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
    (poo-flow-project-compile-alist-ref stage 'elapsed-jiffies 0))))

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

(def (poo-flow-project-compile-guarded! options)
  (let* ((config (poo-flow-project-compile-guard-config options))
         (guard
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
          (let* ((build-receipt (poo-flow-project-compile! options))
                 (completed-guard-receipt (stop!)))
            (let (receipt
                  (.o (schema +poo-flow-project-compile-guard-schema+)
                      (kind 'project-compile-receipt)
                      (outcome 'completed)
                      (build-owner (.ref config 'build-owner))
                      (build-mode (.ref config 'build-mode))
                      (execution-policy (.ref config 'execution-policy))
                      (request-labels (.ref config 'request-labels))
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
        (lambda () (stop!))))))
