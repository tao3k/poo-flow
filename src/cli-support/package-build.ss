;;; -*- Gerbil -*-
;;; Package build implementation used by the thin build.ss entrypoints.

(import :clan/building
        (only-in :gslph/src/build-api/package-receipt
                 gslph-package-build-receipt-status
                 gslph-package-build-receipt-status-ref
                 gslph-package-build-receipt-write)
        (only-in :gerbil/gambit
                 current-directory
                 current-jiffy
                 file-exists?
                 getenv
                 jiffies-per-second
                 path-expand
                 string=?
                 string-append
                 ##cpu-count)
        (only-in :gerbil/compiler/base
                 __available-cores)
        (only-in :std/make
                 make
                 make-clean)
        (only-in :std/misc/process
                 run-process)
        (only-in :std/sugar
                 filter))

(export #t)

(def (nono-c-binding-include-option)
  (string-append "-I" (path-expand "bindings/nono-c")))

(def +poo-flow-runtime-include-dirs+
  '("src"))

(def +poo-flow-test-include-dirs+
  '("t"))

(def +poo-flow-test-support-include-dirs+
  '("t/support"))

(def +poo-flow-runtime-extra-source-files+
  '("src/core/runtime-protocol.ss"
    "src/core/runtime-command-invocation.ss"
    "src/core/runtime-command-descriptor.ss"
    "src/core/runtime-command.ss"
    "src/module-system/base-selection-flags.ss"
    "src/modules/funflow/config-prototypes.ss"
    "src/modules/session/objects-core.ss"
    "src/modules/session/objects-handoff.ss"
    "src/modules/session/objects-graph.ss"
    "src/modules/session/config-session-syntax-core.ss"
    "src/modules/session/config-session-syntax-communication.ss"
    "src/modules/session/config-session-syntax-selector.ss"
    "src/modules/session/config-session-syntax-materialization.ss"
    "src/modules/session/config-session-syntax-agent-node.ss"
    "src/modules/session/config-session-syntax-agent.ss"
    "src/modules/session/config-session-syntax.ss"
    "src/modules/session/config-policy-syntax.ss"))

(def +poo-flow-test-extra-source-files+
  '("t/support/loop-engine-runtime-manifest-receipts.ss"))

(def +poo-flow-special-source-files+
  '("src/modules/nono-sandbox/_nono.ss"
    "src/cli-support/support.ss"
    "src/cli-support/testing-project.ss"
    "src/cli-support/package-build.ss"
    "src/cli.ss"
    "main.ss"
    "manifest.ss"))

(def +poo-flow-ffi-build-spec+
  `((gsc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,(nono-c-binding-include-option))
    (ssi: "src/modules/nono-sandbox/_nono")))

(def +poo-flow-cli-library-build-spec+
  '((gxc: "src/cli-support/support.ss")
    (gxc: "src/cli-support/testing-project.ss")
    (gxc: "src/cli-support/package-build.ss")
    (gxc: "src/cli.ss")))

(def +poo-flow-cli-entry-module-build-spec+
  '((gxc: "user-interface/init")
    (gxc: "user-interface/custom/my-module/cases/loop-engine-owner")
    (gxc: "user-interface/custom/my-module/config")))

(def +poo-flow-runtime-bootstrap-modules+
  '("src/module-system/durable-policy.ss"
    "src/core/runtime-protocol.ss"
    "src/core/runtime-command-invocation.ss"
    "src/core/runtime-command-descriptor.ss"
    "src/core/runtime-command.ss"
    "src/core/runtime-adapter.ss"
    "src/modules/session/objects-core.ss"
    "src/modules/session/objects-handoff.ss"
    "src/modules/session/objects-graph.ss"
    "src/modules/session/objects.ss"
    "src/modules/session/communication.ss"
    "src/modules/session/registry.ss"
    "src/modules/session/agent.ss"
    "src/module-system/loop-engine-intent-utils.ss"
    "src/module-system/loop-engine-session-agent-graph.ss"
    "src/module-system/loop-engine-runtime-agent.ss"
    "src/module-system/durable-runtime-store.ss"
    "src/module-system/durable-runtime-store-backend.ss"
    "src/module-system/durable-runtime-store-operation.ss"
    "src/module-system/durable-runtime-store-operation-bridge.ss"
    "src/module-system/durable-recovery-scenario.ss"
    "src/module-system/load-syntax.ss"
    "src/modules/session/receipt-syntax.ss"
    "src/modules/session/config-session-syntax-core.ss"
    "src/modules/session/config-session-syntax-communication.ss"
    "src/modules/session/config-session-syntax-selector.ss"
    "src/modules/session/config-session-syntax-materialization.ss"
    "src/modules/session/config-session-syntax-agent-node.ss"
    "src/modules/session/config-session-syntax-agent.ss"
    "src/modules/session/config-session-syntax.ss"
    "src/modules/session/config-policy-syntax.ss"
    "src/modules/session/config.ss"))

(def (poo-flow-cli-entry-build-spec _options)
  +poo-flow-cli-entry-module-build-spec+)

(def (poo-flow-entry-build-spec options)
  (poo-flow-cli-entry-build-spec options))

(def (poo-flow-cli-only-build-spec _options)
  +poo-flow-cli-library-build-spec+)

(def (poo-flow-cli-only-module-build-spec _options)
  +poo-flow-cli-library-build-spec+)

(def (poo-flow-cli-bin-dir)
  (path-expand "bin" (getenv "GERBIL_PATH")))

(def (poo-flow-cli-launcher-path)
  (path-expand "poo-flow" (poo-flow-cli-bin-dir)))

(def (poo-flow-cli-launcher-scheme-path)
  (path-expand "poo-flow-launcher.ss" (poo-flow-cli-bin-dir)))

(def (poo-flow-delete-file-if-exists! path)
  (when (file-exists? path)
    (delete-file path)))

(def (poo-flow-ensure-cli-bin-dir!)
  (unless (file-exists? (poo-flow-cli-bin-dir))
    (create-directory (poo-flow-cli-bin-dir))))

(def (poo-flow-write-cli-launcher-scheme port)
  (display "#!/usr/bin/env gxi\n" port)
  (display ";;; Generated by poo-flow package build; do not edit.\n" port)
  (display "(import :gerbil/gambit :poo-flow/src/cli)\n" port)
  (display "(poo-flow-cli-main (poo-flow-cli-script-args (command-line)))\n" port))

(def (poo-flow-write-cli-launcher-shell port)
  (display "#!/bin/sh\n" port)
  (display "# Generated by poo-flow package build; do not edit.\n" port)
  (display "set -eu\n" port)
  (display "bin_dir=$(CDPATH= cd -- \"$(dirname -- \"$0\")\" && pwd)\n" port)
  (display "gerbil_path=$(dirname -- \"$bin_dir\")\n" port)
  (display "case \"${GERBIL_PATH:-}\" in\n" port)
  (display "  \"\") export GERBIL_PATH=\"$gerbil_path\" ;;\n" port)
  (display "  *\"$gerbil_path\"*) ;;\n" port)
  (display "  *) export GERBIL_PATH=\"$gerbil_path:$GERBIL_PATH\" ;;\n" port)
  (display "esac\n" port)
  (display "exec gxi \"$bin_dir/poo-flow-launcher.ss\" \"$@\"\n" port))

(def (poo-flow-write-generated-file! path writer)
  (poo-flow-delete-file-if-exists! path)
  (call-with-output-file path writer))

(def (poo-flow-write-cli-launcher!)
  (poo-flow-package-require-gxpkg-env!)
  (poo-flow-ensure-cli-bin-dir!)
  (poo-flow-write-generated-file!
   (poo-flow-cli-launcher-scheme-path)
   poo-flow-write-cli-launcher-scheme)
  (poo-flow-write-generated-file!
   (poo-flow-cli-launcher-path)
   poo-flow-write-cli-launcher-shell)
  (run-process ["chmod" "755"
                (poo-flow-cli-launcher-scheme-path)
                (poo-flow-cli-launcher-path)]
               stdout-redirection: #f
               stderr-redirection: #f))

(def (poo-flow-with-directory directory thunk)
  (let (previous (current-directory))
    (dynamic-wind
      (lambda () (current-directory directory))
      thunk
      (lambda () (current-directory previous)))))

(def (poo-flow-root-module-path? path)
  (let loop ((index 0))
    (cond
     ((= index (string-length path)) #t)
     ((char=? (string-ref path index) #\/) #f)
     (else (loop (+ index 1))))))

;; : (-> String [String] [String] [String])
(def (poo-flow-module-files/prefix-rev dir paths files-rev)
  (if (null? paths)
    files-rev
    (poo-flow-module-files/prefix-rev
     dir
     (cdr paths)
     (cons (string-append dir "/" (car paths)) files-rev))))

;; : (-> String [String] [String])
(def (poo-flow-module-files/prefix dir paths)
  (reverse (poo-flow-module-files/prefix-rev dir paths '())))

(def (poo-flow-module-files dir exclude-dirs root-only?)
  (poo-flow-with-directory dir
    (lambda ()
      (let (modules (all-gerbil-modules exclude-dirs: exclude-dirs))
        (poo-flow-module-files/prefix
         dir
         (if root-only?
           (filter poo-flow-root-module-path? modules)
           modules))))))

(def (poo-flow-package-flat-map/rev proc value results)
  (let loop ((remaining-values (proc value))
             (result-values results))
    (if (null? remaining-values)
      result-values
      (loop (cdr remaining-values)
            (cons (car remaining-values) result-values)))))

(def (poo-flow-package-flat-map proc values)
  (let loop ((remaining-values values)
             (result-values []))
    (if (null? remaining-values)
      (reverse result-values)
      (loop (cdr remaining-values)
            (poo-flow-package-flat-map/rev
             proc
             (car remaining-values)
             result-values)))))

(def (poo-flow-package-modules dirs exclude-dirs root-only?)
  (poo-flow-package-flat-map
   (lambda (dir)
     (poo-flow-module-files dir exclude-dirs root-only?))
   dirs))

(def (poo-flow-package-remove-members/rev files excluded files-rev)
  (cond
   ((null? files) files-rev)
   ((member (car files) excluded)
    (poo-flow-package-remove-members/rev (cdr files) excluded files-rev))
   (else
    (poo-flow-package-remove-members/rev
     (cdr files)
     excluded
     (cons (car files) files-rev)))))

(def (poo-flow-package-remove-members files excluded)
  (reverse (poo-flow-package-remove-members/rev files excluded [])))

;; : (-> [String] [String] [String])
(def (poo-flow-package-append-missing files extras)
  (append files
          (filter (lambda (extra) (not (member extra files)))
                  extras)))

(def (poo-flow-runtime-modules)
  (poo-flow-package-remove-members
   (poo-flow-package-append-missing
    (poo-flow-package-modules +poo-flow-runtime-include-dirs+ '() #f)
    +poo-flow-runtime-extra-source-files+)
   +poo-flow-special-source-files+))

(def (poo-flow-runtime-bootstrap-modules)
  (filter file-exists? +poo-flow-runtime-bootstrap-modules+))

(def (poo-flow-runtime-main-modules)
  (let (bootstrap (poo-flow-runtime-bootstrap-modules))
    (poo-flow-package-remove-members
     (poo-flow-runtime-modules)
     bootstrap)))

(def (poo-flow-test-modules)
  (poo-flow-package-append-missing
   (append (poo-flow-package-modules +poo-flow-test-include-dirs+ '() #t)
           (poo-flow-package-modules
            +poo-flow-test-support-include-dirs+
            '()
            #f))
   +poo-flow-test-extra-source-files+))

(def (poo-flow-gxc-target file _options)
  [gxc: file])

(def (poo-flow-gxc-spec/rev files options specs-rev)
  (if (null? files)
    specs-rev
    (poo-flow-gxc-spec/rev
     (cdr files)
     options
     (cons (poo-flow-gxc-target (car files) options) specs-rev))))

(def (poo-flow-gxc-spec files options)
  (reverse (poo-flow-gxc-spec/rev files options [])))

(def (poo-flow-runtime-build-spec options)
  (poo-flow-gxc-spec
   (append (poo-flow-runtime-bootstrap-modules)
           (poo-flow-runtime-main-modules))
   options))

(def (poo-flow-runtime-bootstrap-build-spec options)
  (poo-flow-gxc-spec (poo-flow-runtime-bootstrap-modules) options))

(def (poo-flow-runtime-main-build-spec options)
  (poo-flow-gxc-spec (poo-flow-runtime-main-modules) options))

(def (poo-flow-test-build-spec options)
  (poo-flow-gxc-spec (poo-flow-test-modules) options))

(def (poo-flow-package-build-spec options)
  (if (poo-flow-native-build-options? options)
    (append +poo-flow-ffi-build-spec+
            (poo-flow-runtime-build-spec options)
            (poo-flow-test-build-spec options)
            +poo-flow-cli-library-build-spec+
            (poo-flow-entry-build-spec options))
    (append (poo-flow-runtime-build-spec options)
            (poo-flow-test-build-spec options)
            +poo-flow-cli-library-build-spec+
            (poo-flow-entry-build-spec options))))

(def (poo-flow-package-build-spec/without-bootstrap options)
  (if (poo-flow-native-build-options? options)
    (append +poo-flow-ffi-build-spec+
            (poo-flow-runtime-main-build-spec options)
            (poo-flow-test-build-spec options)
            +poo-flow-cli-library-build-spec+
            (poo-flow-entry-build-spec options))
    (append (poo-flow-runtime-main-build-spec options)
            (poo-flow-test-build-spec options)
            +poo-flow-cli-library-build-spec+
            (poo-flow-entry-build-spec options))))

(def (poo-flow-package-library-build-spec/without-bootstrap options)
  (if (poo-flow-native-build-options? options)
    (append +poo-flow-ffi-build-spec+
            (poo-flow-runtime-main-build-spec options)
            (poo-flow-test-build-spec options)
            +poo-flow-cli-library-build-spec+)
    (append (poo-flow-runtime-main-build-spec options)
            (poo-flow-test-build-spec options)
            +poo-flow-cli-library-build-spec+)))

(def (spec)
  (poo-flow-package-build-spec []))

(def (poo-flow-package-srcdir)
  (path-expand "."))

(def (poo-flow-package-require-gxpkg-env!)
  (unless (getenv "GERBIL_PATH" #f)
    (error "poo-flow package builds require gxpkg env; run gxpkg env gxi build.ss compile")))

(def (poo-flow-package-cores-from-env name)
  (let (value (getenv name #f))
    (and value
         (let (cores (string->number value))
           (and (integer? cores)
                (> cores 0)
                cores)))))

(def (poo-flow-package-worker-count)
  (or (poo-flow-package-cores-from-env "GERBIL_BUILD_CORES")
      (max 1 (##cpu-count))))

(def (poo-flow-package-parallelize)
  (let (worker-count (poo-flow-package-worker-count))
    (set! __available-cores worker-count)
    worker-count))

(def (poo-flow-make-options options)
  (match options
    ([build-cli: _ . rest]
     (poo-flow-make-options rest))
    ([force: _ . rest]
     (poo-flow-make-options rest))
    ([key value . rest]
     (cons key
           (cons value
                 (poo-flow-make-options rest))))
    ([] [])))

(def (poo-flow-package-options options)
  (let (parallelize (poo-flow-package-parallelize))
    (if parallelize
      (append (poo-flow-make-options options) [parallelize: parallelize])
      (poo-flow-make-options options))))

(def (poo-flow-package-stage-options stage options)
  (if (> (length stage) 1)
    (poo-flow-package-options options)
    (poo-flow-make-options options)))

(def (poo-flow-package-message action label stage)
  (display "... poo-flow ")
  (display action)
  (display " ")
  (display label)
  (display " targets=")
  (display (length stage))
  (let (parallelize (and (> (length stage) 1)
                         (poo-flow-package-worker-count)))
    (when parallelize
      (display " parallelize=")
      (display parallelize)))
  (newline)
  (force-output))

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

(def (poo-flow-build-elapsed-micros start-jiffy end-jiffy)
  (quotient (* (- end-jiffy start-jiffy) 1000000)
            (jiffies-per-second)))

(def (poo-flow-build-debug-output-count stage options status reason)
  (length
   (if (and (eq? status 'skipped)
            (or (eq? reason 'stamp-current)
                (eq? reason 'receipt-current)))
     (poo-flow-package-flat-map
      poo-flow-diagnostic-outputs
      stage)
     (poo-flow-stage-output-files stage options))))

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
           (cache-status (and receipt-status
                              (gslph-package-build-receipt-status-ref
                               receipt-status
                               'status
                               #f)))
           (target-count (length stage))
           (raw-targets-preview
            (let loop ((rest stage) (remaining 3) (acc []))
              (if (or (null? rest) (= remaining 0))
                (reverse acc)
                (let (source (poo-flow-diagnostic-source-path (car rest)))
                  (loop (cdr rest)
                        (if source (- remaining 1) remaining)
                        (if source (cons source acc) acc))))))
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
        elapsed-micros: (poo-flow-build-elapsed-micros
                         start-jiffy
                         end-jiffy)])
      (newline)
      (force-output))))

(def (poo-flow-all? pred xs)
  (match xs
    ([] #t)
    ([x . rest]
     (and (pred x) (poo-flow-all? pred rest)))))

(def (poo-flow-package-libdir)
  (path-expand "lib" (getenv "GERBIL_PATH")))

(def (poo-flow-package-libdir-prefix)
  (path-expand "poo-flow" (poo-flow-package-libdir)))

(def (poo-flow-stage-cache-stamp-path options . maybe-label)
  (path-expand
   (string-append
    (cond
     ((poo-flow-cli-build-options? options) ".compile-cli")
     (else ".compile-package"))
    (cond
     ((poo-flow-release-build-options? options) "-release")
     ((poo-flow-optimized-build-options? options) "-optimized")
     ((poo-flow-debug-build-options? options) "-debug")
     (else ""))
    (if (null? maybe-label)
      ""
      (string-append "-" (car maybe-label)))
    ".stamp")
   (poo-flow-package-libdir-prefix)))

(def (poo-flow-stage-legacy-cache-stamp-path options . maybe-label)
  (path-expand
   (string-append
    (cond
     ((poo-flow-cli-build-options? options) ".compile-cli")
     (else ".compile-package"))
    (if (null? maybe-label)
      ""
      (string-append "-" (car maybe-label)))
    ".stamp")
   (poo-flow-package-libdir-prefix)))

(def (poo-flow-diagnostic-gxc-file file)
  (let (source (path-expand file (poo-flow-package-srcdir)))
    (if (file-exists? source)
      file
      (let (source.ss (string-append file ".ss"))
        (if (file-exists? (path-expand source.ss (poo-flow-package-srcdir)))
          source.ss
          file)))))

(def (poo-flow-diagnostic-source-path spec)
  (match spec
    ([gxc: file . _]
     (path-expand
      (poo-flow-diagnostic-gxc-file file)
      (poo-flow-package-srcdir)))
    (_ #f)))

(def (poo-flow-stage-default-source-files/rev files sources-rev)
  (if (null? files)
    sources-rev
    (poo-flow-stage-default-source-files/rev
     (cdr files)
     (cons (path-expand (car files) (poo-flow-package-srcdir))
           sources-rev))))

(def (poo-flow-stage-default-source-files)
  (reverse
   (poo-flow-stage-default-source-files/rev
    '("build.ss" "gerbil.pkg")
    [])))

(def (poo-flow-stage-source-files stage)
  (let lp ((rest stage) (sources []))
    (match rest
      ([] (append (reverse sources)
                  (poo-flow-stage-default-source-files)))
      ([spec . rest]
       (let (source (poo-flow-diagnostic-source-path spec))
         (if source
           (lp rest (cons source sources))
           (lp rest sources)))))))

(def (poo-flow-diagnostic-gxc-spec? spec)
  (match spec
    ([gxc: . _] #t)
    (_ #f)))

(def (poo-flow-diagnostic-gxc-outputs file)
  [(path-expand (string-append (poo-flow-diagnostic-gxc-file file) "i")
                (poo-flow-package-libdir-prefix))])

(def (poo-flow-string-prefix? prefix value)
  (let (prefix-length (string-length prefix))
    (and (<= prefix-length (string-length value))
         (let loop ((index 0))
           (cond
            ((= index prefix-length) #t)
            ((char=? (string-ref prefix index)
                     (string-ref value index))
             (loop (+ index 1)))
            (else #f))))))

(def (poo-flow-native-object-prefix output)
  (let (file (path-strip-directory output))
    (let (length (string-length file))
      (if (and (> length 4)
               (char=? (string-ref file (- length 4)) #\.)
               (char=? (string-ref file (- length 3)) #\s)
               (char=? (string-ref file (- length 2)) #\s)
               (char=? (string-ref file (- length 1)) #\i))
        (string-append (substring file 0 (- length 4)) ".o")
        file))))

(def (poo-flow-string-all-digits-from? value start)
  (let (length (string-length value))
    (and (< start length)
         (let loop ((index start))
           (cond
            ((= index length) #t)
            ((char-numeric? (string-ref value index))
             (loop (+ index 1)))
            (else #f))))))

(def (poo-flow-native-object-file-name? prefix file)
  (and (poo-flow-string-prefix? prefix file)
       (poo-flow-string-all-digits-from?
        file
        (string-length prefix))))

(def (poo-flow-native-object-output-files output)
  (let* ((directory (path-directory output))
         (prefix (poo-flow-native-object-prefix output)))
    (if (and directory (file-exists? directory))
      (let loop ((files (directory-files directory)) (outputs []))
        (match files
          ([]
           (reverse outputs))
          ([file . rest]
           (let (path (path-expand file directory))
             (loop rest
                   (if (and (poo-flow-native-object-file-name?
                             prefix
                             file)
                            (file-exists? path))
                     (cons path outputs)
                     outputs))))))
      [])))

(def (poo-flow-diagnostic-output-files spec options)
  (let (outputs (poo-flow-diagnostic-outputs spec))
    (if (poo-flow-native-build-options? options)
      (append outputs
              (poo-flow-package-flat-map
               poo-flow-native-object-output-files
               outputs))
      outputs)))

(def (poo-flow-stage-output-files stage options)
  (poo-flow-package-flat-map
   (lambda (spec)
     (poo-flow-diagnostic-output-files spec options))
   stage))

(def (poo-flow-diagnostic-outputs spec)
  (match spec
    ([gxc: file . _] (poo-flow-diagnostic-gxc-outputs file))
    (_ [])))

(def (poo-flow-stage-cacheable? stage options)
  (poo-flow-all? poo-flow-diagnostic-gxc-spec? stage))

(def (poo-flow-file-mtime-seconds path)
  (and (file-exists? path)
       (time->seconds
        (file-info-last-modification-time
         (file-info path)))))

(def (poo-flow-source-current-against-output?/mtime source output)
  (let ((source-time (poo-flow-file-mtime-seconds source))
        (output-time (poo-flow-file-mtime-seconds output)))
    (and source-time
         output-time
         (<= source-time output-time))))

(def (poo-flow-stage-sources-current-against-stamp?/mtime stage stamp)
  (poo-flow-all?
   (lambda (source)
     (poo-flow-source-current-against-output?/mtime source stamp))
   (poo-flow-stage-source-files stage)))

(def (poo-flow-gxc-spec-lightweight-outputs-current?/mtime spec)
  (let ((source (poo-flow-diagnostic-source-path spec))
        (outputs (poo-flow-diagnostic-outputs spec)))
    (and source
         (not (null? outputs))
         (poo-flow-all?
          (lambda (output)
            (poo-flow-source-current-against-output?/mtime source output))
          outputs))))

(def (poo-flow-stage-lightweight-outputs-current?/mtime stage)
  (poo-flow-all?
   poo-flow-gxc-spec-lightweight-outputs-current?/mtime
   stage))

(def (poo-flow-stage-fast-stamp-current?/mtime stage options stamp)
  (and (not (poo-flow-force-build-options? options))
       (poo-flow-stage-cacheable? stage options)
       (file-exists? stamp)
       (poo-flow-stage-sources-current-against-stamp?/mtime stage stamp)
       (poo-flow-stage-lightweight-outputs-current?/mtime stage)))

(def (poo-flow-native-objects-current?/mtime source output)
  (let (outputs (poo-flow-native-object-output-files output))
    (and (not (null? outputs))
         (poo-flow-source-current-against-any-output?/mtime source outputs))))

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

(def (poo-flow-source-current-against-outputs?/mtime source outputs)
  (let (source-time (poo-flow-file-mtime-seconds source))
    (and source-time
         (poo-flow-all?
          (lambda (output)
            (let (output-time (poo-flow-file-mtime-seconds output))
              (and output-time (<= source-time output-time))))
          outputs))))

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

(def (poo-flow-default-sources-current?/mtime stage options)
  (let (outputs (poo-flow-stage-output-files stage options))
    (and (not (null? outputs))
         (poo-flow-all?
          (lambda (source)
            (poo-flow-source-current-against-outputs?/mtime source outputs))
          (poo-flow-stage-default-source-files)))))

(def (poo-flow-stage-outputs-current?/mtime stage options)
  (and (not (null? stage))
       (poo-flow-all?
        (lambda (spec)
          (poo-flow-gxc-spec-outputs-current?/mtime spec options))
        stage)))

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
           (fast-current?
            (poo-flow-stage-fast-stamp-current?/mtime
             stage
             options
             stamp)))
      (if fast-current?
        (values #t 'stamp-current #f stamp)
        (let* ((sources (poo-flow-stage-source-files stage))
               (outputs (poo-flow-stage-output-files stage options))
               (status (gslph-package-build-receipt-status
                        stamp
                        expected-sources: sources
                        expected-outputs: outputs))
               (receipt-status (gslph-package-build-receipt-status-ref
                                status
                                'status
                                'stale)))
          (cond
           ((eq? receipt-status 'current)
            (values #t 'receipt-current status stamp))
           ((and (poo-flow-native-stage-stamp-seed-present?
                  options
                  maybe-label)
                 (poo-flow-stage-outputs-current?/mtime stage options))
            (begin
              (gslph-package-build-receipt-write
               stamp
               sources
               outputs)
              (values #t 'mtime-current status stamp)))
           (else
            (values #f receipt-status status stamp)))))))))

(def (poo-flow-stage-cache-valid? stage options . maybe-label)
  (call-with-values
    (lambda ()
      (apply poo-flow-stage-cache-assess
             stage
             options
             maybe-label))
    (lambda (current? _reason _receipt-status _stamp)
      current?)))

(def (poo-flow-native-stage-stamp-present? options maybe-label)
  (poo-flow-native-stage-stamp-seed-present? options maybe-label))

(def (poo-flow-stage-spec-current? spec options . maybe-label)
  (let (stage (list spec))
    (and (not (poo-flow-force-build-options? options))
         (poo-flow-stage-cacheable? stage options)
         (poo-flow-native-stage-stamp-present? options maybe-label)
         (poo-flow-stage-outputs-current?/mtime stage options))))

(def (poo-flow-stage-stale-specs stage options . maybe-label)
  (filter (lambda (spec)
            (not (apply poo-flow-stage-spec-current?
                        spec
                        options
                        maybe-label)))
          stage))

(def (poo-flow-bootstrap-spec-current? spec options . maybe-label)
  (apply poo-flow-stage-spec-current?
         spec
         options
         maybe-label))

(def (poo-flow-stage-cache-touch! stage options . maybe-label)
  (when (poo-flow-stage-cacheable? stage options)
    (gslph-package-build-receipt-write
     (apply poo-flow-stage-cache-stamp-path
            options
            maybe-label)
     (poo-flow-stage-source-files stage)
     (poo-flow-stage-output-files stage options))))

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
      (begin
        (poo-flow-package-message "compile" label stage)
        (poo-flow-build-debug-start-line
         'package-stage-spec
         label
         "profiled std/make"
         stage
         options)
        (apply make stage
               srcdir: (poo-flow-package-srcdir)
               (poo-flow-make-options options))
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

(def (poo-flow-make-profiled-stage label stale-stage options)
  (poo-flow-package-message "compile-profiled" label stale-stage)
  (for-each
   (lambda (spec)
     (poo-flow-make-profiled-spec label spec options))
   stale-stage))

(def (poo-flow-make label stage options)
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
          (begin
            (let (stale-stage (poo-flow-stage-stale-specs
                               stage
                               options
                               label))
              (if (null? stale-stage)
                (begin
                  (poo-flow-package-message "skip" label stage)
                  (display "|note kind=build-cache message=\"package-local gxc direct outputs are current after stale target scan; skipped std/make rebuild\"")
                  (newline)
                  (poo-flow-stage-cache-touch! stage options label)
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
                (begin
                  (if (poo-flow-profiled-stage-options?
                       label
                       stale-stage
                       options)
                    (poo-flow-make-profiled-stage
                     label
                     stale-stage
                     options)
                    (begin
                      (poo-flow-package-message "compile" label stale-stage)
                      (poo-flow-build-debug-start-line
                       'package-stage
                       label
                       "std/make"
                       stale-stage
                       options)
                      (apply make stale-stage
                             srcdir: (poo-flow-package-srcdir)
                             (poo-flow-package-stage-options
                              stale-stage
                              options))))
                  (poo-flow-stage-cache-touch! stage options label)
                  (poo-flow-build-debug-tracking-line
                   'package-stage
                   label
                   (if (poo-flow-profiled-stage-options?
                        label
                        stale-stage
                        options)
                     "profiled std/make"
                     "std/make")
                   'compiled
                   reason
                   stale-stage
                   options
                   stamp
                   receipt-status
                   start-jiffy))))))))))

(def (poo-flow-make-uncached label stage options)
  (poo-flow-package-require-gxpkg-env!)
  (poo-flow-package-message "compile" label stage)
  (apply make stage
         srcdir: (poo-flow-package-srcdir)
         (poo-flow-make-options options)))

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
             start-jiffy))
          (begin
            (for-each
             (lambda (spec)
               (poo-flow-make-bootstrap-spec label spec options))
             stage)
            (poo-flow-stage-cache-touch! stage options label)
            (poo-flow-build-debug-tracking-line
             'package-bootstrap-stage
             label
             "sequential std/make"
             'compiled
             reason
             stage
             options
             stamp
             receipt-status
             start-jiffy)))))))

(def (poo-flow-make-clean label stage)
  (poo-flow-package-require-gxpkg-env!)
  (poo-flow-package-message "clean" label stage)
  (apply make-clean stage
         srcdir: (poo-flow-package-srcdir)
         (poo-flow-package-stage-options stage [])))

(def (poo-flow-gxc-spec-file spec)
  (match spec
    ([gxc: file . _] file)
    (_ (error "poo-flow direct gxc stage only supports gxc specs" spec))))

(def (poo-flow-gxc-source-file file)
  (cond
   ((file-exists? file) file)
   ((file-exists? (string-append file ".ss"))
    (string-append file ".ss"))
   (else file)))

(def (poo-flow-run-gxc-spec! spec)
  (let* ((file (poo-flow-gxc-spec-file spec))
         (source (poo-flow-gxc-source-file file)))
    (display "|gxc file=")
    (write source)
    (newline)
    (run-process ["gxc" source]
                 stdin-redirection: #f
                 stdout-redirection: #f
                 stderr-redirection: #f)))

(def (poo-flow-gxc-stage label stage options)
  (poo-flow-package-require-gxpkg-env!)
  (poo-flow-package-message "check" label stage)
  (if (poo-flow-stage-cache-valid? stage options)
    (begin
      (poo-flow-package-message "skip" label stage)
      (display "|note kind=build-cache message=\"package-local direct gxc outputs are current; skipped focused cli rebuild\"")
      (newline))
    (begin
      (poo-flow-package-message "compile" label stage)
      (for-each poo-flow-run-gxc-spec! stage)
      (poo-flow-stage-cache-touch! stage options))))

(def (poo-flow-entry-options release optimized debug cli force verbose)
  (append
   (if release [build-release: #t] [])
   (if optimized [build-optimized: #t] [])
   (if debug [debug: #t] [])
   (if cli [build-cli: #t] [])
   (if force [force: #t] [])
   (if verbose [verbose: 9] [])))

(def (poo-flow-release-build-options? options)
  (match options
    ([build-release: value . _] value)
    ([_ _ . rest] (poo-flow-release-build-options? rest))
    ([] #f)))

(def (poo-flow-optimized-build-options? options)
  (match options
    ([build-optimized: value . _] value)
    ([_ _ . rest] (poo-flow-optimized-build-options? rest))
    ([] #f)))

(def (poo-flow-debug-build-options? options)
  (match options
    ([debug: value . _] value)
    ([_ _ . rest] (poo-flow-debug-build-options? rest))
    ([] #f)))

(def (poo-flow-verbose-build-options? options)
  (match options
    ([verbose: value . _] value)
    ([_ _ . rest] (poo-flow-verbose-build-options? rest))
    ([] #f)))

(def (poo-flow-build-debug-tracking-options? options)
  (or (poo-flow-debug-build-options? options)
      (poo-flow-verbose-build-options? options)))

(def (poo-flow-profiled-stage-label? label)
  (or (string=? label "runtime")
      (string=? label "tests")))

(def (poo-flow-profiled-stage-options? label stage options)
  (and (> (length stage) 1)
       (poo-flow-build-debug-tracking-options? options)
       (poo-flow-profiled-stage-label? label)))

(def (poo-flow-cli-build-options? options)
  (match options
    ([build-cli: value . _] value)
    ([_ _ . rest] (poo-flow-cli-build-options? rest))
    ([] #f)))

(def (poo-flow-force-build-options? options)
  (match options
    ([force: value . _] value)
    ([_ _ . rest] (poo-flow-force-build-options? rest))
    ([] #f)))

(def (poo-flow-native-build-options? options)
  (or (poo-flow-release-build-options? options)
      (poo-flow-optimized-build-options? options)
      (poo-flow-debug-build-options? options)))

(def (poo-flow-compile-build-spec options)
  (cond
   ((poo-flow-cli-build-options? options)
    (poo-flow-cli-only-build-spec options))
   ((poo-flow-release-build-options? options)
    (poo-flow-package-build-spec options))
   (else
    (poo-flow-package-build-spec options))))

(def (poo-flow-package-compile options)
  (if (poo-flow-cli-build-options? options)
    (begin
      (poo-flow-gxc-stage "cli-modules"
                          (poo-flow-cli-only-module-build-spec options)
                          options)
      (poo-flow-write-cli-launcher!))
    (begin
      (poo-flow-make-bootstrap
       "runtime-bootstrap"
       (poo-flow-runtime-bootstrap-build-spec options)
       options)
      (when (poo-flow-native-build-options? options)
        (poo-flow-make
         "ffi"
         +poo-flow-ffi-build-spec+
         options))
      (poo-flow-make
       "runtime"
       (poo-flow-runtime-main-build-spec options)
       options)
      (poo-flow-make
       "tests"
       (poo-flow-test-build-spec options)
       options)
      (poo-flow-make
       "cli-library"
       +poo-flow-cli-library-build-spec+
       options)
      (poo-flow-make
       "entry"
       (poo-flow-entry-build-spec options)
       options)
      (poo-flow-write-cli-launcher!))))

(def (poo-flow-clean)
  (poo-flow-make-clean "package" (poo-flow-package-build-spec [])))
