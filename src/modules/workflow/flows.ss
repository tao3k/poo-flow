;;; -*- Gerbil -*-
;;; This module owns cross-extension workflow composition for tutorial-result
;;; gates that need more than one opt-in backend family.
;;; It gives users a public import target for composed run configs without
;;; making Docker or Store a dependency of core defaults.
;;; Preserve the import/export boundary: Docker and Store modules own their task
;;; constructors, descriptors, adapter capabilities, and runtime semantics.
;;; Preserve the runtime boundary: this module only stitches registries,
;;; strategy capabilities, and adapter wrappers around the shared command slot.
;;; Parser and policy evidence for multi-extension workflows should point here
;;; for composition shape, while real Docker/CAS behavior stays runtime-owned.

(import (only-in :clan/poo/object .o .ref object?)
        (only-in :std/srfi/1 filter-map fold)
        :core/api
        :modules/docker
        :workflow/store)

(export make-docker-store-run-config
        poo-flow-funflow-tutorial-alignment-schema
        poo-flow-funflow-tutorial-alignment-spec-kind
        poo-flow-funflow-tutorial-alignment-report-kind
        poo-flow-funflow-tutorial-alignment-spec
        poo-flow-funflow-tutorial-alignment-spec?
        poo-flow-funflow-tutorial-alignment-report?
        poo-flow-funflow-tutorial-alignment-spec-id
        poo-flow-funflow-tutorial-alignment-spec-status
        poo-flow-funflow-tutorial-alignment-specs
        poo-flow-funflow-tutorial-alignment-report
        make-ccompilation-flow
        make-ccompilation-store-workflow
        make-tensorflow-train-flow
        make-tensorflow-inference-flow
        make-tensorflow-workflow
        make-makefile-tool-parse-flow
        make-makefile-tool-run-flow
        make-makefile-tool-workflow
        make-makefile-tool-runtime-arguments
        make-makefile-tool-runtime-command-descriptor)

;;; Boundary: this schema symbol is the stable POO report envelope identity.
;;; Tests and docs compare this value directly, so it must not drift with paths.
;; | PooFlowFunflowTutorialAlignmentSchema = Symbol
;; : (-> Unit PooFlowFunflowTutorialAlignmentSchema)
(def (poo-flow-funflow-tutorial-alignment-schema)
  'poo-flow.modules.funflow.tutorial-alignment.v1)

;;; Boundary: spec kind tags individual tutorial evidence rows inside the report.
;;; It separates row objects from the aggregate report without runtime loading.
;; | PooFlowFunflowTutorialAlignmentKind = String
;; : (-> Unit PooFlowFunflowTutorialAlignmentKind)
(def (poo-flow-funflow-tutorial-alignment-spec-kind)
  "poo-flow.modules.funflow.tutorial-alignment.spec.v1")

;;; Boundary: report kind tags the aggregate alignment object consumed by tests.
;;; The string is external evidence metadata, not an executable workflow handle.
;; | PooFlowFunflowTutorialAlignmentKind = String
;; : (-> Unit PooFlowFunflowTutorialAlignmentKind)
(def (poo-flow-funflow-tutorial-alignment-report-kind)
  "poo-flow.modules.funflow.tutorial-alignment.report.v1")

;; : (-> PooObject PooFlowFunflowTutorialAlignmentKind Boolean)
(def (poo-flow-funflow-alignment-kind? value kind)
  (and (object? value)
       (equal? (.ref value 'kind) kind)
       (equal? (.ref value 'schema)
               (poo-flow-funflow-tutorial-alignment-schema))))

;; : (-> Symbol String String Symbol [Symbol] [String] [Symbol] [Symbol] PooObject)
(def (poo-flow-funflow-tutorial-alignment-spec
      id source observable status coverage proofs runtime-owned deferred)
  (let ((id-value id)
        (source-value source)
        (observable-value observable)
        (status-value status)
        (coverage-value coverage)
        (proofs-value proofs)
        (runtime-owned-value runtime-owned)
        (deferred-value deferred))
    (.o kind: (poo-flow-funflow-tutorial-alignment-spec-kind)
        schema: (poo-flow-funflow-tutorial-alignment-schema)
        id: id-value
        source: source-value
        observable: observable-value
        status: status-value
        coverage: coverage-value
        proofs: proofs-value
        runtime-owned: runtime-owned-value
        deferred: deferred-value)))

;; : (-> PooObject Boolean)
(def (poo-flow-funflow-tutorial-alignment-spec? value)
  (poo-flow-funflow-alignment-kind?
   value
   (poo-flow-funflow-tutorial-alignment-spec-kind)))

;; : (-> PooObject Boolean)
(def (poo-flow-funflow-tutorial-alignment-report? value)
  (poo-flow-funflow-alignment-kind?
   value
   (poo-flow-funflow-tutorial-alignment-report-kind)))

;; : (-> PooObject Symbol)
(def (poo-flow-funflow-tutorial-alignment-spec-id spec)
  (.ref spec 'id))

;; : (-> PooObject Symbol)
(def (poo-flow-funflow-tutorial-alignment-spec-status spec)
  (.ref spec 'status))

;;; Boundary: this table is the canonical Funflow tutorial alignment corpus.
;;; Keep row construction centralized so report tests can detect drift in coverage.
;; : (-> Unit [PooObject])
(def (poo-flow-funflow-tutorial-alignment-specs)
  (list
   (poo-flow-funflow-tutorial-alignment-spec
    'tutorial1
    "funflow-tutorial/notebooks/Tutorial1.ipynb"
    "runFlow over input 1 returns 2"
    'result-covered
    '(pure-flow runner-result)
    '("gxtest t/tutorial-result-test.ss: stage 1 tutorial1 minimal pure flow returns 2")
    '()
    '())
   (poo-flow-funflow-tutorial-alignment-spec
    'quick-reference
    "funflow-tutorial/notebooks/QuickReference.ipynb"
    "Hello Watson !, Hello world, conditional result 1, cached increment reuse"
    'result-covered
    '(pure-flow composition conditional-flow cached-scheme-flow)
    '("gxtest t/tutorial-result-test.ss: stage 2 quick reference hello and composition results"
      "gxtest t/tutorial-feature-batch-test.ss: stage 11 quick reference conditional and cached increment run")
    '()
    '())
   (poo-flow-funflow-tutorial-alignment-spec
    'tutorial2-custom-task
    "funflow-tutorial/notebooks/Tutorial2.ipynb"
    "Kangaroo goes woop! repeated seven times"
    'result-covered
    '(custom-task-family custom-run-config extension-owned-interpreter)
    '("gxtest t/tutorial-result-test.ss: stage 3 tutorial2 extension behavior repeats custom text"
      "gxtest t/tutorial-feature-batch-test.ss: stage 12 tutorial2 custom task interpreter runs through extension")
    '()
    '())
   (poo-flow-funflow-tutorial-alignment-spec
    'word-count
    "funflow-tutorial/notebooks/WordCount/WordCount.ipynb"
    "word count lines include a: 3, and: 3, Lets: 2, FILE: 1"
    'result-covered
    '(text-task-family word-count-summary)
    '("gxtest t/tutorial-result-test.ss: stage 4 word count exposes deterministic counts"
      "gxtest t/tutorial-feature-batch-test.ss: stage 13 word count extension returns notebook counts")
    '()
    '())
   (poo-flow-funflow-tutorial-alignment-spec
    'external-config
    "funflow-tutorial/notebooks/ExternalConfig/ExternalConfig.ipynb"
    "file/env/literal arguments render before Docker work; missing keys fail fast"
    'result-covered
    '(config-preflight argument-rendering missing-config-diagnostics)
    '("gxtest t/tutorial-result-test.ss: stage 5 external config fails before runtime submission"
      "gxtest t/store-funflow-alignment-test.ss: aligns Funflow external config preflight and rendering")
    '(docker-echo runtime-container)
    '(real-docker-echo-output))
   (poo-flow-funflow-tutorial-alignment-spec
    'error-handling
    "funflow-tutorial/notebooks/ErrorHandling.ipynb"
    "try boundary routes local and runtime failures to handled values"
    'result-covered
    '(try-flow runner-recover adapter-failure-receipt)
    '("gxtest t/tutorial-result-test.ss: stage 6 error handling try-flow routes thrown failures"
      "gxtest t/tutorial-feature-batch-test.ss: stage 15 error handling recovers local throw and adapter failure")
    '(runtime-failure-source)
    '())
   (poo-flow-funflow-tutorial-alignment-spec
    'ccompilation
    "funflow-tutorial/notebooks/CCompilation/CCompilation.ipynb"
    "Docker-backed GCC flow prints 15 for input 3"
    'runtime-manifest-covered
    '(docker-flow stdout-runtime-response docker-store-handoff runtime-manifest)
    '("gxtest t/tutorial-runtime-result-test.ss: stage 7 docker process runtime command returns CCompilation visible result"
      "gxtest t/tutorial-runtime-result-test.ss: stage 8 docker artifact feeds store manifest"
      "gxtest t/tutorial-runtime-result-test.ss: stage 9 descriptor command drives docker store workflow"
      "gxtest t/tutorial-runtime-result-test.ss: stage 10 descriptor manifest exposes rust cli handoff")
    '(docker-process cas-materialization artifact-store)
    '(real-container-execution real-cas-write))
   (poo-flow-funflow-tutorial-alignment-spec
    'tensorflow-docker
    "funflow-tutorial/notebooks/TensorflowDocker/TensorflowDocker.ipynb"
    "store data, train model, run inference, render summary.png"
    'descriptor-covered
    '(tensorflow-train-flow tensorflow-inference-flow docker-store-plan)
    '("gxtest t/tutorial-feature-batch-test.ss: stage 14 ccompilation and tensorflow workflow descriptors are public")
    '(docker-process python-training image-rendering cas-materialization)
    '(real-training-result real-inference-output summary-png))
   (poo-flow-funflow-tutorial-alignment-spec
    'makefile-tool
    "funflow-examples/makefile-tool/README.md"
    "parse Makefile project, build hello target, return process output"
    'runtime-manifest-covered
    '(external-parse-flow external-run-flow runtime-cli-manifest)
    '("gxtest t/tutorial-feature-batch-test.ss: stage 16 makefile tool workflow descriptor is public"
      "gxtest t/tutorial-makefile-runtime-test.ss: stage 17 descriptor command drives makefile tool workflow"
      "gxtest t/tutorial-makefile-runtime-test.ss: stage 18 makefile tool descriptor manifest exposes rust cli handoff")
    '(make-process filesystem-build)
    '(real-make-execution real-hello-binary-output))))

;; : (-> Symbol Alist Alist)
(def (alignment-status-count-increment status counts)
  (cond
   ((null? counts) (list (cons status 1)))
   ((eq? status (caar counts))
    (cons (cons status (+ 1 (cdar counts))) (cdr counts)))
   (else
    (cons (car counts)
          (alignment-status-count-increment status (cdr counts))))))

;;; Boundary: status counts are report metadata only; they summarize coverage
;;; states without changing runtime ownership or proof semantics.
;; : (-> [PooObject] Alist)
(def (alignment-status-counts specs)
  (fold (lambda (spec counts)
          (alignment-status-count-increment
           (poo-flow-funflow-tutorial-alignment-spec-status spec)
           counts))
        '()
        specs))

;;; Boundary: map preserves source row order so report output stays diff-stable.
;; : (-> [PooObject] [Symbol])
(def (alignment-spec-ids specs)
  (map poo-flow-funflow-tutorial-alignment-spec-id specs))

;;; Boundary: deferred ids keep runtime-owned gaps visible in diagnostics.
;;; Empty deferred slots stay out of the public report projection.
;; : (-> [PooObject] [Symbol])
(def (alignment-deferred-ids specs)
  (filter-map
   (lambda (spec)
     (if (null? (.ref spec 'deferred))
       #f
       (poo-flow-funflow-tutorial-alignment-spec-id spec)))
   specs))

;;; Boundary: proof counts are observability summaries, not success predicates.
;;; The helper counts attached proof strings without interpreting their content.
;; : (-> [PooObject] Integer)
(def (alignment-proof-count specs)
  (fold (lambda (spec count)
          (+ count (length (.ref spec 'proofs))))
        0
        specs))

;; : (-> PooObject Alist)
(def (alignment-spec-snapshot spec)
  (list (cons 'id (.ref spec 'id))
        (cons 'source (.ref spec 'source))
        (cons 'observable (.ref spec 'observable))
        (cons 'status (.ref spec 'status))
        (cons 'coverage (.ref spec 'coverage))
        (cons 'proofs (.ref spec 'proofs))
        (cons 'runtime-owned (.ref spec 'runtime-owned))
        (cons 'deferred (.ref spec 'deferred))))

;;; Boundary: aggregate observability is derived only from normalized spec rows.
;;; The map keeps row snapshots separate from report-level summary metadata.
;; : (-> [PooObject] PooObject)
(def (poo-flow-funflow-tutorial-alignment-report . maybe-specs)
  (let* ((specs (if (null? maybe-specs)
                  (poo-flow-funflow-tutorial-alignment-specs)
                  (car maybe-specs)))
         (ids-value (alignment-spec-ids specs))
         (source-count-value (length specs))
         (status-counts-value (alignment-status-counts specs))
         (deferred-ids-value (alignment-deferred-ids specs))
         (proof-count-value (alignment-proof-count specs))
         (spec-snapshots-value (map alignment-spec-snapshot specs)))
   (.o kind: (poo-flow-funflow-tutorial-alignment-report-kind)
       schema: (poo-flow-funflow-tutorial-alignment-schema)
        upstream: "tweag/funflow"
        upstream-revision: "356bc675"
        audited-surface: "funflow-tutorial/notebooks plus funflow-examples/makefile-tool"
        source-count: source-count-value
        spec-ids: ids-value
        specs: spec-snapshots-value
        status-counts: status-counts-value
        deferred-ids: deferred-ids-value
        proof-count: proof-count-value
        runtime-owner: "marlin-agent-core"
        runtime-executed: #f)))

;;; Workflow options stay alist-shaped so this composition layer can pass
;;; caller metadata through without owning Docker or Store schema validation.
;; : (-> Alist Symbol Value Value)
(def (workflow-option options key default)
  (let (entry (assoc key options))
    (if entry
      (cdr entry)
      default)))

;;; Boundary:
;;; - Option filtering keeps control callbacks out of exported descriptor metadata.
;;; - Metadata remains inert data for runtime manifests.
;; : (-> Alist Symbol Alist)
(def (workflow-options-without options key)
  (cond
   ((null? options) '())
   ((eq? (car (car options)) key)
    (workflow-options-without (cdr options) key))
   (else
    (cons (car options)
          (workflow-options-without (cdr options) key)))))

;;; Boundary:
;;; - Runtime manifests are argv-shaped, so every projected value becomes text.
;;; - Symbols stay readable while structured values use s-expression spelling.
;; : (-> RuntimeValue CliArgument)
(def (workflow-cli-string value)
  (cond
   ((not value) "")
   ((string? value) value)
   ((symbol? value) (symbol->string value))
   (else (object->string value))))

;;; The Docker+Store config composes capabilities and task registries while
;;; keeping both backend contracts behind the same runtime command boundary.
;; : (-> [Alist] RunConfig)
(def (make-docker-store-run-config . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (command (workflow-option options 'runtime-command #f)))
    (make-run-config
     'docker-store-runtime
     (store-enable-strategy
      (docker-enable-strategy (make-local-eager-strategy)))
     (make-store-enabled-adapter
      (make-docker-enabled-adapter (make-rust-adapter command)))
     (append '((runtime . rust)
               (extensions . (docker store)))
             options)
     (make-store-task-family-registry
      (make-docker-task-family-registry))
     default-flow-declaration-registry)))

;;; CCompilation's public Scheme result is a descriptor-shaped Docker flow.
;;; The runtime command owns image pulls, volume realization, compilation, and
;;; process handles; this constructor owns the tutorial's stable request shape.
;; : (-> Symbol Flow)
(def (make-ccompilation-flow name)
  (docker-flow name
               "gcc:9.3.0"
               "gcc"
               '("/example/double.c"
                 "/example/square.c"
                 "/example/main.c"
                 "-o"
                 "/output/main")
               '(((store-item . ccompilation-src)
                  (mount-path . "/example"))
                 ((store-item . ccompilation-output)
                  (mount-path . "/output")))
               'process-handle
               'integer
               'process-handle))

;;; The store handoff mirrors the tutorial's post-compile artifact boundary:
;;; Docker produces a process/artifact result, Store records a durable manifest.
;; : (-> Symbol Flow)
(def (make-ccompilation-store-workflow name)
  (flow-then name
             (make-ccompilation-flow 'compile-c)
             (store-flow 'store-c-binary
                         'put
                         '((store-item . c-binary)
                           (path . "/output/main"))
                         'process-handle
                         'artifact-manifest)))

;; : (-> Symbol Flow)
(def (make-tensorflow-train-flow name)
  (docker-flow name
               "tensorflow/tensorflow:2.3.0"
               "bash"
               '("-c"
                 "pip install -r /tensorflow-example/requirements.txt && python /tensorflow-example/train_mnist.py --n_epochs 10 ./model")
               '(((store-item . tensorflow-example)
                  (mount-path . "/tensorflow-example"))
                 ((store-item . trained-model-output)
                  (mount-path . "/model-output")))
               'trained-model
               'unit
               'trained-model))

;; : (-> Symbol Flow)
(def (make-tensorflow-inference-flow name)
  (docker-flow name
               "tensorflow/tensorflow:2.3.0"
               "bash"
               '("-c"
                 "pip install -r /tensorflow-example/requirements.txt && python /tensorflow-example/inference_mnist.py /trained/model /tensorflow-example/demo-images ./summary.png")
               '(((store-item . tensorflow-example)
                  (mount-path . "/tensorflow-example"))
                 ((store-item . trained-model)
                  (mount-path . "/trained"))
                 ((store-item . tensorflow-summary-output)
                  (mount-path . "/summary-output")))
               'summary-image
               'trained-model
               'summary-image))

;;; TensorflowDocker is represented as a two-step external workflow. It keeps
;;; the visible training/inference milestones inspectable while leaving model
;;; training, image rendering, and filesystem writes to the runtime owner.
;; : (-> Symbol Flow)
(def (make-tensorflow-workflow name)
  (flow-then name
             (make-tensorflow-train-flow 'train-mnist)
             (make-tensorflow-inference-flow 'infer-mnist)))

;;; Boundary:
;;; - makefile-tool parsing is a runtime-owned external task.
;;; - Scheme owns only the tutorial-visible project descriptor.
;; : (-> Symbol Flow)
(def (make-makefile-tool-parse-flow name)
  (external-flow name
                 'makefile-tool-parse
                 '((makefile . "Makefile")
                   (working-directory . "funflow-examples/makefile-tool/test")
                   (sources . ("main.cpp" "hello.cpp" "factorial.cpp")))
                 'makefile-project
                 'makefile-plan))

;;; Boundary:
;;; - makefile-tool execution is a runtime-owned external task.
;;; - The output contract models the notebook's process-output result.
;; : (-> Symbol Flow)
(def (make-makefile-tool-run-flow name)
  (external-flow name
                 'makefile-tool-run
                 '((target . "hello")
                   (binary . "./hello")
                   (expected-output . process-output))
                 'makefile-plan
                 'process-output))

;;; Boundary:
;;; - This workflow preserves the tutorial's parse-then-run milestone shape.
;;; - Rust or another adapter owns Makefile execution and filesystem effects.
;; : (-> Symbol Flow)
(def (make-makefile-tool-workflow name)
  (flow-then name
             (make-makefile-tool-parse-flow 'makefile-tool-parse)
             (make-makefile-tool-run-flow 'makefile-tool-run)))

;;; Boundary:
;;; - This argument builder is the Rust CLI handoff for makefile-tool requests.
;;; - It serializes request metadata without running Makefile or process work.
;; | RuntimeArgumentBuilder = (-> RuntimeEnvelope [String])
;; : (-> [Alist] RuntimeArgumentBuilder)
;; make-makefile-tool-runtime-arguments
;;   : (-> [Alist] RuntimeArgumentBuilder)
;;   | contract: options produce an envelope serializer, not runtime execution
;;   | doc m%
;;   | # Examples
;;   | ```scheme
;;   | ((make-makefile-tool-runtime-arguments '((runtime-name . "makefile-tool")))
;;   |  runtime-envelope)
;;   | ```
;;   | result: CLI argv list for the Marlin-owned runtime command.
(def (make-makefile-tool-runtime-arguments . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (runtime-name (workflow-option options
                                        'runtime-name
                                        "makefile-tool")))
    (lambda (envelope)
      (let* ((request (cdr (assoc 'request envelope)))
             (operation (cadr (execution-request-request request)))
             (payload (caddr (execution-request-request request)))
             (base (list runtime-name
                         "--request-id"
                         (workflow-cli-string (cdr (assoc 'request-id envelope)))
                         "--plan-id"
                         (workflow-cli-string (execution-request-plan-id request))
                         "--operation"
                         (workflow-cli-string operation))))
        (append
         base
         (cond
          ((eq? operation 'makefile-tool-parse)
           (list "--working-directory"
                 (workflow-cli-string
                  (workflow-option payload 'working-directory "."))
                 "--makefile"
                 (workflow-cli-string
                  (workflow-option payload 'makefile "Makefile"))
                 "--sources"
                 (workflow-cli-string
                  (workflow-option payload 'sources '()))))
          ((eq? operation 'makefile-tool-run)
           (list "--target"
                 (workflow-cli-string
                  (workflow-option payload 'target ""))
                 "--binary"
                 (workflow-cli-string
                  (workflow-option payload 'binary ""))
                 "--expected-output"
                 (workflow-cli-string
                  (workflow-option payload 'expected-output 'process-output))))
          (else
           (list "--payload" (workflow-cli-string payload)))))))))

;;; Boundary:
;;; - The descriptor is inert until materialized by runtime-adapter code.
;;; - Tests may override =arguments= to emulate a runtime response through /bin/echo.
;; : (-> Symbol String [Alist] RuntimeCommandDescriptor)
(def (make-makefile-tool-runtime-command-descriptor name executable . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (arguments (workflow-option
                     options
                     'arguments
                     (make-makefile-tool-runtime-arguments options)))
         (metadata (append '((workflow . makefile-tool)
                             (runtime . rust-cli-compatible))
                           (workflow-options-without options 'arguments))))
    (make-stdout-runtime-command-descriptor name
                                            executable
                                            arguments
                                            metadata)))
