;;; -*- Gerbil -*-
;;; Boundary: focused build commands and package build cache checks for the local CLI.

(import :gerbil/gambit
        (only-in :gslph/src/build-api/package-receipt
                 gslph-package-build-receipt-status
                 gslph-package-build-receipt-status-ref)
        :poo-flow/src/cli-support/support)

(export poo-flow-cli-build)

;; : (-> String [String] Boolean)
(def (poo-flow-cli-arg-present? flag args)
  (cond
   ((null? args) #f)
   ((equal? (car args) flag) #t)
   (else (poo-flow-cli-arg-present? flag (cdr args)))))

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

;; : (-> [String] Boolean)
(def (poo-flow-cli-package-tests? args)
  (poo-flow-cli-arg-present? "--tests" args))

;; : (-> [String] Boolean)
(def (poo-flow-cli-package-all-tests? args)
  (poo-flow-cli-arg-present? "--all-tests" args))

;; : (-> String Integer)
(def (poo-flow-cli-reject-native-module-build! module-file)
  (poo-flow-cli-error "poo-flow build: single-module native builds are not supported; use the package build graph")
  (poo-flow-cli-error (string-append "module: " module-file))
  (poo-flow-cli-error "next: gxpkg build -R -O")
  70)

;; : (-> String [String] MaybeStringList)
(def (poo-flow-cli-module-gxc-argv module-file args)
  (if (poo-flow-cli-native-module-build? args)
    #f
    (poo-flow-cli-gerbil-env-argv "gxc" [module-file])))

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

;; : (-> [String] String)
(def (poo-flow-cli-package-cache-mode args)
  (cond
   ((poo-flow-cli-package-all-tests? args) "all-tests")
   ((poo-flow-cli-package-tests? args) "tests")
   (else "package")))

;; : (-> [String] String)
(def (poo-flow-cli-package-cache-stamp-path args)
  (path-expand
   (cond
    ((poo-flow-cli-package-all-tests? args) ".compile-package-all-tests.stamp")
    ((poo-flow-cli-package-tests? args) ".compile-package-tests.stamp")
    (else ".compile-package.stamp"))
   (poo-flow-cli-package-cache-dir)))

;; : (-> [String] String)
(def (poo-flow-cli-package-compile-command args)
  (cond
   ((poo-flow-cli-package-all-tests? args)
    "gxpkg env ./build.ss compile --all-tests --force")
   ((poo-flow-cli-package-tests? args)
    "gxpkg env ./build.ss compile --tests --force")
   (else
    "gxpkg env ./build.ss compile --force")))

;; : (-> [String] Alist Integer)
(def (poo-flow-cli-write-package-status args status)
  (let ((state (gslph-package-build-receipt-status-ref status 'status 'stale))
        (reason (gslph-package-build-receipt-status-ref status 'reason #f))
        (sources (gslph-package-build-receipt-status-ref status 'sources 0))
        (outputs (gslph-package-build-receipt-status-ref status 'outputs 0))
        (stamp (gslph-package-build-receipt-status-ref
                status
                'stamp
                (poo-flow-cli-package-cache-stamp-path args))))
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
    (when (not (eq? state 'current))
      (display "|next command=")
      (write (poo-flow-cli-package-compile-command args))
      (newline))
    (if (eq? state 'current) 0 70)))

;; : (-> [String] Integer)
(def (poo-flow-cli-build-package-status args)
  (poo-flow-cli-write-package-status
   args
   (gslph-package-build-receipt-status
    (poo-flow-cli-package-cache-stamp-path args))))

;; : (-> BuildSpec Integer)
(def (poo-flow-cli-write-build-spec spec)
  (write spec)
  (newline)
  0)

;; : (-> String [String] Integer)
(def (poo-flow-cli-build-spec-module module-file rest)
  (let (spec (poo-flow-cli-module-spec module-file rest))
    (if spec
      (poo-flow-cli-write-build-spec spec)
      (poo-flow-cli-reject-native-module-build! module-file))))

;; : (-> [String] [String] Integer)
(def (poo-flow-cli-build-spec-command args rest)
  (let (module-file (poo-flow-cli-module-arg rest))
    (if module-file
      (poo-flow-cli-build-spec-module module-file rest)
      (poo-flow-cli-reject-package-build! args))))

;; : (-> String [String] Integer)
(def (poo-flow-cli-build-compile-module module-file rest)
  (let (argv (poo-flow-cli-module-gxc-argv module-file rest))
    (if argv
      (poo-flow-cli-run-inherited argv)
      (poo-flow-cli-reject-native-module-build! module-file))))

;; : (-> [String] [String] Integer)
(def (poo-flow-cli-build-compile-command args rest)
  (let (module-file (poo-flow-cli-module-arg rest))
    (if module-file
      (poo-flow-cli-build-compile-module module-file rest)
      (poo-flow-cli-reject-package-build! args))))

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
