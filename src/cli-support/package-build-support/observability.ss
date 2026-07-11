;;; -*- Gerbil -*-
;;; Package build support module split out of ../package-build.ss.

(import (only-in "./receipt.ss"
                 poo-flow-package-build-receipt-status-ref)
        (only-in :gerbil/gambit
                 current-directory
                 current-jiffy
                 current-second
                 delete-file
                 delete-file-or-directory
                 directory-files
                 file-exists?
                 file-info
                 file-info-type
                 getenv
                 jiffies-per-second
                 path-expand
                 string=?
                 string-append
                 make-thread
                 thread-sleep!
                 thread-start!
                 ##os-file-times-set!
                 ##cpu-count)
        (only-in :gerbil/compiler/base
                 __available-cores)
        (only-in :gerbil/compiler
                 compile-module)
        (only-in :std/misc/process
                 run-process)
        (only-in :std/srfi/13
                 string-index
                 string-prefix?
                 string-skip
                 string-suffix?)
        (only-in :std/sugar
                 filter)
        (only-in "./options.ss"
                 poo-flow-build-debug-tracking-options?)
        (only-in "./specs.ss"
                 poo-flow-package-flat-map)
        (only-in "./env.ss"
                 poo-flow-package-srcdir
                 poo-flow-package-worker-count)
        (only-in "./stage-output.ss"
                 poo-flow-diagnostic-outputs
                 poo-flow-diagnostic-source-path
                 poo-flow-stage-output-files)
        (only-in "./stage-cache.ss"
                 poo-flow-stage-cache-assess))

(export #t)

;; : (-> Symbol String String [BuildSpec] BuildOptions Void)
(def (poo-flow-build-debug-start-line phase label command stage options)
  (when (poo-flow-build-debug-tracking-options? options)
    (let* ((target-count (length stage))
           (target (and (= target-count 1)
                        (poo-flow-diagnostic-source-path (car stage)))))
      (display "|poo-flow-compile-start ")
      (write
       [phase: phase
        label: label
        command: command
        target-count: target-count
        target: target
        srcdir: (poo-flow-package-srcdir)])
      (newline)
      (force-output))))

;; : (-> Integer Integer Integer)
(def (poo-flow-build-elapsed-micros start-jiffy end-jiffy)
  (quotient (* (- end-jiffy start-jiffy) 1000000)
            (jiffies-per-second)))

;; : (-> String Integer Integer)
(def (poo-flow-build-observability-budget-seconds name default-value)
  (let (value (getenv name #f))
    (if value
      (let (parsed (string->number value))
        (if (and (integer? parsed) (> parsed 0))
          parsed
          default-value))
      default-value)))

;; : (-> String Integer Integer)
(def (poo-flow-build-observability-budget-micros name default-seconds)
  (* (poo-flow-build-observability-budget-seconds name default-seconds)
     1000000))

;; : (-> Integer Integer Symbol)
(def (poo-flow-build-observability-budget-status target-count elapsed-micros)
  (let* ((warn-single
         (poo-flow-build-observability-budget-micros
          "POO_FLOW_BUILD_WARN_SINGLE_TARGET_SECONDS"
          30))
        (fail-single
         (poo-flow-build-observability-budget-micros
          "POO_FLOW_BUILD_FAIL_SINGLE_TARGET_SECONDS"
          120))
        (warn-stage
         (poo-flow-build-observability-budget-micros
          "POO_FLOW_BUILD_WARN_STAGE_SECONDS"
          60))
        (fail-stage
         (poo-flow-build-observability-budget-micros
          "POO_FLOW_BUILD_FAIL_STAGE_SECONDS"
          300))
        (effective-fail-stage
         (if (> target-count 1) #f fail-stage)))
    (cond
     ((and (= target-count 1) (> elapsed-micros fail-single))
      'single-target-time-budget-exceeded)
     ((and effective-fail-stage (> elapsed-micros effective-fail-stage))
      'stage-time-budget-exceeded)
     ((and (= target-count 1) (> elapsed-micros warn-single))
      'single-target-time-budget-warning)
     ((> elapsed-micros warn-stage)
      'stage-time-budget-warning)
     (else 'ok))))

;; : (-> Symbol Boolean)
(def (poo-flow-build-observability-budget-failure? status)
  (or (eq? status 'single-target-time-budget-exceeded)
      (eq? status 'stage-time-budget-exceeded)))

;; : (-> Symbol String String Symbol Symbol Integer Integer [String] Unit)
(def (poo-flow-build-observability-guard! phase
                                          label
                                          command
                                          status
                                          reason
                                          target-count
                                          elapsed-micros
                                          targets-preview)
  (let (budget-status
        (poo-flow-build-observability-budget-status
         target-count
         elapsed-micros))
    (unless (eq? budget-status 'ok)
      (display "|poo-flow-build-observability ")
      (write
       [phase: phase
        label: label
        command: command
        status: status
        reason: reason
        budget-status: budget-status
        target-count: target-count
        elapsed-micros: elapsed-micros
        targets-preview: targets-preview])
      (newline)
      (force-output))
    (when (poo-flow-build-observability-budget-failure? budget-status)
      (error "poo-flow build observability budget exceeded"
             budget-status
             label
             elapsed-micros))))

;; : (-> [BuildSpec] [String])
(def (poo-flow-build-observability-targets-preview stage)
  (let (sources
        (filter-map poo-flow-diagnostic-source-path stage))
    (if (> (length sources) 3)
      (take sources 3)
      sources)))

;; : (-> Symbol String String [BuildSpec] BuildOptions Thunk Value)
(def (poo-flow-build-observability-with-live-watchdog phase
                                                      label
                                                      command
                                                      stage
                                                      _options
                                                      thunk)
  (let ((completed? #f)
        (target-count (length stage))
        (watchdog-thread #f))
    (when (= target-count 1)
      (let* ((fail-seconds
              (poo-flow-build-observability-budget-seconds
               "POO_FLOW_BUILD_FAIL_SINGLE_TARGET_SECONDS"
               120))
             (targets-preview
              (poo-flow-build-observability-targets-preview stage))
             (watchdog
              (make-thread
               (lambda ()
                 (thread-sleep! fail-seconds)
                 (unless completed?
                   (display "|poo-flow-build-observability ")
                   (write
                    [phase: phase
                     label: label
                     command: command
                     status: 'running
                     reason: 'live-watchdog
                     budget-status: 'single-target-live-time-budget-exceeded
                     target-count: target-count
                     timeout-seconds: fail-seconds
                     targets-preview: targets-preview])
                   (newline)
                   (force-output)
                   (exit 124))))))
        (set! watchdog-thread watchdog)
        (thread-start! watchdog)))
    (dynamic-wind
      (lambda () #!void)
      thunk
      (lambda ()
        (set! completed? #t)
        (when watchdog-thread
          (thread-terminate! watchdog-thread))))))

;; : (-> [BuildSpec] BuildOptions Symbol Symbol Integer)
(def (poo-flow-build-debug-output-count stage options status reason)
  (length
   (if (and (eq? status 'skipped)
            (or (eq? reason 'stamp-current)
                (eq? reason 'receipt-current)
                (eq? reason 'mtime-current)))
     (poo-flow-package-flat-map
      poo-flow-diagnostic-outputs
      stage)
     (poo-flow-stage-output-files stage options))))

;;; Boundary: build debug tracking owns long build-log receipts, so branch edits
;;; must preserve deterministic phase/status output.
;; : (-> Symbol String [String] Symbol Symbol BuildSpec BuildOptions Object Symbol Integer Void)
(def (poo-flow-build-debug-tracking-line phase
                                         label
                                         command
                                         status
                                         reason
                                         stage
                                         options
                                         stamp
                                         receipt-status
                                         start-jiffy)
  (when (poo-flow-build-debug-tracking-options? options)
    (let* ((end-jiffy (current-jiffy))
           (elapsed-micros
            (poo-flow-build-elapsed-micros start-jiffy end-jiffy))
           (cache-status (and receipt-status
                              (poo-flow-package-build-receipt-status-ref
                               receipt-status
                               'status
                               #f)))
           (target-count (length stage))
           (raw-targets-preview
            (poo-flow-build-observability-targets-preview stage))
           (targets-preview
            (if (<= target-count 3)
              raw-targets-preview
              (append raw-targets-preview
                      [(string-append "...+"
                                      (number->string (- target-count 3))
                                      " more")]))))
      (display "|poo-flow-compile-debug ")
      (write
       [phase: phase
        label: label
        command: command
        status: status
        reason: reason
        cache-status: cache-status
        target-count: target-count
        output-count: (poo-flow-build-debug-output-count
                       stage
                       options
                       status
                       reason)
        worker-count: (and (> target-count 1)
                           (poo-flow-package-worker-count))
        targets-preview: targets-preview
        cache-stamp: stamp
         srcdir: (poo-flow-package-srcdir)
         elapsed-micros: elapsed-micros])
       (newline)
       (force-output)
       (unless (and (eq? phase 'package-stage)
                    (string=? command "profiled std/make"))
         (poo-flow-build-observability-guard!
          phase
          label
          command
          status
          reason
          target-count
          elapsed-micros
          targets-preview)))))

;; : (-> BuildOptions Integer Void)
(def (poo-flow-build-debug-package-total-line options start-jiffy)
  (when (poo-flow-build-debug-tracking-options? options)
    (let (end-jiffy (current-jiffy))
      (display "|poo-flow-compile-debug ")
      (write
       [phase: 'package-total
        label: "package"
        command: "poo-flow-package-compile"
        status: 'completed
        reason: 'package-entry-complete
        scope: 'poo-flow-build-script
        excludes: 'gxpkg-env-startup
        elapsed-micros: (poo-flow-build-elapsed-micros
                         start-jiffy
                         end-jiffy)])
      (newline)
      (force-output))))
