;;; -*- Gerbil -*-
;;; Boundary: focused build commands and package build cache checks for the local CLI.

(import :gerbil/gambit
        (only-in :gslph/src/build-api/package-receipt
                 gslph-package-build-receipt-status
                 gslph-package-build-receipt-status-ref)
        :poo-flow/src/cli-support/support)

(export poo-flow-cli-build)

;;; Boundary: cli arg present predicate is the policy-visible edge for CLI
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> String [String] Boolean)
(def (poo-flow-cli-arg-present? flag args)
  (cond
   ((null? args) #f)
   ((equal? (car args) flag) #t)
   (else (poo-flow-cli-arg-present? flag (cdr args)))))

;;; Boundary: cli module arg is the policy-visible edge for CLI behavior,
;;; keeping validation, lookup, or projection responsibilities centralized for
;;; callers.
;; : (-> [String] MaybeString)
(def (poo-flow-cli-module-arg args)
  (match args
    ([] #f)
    (["--module" file . _] file)
    ([_ . rest] (poo-flow-cli-module-arg rest))))

;; : (-> [String] Boolean)
(def (poo-flow-cli-native-module-build? args)
  (or (poo-flow-cli-arg-present? "--release" args)
      (poo-flow-cli-arg-present? "--optimized" args)
      (poo-flow-cli-arg-present? "--debug" args)))

;; : (-> String Integer)
(def (poo-flow-cli-reject-native-module-build! module-file)
  (poo-flow-cli-error "poo-flow build: single-module native builds are not supported; use the package build graph")
  (poo-flow-cli-error (string-append "module: " module-file))
  (poo-flow-cli-error "next: gxpkg build -R -O")
  70)

;;; Boundary: cli module gxc argv is the policy-visible edge for CLI behavior,
;;; keeping validation, lookup, or projection responsibilities centralized for
;;; callers.
;; : (-> String [String] MaybeStringList)
(def (poo-flow-cli-module-gxc-argv module-file args)
  (if (poo-flow-cli-native-module-build? args)
    #f
    (poo-flow-cli-gerbil-env-argv "gxc" [module-file])))

;;; Boundary: cli module spec is the policy-visible edge for CLI behavior,
;;; keeping validation, lookup, or projection responsibilities centralized for
;;; callers.
;; : (-> String [String] MaybeBuildSpec)
(def (poo-flow-cli-module-spec module-file args)
  (if (poo-flow-cli-native-module-build? args)
    #f
    [[gxc: module-file]]))

;; : (-> [String] Integer)
(def (poo-flow-cli-reject-package-build! args)
  (poo-flow-cli-error "poo-flow build: full package builds are owned by gxpkg build")
  (poo-flow-cli-error (string-append "args: " (object->string args)))
  (poo-flow-cli-error "next: gxpkg build -R -O")
  64)

;; : (-> String)
(def (poo-flow-cli-package-cache-dir)
  (path-expand ".gerbil/lib/poo-flow"))

;;; Boundary: cli package cache mode is the policy-visible edge for CLI
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [String] String)
(def (poo-flow-cli-package-cache-mode args)
  "package")

;;; Boundary: cli package cache stamp path is the policy-visible edge for CLI
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [String] String)
(def (poo-flow-cli-package-cache-stamp-path args)
  (path-expand
   ".compile-package.stamp"
   (poo-flow-cli-package-cache-dir)))

;;; Boundary: cli package compile command is the policy-visible edge for CLI
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [String] String)
(def (poo-flow-cli-package-compile-command args)
  "gxpkg env ./build.ss compile")

;; : (-> [String] Integer)
(def (poo-flow-cli-reject-package-status-args! args)
  (poo-flow-cli-error "poo-flow build package-status: arguments are no longer supported")
  (poo-flow-cli-error (string-append "args: " (object->string args)))
  (poo-flow-cli-error "next: poo-flow build package-status")
  64)

;; : [String]
(def +poo-flow-cli-binary-source-files+
  '("build.ss"
    "src/cli.ss"
    "src/cli-support/build.ss"
    "src/cli-support/support.ss"
    "src/cli-support/test.ss"))

;; : (-> String)
(def (poo-flow-cli-binary-dir)
  (path-expand ".gerbil/bin"))

;; : (-> String)
(def (poo-flow-cli-binary-path)
  (path-expand "poo-flow" (poo-flow-cli-binary-dir)))

;; : (-> String)
(def (poo-flow-cli-binary-launcher-scheme-path)
  (path-expand "poo-flow-launcher.ss" (poo-flow-cli-binary-dir)))

;; : (-> String String)
(def (poo-flow-cli-binary-compile-command)
  "gxpkg env ./build.ss compile --cli")

;; : (-> String MaybeNumber)
(def (poo-flow-cli-file-mtime-seconds path)
  (and (file-exists? path)
       (time->seconds
        (file-info-last-modification-time (file-info path)))))

;; : ([String] Number Fixnum -> Alist)
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

;; : (Alist Symbol a -> a)
(def (poo-flow-cli-alist-ref alist key default)
  (let (pair (assoc key alist))
    (if pair (cdr pair) default)))

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

;; : (Alist -> Void)
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

;;; Boundary: cli write package status is the policy-visible edge for CLI
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [String] Alist Integer)
(def (poo-flow-cli-write-package-status args status)
  (let ((state (gslph-package-build-receipt-status-ref status 'status 'stale))
        (reason (gslph-package-build-receipt-status-ref status 'reason #f))
        (sources (gslph-package-build-receipt-status-ref status 'sources 0))
        (outputs (gslph-package-build-receipt-status-ref status 'outputs 0))
        (stamp (gslph-package-build-receipt-status-ref
                status
                'stamp
                (poo-flow-cli-package-cache-stamp-path args)))
        (binary-status (poo-flow-cli-binary-status)))
    (display "[poo-flow-build-status] scope=package")
    (display " mode=")
    (display (poo-flow-cli-package-cache-mode args))
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
      (write (poo-flow-cli-package-compile-command args))
      (newline)
      70)
     ((not (eq? (poo-flow-cli-alist-ref binary-status 'status 'stale)
                'current))
      (display "|next command=")
      (write (poo-flow-cli-binary-compile-command))
      (newline)
      70)
     (else 0))))

;; : (-> [String] Integer)
(def (poo-flow-cli-build-package-status args)
  (if (null? args)
    (poo-flow-cli-write-package-status
     args
     (gslph-package-build-receipt-status
      (poo-flow-cli-package-cache-stamp-path args)))
    (poo-flow-cli-reject-package-status-args! args)))

;; : (-> BuildSpec Integer)
(def (poo-flow-cli-write-build-spec spec)
  (write spec)
  (newline)
  0)

;;; Boundary: cli build spec module is the policy-visible edge for CLI
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> String [String] Integer)
(def (poo-flow-cli-build-spec-module module-file rest)
  (let (spec (poo-flow-cli-module-spec module-file rest))
    (if spec
      (poo-flow-cli-write-build-spec spec)
      (poo-flow-cli-reject-native-module-build! module-file))))

;;; Boundary: cli build spec command is the policy-visible edge for CLI
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [String] [String] Integer)
(def (poo-flow-cli-build-spec-command args rest)
  (let (module-file (poo-flow-cli-module-arg rest))
    (if module-file
      (poo-flow-cli-build-spec-module module-file rest)
      (poo-flow-cli-reject-package-build! args))))

;;; Boundary: cli build compile module is the policy-visible edge for CLI
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> String [String] Integer)
(def (poo-flow-cli-build-compile-module module-file rest)
  (let (argv (poo-flow-cli-module-gxc-argv module-file rest))
    (if argv
      (poo-flow-cli-run-inherited argv)
      (poo-flow-cli-reject-native-module-build! module-file))))

;;; Boundary: cli build compile command is the policy-visible edge for CLI
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> [String] [String] Integer)
(def (poo-flow-cli-build-compile-command args rest)
  (let (module-file (poo-flow-cli-module-arg rest))
    (if module-file
      (poo-flow-cli-build-compile-module module-file rest)
      (poo-flow-cli-build-package-status rest))))

;;; Boundary: cli build is the policy-visible edge for CLI behavior, keeping
;;; validation, lookup, or projection responsibilities centralized for callers.
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
