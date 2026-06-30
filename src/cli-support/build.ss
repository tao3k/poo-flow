;;; -*- Gerbil -*-
;;; Boundary: focused build commands and package build cache checks for the local CLI.

(import :gerbil/gambit
        (only-in :gslph/src/build-api/package-receipt
                 gslph-package-build-receipt-status
                 gslph-package-build-receipt-status-ref)
        :poo-flow/src/cli-support/support)

(export poo-flow-cli-build)

;;; Intent: recognize single-token build flags without allocating option state.
;;; Boundary: callers keep raw argv order; this helper only answers membership.
;; : (-> String [String] Boolean)
(def (poo-flow-cli-arg-present? flag args)
  (cond
   ((null? args) #f)
   ((equal? (car args) flag) #t)
   (else (poo-flow-cli-arg-present? flag (cdr args)))))

;;; Intent: extract the focused module target from the build command argv.
;;; Boundary: package builds are rejected elsewhere when no module is present.
;; : (-> [String] (U #f String))
(def (poo-flow-cli-module-arg args)
  (match args
    ([] #f)
    (["--module" file . _] file)
    ([_ . rest] (poo-flow-cli-module-arg rest))))

;;; Intent: detect native-output build requests that cannot be handled by gxc.
;;; Boundary: focused CLI builds only support interpreted/module compilation.
;; : (-> [String] Boolean)
(def (poo-flow-cli-native-module-build? args)
  (or (poo-flow-cli-arg-present? "--release" args)
      (poo-flow-cli-arg-present? "--optimized" args)
      (poo-flow-cli-arg-present? "--debug" args)))

;;; Intent: explain why a focused module command cannot produce native binaries.
;;; Boundary: repair points to the package graph instead of attempting gxc flags.
;; : (-> String Integer)
(def (poo-flow-cli-reject-native-module-build! module-file)
  (poo-flow-cli-error "poo-flow build: single-module native builds are not supported; use the package build graph")
  (poo-flow-cli-error (string-append "module: " module-file))
  (poo-flow-cli-error "next: gxpkg build -R -O")
  70)

;;; Intent: project a focused source build into the package-local gxc command.
;;; Boundary: native release/debug flags stay owned by the package build graph.
;; : (-> String [String] (U #f [String]))
(def (poo-flow-cli-module-gxc-argv module-file args)
  (if (poo-flow-cli-native-module-build? args)
    #f
    (poo-flow-cli-gerbil-env-argv "gxc" [module-file])))

;;; Intent: expose the focused module build spec for diagnostics and tests.
;;; Boundary: native flags return #f so callers can emit the package-graph repair.
;; : (-> String [String] (U #f BuildSpec))
(def (poo-flow-cli-module-spec module-file args)
  (if (poo-flow-cli-native-module-build? args)
    #f
    [[gxc: module-file]]))

;;; Intent: reject accidental package-wide work from the focused build CLI.
;;; Boundary: keeps expensive graph compilation in gxpkg/std/make.
;; : (-> [String] Integer)
(def (poo-flow-cli-reject-package-build! args)
  (poo-flow-cli-error "poo-flow build: full package builds are owned by gxpkg build")
  (poo-flow-cli-error (string-append "args: " (object->string args)))
  (poo-flow-cli-error "next: gxpkg build -R -O")
  64)

;;; Intent: locate the package owner receipt without entering std/make.
;;; Boundary: the compiled CLI reads this stamp; only build.ss compile writes it.
;; : (-> String)
(def (poo-flow-cli-package-cache-stamp-path)
  (path-expand
   ".compile-package.stamp"
   ".gerbil/lib/poo-flow"))

;;; Intent: reject legacy receipt mode flags after tests moved to the framework.
;;; Boundary: package-status has no submode; the repair command is argument-free.
;; : (-> [String] Integer)
(def (poo-flow-cli-reject-package-status-args! args)
  (poo-flow-cli-error "poo-flow build package-status: arguments are no longer supported")
  (poo-flow-cli-error (string-append "args: " (object->string args)))
  (poo-flow-cli-error "next: poo-flow build package-status")
  64)

;;; Intent: list the sources that determine whether the compiled CLI is stale.
;;; Boundary: this fast status path watches only the small CLI surface.
;; : (Listof String)
(def +poo-flow-cli-binary-source-files+
  '("build.ss"
    "src/cli.ss"
    "src/cli-support/build.ss"
    "src/cli-support/support.ss"
    "src/cli-support/test.ss"))

;;; Intent: locate package-local executable artifacts below GERBIL_PATH.
;;; Boundary: caller must run under gxpkg env so the path is package-owned.
;; : (-> String)
(def (poo-flow-cli-binary-dir)
  (path-expand ".gerbil/bin"))

;;; Intent: locate the shell launcher used by external agent commands.
;;; Boundary: the launcher path is status-checked but never generated here.
;; : (-> String)
(def (poo-flow-cli-binary-path)
  (path-expand "poo-flow" (poo-flow-cli-binary-dir)))

;;; Intent: locate the generated Scheme launcher that imports the compiled CLI.
;;; Boundary: source freshness compares this file against CLI source mtimes.
;; : (-> String)
(def (poo-flow-cli-binary-launcher-scheme-path)
  (path-expand "poo-flow-launcher.ss" (poo-flow-cli-binary-dir)))

;;; Intent: print the exact command that refreshes the small compiled CLI.
;;; Boundary: used only as repair advice when binary freshness is stale.
;; : (-> String String)
(def (poo-flow-cli-binary-compile-command)
  "gxpkg env ./build.ss compile --cli")

;;; Intent: read a source or artifact mtime for freshness comparisons.
;;; Boundary: missing files normalize to #f instead of raising.
;; : (-> String (U #f Number))
(def (poo-flow-cli-file-mtime-seconds path)
  (and (file-exists? path)
       (time->seconds
        (file-info-last-modification-time (file-info path)))))

;;; Intent: fold source mtimes into newest/missing counters without allocation-heavy scans.
;;; Boundary: caller owns the watched file list and initial accumulator values.
;; : (-> (List String) Number Fixnum Alist)
(def (poo-flow-cli-source-mtime-summary paths newest missing)
  (match paths
    ([]
     (list (cons 'newest newest)
           (cons 'missing missing)))
    ([path . rest]
     (let (mtime (poo-flow-cli-file-mtime-seconds path))
       (if mtime
         (poo-flow-cli-source-mtime-summary
          rest
          (if (> mtime newest) mtime newest)
          missing)
         (poo-flow-cli-source-mtime-summary
          rest
          newest
          (+ missing 1)))))))

;;; Intent: read optional status fields with a caller-owned default.
;;; Boundary: the receipt remains an alist so command output stays simple.
;; : (forall (a) (-> Alist Symbol a a))
(def (poo-flow-cli-alist-ref alist key default)
  (let (pair (assoc key alist))
    (if pair (cdr pair) default)))

;;; Intent: classify whether the generated CLI launcher is current.
;;; Boundary: compares only source mtimes and generated files, not package deps.
;; : (-> Alist)
(def (poo-flow-cli-binary-status)
  (let* ((binary (poo-flow-cli-binary-path))
         (binary-mtime (poo-flow-cli-file-mtime-seconds binary))
         (launcher-scheme (poo-flow-cli-binary-launcher-scheme-path))
         (launcher-scheme-mtime (poo-flow-cli-file-mtime-seconds launcher-scheme))
         (source-summary
          (poo-flow-cli-source-mtime-summary
           +poo-flow-cli-binary-source-files+
           0
           0))
         (source-newest (poo-flow-cli-alist-ref source-summary 'newest 0))
         (missing-sources (poo-flow-cli-alist-ref source-summary 'missing 0)))
    (cond
     ((not binary-mtime)
      (append
       (list (cons 'status 'stale)
             (cons 'reason 'missing-binary)
             (cons 'path binary))
       source-summary))
     ((not launcher-scheme-mtime)
      (append
       (list (cons 'status 'stale)
             (cons 'reason 'missing-launcher)
             (cons 'path binary)
             (cons 'launcher launcher-scheme)
             (cons 'binary-mtime binary-mtime))
       source-summary))
     ((> missing-sources 0)
      (append
       (list (cons 'status 'stale)
             (cons 'reason 'missing-source)
             (cons 'path binary)
             (cons 'binary-mtime binary-mtime))
       source-summary))
     ((or (> source-newest binary-mtime)
          (> source-newest launcher-scheme-mtime))
      (append
       (list (cons 'status 'stale)
             (cons 'reason 'source-newer)
             (cons 'path binary)
             (cons 'launcher launcher-scheme)
             (cons 'binary-mtime binary-mtime)
             (cons 'launcher-mtime launcher-scheme-mtime))
       source-summary))
     (else
      (append
       (list (cons 'status 'current)
             (cons 'path binary)
             (cons 'launcher launcher-scheme)
             (cons 'binary-mtime binary-mtime)
             (cons 'launcher-mtime launcher-scheme-mtime))
       source-summary)))))

;;; Intent: render the binary freshness section inside package-status output.
;;; Boundary: output stays line-oriented for agent parsing.
;; : (-> Alist Unit)
(def (poo-flow-cli-write-binary-status status)
  (display "|binary scope=cli status=")
  (display
   (symbol->string
    (poo-flow-cli-alist-ref status 'status 'stale)))
  (display " sources=")
  (display (length +poo-flow-cli-binary-source-files+))
  (display " missingSources=")
  (display (poo-flow-cli-alist-ref status 'missing 0))
  (display " path=")
  (write (poo-flow-cli-alist-ref status 'path (poo-flow-cli-binary-path)))
  (display " launcher=")
  (write (poo-flow-cli-alist-ref
          status
          'launcher
          (poo-flow-cli-binary-launcher-scheme-path)))
  (newline)
  (let (reason (poo-flow-cli-alist-ref status 'reason #f))
    (when reason
      (display "|binary reason=")
      (display (symbol->string reason))
      (newline))))

;;; Intent: render a cheap package/binary freshness receipt for agents.
;;; Boundary: output is command-oriented; no package compilation is triggered.
;; : (-> [String] Alist Integer)
(def (poo-flow-cli-write-package-status args status)
  (let ((state (gslph-package-build-receipt-status-ref status 'status 'stale))
        (reason (gslph-package-build-receipt-status-ref status 'reason #f))
        (sources (gslph-package-build-receipt-status-ref status 'sources 0))
        (outputs (gslph-package-build-receipt-status-ref status 'outputs 0))
        (stamp (gslph-package-build-receipt-status-ref
                status
                'stamp
                (poo-flow-cli-package-cache-stamp-path)))
        (binary-status (poo-flow-cli-binary-status)))
    (display "[poo-flow-build-status] scope=package")
    (display " mode=")
    (display "package")
    (display " status=")
    (display (symbol->string state))
    (display " sources=")
    (display sources)
    (display " outputs=")
    (display outputs)
    (display " stamp=")
    (write stamp)
    (newline)
    (when reason
      (display "|reason kind=")
      (display (symbol->string reason))
      (newline))
    (poo-flow-cli-write-binary-status binary-status)
    (cond
     ((not (eq? state 'current))
      (display "|next command=")
      (write "gxpkg env ./build.ss compile")
      (newline)
      70)
     ((not (eq? (poo-flow-cli-alist-ref binary-status 'status 'stale)
                'current))
      (display "|next command=")
      (write (poo-flow-cli-binary-compile-command))
      (newline)
      70)
     (else 0))))

;;; Intent: load and render the package receipt, rejecting any legacy submode args.
;;; Boundary: stale status returns a repair code instead of compiling.
;; : (-> [String] Integer)
(def (poo-flow-cli-build-package-status args)
  (if (null? args)
    (poo-flow-cli-write-package-status
     args
     (gslph-package-build-receipt-status
      (poo-flow-cli-package-cache-stamp-path)))
    (poo-flow-cli-reject-package-status-args! args)))

;;; Intent: print a focused build spec as the CLI inspection result.
;;; Boundary: spec construction stays pure; this function only renders it.
;; : (-> BuildSpec Integer)
(def (poo-flow-cli-write-build-spec spec)
  (write spec)
  (newline)
  0)

;;; Intent: return the focused module build spec used by CLI tests and advice.
;;; Boundary: package-wide specs remain in build.ss, not the compiled CLI.
;; : (-> String [String] Integer)
(def (poo-flow-cli-build-spec-module module-file rest)
  (let (spec (poo-flow-cli-module-spec module-file rest))
    (if spec
      (poo-flow-cli-write-build-spec spec)
      (poo-flow-cli-reject-native-module-build! module-file))))

;;; Intent: parse `poo-flow build spec` as a focused module inspection command.
;;; Boundary: missing --module is a user error because full package builds use gxpkg.
;; : (-> [String] [String] Integer)
(def (poo-flow-cli-build-spec-command args rest)
  (let (module-file (poo-flow-cli-module-arg rest))
    (if module-file
      (poo-flow-cli-build-spec-module module-file rest)
      (poo-flow-cli-reject-package-build! args))))

;;; Intent: execute the focused module compile command on the inherited streams.
;;; Boundary: native executable builds are rejected before spawning gxc.
;; : (-> String [String] Integer)
(def (poo-flow-cli-build-compile-module module-file rest)
  (let (argv (poo-flow-cli-module-gxc-argv module-file rest))
    (if argv
      (poo-flow-cli-run-inherited argv)
      (poo-flow-cli-reject-native-module-build! module-file))))

;;; Intent: route `build compile` either to a focused module build or status check.
;;; Boundary: full package compilation is only reported as the repair command.
;; : (-> [String] [String] Integer)
(def (poo-flow-cli-build-compile-command args rest)
  (let (module-file (poo-flow-cli-module-arg rest))
    (if module-file
      (poo-flow-cli-build-compile-module module-file rest)
      (poo-flow-cli-build-package-status rest))))

;;; Intent: keep the compiled build CLI limited to fast module/status actions.
;;; Boundary: any full package request receives a gxpkg-owned repair path.
;; : (-> [String] Integer)
(def (poo-flow-cli-build args)
  (match args
    (["meta"]
     (write '("spec" "compile" "package-status"))
     (newline)
     0)
    (["package-status" . rest]
     (poo-flow-cli-build-package-status rest))
    (["spec" . rest]
     (poo-flow-cli-build-spec-command args rest))
    (["compile" . rest]
     (poo-flow-cli-build-compile-command args rest))
    (_ (poo-flow-cli-reject-package-build! args))))
