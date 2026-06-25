;;; -*- Gerbil -*-
;;; Boundary: focused build commands for the local CLI.

(import :poo-flow/src/cli-support/support)

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
     (write '("spec" "compile"))
     (newline)
     0)
    (["spec" . rest]
     (poo-flow-cli-build-spec-command args rest))
    (["compile" . rest]
     (poo-flow-cli-build-compile-command args rest))
    (_ (poo-flow-cli-reject-package-build! args))))
