;;; -*- Gerbil -*-
;;; Package build support module split out of ../package-build.ss.

(import (only-in :gerbil/gambit
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
                 setenv
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
                 poo-flow-cli-build-options?
                 poo-flow-native-build-options?
                 poo-flow-profiled-spec-options
                 poo-flow-profiled-stage-options?
                 poo-flow-release-build-options?
                 poo-flow-tests-build-options?)
        (only-in "./specs.ss"
                 +poo-flow-cli-library-build-spec+
                 +poo-flow-direct-gxc-stale-stage-target-limit+
                 +poo-flow-ffi-build-spec+
                 +poo-flow-testing-project-build-spec+
                 poo-flow-cli-only-build-spec
                 poo-flow-cli-only-module-build-spec
                 poo-flow-entry-build-spec
                 poo-flow-build-gsc-options
                 poo-flow-build-homebrew-static-clean?
                 poo-flow-build-nonempty-env
                 poo-flow-package-build-spec
                 poo-flow-runtime-bootstrap-build-spec
                 poo-flow-runtime-main-build-spec
                 poo-flow-test-build-spec)
        (only-in "./env.ss"
                 poo-flow-apply-make
                 poo-flow-apply-make-clean
                 poo-flow-make-options
                 poo-flow-native-object-output-directory-cache-clear!
                 poo-flow-package-message
                 poo-flow-package-require-gxpkg-env!
                 poo-flow-package-srcdir
                 poo-flow-package-stage-options)
        (only-in "./launcher.ss"
                 poo-flow-write-cli-launcher!)
        (only-in "./stage-output.ss"
                 poo-flow-all?
                 poo-flow-diagnostic-gxc-spec?
                 poo-flow-gxc-source-file
                 poo-flow-package-libdir)
        (only-in "./stage-cache.ss"
                 poo-flow-bootstrap-spec-current?
                 poo-flow-bootstrap-stale-specs
                 poo-flow-delete-native-object-siblings!
                 poo-flow-spec-output-files-retouch!
                 poo-flow-stage-cache-assess
                 poo-flow-stage-cache-refresh!
                 poo-flow-stage-cache-retouch!
                 poo-flow-stage-cache-touch!
                 poo-flow-stage-cache-valid?
                 poo-flow-stage-spec-current?
                 poo-flow-stage-stale-specs)
        (only-in "./observability.ss"
                 poo-flow-build-debug-package-total-line
                 poo-flow-build-debug-start-line
                 poo-flow-build-debug-tracking-line
                 poo-flow-build-observability-with-live-watchdog))

(import (only-in "./stage-result.ss"
                 make-poo-flow-stage-result))

(export #t)

;; : (-> String BuildSpec BuildOptions Void)
(def (poo-flow-make-profiled-spec label spec options)
  (let ((stage (list spec))
        (start-jiffy (current-jiffy)))
    (if (poo-flow-stage-spec-current? spec options label)
      (begin
        (poo-flow-package-message "skip" label stage)
        (poo-flow-build-debug-tracking-line
         'package-stage-spec
         label
         "profiled std/make"
         'skipped
         'mtime-current
         stage
         options
         #f
         #f
         start-jiffy))
      (let (spec-options (poo-flow-profiled-spec-options spec options))
        (poo-flow-package-message "compile" label stage)
        (poo-flow-build-debug-start-line
         'package-stage-spec
         label
         "profiled std/make"
         stage
         options)
	        (poo-flow-build-observability-with-live-watchdog
	         'package-stage-spec
	         label
	         "profiled std/make"
	         stage
	         options
         (lambda ()
           (poo-flow-build-with-homebrew-static-clean
            (lambda ()
              (apply poo-flow-apply-make stage
                     srcdir: (poo-flow-package-srcdir)
                     (poo-flow-make-options spec-options))))))
	        (poo-flow-native-object-output-directory-cache-clear!)
	        (poo-flow-spec-output-files-retouch! spec spec-options)
	        (poo-flow-build-debug-tracking-line
         'package-stage-spec
         label
         "profiled std/make"
         'compiled
         'stale
         stage
         options
         #f
         #f
         start-jiffy)))))

;; : (-> String [BuildSpec] BuildOptions Void)
(def (poo-flow-make-profiled-stage label stale-stage options)
  (poo-flow-package-message "compile-profiled" label stale-stage)
  (for-each
   (lambda (spec)
     (poo-flow-make-profiled-spec label spec options))
   stale-stage))

;; poo-flow-direct-gxc-stale-stage?
;;   : (-> [BuildSpec] [BuildSpec] Boolean)
;;   | doc m%
;;       A direct gxc rebuild is valid only for a singleton stage: std/make owns
;;       dependency timestamp propagation for every multi-spec stage.
;;     %
(def (poo-flow-direct-gxc-stale-stage? stage stale-stage)
  (and (= (length stage) 1)
       (not (null? stale-stage))
       (<= (length stale-stage)
           +poo-flow-direct-gxc-stale-stage-target-limit+)
       (poo-flow-all? poo-flow-diagnostic-gxc-spec? stale-stage)))

;; : (-> [BuildSpec] Boolean)
(def (poo-flow-bootstrap-direct-gxc-stale-stage? stale-stage)
  (and (not (null? stale-stage))
       (<= (length stale-stage)
           +poo-flow-direct-gxc-stale-stage-target-limit+)
       (poo-flow-all? poo-flow-diagnostic-gxc-spec? stale-stage)))

;; poo-flow-make-direct-gxc-stage!
;;   : (-> String [BuildSpec] BuildOptions Boolean Void)
;;   | doc m%
;;       Compile a small focused stale stage with direct gxc calls.
;;     %
(def (poo-flow-make-direct-gxc-stage! label stale-stage options . maybe-force?)
  (poo-flow-package-message "compile-direct-gxc" label stale-stage)
  (let (force? (and (pair? maybe-force?)
                     (car maybe-force?)))
    (for-each
     (lambda (spec)
       (poo-flow-run-gxc-spec! label spec options force?))
     stale-stage)))

;; : (-> String [BuildSpec] BuildOptions Symbol MaybeAlist MaybeString Integer Void)
(def (poo-flow-make-skip-current! label
                                  stage
                                  options
                                  reason
                                  receipt-status
                                  stamp
                                  start-jiffy)
  (poo-flow-package-message "skip" label stage)
  (display "|note kind=build-cache message=\"package-local gxc direct outputs are current; skipped std/make no-op rebuild\"")
  (newline)
  (poo-flow-build-debug-tracking-line
   'package-stage
   label
   "std/make"
   'skipped
   reason
   stage
   options
   stamp
   receipt-status
   start-jiffy))

;; : (-> String [BuildSpec] BuildOptions MaybeAlist MaybeString Integer Void)
(def (poo-flow-make-skip-stale-current! label
                                        stage
                                        options
                                        receipt-status
                                        stamp
                                        start-jiffy)
  (poo-flow-package-message "skip" label stage)
  (display "|note kind=build-cache message=\"package-local gxc direct outputs are current after stale target scan; skipped std/make rebuild\"")
  (newline)
  (poo-flow-stage-cache-refresh! stage options label)
  (poo-flow-build-debug-tracking-line
   'package-stage
   label
   "std/make"
   'skipped
   'mtime-current
   stage
   options
   stamp
   receipt-status
   start-jiffy))

;; : (-> String [BuildSpec] BuildOptions Void)
(def (poo-flow-make-std-stage! label stale-stage options)
  (poo-flow-package-message "compile" label stale-stage)
  (poo-flow-build-debug-start-line
   'package-stage
   label
   "std/make"
   stale-stage
   options)
  (poo-flow-build-observability-with-live-watchdog
   'package-stage
   label
   "std/make"
   stale-stage
   options
   (lambda ()
     (poo-flow-build-with-homebrew-static-clean
      (lambda ()
        (apply poo-flow-apply-make stale-stage
               srcdir: (poo-flow-package-srcdir)
               (poo-flow-package-stage-options
                stale-stage
                options))))))
  (poo-flow-native-object-output-directory-cache-clear!))

;; : (-> Boolean String [BuildSpec] [BuildSpec] BuildOptions Void)
(def (poo-flow-make-run-stale-stage! profiled? label stage stale-stage options)
  (cond
   ((poo-flow-direct-gxc-stale-stage? stage stale-stage)
    (poo-flow-make-direct-gxc-stage! label stale-stage options))
   (profiled?
    (poo-flow-make-profiled-stage label stale-stage options))
   (else
    (poo-flow-make-std-stage! label stage options))))

;; : (-> [BuildSpec] String)
(def (poo-flow-make-profiled-engine-label stale-stage)
  (if (= (length stale-stage) 1)
    "profiled std/make"
    "profiled std/make per-spec"))

;; : (-> Boolean [BuildSpec] [BuildSpec] String)
(def (poo-flow-make-stage-engine-label profiled? stage stale-stage)
  (cond
   ((poo-flow-direct-gxc-stale-stage? stage stale-stage)
    "direct gxc")
   (profiled?
    (poo-flow-make-profiled-engine-label stale-stage))
   (else
    "std/make")))

;; poo-flow-compiled-stage-cache-fast-retouch?
;;   : (-> Symbol MaybeString [BuildSpec] [BuildSpec] Boolean)
;;   | doc m%
;;       A small direct-gxc rebuild for a sources-stale stage does not change the
;;       stage source/output membership, so retouching the existing receipt stamp
;;       avoids rewriting large expected-output receipts.
;;     %
(def (poo-flow-compiled-stage-cache-fast-retouch? reason stamp stage stale-stage)
  (and (eq? reason 'sources-stale)
       stamp
       (file-exists? stamp)
       (poo-flow-direct-gxc-stale-stage? stage stale-stage)))

;; poo-flow-compiled-stage-cache-complete!
;;   : (-> [BuildSpec] BuildOptions String Symbol MaybeString [BuildSpec] Void)
;;   | doc m%
;;       Complete cache maintenance after a stale-stage compile.
;;     %
(def (poo-flow-compiled-stage-cache-complete! stage
                                             options
                                             label
                                             reason
                                             stamp
                                             stale-stage)
  (if (poo-flow-compiled-stage-cache-fast-retouch? reason stamp stage stale-stage)
    (poo-flow-stage-cache-retouch! stamp)
    (poo-flow-stage-cache-refresh! stage options label)))

;; : (-> String [BuildSpec] BuildOptions Symbol MaybeAlist MaybeString Integer [BuildSpec] Void)
(def (poo-flow-make-compile-stale-stage! label
                                         stage
                                         options
                                         reason
                                         receipt-status
                                         stamp
                                         start-jiffy
                                         stale-stage)
  (let (profiled?
        (poo-flow-profiled-stage-options? label stale-stage options))
    (poo-flow-make-run-stale-stage! profiled? label stage stale-stage options)
    (poo-flow-compiled-stage-cache-complete!
     stage
     options
     label
     reason
     stamp
     stale-stage)
    (poo-flow-build-debug-tracking-line
     'package-stage
     label
     (poo-flow-make-stage-engine-label profiled? stage stale-stage)
     'compiled
     reason
     stale-stage
     options
     stamp
     receipt-status
     start-jiffy)))

;; : (-> String [BuildSpec] BuildOptions Symbol MaybeAlist MaybeString Integer Boolean)
(def (poo-flow-make-stale-stage! label
                                 stage
                                 options
                                 reason
                                 receipt-status
                                 stamp
                                 start-jiffy)
  (let (stale-stage
        (poo-flow-stage-stale-specs stage options label))
    (if (null? stale-stage)
      (begin
        (poo-flow-make-skip-stale-current! label
                                           stage
                                           options
                                           receipt-status
                                           stamp
                                           start-jiffy)
        #f)
      (begin
        (poo-flow-make-compile-stale-stage! label
                                            stage
                                            options
                                            reason
                                            receipt-status
                                            stamp
                                            start-jiffy
                                            stale-stage)
        #t))))

;; : (-> String [BuildSpec] BuildOptions Boolean Symbol MaybeAlist MaybeString Integer Boolean)
(def (poo-flow-make-dispatch! label
                              stage
                              options
                              current?
                              reason
                              receipt-status
                              stamp
                              start-jiffy)
  (if current?
    (begin
      (poo-flow-make-skip-current! label
                                   stage
                                   options
                                   reason
                                   receipt-status
                                   stamp
                                   start-jiffy)
      #f)
    (poo-flow-make-stale-stage! label
                                stage
                                options
                                reason
                                receipt-status
                                stamp
                                start-jiffy)))

;; : (-> String [BuildSpec] Boolean)
(def (poo-flow-composition-refresh-stage? label stage)
  (and (string=? label "entry")
       (poo-flow-all? poo-flow-diagnostic-gxc-spec? stage)))

;; : (-> String [BuildSpec] String)
(def (poo-flow-upstream-dirty-stage-engine-label label stage)
  (if (poo-flow-composition-refresh-stage? label stage)
    "direct gxc composition-refresh"
    "std/make dependency-check"))

;; : (-> String [BuildSpec] BuildOptions MaybeAlist MaybeString Integer Boolean)
(def (poo-flow-make-upstream-dirty-stage! label
                                           stage
                                           options
                                           receipt-status
                                           stamp
                                           start-jiffy)
  (if (poo-flow-composition-refresh-stage? label stage)
    (poo-flow-make-direct-gxc-stage! label stage options #t)
    (poo-flow-make-std-stage! label stage options))
  (poo-flow-stage-cache-refresh! stage options label)
  (poo-flow-build-debug-tracking-line
   'package-stage
   label
   (poo-flow-upstream-dirty-stage-engine-label label stage)
   'compiled
   'upstream-stage-dirty
   stage
   options
   stamp
   receipt-status
   start-jiffy)
  #t)

;; : (-> String [BuildSpec] BuildOptions Boolean Boolean)
(def (poo-flow-make label stage options . maybe-upstream-dirty?)
  (poo-flow-package-require-gxpkg-env!)
  (poo-flow-package-message "check" label stage)
  (let* ((start-jiffy (current-jiffy))
         (upstream-dirty?
          (and (pair? maybe-upstream-dirty?)
               (car maybe-upstream-dirty?))))
    (call-with-values
      (lambda ()
        (poo-flow-stage-cache-assess stage options label))
      (lambda (current? reason receipt-status stamp)
        (if upstream-dirty?
          (poo-flow-make-upstream-dirty-stage! label
                                                stage
                                                options
                                                receipt-status
                                                stamp
                                                start-jiffy)
          (poo-flow-make-dispatch! label
                                   stage
                                   options
                                   current?
                                   reason
                                   receipt-status
                                   stamp
                                   start-jiffy))))))

;; : (-> String [BuildSpec] BuildOptions Void)
(def (poo-flow-make-uncached label stage options)
  (poo-flow-package-require-gxpkg-env!)
  (poo-flow-package-message "compile" label stage)
  (poo-flow-build-with-homebrew-static-clean
   (lambda ()
     (apply poo-flow-apply-make stage
            srcdir: (poo-flow-package-srcdir)
            (poo-flow-make-options options))))
  (poo-flow-native-object-output-directory-cache-clear!))

;; : (-> String BuildSpec BuildOptions Void)
(def (poo-flow-make-bootstrap-spec label spec options)
  (let ((stage (list spec))
        (start-jiffy (current-jiffy)))
    (if (poo-flow-bootstrap-spec-current? spec options label)
      (begin
        (poo-flow-package-message "skip" label stage)
        (poo-flow-build-debug-tracking-line
         'package-bootstrap-spec
         label
         "sequential std/make"
         'skipped
         'mtime-current
         stage
         options
         #f
         #f
         start-jiffy))
      (begin
        (poo-flow-make-uncached label stage options)
        (poo-flow-spec-output-files-retouch! spec options)
        (poo-flow-build-debug-tracking-line
         'package-bootstrap-spec
         label
         "sequential std/make"
         'compiled
         'stale
         stage
         options
         #f
         #f
         start-jiffy)))))

;; : (-> String [BuildSpec] BuildOptions MaybeAlist MaybeString Integer Void)
(def (poo-flow-make-bootstrap-skip-stale-current! label
                                                   stage
                                                   options
                                                   receipt-status
                                                   stamp
                                                   start-jiffy)
  (poo-flow-package-message "skip" label stage)
  (display "|note kind=build-cache message=\"package-local bootstrap outputs are current after stale target scan; skipped sequential bootstrap rebuild\"")
  (newline)
  (poo-flow-stage-cache-touch! stage options label)
  (poo-flow-build-debug-tracking-line
   'package-bootstrap-stage
   label
   "sequential std/make"
   'skipped
   'mtime-current
   stage
   options
   stamp
   receipt-status
   start-jiffy))

;; : (-> String [BuildSpec] BuildOptions Symbol MaybeAlist MaybeString Integer [BuildSpec] Boolean)
(def (poo-flow-make-bootstrap-compile-stale-stage! label
                                                   stage
                                                   options
                                                   reason
                                                   receipt-status
                                                   stamp
                                                   start-jiffy
                                                   stale-stage)
  (if (poo-flow-bootstrap-direct-gxc-stale-stage? stale-stage)
    (poo-flow-make-direct-gxc-stage! label stale-stage options)
    (for-each
     (lambda (spec)
       (poo-flow-make-bootstrap-spec label spec options))
     stale-stage))
  (poo-flow-stage-cache-touch! stage options label)
  (poo-flow-build-debug-tracking-line
   'package-bootstrap-stage
   label
   (if (poo-flow-bootstrap-direct-gxc-stale-stage? stale-stage)
     "direct gxc"
     "sequential std/make")
   'compiled
   reason
   stale-stage
   options
   stamp
   receipt-status
   start-jiffy)
  #t)

;; : (-> String [BuildSpec] BuildOptions Boolean)
(def (poo-flow-make-bootstrap label stage options)
  (poo-flow-package-require-gxpkg-env!)
  (poo-flow-package-message "check" label stage)
  (let (start-jiffy (current-jiffy))
    (call-with-values
      (lambda ()
        (poo-flow-stage-cache-assess stage options label))
      (lambda (current? reason receipt-status stamp)
        (if current?
          (begin
            (poo-flow-package-message "skip" label stage)
            (display "|note kind=build-cache message=\"package-local bootstrap outputs are current; skipped sequential bootstrap rebuild\"")
            (newline)
            (poo-flow-build-debug-tracking-line
             'package-bootstrap-stage
             label
             "sequential std/make"
             'skipped
             reason
             stage
             options
             stamp
             receipt-status
             start-jiffy)
            #f)
          (begin
            (let (stale-stage
                  (poo-flow-bootstrap-stale-specs stage options label))
              (if (null? stale-stage)
                (begin
                  (poo-flow-make-bootstrap-skip-stale-current!
                   label
                   stage
                   options
                   receipt-status
                   stamp
                   start-jiffy)
                  #f)
                (poo-flow-make-bootstrap-compile-stale-stage!
                 label
                 stage
                 options
                 reason
                 receipt-status
                 stamp
                 start-jiffy
                 stale-stage)))))))))

;; : (-> String [BuildSpec] Void)
(def (poo-flow-make-clean label stage)
  (poo-flow-package-require-gxpkg-env!)
  (poo-flow-package-message "clean" label stage)
  (apply poo-flow-apply-make-clean stage
         srcdir: (poo-flow-package-srcdir)
         (poo-flow-package-stage-options stage [])))

;; : (-> BuildSpec Boolean)
(def (poo-flow-make-cleanable-spec? spec)
  (match spec
    ([gxc: _ . _] #t)
    ([ssi: _ . _] #t)
    (_ #f)))

;; : (-> [BuildSpec] [BuildSpec])
(def (poo-flow-make-cleanable-stage stage)
  (filter poo-flow-make-cleanable-spec? stage))

;; : (-> BuildSpec String)
(def (poo-flow-gxc-spec-file spec)
  (match spec
    ([gxc: file . _] file)
    (_ (error "poo-flow direct gxc stage only supports gxc specs" spec))))

;; Scope SDKROOT cleanup to the active Homebrew compiler on macOS only.
;; : (forall (a) (-> (-> a) a))
(def (poo-flow-build-with-homebrew-static-clean thunk)
  (cond-expand
   (darwin
    (let (sdkroot (getenv "SDKROOT" #f))
      (if (and sdkroot
               (poo-flow-build-homebrew-static-clean?))
        (dynamic-wind
          (lambda () (setenv "SDKROOT" ""))
          thunk
          (lambda () (setenv "SDKROOT" sdkroot)))
        (thunk))))
   (else (thunk))))

;; poo-flow-compile-module/direct-gxc!
;;   : (-> String Void)
;;   | doc m%
;;       Compile one focused stale module through the compiler API already loaded
;;       by the package build process, avoiding a second external `gxc` startup.
;;     %
(def (poo-flow-compile-module/direct-gxc! label source)
  (poo-flow-build-with-homebrew-static-clean
   (lambda ()
     (compile-module source
                     [invoke-gsc: #t
                      gsc-options: (poo-flow-build-gsc-options)
                      keep-scm: #f
                      output-dir: (poo-flow-package-libdir)
                      optimize: #f
                      debug: #f
                      generate-ssxi: #t]))))

;; : (-> String BuildSpec BuildOptions Boolean Void)
(def (poo-flow-stage-result-elapsed-micros start-jiffy)
  (quotient
   (* (- (current-jiffy) start-jiffy) 1000000)
   (jiffies-per-second)))

(def (poo-flow-make-stage-result label specs outcome reason cache-status start-jiffy)
  (make-poo-flow-stage-result
   label
   specs
   outcome
   reason
   cache-status
   (poo-flow-stage-result-elapsed-micros start-jiffy)))

(def (poo-flow-run-gxc-specs! label specs options)
  (cond
   ((null? specs) '())
   (else
    (cons (poo-flow-run-gxc-spec/result! label (car specs) options)
          (poo-flow-run-gxc-specs!
           label
           (cdr specs)
           options)))))

(def (poo-flow-run-gxc-specs/force! label specs options)
  (cond
   ((null? specs) '())
   (else
    (cons (poo-flow-run-gxc-spec/result! label (car specs) options #t)
          (poo-flow-run-gxc-specs/force!
           label
           (cdr specs)
           options)))))

(def (poo-flow-run-gxc-spec! label spec options . maybe-force?)
  (let* ((file (poo-flow-gxc-spec-file spec))
         (source (poo-flow-gxc-source-file file))
         (stage (list spec))
         (start-jiffy (current-jiffy))
         (force? (and (pair? maybe-force?)
                      (car maybe-force?))))
    (if (and (not force?)
             (poo-flow-stage-spec-current? spec options label))
      (begin
        (poo-flow-package-message "skip" label stage)
        (poo-flow-build-debug-tracking-line
         'direct-gxc-spec
         label
         "gxc"
         'skipped
         'mtime-current
         stage
         options
         #f
         #f
         start-jiffy))
      (begin
        (display "|gxc file=")
        (write source)
        (newline)
        (poo-flow-delete-native-object-siblings! spec)
        (poo-flow-build-debug-start-line
         'direct-gxc-spec
         label
	         "gxc"
	         stage
	         options)
	        (poo-flow-build-observability-with-live-watchdog
	         'direct-gxc-spec
	         label
	         "gxc"
	         stage
         options
         (lambda ()
           (poo-flow-compile-module/direct-gxc! label source)))
	        (poo-flow-native-object-output-directory-cache-clear!)
	        (poo-flow-build-debug-tracking-line
	         'direct-gxc-spec
         label
         "gxc"
         'compiled
         (if force? 'upstream-stage-dirty 'stale)
	         stage
	         options
	         #f
	         #f
	         start-jiffy)))))

;; : (-> String [BuildSpec] BuildOptions Void)
(def (poo-flow-run-gxc-spec/result! label spec options . maybe-force?)
  (let* ((stage (list spec))
         (start-jiffy (current-jiffy))
         (force? (and (pair? maybe-force?)
                      (car maybe-force?)))
         (current? (and (not force?)
                        (poo-flow-stage-spec-current? spec options label))))
    (if force?
      (poo-flow-run-gxc-spec! label spec options #t)
      (poo-flow-run-gxc-spec! label spec options))
    (poo-flow-make-stage-result
     label
     stage
     (if current? 'skip 'compile)
     (if current?
       'mtime-current
       (if force? 'upstream-stage-dirty 'stale))
     (if current? 'current 'stale)
     start-jiffy)))

(def (poo-flow-gxc-stage label stage options)
  (let (start-jiffy (current-jiffy))
    (poo-flow-package-require-gxpkg-env!)
    (poo-flow-package-message "check" label stage)
    (if (poo-flow-stage-cache-valid? stage options)
      (begin
        (poo-flow-package-message "skip" label stage)
        (display "|note kind=build-cache message=\"package-local direct gxc outputs are current; skipped focused cli rebuild\"")
        (newline)
        (list (poo-flow-make-stage-result
               label
               stage
               'skip
               'stage-cache-valid
               'current
               start-jiffy)))
      (let (stale-stage
            (poo-flow-stage-stale-specs stage options label))
        (if (null? stale-stage)
          (begin
            (poo-flow-package-message "skip" label stage)
            (display "|note kind=build-cache message=\"package-local direct gxc outputs are current after stale target scan; skipped focused cli rebuild\"")
            (newline)
            (poo-flow-stage-cache-refresh! stage options label)
            (list (poo-flow-make-stage-result
                   label
                   stage
                   'skip
                   'stale-spec-current
                   'current
                   start-jiffy)))
          (begin
            (poo-flow-package-message "compile" label stale-stage)
            (let (results
                  (poo-flow-run-gxc-specs! label stale-stage options))
              (poo-flow-stage-cache-refresh! stage options label)
              results)))))))

;; : (-> String [BuildSpec] PooFlowBuildOptions Void)
;;; A test bootstrap cannot trust pre-existing native objects after a source
;;; tree or package identity change.  Rebuild its ordered interface closure on
;;; a stage-cache miss, then retain the regular warm-cache path.
(def (poo-flow-gxc-stage/force-on-cache-miss! label stage options)
  (let (start-jiffy (current-jiffy))
    (poo-flow-package-require-gxpkg-env!)
    (poo-flow-package-message "check" label stage)
    (if (poo-flow-stage-cache-valid? stage options)
      (begin
        (poo-flow-package-message "skip" label stage)
        (display "|note kind=build-cache message=\"test bootstrap outputs are current; skipped focused rebuild\"")
        (newline)
        (list (poo-flow-make-stage-result
               label
               stage
               'skip
               'stage-cache-valid
               'current
               start-jiffy)))
      (begin
        (poo-flow-package-message "compile" label stage)
        (let (results
              (poo-flow-run-gxc-specs/force! label stage options))
          (poo-flow-stage-cache-refresh! stage options label)
          results)))))

;; : (-> BuildOptions [BuildSpec])
(def (poo-flow-compile-build-spec options)
  (cond
   ((poo-flow-cli-build-options? options)
    (poo-flow-cli-only-build-spec options))
   ((poo-flow-release-build-options? options)
    (poo-flow-package-build-spec options))
   (else
    (poo-flow-package-build-spec options))))

;; : (-> BuildOptions Void)

;; : (-> Void)
(def (poo-flow-clean)
  (poo-flow-make-clean
   "package"
   (poo-flow-make-cleanable-stage
    (poo-flow-package-build-spec []))))
