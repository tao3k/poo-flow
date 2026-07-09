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
                 poo-flow-native-build-options?))

(export #t)

;; : (-> String)
(def (nono-c-binding-include-option)
  (string-append "-I" (path-expand "bindings/nono-c")))

;; : [String]
(def +poo-flow-ffi-link-options+
  (cond-expand
   (darwin '("-ld-options" "-Wl,-undefined,dynamic_lookup"))
   (else '())))

;; : [String]
(def +poo-flow-runtime-include-dirs+
  '("src"))

;; : [String]
(def +poo-flow-test-include-dirs+
  '("t"))

;; : [String]
(def +poo-flow-test-support-include-dirs+
  '("t/support"
    "t/module-system-poo-performance-test-support"))

;; : [String]
(def +poo-flow-custom-loop-engine-test-support-source-files+
  '("t/support/custom-loop-engine/fixtures.ss"
    "t/support/custom-loop-engine/declaration.ss"
    "t/support/custom-loop-engine/agent.ss"
    "t/support/custom-loop-engine/operation.ss"
    "t/support/custom-loop-engine/presentation.ss"
    "t/support/custom-loop-engine/case.ss"))

;; : [String]
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

;; : [String]
(def +poo-flow-test-extra-source-files+
  '("t/support/loop-engine-runtime-manifest-receipts.ss"
    "t/build-cache-performance-test.ss"))

;; : [String]
(def +poo-flow-special-source-files+
  '("src/modules/nono-sandbox/_nono.ss"
    "src/cli-support/support.ss"
    "src/testing/project.ss"
    "src/cli-support/package-build-support/options.ss"
    "src/cli-support/package-build-support/specs.ss"
    "src/cli-support/package-build-support/env.ss"
    "src/cli-support/package-build-support/launcher.ss"
    "src/cli-support/package-build-support/receipt.ss"
    "src/cli-support/package-build-support/stage-output.ss"
    "src/cli-support/package-build-support/stage-cache.ss"
    "src/cli-support/package-build-support/observability.ss"
    "src/cli-support/package-build-support/engine.ss"
    "src/cli-support/package-build.ss"
    "src/cli-support/package-build-compiled.ss"
    "src/cli.ss"
    "main.ss"
    "manifest.ss"))

;; : [[String]]
(def +poo-flow-build-macro-dependency-source-files+
  '(("src/module-system/sandbox-backend-object-syntax.ss"
     "src/modules/nono-sandbox/objects.ss"
     "src/modules/cubeSandbox/objects.ss"
     "src/modules/docker-sandbox/objects.ss")))

;; : HashTable
(def +poo-flow-native-object-output-directory-cache+
  (make-hash-table))

;; : Integer
(def +poo-flow-direct-gxc-stale-stage-target-limit+
  4)

;; : Integer
(def +poo-flow-native-object-sibling-miss-limit+
  16)

;; : [BuildSpec]
(def +poo-flow-ffi-build-spec+
  `((gsc: "src/modules/nono-sandbox/_nono"
          "-cc-options" ,(nono-c-binding-include-option)
          ,@+poo-flow-ffi-link-options+)
    (ssi: "src/modules/nono-sandbox/_nono")))

;; : [BuildSpec]
(def +poo-flow-cli-library-build-spec+
  '((gxc: "src/cli-support/support.ss")
    (gxc: "src/cli-support/package-build-support/options.ss")
    (gxc: "src/cli-support/package-build-support/specs.ss")
    (gxc: "src/cli-support/package-build-support/env.ss")
    (gxc: "src/cli-support/package-build-support/launcher.ss")
    (gxc: "src/cli-support/package-build-support/receipt.ss")
    (gxc: "src/cli-support/package-build-support/stage-output.ss")
    (gxc: "src/cli-support/package-build-support/stage-cache.ss")
    (gxc: "src/cli-support/package-build-support/observability.ss")
    (gxc: "src/cli-support/package-build-support/engine.ss")
    (gxc: "src/cli-support/package-build.ss")
    (gxc: "src/cli-support/package-build-compiled.ss")
    (gxc: "src/cli.ss")))

;; : [BuildSpec]
(def +poo-flow-testing-project-build-spec+
  '((gxc: "src/testing/project.ss")))

;; : [BuildSpec]
(def +poo-flow-cli-entry-module-build-spec+
  '((gxc: "user-interface/init")
    (gxc: "user-interface/custom/my-module/profiles/all")
    (gxc: "user-interface/custom/my-module/cases/cicd-owner")
    (gxc: "user-interface/custom/my-module/cases/loop-engine-owner")
    (gxc: "user-interface/custom/my-module/cases/session-owner")
    (gxc: "user-interface/custom/my-module/cases/runtime-owner")
    (gxc: "user-interface/custom/my-module/cases/durable-owner")
    (gxc: "user-interface/custom/my-module/config")))

;; : [String]
(def +poo-flow-runtime-bootstrap-modules+
  '("src/semantic/boundary-namespace.ss"
    "src/type-facts/objects.ss"
    "src/utilities/contracts.ss"
    "src/utilities/contract-syntax.ss"
    "src/observability/types.ss"
    "src/observability/objects.ss"
    "src/contract/boundary-namespace.ss"
    "src/contract/functional.ss"
    "src/contract/json-schema-source.ss"
    "src/contract/json-schema-constraints.ss"
    "src/contract/json-schema-ir.ss"
    "src/contract/json-schema-normalize-core.ss"
    "src/contract/json-schema-normalize-parse.ss"
    "src/contract/json-schema-normalize-resolve.ss"
    "src/contract/json-schema-normalize.ss"
    "src/contract/json-schema-emit.ss"
    "src/contract/json-schema-receipt.ss"
    "src/contract/json-schema-validation-core.ss"
    "src/contract/json-schema-valid.ss"
    "src/contract/json-schema-validate.ss"
    "src/module-system/durable-policy.ss"
    "src/module-system/indexed-family.ss"
    "src/module-system/object-family-syntax.ss"
    "src/core/projection-syntax.ss"
    "src/core/failure.ss"
    "src/core/roles.ss"
    "src/core/object-syntax.ss"
    "src/loops/descriptor.ss"
    "src/loops/strategy.ss"
    "src/loops/governor-core.ss"
    "src/loops/governor-policy-sets.ss"
    "src/module-system/extension.ss"
    "src/module-system/object-core-support/contracts.ss"
    "src/module-system/object-core-support/merge.ss"
    "src/module-system/object-core-support/object-slots.ss"
    "src/modules/sandbox-core/profile-support/policy-core.ss"
    "src/modules/sandbox-core/profile-support/projection-syntax.ss"
    "src/modules/sandbox-core/profile-support/policy-backend-capability.ss"
    "src/modules/sandbox-core/profile-support/policy-backend-validation.ss"
    "src/core/runtime-protocol.ss"
    "src/core/runtime-command-invocation.ss"
    "src/core/runtime-command-descriptor.ss"
    "src/core/runtime-command.ss"
    "src/core/runtime-adapter.ss"
    "src/modules/session/objects-core.ss"
    "src/modules/session/objects-handoff.ss"
    "src/modules/session/objects-graph.ss"
    "src/modules/session/objects.ss"
    "src/modules/session/transform-support/memory-intent.ss"
    "src/modules/model-core/objects.ss"
    "src/modules/model-core/config.ss"
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
    "src/modules/session/policy-syntax.ss"
    "src/modules/session/config-session-syntax-core.ss"
    "src/modules/session/config-session-syntax-selector.ss"
    "src/modules/session/config-session-syntax-communication.ss"
    "src/modules/session/config-session-syntax-materialization.ss"
    "src/modules/session/config-session-syntax-agent-node.ss"
    "src/modules/session/config-session-syntax-agent.ss"
    "src/modules/session/config-session-syntax.ss"
    "src/modules/session/policy-core.ss"
    "src/modules/session/policy-tool-grant.ss"
    "src/modules/session/policy-families.ss"
    "src/modules/session/policy-permissions.ss"
    "src/modules/session/policy.ss"
    "src/modules/session/policy-validation-support.ss"
    "src/modules/session/policy-validation-communication.ss"
    "src/modules/session/policy-validation-catalog.ss"
    "src/modules/session/policy-validation-receipt.ss"
    "src/modules/session/config-session-syntax-core.ss"
    "src/modules/session/config-session-syntax-communication.ss"
    "src/modules/session/config-session-syntax-selector.ss"
    "src/modules/session/config-session-syntax-materialization.ss"
    "src/modules/session/config-session-syntax-agent-node.ss"
    "src/modules/session/config-session-syntax-agent.ss"
    "src/modules/session/config-session-syntax.ss"
    "src/modules/session/config-policy-syntax.ss"
    "src/modules/session/config.ss"))

;; poo-flow-cli-entry-build-spec
;; : (-> BuildOptions [BuildSpec])
;; | doc m%
;;   Return the generated CLI entry build spec for the package build.
;;   # Examples
;;   ```scheme
;;   (poo-flow-cli-entry-build-spec [])
;;   ;; => CLI entry build spec rows
;;   ```
(def (poo-flow-cli-entry-build-spec _options)
  +poo-flow-cli-entry-module-build-spec+)

;; poo-flow-entry-build-spec
;; : (-> BuildOptions [BuildSpec])
;; | doc m%
;;   Preserve the package entrypoint alias used by build.ss.
;;   # Examples
;;   ```scheme
;;   (poo-flow-entry-build-spec [])
;;   ;; => CLI entry build spec rows
;;   ```
(def (poo-flow-entry-build-spec options)
  (poo-flow-cli-entry-build-spec options))

;; poo-flow-cli-only-build-spec
;; : (-> BuildOptions [BuildSpec])
;; | doc m%
;;   Return the CLI library build rows without runtime or test stages.
;;   # Examples
;;   ```scheme
;;   (poo-flow-cli-only-build-spec [])
;;   ;; => CLI library build spec rows
;;   ```
(def (poo-flow-cli-only-build-spec _options)
  +poo-flow-cli-library-build-spec+)

;; poo-flow-cli-only-module-build-spec
;; : (-> BuildOptions [BuildSpec])
;; | doc m%
;;   Preserve the module-scoped CLI-only build alias for package consumers.
;;   # Examples
;;   ```scheme
;;   (poo-flow-cli-only-module-build-spec [])
;;   ;; => CLI library build spec rows
;;   ```
(def (poo-flow-cli-only-module-build-spec _options)
  +poo-flow-cli-library-build-spec+)

;; : (-> String Boolean)
(def (poo-flow-root-module-path? path)
  (not (string-index path #\/)))

;; poo-flow-string-suffix?
;; : (-> String String Boolean)
;; | doc m%
;;   Check whether VALUE ends with SUFFIX without allocating substrings.
;;   # Examples
;;   ```scheme
;;   (poo-flow-string-suffix? ".ss" "build.ss")
;;   ;; => #t
;;   ```
(def (poo-flow-string-suffix? suffix value)
  (string-suffix? suffix value))

;; : (-> String [String] Boolean)
(def (poo-flow-string-member? value values)
  (match values
    ([] #f)
    ([candidate . rest]
     (or (string=? value candidate)
         (poo-flow-string-member? value rest)))))

;; : (-> String Boolean)
(def (poo-flow-directory-path? path)
  (and (file-exists? path)
       (eq? (file-info-type (file-info path)) 'directory)))

;; : (-> String Boolean)
(def (poo-flow-skip-directory-name? name)
  (or (string=? name ".")
      (string=? name "..")))

;; : (-> String String String)
(def (poo-flow-path-join prefix name)
  (if (string=? prefix "")
    name
    (string-append prefix "/" name)))

;; : (-> String String)
(def (poo-flow-gerbil-source-module-path path)
  path)

;; poo-flow-gerbil-module-files-rev
;; : (-> String [String] String [String] [String])
;; | doc m%
;;   Collect Gerbil module files under ROOT into FILES-REV.
;;   # Examples
;;   ```scheme
;;   (poo-flow-gerbil-module-files-rev "." '() "" '())
;;   ;; => reversed module source paths
;;   ```
(def (poo-flow-gerbil-module-files-rev root exclude-dirs rel-prefix files-rev)
  (let loop ((entries (directory-files (path-expand rel-prefix root)))
             (current files-rev))
    (match entries
      ([]
       current)
      ([entry . rest]
       (let* ((rel-path (poo-flow-path-join rel-prefix entry))
              (abs-path (path-expand rel-path root)))
         (cond
          ((poo-flow-skip-directory-name? entry)
           (loop rest current))
          ((and (poo-flow-directory-path? abs-path)
                (not (poo-flow-string-member? entry exclude-dirs))
                (not (poo-flow-string-member? rel-path exclude-dirs)))
           (loop rest
                 (poo-flow-gerbil-module-files-rev
                  root
                  exclude-dirs
                  rel-path
                  current)))
          ((poo-flow-string-suffix? ".ss" entry)
           (loop rest
                 (cons (poo-flow-gerbil-source-module-path rel-path)
                       current)))
          (else
           (loop rest current))))))))

;; : (-> String [String] [String])
(def (poo-flow-gerbil-module-files dir exclude-dirs)
  (reverse (poo-flow-gerbil-module-files-rev dir exclude-dirs "" '())))

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

;; : (-> String [String] Boolean [String])
(def (poo-flow-module-files dir exclude-dirs root-only?)
  (let (modules (poo-flow-gerbil-module-files dir exclude-dirs))
    (poo-flow-module-files/prefix
     dir
     (if root-only?
       (filter poo-flow-root-module-path? modules)
       modules))))

;; : (forall (a b) (-> (-> a [b]) a [b] [b]))
(def (poo-flow-package-flat-map/rev proc value results)
  (foldl cons results (proc value)))

;; : (forall (a b) (-> (-> a [b]) [a] [b]))
(def (poo-flow-package-flat-map proc values)
  (foldr
   (lambda (value result-values)
     (foldr cons result-values (proc value)))
   []
   values))

;; : (-> [String] [String] Boolean [String])
(def (poo-flow-package-modules dirs exclude-dirs root-only?)
  (poo-flow-package-flat-map
   (lambda (dir)
     (poo-flow-module-files dir exclude-dirs root-only?))
   dirs))

;; : (-> [String] [String] [String] [String])
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

;; : (-> [String] [String] [String])
(def (poo-flow-package-remove-members files excluded)
  (reverse (poo-flow-package-remove-members/rev files excluded [])))

;; : (-> [String] [String] [String])
(def (poo-flow-package-append-missing files extras)
  (append files
          (filter (lambda (extra) (not (member extra files)))
                  extras)))

;; : (-> [String])
(def (poo-flow-runtime-modules)
  (poo-flow-package-remove-members
   (poo-flow-package-append-missing
    (poo-flow-package-modules +poo-flow-runtime-include-dirs+ '() #f)
    +poo-flow-runtime-extra-source-files+)
   +poo-flow-special-source-files+))

;; : (-> [String])
(def (poo-flow-runtime-bootstrap-modules)
  (filter file-exists? +poo-flow-runtime-bootstrap-modules+))

;; : (-> [String])
(def (poo-flow-runtime-main-modules)
  (let (bootstrap (poo-flow-runtime-bootstrap-modules))
    (poo-flow-package-remove-members
     (poo-flow-runtime-modules)
     bootstrap)))

;; : (-> [String])
(def (poo-flow-test-modules)
  (let (support-modules
        (poo-flow-package-remove-members
         (poo-flow-package-modules
          +poo-flow-test-support-include-dirs+
          '()
          #f)
         +poo-flow-custom-loop-engine-test-support-source-files+))
    (poo-flow-package-append-missing
     (append +poo-flow-custom-loop-engine-test-support-source-files+
             support-modules
             (poo-flow-package-modules +poo-flow-test-include-dirs+ '() #t))
     +poo-flow-test-extra-source-files+)))

;; : (-> String BuildOptions BuildSpec)
(def (poo-flow-gxc-target file _options)
  (if (string=? file "src/module-system/object-family-syntax.ss")
    [ssi: file]
    (let (gsc-options (poo-flow-build-gsc-options))
      (if (null? gsc-options)
        [gxc: file]
        (cons 'gxc: (cons file gsc-options))))))

;; : (-> String MaybeString)
(def (poo-flow-build-nonempty-env name)
  (let (value (getenv name #f))
    (and value
         (not (string=? value ""))
         value)))

;; : (-> MaybeString MaybeString)
(def (poo-flow-build-system-default-gsc-cc sdkroot)
  (cond-expand
   (darwin (and sdkroot "clang"))
   (else #f)))

;; : (-> MaybeString MaybeString)
(def (poo-flow-build-system-default-gsc-cc-options sdkroot)
  (cond-expand
   (darwin
    (and sdkroot
         "-Wno-ignored-optimization-argument -Wno-unused-command-line-argument"))
   (else #f)))

;; : (-> MaybeString MaybeString)
(def (poo-flow-build-system-default-gsc-ld-options sdkroot)
  (cond-expand
   (darwin (and sdkroot "-bundle -Wl,-undefined,dynamic_lookup"))
   (else #f)))

;; : (-> [String])
(def (poo-flow-build-gsc-options)
  (let* ((explicit-cc (poo-flow-build-nonempty-env "POO_FLOW_GSC_CC"))
         (sdkroot (poo-flow-build-nonempty-env "SDKROOT"))
         (cc (or explicit-cc
                 (poo-flow-build-system-default-gsc-cc sdkroot)))
         (explicit-cc-options
          (poo-flow-build-nonempty-env "POO_FLOW_GSC_CC_OPTIONS"))
         (cc-options (or explicit-cc-options
                         (poo-flow-build-system-default-gsc-cc-options
                          sdkroot))))
    (if cc
      (let (cc-args (list "-cc" cc))
        (let* ((with-cc-options
                (if cc-options
                  (append cc-args (list "-cc-options" cc-options))
                  cc-args))
               (explicit-ld-options
                (poo-flow-build-nonempty-env "POO_FLOW_GSC_LD_OPTIONS"))
               (ld-options (or explicit-ld-options
                               (poo-flow-build-system-default-gsc-ld-options
                                sdkroot))))
          (if ld-options
            (append with-cc-options (list "-ld-options" ld-options))
            with-cc-options)))
      '())))

;; : (-> [String] BuildOptions [BuildSpec] [BuildSpec])
(def (poo-flow-gxc-spec/rev files options specs-rev)
  (if (null? files)
    specs-rev
    (poo-flow-gxc-spec/rev
     (cdr files)
     options
     (cons (poo-flow-gxc-target (car files) options) specs-rev))))

;; : (-> [String] BuildOptions [BuildSpec])
(def (poo-flow-gxc-spec files options)
  (reverse (poo-flow-gxc-spec/rev files options [])))

;; : (-> BuildOptions [BuildSpec])
(def (poo-flow-runtime-build-spec options)
  (poo-flow-gxc-spec
   (append (poo-flow-runtime-bootstrap-modules)
           (poo-flow-runtime-main-modules))
   options))

;; : (-> BuildOptions [BuildSpec])
(def (poo-flow-runtime-bootstrap-build-spec options)
  (poo-flow-gxc-spec (poo-flow-runtime-bootstrap-modules) options))

;; : (-> BuildOptions [BuildSpec])
(def (poo-flow-runtime-main-build-spec options)
  (poo-flow-gxc-spec (poo-flow-runtime-main-modules) options))

;; : (-> BuildOptions [BuildSpec])
(def (poo-flow-test-build-spec options)
  (poo-flow-gxc-spec (poo-flow-test-modules) options))

;; : (-> BuildOptions [BuildSpec])
(def (poo-flow-package-build-spec options)
  (if (poo-flow-native-build-options? options)
    (append +poo-flow-ffi-build-spec+
            (poo-flow-runtime-build-spec options)
            +poo-flow-testing-project-build-spec+
            +poo-flow-cli-library-build-spec+
            (poo-flow-test-build-spec options)
            (poo-flow-entry-build-spec options))
    (append (poo-flow-runtime-build-spec options)
            +poo-flow-testing-project-build-spec+
            +poo-flow-cli-library-build-spec+
            (poo-flow-test-build-spec options)
            (poo-flow-entry-build-spec options))))

;; : (-> BuildOptions [BuildSpec])
(def (poo-flow-package-build-spec/without-bootstrap options)
  (if (poo-flow-native-build-options? options)
    (append +poo-flow-ffi-build-spec+
            (poo-flow-runtime-main-build-spec options)
            +poo-flow-testing-project-build-spec+
            +poo-flow-cli-library-build-spec+
            (poo-flow-test-build-spec options)
            (poo-flow-entry-build-spec options))
    (append (poo-flow-runtime-main-build-spec options)
            +poo-flow-testing-project-build-spec+
            +poo-flow-cli-library-build-spec+
            (poo-flow-test-build-spec options)
            (poo-flow-entry-build-spec options))))

;; : (-> BuildOptions [BuildSpec])
(def (poo-flow-package-library-build-spec/without-bootstrap options)
  (if (poo-flow-native-build-options? options)
    (append +poo-flow-ffi-build-spec+
            (poo-flow-runtime-main-build-spec options)
            +poo-flow-testing-project-build-spec+
            +poo-flow-cli-library-build-spec+
            (poo-flow-test-build-spec options))
    (append (poo-flow-runtime-main-build-spec options)
            +poo-flow-testing-project-build-spec+
            +poo-flow-cli-library-build-spec+
            (poo-flow-test-build-spec options))))

;; : (-> [BuildSpec])
(def (spec)
  (poo-flow-package-build-spec []))
