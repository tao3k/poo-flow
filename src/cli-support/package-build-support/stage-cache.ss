;;; -*- Gerbil -*-
;;; Package build support module split out of ../package-build.ss.

(import (only-in "./receipt.ss"
                 poo-flow-package-build-receipt-status
                 poo-flow-package-build-receipt-status-ref
                 poo-flow-package-build-receipt-write)
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
        (only-in "./specs.ss"
                 poo-flow-package-flat-map
                 poo-flow-string-suffix?)
        (only-in "./env.ss"
                 poo-flow-delete-file-if-exists!
                 poo-flow-native-object-output-directory-cache-clear!
                 poo-flow-package-srcdir)
        (only-in "./options.ss"
                 poo-flow-force-build-options?
                 poo-flow-native-build-options?)
        (only-in "./stage-output.ss"
                 poo-flow-all?
                 poo-flow-diagnostic-gxc-spec?
                 poo-flow-diagnostic-output-files
                 poo-flow-diagnostic-outputs
                 poo-flow-diagnostic-source-path
                 poo-flow-gxc-source-file
                 poo-flow-native-object-output-files
                 poo-flow-package-libdir-prefix
                 poo-flow-stage-cache-stamp-path
                 poo-flow-stage-default-source-files
                 poo-flow-stage-legacy-cache-stamp-path
                 poo-flow-stage-output-files
                 poo-flow-stage-source-files))

(export #t)

;; : (-> BuildSpec Boolean)
(def (poo-flow-diagnostic-cache-spec? spec)
  (match spec
    ([gxc: . _] #t)
    ([gsc: . _] #t)
    ([ssi: . _] #t)
    (_ #f)))

;; : (-> [BuildSpec] BuildOptions Boolean)
(def (poo-flow-stage-cacheable? stage options)
  (poo-flow-all? poo-flow-diagnostic-cache-spec? stage))

;; : (-> String MaybeInteger)
(def (poo-flow-file-mtime-seconds path)
  (and (file-exists? path)
       (time->seconds
        (file-info-last-modification-time
         (file-info path)))))

;; : (-> String String Boolean)
(def (poo-flow-source-current-against-output?/mtime source output)
  (let ((source-time (poo-flow-file-mtime-seconds source))
        (output-time (poo-flow-file-mtime-seconds output)))
    (and source-time
         output-time
         (<= source-time output-time))))

;; : (-> [BuildSpec] String Boolean)
(def (poo-flow-stage-sources-current-against-stamp?/mtime stage stamp)
  (poo-flow-all?
   (lambda (source)
     (poo-flow-source-current-against-output?/mtime source stamp))
   (poo-flow-stage-source-files stage)))

;; : (-> BuildSpec Boolean)
(def (poo-flow-gxc-spec-lightweight-outputs-current?/mtime spec)
  (let ((source (poo-flow-diagnostic-source-path spec))
        (outputs (poo-flow-diagnostic-outputs spec)))
    (and source
         (not (null? outputs))
         (poo-flow-all?
          (lambda (output)
            (poo-flow-source-current-against-output?/mtime source output))
          outputs))))

;; : (-> [BuildSpec] Boolean)
(def (poo-flow-stage-lightweight-outputs-current?/mtime stage)
  (poo-flow-all?
   poo-flow-gxc-spec-lightweight-outputs-current?/mtime
   stage))

;; : (-> BuildSpec Boolean)
(def (poo-flow-gxc-spec-lightweight-outputs-present? spec)
  (let (outputs (poo-flow-diagnostic-outputs spec))
    (and (not (null? outputs))
         (poo-flow-all? file-exists? outputs))))

;; : (-> String String Boolean)
(def (poo-flow-source-newer-than-stamp?/mtime source stamp)
  (let ((source-time (poo-flow-file-mtime-seconds source))
        (stamp-time (poo-flow-file-mtime-seconds stamp)))
    (or (not source-time)
        (not stamp-time)
        (> source-time stamp-time))))

;; : (-> BuildSpec String Boolean)
(def (poo-flow-stage-spec-source-stale?/mtime spec stamp)
  (let (source (poo-flow-diagnostic-source-path spec))
    (or (not source)
        (poo-flow-source-newer-than-stamp?/mtime source stamp)
        (not (poo-flow-gxc-spec-lightweight-outputs-present? spec)))))

;; : (-> [BuildSpec] String [BuildSpec])
(def (poo-flow-stage-source-stale-specs stage stamp)
  (filter (lambda (spec)
            (poo-flow-stage-spec-source-stale?/mtime spec stamp))
          stage))

;; : (-> [BuildSpec] BuildOptions String Boolean)
(def (poo-flow-stage-fast-stamp-current?/mtime stage options stamp)
  (and (not (poo-flow-force-build-options? options))
       (poo-flow-stage-cacheable? stage options)
       (file-exists? stamp)
       (poo-flow-stage-sources-current-against-stamp?/mtime stage stamp)
       (poo-flow-stage-lightweight-outputs-current?/mtime stage)))

;; : (-> String String Boolean)
(def (poo-flow-native-objects-current?/mtime source output)
  (let (outputs (poo-flow-native-object-output-files output))
    (and (not (null? outputs))
         (poo-flow-source-current-against-any-output?/mtime source outputs))))

;; : (-> BuildSpec BuildOptions Boolean)
(def (poo-flow-gxc-spec-outputs-current?/mtime spec options)
  (let ((source (poo-flow-diagnostic-source-path spec))
        (outputs (poo-flow-diagnostic-outputs spec)))
    (and source
         (not (null? outputs))
         (let (source-time (poo-flow-file-mtime-seconds source))
           (and source-time
                (poo-flow-all?
                 (lambda (output)
                   (let (output-time (poo-flow-file-mtime-seconds output))
                     (and output-time (<= source-time output-time))))
                 outputs)
                (or (not (poo-flow-native-build-options? options))
	                    (poo-flow-all?
	                     (lambda (output)
	                       (poo-flow-native-objects-current?/mtime
	                        source
	                        output))
	                     outputs)))))))

;; poo-flow-stage-spec-outputs-current?/mtime
;;   : (-> BuildSpec BuildOptions Boolean)
;;   | doc m%
;;       Use the primary gxc output fast path for per-spec stale scans. Full
;;       stage receipt writes still collect diagnostic/native outputs.
;;     %
(def (poo-flow-stage-spec-outputs-current?/mtime spec options)
  (match spec
    ([gxc: . _]
     (poo-flow-gxc-spec-primary-outputs-current?/mtime spec))
    (_
     (poo-flow-gxc-spec-outputs-current?/mtime spec options))))

;; : (-> String String)
(def (poo-flow-source-stem path)
  (let ((suffix ".ss")
        (path-length (string-length path)))
    (if (poo-flow-string-suffix? suffix path)
      (substring path 0 (- path-length (string-length suffix)))
      path)))

;; : (-> String String String)
(def (poo-flow-package-output-path stem suffix)
  (path-expand
   (string-append ".gerbil/lib/poo-flow/" stem suffix)
   (poo-flow-package-srcdir)))

;; : (-> String String Boolean)
(def (poo-flow-file-current-against-source?/mtime source output)
  (let ((source-time (poo-flow-file-mtime-seconds source))
        (output-time (poo-flow-file-mtime-seconds output)))
    (and source-time output-time (<= source-time output-time))))

;; : (-> String String Boolean)
(def (poo-flow-existing-file-current-against-source?/mtime source output)
  (or (not (file-exists? output))
      (poo-flow-file-current-against-source?/mtime source output)))

;; : (-> BuildSpec Boolean)
(def (poo-flow-gxc-spec-primary-outputs-current?/mtime spec)
  (match spec
    ([gxc: file . _]
     (let* ((source (poo-flow-gxc-source-file file))
            (stem (poo-flow-source-stem source))
            (ssi (poo-flow-package-output-path stem ".ssi"))
            (scm (poo-flow-package-output-path stem ".scm"))
            (object (poo-flow-package-output-path stem ".o")))
       (and (poo-flow-file-current-against-source?/mtime source ssi)
            (poo-flow-file-current-against-source?/mtime source scm)
            (poo-flow-existing-file-current-against-source?/mtime
             source
             object))))
    (_ #f)))

;; : (-> [BuildSpec] Boolean)
(def (poo-flow-stage-primary-outputs-current?/mtime stage)
  (and (not (null? stage))
       (poo-flow-all? poo-flow-gxc-spec-primary-outputs-current?/mtime
                      stage)))

;; : (-> String [String] Boolean)
(def (poo-flow-source-current-against-outputs?/mtime source outputs)
  (let (source-time (poo-flow-file-mtime-seconds source))
    (and source-time
         (poo-flow-all?
          (lambda (output)
            (let (output-time (poo-flow-file-mtime-seconds output))
              (and output-time (<= source-time output-time))))
          outputs))))

;; poo-flow-source-current-against-any-output?/mtime
;; : (-> String [String] Boolean)
;; | doc m%
;;   Return true when SOURCE is no newer than at least one output file.
;;   # Examples
;;   ```scheme
;;   (poo-flow-source-current-against-any-output?/mtime source outputs)
;;   ;; => #t when any output is current
;;   ```
(def (poo-flow-source-current-against-any-output?/mtime source outputs)
  (let (source-time (poo-flow-file-mtime-seconds source))
    (and source-time
         (let loop ((rest outputs))
           (match rest
             ([] #f)
             ([output . rest]
              (let (output-time (poo-flow-file-mtime-seconds output))
                (or (and output-time (<= source-time output-time))
                    (loop rest)))))))))

;; : (-> [BuildSpec] BuildOptions Boolean)
(def (poo-flow-default-sources-current?/mtime stage options)
  (let (outputs (poo-flow-stage-output-files stage options))
    (and (not (null? outputs))
         (poo-flow-all?
          (lambda (source)
            (poo-flow-source-current-against-outputs?/mtime source outputs))
          (poo-flow-stage-default-source-files)))))

;; : (-> [BuildSpec] BuildOptions Boolean)
(def (poo-flow-stage-outputs-current?/mtime stage options)
  (and (not (null? stage))
       (poo-flow-all?
	     (lambda (spec)
	          (poo-flow-stage-spec-outputs-current?/mtime spec options))
	        stage)))

;; : (-> BuildOptions [String] Boolean)
(def (poo-flow-native-stage-stamp-seed-present? options maybe-label)
  (or (not (poo-flow-native-build-options? options))
      (file-exists?
       (apply poo-flow-stage-cache-stamp-path
              options
              maybe-label))
      (file-exists?
       (apply poo-flow-stage-legacy-cache-stamp-path
              options
              maybe-label))))

;; poo-flow-stage-cache-assess-sources-stale
;;   : (-> [BuildSpec] BuildOptions String [String]
;;         (Values Boolean Symbol MaybeAlist String))
;;   | doc m%
;;       A source newer than the cache stamp is not automatically a rebuild:
;;       direct compiles can leave outputs newer than sources while the receipt
;;       stamp is old. Refresh the receipt when outputs are already current.
;;     %
(def (poo-flow-stage-cache-assess-sources-stale stage options stamp sources)
  (if (poo-flow-stage-outputs-current?/mtime stage options)
    (begin
      (poo-flow-stage-cache-write! stamp sources
                                   (poo-flow-stage-output-files
                                    stage
                                    options))
      (values #t 'mtime-current #f stamp))
    (values #f 'sources-stale #f stamp)))

;; : (-> [BuildSpec] BuildOptions [String] (Values Boolean Symbol MaybeAlist MaybeString))
(def (poo-flow-stage-cache-assess stage options . maybe-label)
  (cond
   ((poo-flow-force-build-options? options)
    (values #f 'forced #f #f))
   ((not (poo-flow-stage-cacheable? stage options))
    (values #f 'unsupported-stage-or-native-options #f #f))
   (else
    (let* ((stamp (apply poo-flow-stage-cache-stamp-path
                         options
                         maybe-label))
            (sources (poo-flow-stage-source-files stage)))
       (cond
        ((and (poo-flow-stage-fast-stamp-current?/mtime stage options stamp)
              (poo-flow-stage-primary-outputs-current?/mtime stage))
         (values #t 'stamp-current #f stamp))
        ((and (file-exists? stamp)
              (not (poo-flow-stage-sources-current-against-stamp?/mtime
                    stage
                    stamp)))
         (poo-flow-stage-cache-assess-sources-stale stage
                                                    options
                                                    stamp
                                                    sources))
        ((and (file-exists? stamp)
              (poo-flow-stage-lightweight-outputs-current?/mtime stage))
         (begin
           (poo-flow-stage-cache-retouch! stamp)
           (values #t 'mtime-current #f stamp)))
        (else
         (let* ((outputs (poo-flow-stage-output-files stage options))
               (status (poo-flow-package-build-receipt-status
                         stamp
                         expected-sources: sources
                         expected-outputs: outputs))
                (receipt-status (poo-flow-package-build-receipt-status-ref
                                 status
                                 'status
                                 'stale)))
           (cond
            ((and (eq? receipt-status 'current)
                  (poo-flow-stage-primary-outputs-current?/mtime stage))
             (values #t 'receipt-current status stamp))
            ((and (poo-flow-native-stage-stamp-seed-present?
                   options
                   maybe-label)
                  (poo-flow-stage-outputs-current?/mtime stage options))
             (begin
               (poo-flow-stage-cache-write! stamp sources outputs)
               (values #t 'mtime-current status stamp)))
            (else
             (values #f receipt-status status stamp))))))))))

;; : (-> [BuildSpec] BuildOptions [String] Boolean)
(def (poo-flow-stage-cache-valid? stage options . maybe-label)
  (call-with-values
    (lambda ()
      (apply poo-flow-stage-cache-assess
             stage
             options
             maybe-label))
    (lambda (current? _reason _receipt-status _stamp)
      current?)))

;; : (-> BuildOptions [String] Boolean)
(def (poo-flow-native-stage-stamp-present? options maybe-label)
  (poo-flow-native-stage-stamp-seed-present? options maybe-label))

;; : (-> BuildSpec BuildOptions [String] Boolean)
(def (poo-flow-stage-spec-current? spec options . maybe-label)
  (let (stage (list spec))
    (and (not (poo-flow-force-build-options? options))
         (poo-flow-stage-cacheable? stage options)
         (poo-flow-native-stage-stamp-present? options maybe-label)
         (poo-flow-stage-outputs-current?/mtime stage options))))

;; : (-> [BuildSpec] BuildOptions [String] [BuildSpec])
(def (poo-flow-stage-stale-specs stage options . maybe-label)
  (filter (lambda (spec)
            (not (apply poo-flow-stage-spec-current?
                        spec
                        options
                        maybe-label)))
          stage))

;; : (-> BuildSpec BuildOptions [String] Boolean)
(def (poo-flow-bootstrap-spec-current? spec options . maybe-label)
  (apply poo-flow-stage-spec-current?
         spec
         options
         maybe-label))

;; : (-> String [String] [String] Void)
(def (poo-flow-stage-cache-write! stamp sources outputs)
  (when (file-exists? stamp)
    (delete-file stamp))
  (poo-flow-package-build-receipt-write stamp sources outputs))

;; : (-> String Void)
(def (poo-flow-stage-cache-retouch! stamp)
  (let (time (current-second))
    (##os-file-times-set! stamp time time)))

;; : (-> [String] Void)
(def (poo-flow-output-files-retouch! outputs)
  (let (time (current-second))
    (for-each
     (lambda (output)
       (when (file-exists? output)
         (##os-file-times-set! output time time)))
     outputs)))

;; : (-> BuildSpec [String])
(def (poo-flow-gxc-spec-primary-output-files spec)
  (match spec
    ([gxc: file . _]
     (let* ((source (poo-flow-gxc-source-file file))
            (stem (poo-flow-source-stem source))
            (ssi (poo-flow-package-output-path stem ".ssi"))
            (scm (poo-flow-package-output-path stem ".scm"))
            (object (poo-flow-package-output-path stem ".o")))
       (if (file-exists? object)
         (list ssi scm object)
         (list ssi scm))))
    (_ [])))

;; : (-> BuildSpec BuildOptions Void)
(def (poo-flow-spec-output-files-retouch! spec options)
  (poo-flow-output-files-retouch!
   (append (poo-flow-gxc-spec-primary-output-files spec)
           (poo-flow-diagnostic-output-files spec options))))

;; poo-flow-delete-native-object-siblings!
;;   : (-> BuildSpec Void)
;;   | doc m%
;;       Direct single-target compiles can leave incrementing Gambit native
;;       object siblings behind. Remove the old siblings before compiling so
;;       repeated stale checks do not grow output scans or linker work.
;;     %
(def (poo-flow-delete-native-object-siblings! spec)
  (poo-flow-native-object-output-directory-cache-clear!)
  (let (outputs (poo-flow-diagnostic-outputs spec))
    (for-each
     poo-flow-delete-file-if-exists!
     (poo-flow-package-flat-map
      poo-flow-native-object-output-files
      outputs)))
  (poo-flow-native-object-output-directory-cache-clear!))

;; : (-> [BuildSpec] BuildOptions [String] Void)
(def (poo-flow-stage-cache-touch! stage options . maybe-label)
  (when (poo-flow-stage-cacheable? stage options)
    (poo-flow-stage-cache-write!
     (apply poo-flow-stage-cache-stamp-path
            options
            maybe-label)
     (poo-flow-stage-source-files stage)
     (poo-flow-stage-output-files stage options))))

;; : (-> [BuildSpec] BuildOptions [String] Void)
(def (poo-flow-stage-cache-refresh! stage options . maybe-label)
  (when (poo-flow-stage-cacheable? stage options)
    (apply poo-flow-stage-cache-touch! stage options maybe-label)))
