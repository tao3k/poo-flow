(export poo-flow-project-compile-plan
        poo-flow-project-compile-guarded!)

(import :clan/poo/object
        :gerbil/gambit
        :std/srfi/1
        (only-in :std/misc/process run-process)
        :gslph/src/building/facade
        :poo-flow/src/cli-support/project-build
        :poo-flow/src/build-api/process-memory-guard)

(def +poo-flow-project-compile-guard-schema+
  'poo-flow.project-compile-guard.v1)

(def +poo-flow-project-compile-default-chunk-size+ 8)
(def +poo-flow-project-compile-default-workers+ 1)
(def +poo-flow-project-compile-default-max-rss-bytes+ (* 768 1024 1024))
(def +poo-flow-project-compile-default-timeout-seconds+ 300)
(def +poo-flow-project-compile-default-total-timeout-seconds+ 1800)
(def +poo-flow-project-compile-default-sample-seconds+ 0.1)

(def (poo-flow-project-compile-positive-integer-from-env name fallback)
  (let* ((raw (getenv name #f))
         (value (and raw (string->number raw))))
    (if (and (exact-integer? value) (> value 0)) value fallback)))

(def (poo-flow-project-compile-real-from-env name fallback)
  (let* ((raw (getenv name #f))
         (value (and raw (string->number raw))))
    (if (and (real? value) (> value 0)) value fallback)))

(def (poo-flow-project-compile-chunks values size)
  (let lp ((rest values) (current '()) (count 0) (chunks '()))
    (cond
     ((null? rest)
      (reverse
       (if (null? current) chunks (cons (reverse current) chunks))))
     ((= count size)
      (lp rest '() 0 (cons (reverse current) chunks)))
     (else
      (lp (cdr rest)
          (cons (car rest) current)
          (+ count 1)
          chunks)))))

(def (poo-flow-project-compile-indexed-map proc values)
  (let lp ((rest values) (index 0) (result '()))
    (if (null? rest)
      (reverse result)
      (lp (cdr rest)
          (+ index 1)
          (cons (proc index (car rest)) result)))))

(def (poo-flow-project-compile-stage-spec stage-spec)
  (if (and (pair? stage-spec) (null? (cdr stage-spec)))
    (car stage-spec)
    stage-spec))

(def (poo-flow-project-compile-stage-layers label root specs mode)
  (if (eq? mode 'topology)
    (package-source-stage-topology-layers
     (make-package-source-stage label root "poo-flow" specs mode))
    (list specs)))

(def (poo-flow-project-compile-stage-chunks
      stage-index label root specs mode chunk-size)
  (append-map
   (lambda (layer-entry)
     (let ((layer-index (car layer-entry))
           (layer-specs (cdr layer-entry)))
       (poo-flow-project-compile-indexed-map
        (lambda (chunk-index chunk-specs)
          (let ((stage-index-value stage-index)
                (layer-index-value layer-index)
                (chunk-index-value chunk-index)
                (chunk-specs-value chunk-specs))
            (.o (kind 'project-compile-chunk)
              (stage-index stage-index-value)
              (stage-label label)
              (layer-index layer-index-value)
              (chunk-index chunk-index-value)
              (specs chunk-specs-value))))
        (poo-flow-project-compile-chunks layer-specs chunk-size))))
   (poo-flow-project-compile-indexed-map
    (lambda (index layer) (cons index layer))
    (poo-flow-project-compile-stage-layers label root specs mode))))

(def (poo-flow-project-compile-plan options root chunk-size)
  (poo-flow-project-configure-build-root! root)
  (let ((stage-specs (poo-flow-project-build-spec options)))
    (unless (= (length stage-specs) 3)
      (error "POO Flow guarded compile expects ffi, runtime, and user-interface stages"
             (length stage-specs)))
    (let* ((labels '("nono-c-ffi" "runtime" "user-interface"))
           (modes '(#t topology topology))
           (chunks
            (append-map
             (lambda (stage-index)
               (poo-flow-project-compile-stage-chunks
                stage-index
                (list-ref labels stage-index)
                root
                (poo-flow-project-compile-stage-spec
                 (list-ref stage-specs stage-index))
                (list-ref modes stage-index)
                chunk-size))
             '(0 1 2))))
      (let ((root-value root)
            (options-value options)
            (chunk-size-value chunk-size)
            (chunks-value chunks))
        (.o (schema +poo-flow-project-compile-guard-schema+)
            (kind 'project-compile-plan)
            (root root-value)
            (options options-value)
            (chunk-size chunk-size-value)
            (chunks chunks-value))))))

(def (poo-flow-project-compile-options->string options)
  (call-with-output-string (lambda (port) (write options port))))

(def (poo-flow-project-compile-options-from-string value)
  (call-with-input-string value read))

(def (poo-flow-project-compile-required-env name)
  (or (getenv name #f)
      (error "missing guarded compile environment" name)))

(def (poo-flow-project-compile-child-argv)
  (list "/bin/sh"
        "-c"
        "\"$@\""
        "poo-flow-gxi"
        (path-expand "~~bin/gxi")
        "-e"
        "(import :poo-flow/src/build-api/project-compile-guard)"
        "-e"
        "(poo-flow-project-compile-chunk-from-environment!)"))

(def (poo-flow-project-compile-chunk-run! root options label specs workers)
  (let* (
         (effective-options (append options (list 'parallelize: workers)))
         (stage
          (make-package-source-stage
           label
           root
           "poo-flow"
           specs
           #t))
         (request (package-source-stage->request stage effective-options)))
    (build-request-run! request)))

(def (poo-flow-project-compile-chunk-from-environment!)
  (let* ((root (poo-flow-project-compile-required-env "POO_FLOW_BUILD_ROOT"))
         (options
          (poo-flow-project-compile-options-from-string
           (poo-flow-project-compile-required-env "POO_FLOW_BUILD_OPTIONS")))
         (label
          (poo-flow-project-compile-required-env "POO_FLOW_BUILD_STAGE_LABEL"))
         (specs
          (poo-flow-project-compile-options-from-string
           (poo-flow-project-compile-required-env "POO_FLOW_BUILD_CHUNK_SPECS")))
         (workers
          (string->number
           (poo-flow-project-compile-required-env "POO_FLOW_BUILD_CHUNK_WORKERS")))
         (max-rss-bytes
          (string->number
           (poo-flow-project-compile-required-env "POO_FLOW_BUILD_MAX_RSS_BYTES")))
         (timeout-seconds
          (string->number
           (poo-flow-project-compile-required-env
            "POO_FLOW_BUILD_CHUNK_TIMEOUT_SECONDS")))
         (sample-seconds
          (string->number
           (poo-flow-project-compile-required-env
            "POO_FLOW_BUILD_GUARD_SAMPLE_SECONDS"))))
    (unless (and (pair? specs)
                 (exact-integer? workers)
                 (> workers 0)
                 (exact-integer? max-rss-bytes)
                 (> max-rss-bytes 0)
                 (real? timeout-seconds)
                 (> timeout-seconds 0)
                 (real? sample-seconds)
                 (> sample-seconds 0))
      (error "invalid guarded compile chunk selection"
             label workers))
    (let* ((guard
            (poo-flow-current-process-memory-guard-start!
             (list 'compile label)
             max-rss-bytes
             timeout-seconds
             sample-seconds))
           (result
            (poo-flow-project-compile-chunk-run!
             root options label specs workers)))
      (poo-flow-current-process-memory-guard-stop! guard)
      result)))

(def (poo-flow-project-compile-guard-receipt-ok? receipt)
  (and (eq? (.ref receipt 'outcome) 'completed)
       (= (.ref receipt 'child-exit-code) 0)))

(def (poo-flow-project-compile-shell-quote value)
  (call-with-output-string
   (lambda (port)
     (display "'" port)
     (string-for-each
      (lambda (char)
        (if (char=? char #\')
          (display "'\"'\"'" port)
          (write-char char port)))
      value)
     (display "'" port))))

(def (poo-flow-project-compile-shell-command argv)
  (string-join (map poo-flow-project-compile-shell-quote argv) " "))

(def (poo-flow-project-compile-option-enabled? options key)
  (let lp ((rest options))
    (cond
     ((null? rest) #f)
     ((and (pair? (cdr rest)) (eq? (car rest) key))
      (cadr rest))
     ((pair? (cdr rest)) (lp (cddr rest)))
     (else #f))))

(def (poo-flow-project-compile-output-directory)
  (path-expand
   "lib"
   (or (getenv "GERBIL_PATH" #f)
       (path-expand ".gerbil"))))

(def (poo-flow-project-compile-module-argv path options)
  (append
   (list (or (getenv "POO_FLOW_GXC" #f) "gxc")
         "-O"
         "-d"
         (poo-flow-project-compile-output-directory))
   (if (poo-flow-project-compile-option-enabled? options 'debug:)
     (list "-g")
     '())
   (if (poo-flow-project-compile-option-enabled? options 'verbose:)
     (list "-V")
     '())
   (list path)))

(def (poo-flow-project-compile-structured-expression specs)
  (call-with-output-string
   (lambda (port)
     (display "(make '" port)
     (write specs port)
     (display " srcdir: (current-directory) prefix: \"poo-flow\")" port))))

(def (poo-flow-project-compile-structured-argv specs)
  (list (or (getenv "POO_FLOW_GXI" #f) "gxi")
        "-e"
        "(import :std/make)"
        "-e"
        (poo-flow-project-compile-structured-expression specs)))

(def (poo-flow-project-compile-spec-argv spec options)
  (cond
   ((string? spec)
    (poo-flow-project-compile-module-argv spec options))
   ((and (pair? spec) (eq? (car spec) 'ssi:) (pair? (cdr spec)))
    (poo-flow-project-compile-module-argv (cadr spec) options))
   (else
    (poo-flow-project-compile-structured-argv (list spec)))))

(def (poo-flow-project-compile-spec-current? chunk spec)
  (let (stage
        (make-package-source-stage
         (.ref chunk 'stage-label)
         (current-directory)
         "poo-flow"
         (list spec)
         #t))
    (package-source-stage-current? stage (list spec))))

(def (poo-flow-project-compile-native-spec! chunk spec options)
  (let* ((started (guard-now-seconds))
         (current? (poo-flow-project-compile-spec-current? chunk spec))
         (argv (and (not current?)
                    (poo-flow-project-compile-spec-argv spec options)))
         (status (if current?
                   0
                   (guard-exit-code
                    (shell-command
                     (poo-flow-project-compile-shell-command argv)))))
         (elapsed-ms
          (inexact->exact
           (round (* 1000 (- (guard-now-seconds) started))))))
    (unless (= status 0)
      (error "isolated native Gerbil compile failed" spec status))
    (object<-alist
     (list (cons 'kind 'poo-flow.project-native-compile.v1)
           (cons 'schema 'poo-flow.project-native-compile.v1)
           (cons 'stage-label (.ref chunk 'stage-label))
           (cons 'layer-index (.ref chunk 'layer-index))
           (cons 'chunk-index (.ref chunk 'chunk-index))
           (cons 'spec spec)
           (cons 'outcome (if current? 'current 'completed))
           (cons 'exit-code status)
           (cons 'elapsed-ms elapsed-ms)))))

(def (poo-flow-project-compile-native-structured-chunk! chunk specs)
  (let* ((started (guard-now-seconds))
         (stage
          (make-package-source-stage
           (.ref chunk 'stage-label)
           (current-directory)
           "poo-flow"
           specs
           #t))
         (current? (package-source-stage-current? stage specs))
         (status
          (if current?
            0
            (guard-exit-code
             (shell-command
              (poo-flow-project-compile-shell-command
               (poo-flow-project-compile-structured-argv specs))))))
         (elapsed-ms
          (inexact->exact
           (round (* 1000 (- (guard-now-seconds) started))))))
    (unless (= status 0)
      (error "isolated structured Gerbil compile failed" specs status))
    (object<-alist
     (list (cons 'kind 'poo-flow.project-native-compile.v1)
           (cons 'schema 'poo-flow.project-native-compile.v1)
           (cons 'stage-label (.ref chunk 'stage-label))
           (cons 'layer-index (.ref chunk 'layer-index))
           (cons 'chunk-index (.ref chunk 'chunk-index))
           (cons 'spec specs)
           (cons 'outcome (if current? 'current 'completed))
           (cons 'exit-code status)
           (cons 'elapsed-ms elapsed-ms)))))

(def (poo-flow-project-compile-native-chunk! chunk options)
  (let* ((specs (.ref chunk 'specs))
         (structured? (ormap (lambda (spec) (not (string? spec))) specs))
         (receipts
          (if structured?
            (list (poo-flow-project-compile-native-structured-chunk!
                   chunk specs))
            (let lp ((rest specs) (result '()))
              (if (null? rest)
                (reverse result)
                (lp (cdr rest)
                    (cons (poo-flow-project-compile-native-spec!
                           chunk (car rest) options)
                          result)))))))
    (object<-alist
     (list (cons 'kind 'poo-flow.project-native-compile-chunk.v1)
           (cons 'schema 'poo-flow.project-native-compile-chunk.v1)
           (cons 'stage-label (.ref chunk 'stage-label))
           (cons 'layer-index (.ref chunk 'layer-index))
           (cons 'chunk-index (.ref chunk 'chunk-index))
           (cons 'outcome 'completed)
           (cons 'exit-code 0)
           (cons 'child-exit-code 0)
           (cons 'peak-rss-bytes #f)
           (cons 'specs receipts)))))

(def (poo-flow-project-compile-child-environment
      root options chunk workers max-rss-bytes timeout-seconds sample-seconds)
  (list
   (cons "POO_FLOW_BUILD_ROOT" root)
   (cons "POO_FLOW_BUILD_OPTIONS"
         (poo-flow-project-compile-options->string options))
   (cons "POO_FLOW_BUILD_STAGE_LABEL" (.ref chunk 'stage-label))
   (cons "POO_FLOW_BUILD_CHUNK_SPECS"
         (poo-flow-project-compile-options->string (.ref chunk 'specs)))
   (cons "POO_FLOW_BUILD_CHUNK_WORKERS" (number->string workers))
   (cons "POO_FLOW_BUILD_MAX_RSS_BYTES" (number->string max-rss-bytes))
   (cons "POO_FLOW_BUILD_CHUNK_TIMEOUT_SECONDS"
         (number->string timeout-seconds))
   (cons "POO_FLOW_BUILD_GUARD_SAMPLE_SECONDS"
         (number->string sample-seconds))))

(def (poo-flow-project-compile-child-run!
      label argv environment max-rss-bytes timeout-seconds)
  (let (status 0)
    (for-each
     (lambda (binding) (setenv (car binding) (cdr binding)))
     environment)
    (run-process
     argv
     stdout-redirection: #f
     stderr-redirection: #f
     check-status:
     (lambda (exit-status _settings)
       (set! status (guard-exit-code exit-status))))
    (object<-alist
     (list (cons 'kind 'poo-flow.project-compile-child.v1)
           (cons 'schema 'poo-flow.project-compile-child.v1)
           (cons 'label label)
           (cons 'outcome (if (= status 0) 'completed 'failed))
           (cons 'exit-code status)
           (cons 'child-exit-code status)
           (cons 'peak-rss-bytes #f)
           (cons 'peak-rss-source 'child-guard-receipt)
           (cons 'max-rss-bytes max-rss-bytes)
           (cons 'timeout-ms
                 (inexact->exact (round (* timeout-seconds 1000))))))))

(def (poo-flow-project-compile-guarded! options)
  (let* ((root (current-directory))
         (chunk-size
          (poo-flow-project-compile-positive-integer-from-env
           "POO_FLOW_BUILD_CHUNK_SIZE"
           +poo-flow-project-compile-default-chunk-size+))
         (workers
          (poo-flow-project-compile-positive-integer-from-env
           "POO_FLOW_BUILD_CHUNK_WORKERS"
           +poo-flow-project-compile-default-workers+))
         (max-rss-bytes
          (poo-flow-project-compile-positive-integer-from-env
           "POO_FLOW_BUILD_MAX_RSS_BYTES"
           +poo-flow-project-compile-default-max-rss-bytes+))
         (timeout-seconds
          (poo-flow-project-compile-positive-integer-from-env
           "POO_FLOW_BUILD_CHUNK_TIMEOUT_SECONDS"
           +poo-flow-project-compile-default-timeout-seconds+))
         (total-timeout-seconds
          (poo-flow-project-compile-positive-integer-from-env
           "POO_FLOW_BUILD_TOTAL_TIMEOUT_SECONDS"
           +poo-flow-project-compile-default-total-timeout-seconds+))
         (sample-seconds
          (poo-flow-project-compile-real-from-env
           "POO_FLOW_BUILD_GUARD_SAMPLE_SECONDS"
           +poo-flow-project-compile-default-sample-seconds+))
         (parent-guard
          (poo-flow-current-process-memory-guard-start!
           '(compile control-plane)
           max-rss-bytes
           total-timeout-seconds
           sample-seconds))
         (plan (poo-flow-project-compile-plan options root chunk-size))
         (chunks (.ref plan 'chunks)))
    (let lp ((rest chunks) (index 0) (receipts '()))
      (if (null? rest)
        (let ((parent-receipt
               (poo-flow-current-process-memory-guard-stop! parent-guard))
              (chunk-size-value chunk-size)
              (workers-value workers)
              (max-rss-bytes-value max-rss-bytes)
              (receipts-value (reverse receipts)))
          (.o (schema +poo-flow-project-compile-guard-schema+)
              (kind 'project-compile-receipt)
              (outcome 'completed)
              (chunk-count index)
              (chunk-size chunk-size-value)
              (workers workers-value)
              (max-rss-bytes max-rss-bytes-value)
              (peak-rss-bytes (.ref parent-receipt 'peak-rss-bytes))
              (peak-rss-source 'scheme-control-plane)
              (control-plane-guard parent-receipt)
              (chunks receipts-value)))
        (let* ((chunk (car rest))
               (label
                (list 'compile
                      (.ref chunk 'stage-label)
                      (.ref chunk 'layer-index)
                      (.ref chunk 'chunk-index)))
               (receipt
                (poo-flow-project-compile-native-chunk! chunk options)))
          (unless (poo-flow-project-compile-guard-receipt-ok? receipt)
            (error "guarded POO Flow compile chunk failed"
                   (poo-flow-process-memory-guard-receipt->alist receipt)))
          (lp (cdr rest) (+ index 1) (cons receipt receipts)))))))
