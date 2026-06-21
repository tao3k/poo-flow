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
        :poo-flow/src/core/api
        :poo-flow/src/modules/docker
        :poo-flow/src/workflow/store)

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

;; | PooFlowAlignmentGateProof = Alist

;;; Boundary: gate proofs are report metadata, not test execution directives.
;;; Keeping proof strings inert lets downstream tooling audit coverage safely.
;; : (-> Symbol [String] PooFlowAlignmentGateProof)
(def (alignment-gate-proof id proofs)
  (list (cons 'id id)
        (cons 'proofs proofs)))

;;; Boundary: result gates track the repository proof ladder, not upstream files.
;;; The catalog connects tutorial parity to concrete local verification commands.
;; : (-> Unit [PooFlowAlignmentGateProof])
(def (poo-flow-funflow-tutorial-alignment-gate-proofs)
  (list
   (alignment-gate-proof
    'stage-1-minimal-flow
    '("gxtest t/tutorial-result-test.ss: stage 1 tutorial1 minimal pure flow returns 2"))
   (alignment-gate-proof
    'stage-2-composition-and-greeting
    '("gxtest t/tutorial-result-test.ss: stage 2 quick reference hello and composition results"))
   (alignment-gate-proof
    'stage-3-extension-behavior
    '("gxtest t/tutorial-result-test.ss: stage 3 tutorial2 extension behavior repeats custom text"
      "gxtest t/tutorial-feature-batch-test.ss: stage 12 tutorial2 custom task interpreter runs through extension"))
   (alignment-gate-proof
    'stage-4-word-count-pipeline
    '("gxtest t/tutorial-result-test.ss: stage 4 word count exposes deterministic counts"
      "gxtest t/tutorial-feature-batch-test.ss: stage 13 word count extension returns notebook counts"))
   (alignment-gate-proof
    'stage-5-external-config-fail-fast
    '("gxtest t/tutorial-result-test.ss: stage 5 external config fails before runtime submission"))
   (alignment-gate-proof
    'stage-6-error-handling-try-boundary
    '("gxtest t/tutorial-result-test.ss: stage 6 error handling try-flow routes thrown failures"
      "gxtest t/functional-flow-kernel-test.ss: authors functional flows with hygienic Gerbil macros"))
   (alignment-gate-proof
    'stage-7-docker-cas-real-runtime
    '("gxtest t/tutorial-runtime-result-test.ss: stage 7 docker process runtime command returns CCompilation visible result"
      "gxtest t/docker-descriptor-test.ss: captures CCompilation-style docker payload"
      "gxtest t/docker-descriptor-test.ss: captures ExternalConfig-style rendered arguments"))
   (alignment-gate-proof
    'stage-8-docker-artifact-handoff-to-store
    '("gxtest t/tutorial-runtime-result-test.ss: stage 8 docker artifact feeds store manifest"))
   (alignment-gate-proof
    'stage-9-descriptor-declared-runtime-command
    '("gxtest t/runtime-bridge-test.ss: stdout runtime command descriptor materializes process command"
      "gxtest t/tutorial-runtime-result-test.ss: stage 9 descriptor command drives docker store workflow"))
   (alignment-gate-proof
    'stage-10-descriptor-manifest-for-rust-cli-handoff
    '("gxtest t/runtime-bridge-test.ss: runtime command descriptor exports cli manifest"
      "gxtest t/tutorial-runtime-result-test.ss: stage 10 descriptor manifest exposes rust cli handoff"))
   (alignment-gate-proof
    'stage-11-quick-reference-conditional-and-cache
    '("gxtest t/tutorial-feature-batch-test.ss: stage 11 quick reference conditional and cached increment run"))
   (alignment-gate-proof
    'stage-12-tutorial2-custom-task-interpreter
    '("gxtest t/tutorial-feature-batch-test.ss: stage 12 tutorial2 custom task interpreter runs through extension"))
   (alignment-gate-proof
    'stage-13-word-count-text-extension
    '("gxtest t/tutorial-feature-batch-test.ss: stage 13 word count extension returns notebook counts"))
   (alignment-gate-proof
    'stage-14-ccompilation-and-tensorflow-descriptors
    '("gxtest t/tutorial-feature-batch-test.ss: stage 14 ccompilation and tensorflow workflow descriptors are public"))
   (alignment-gate-proof
    'stage-15-error-handling-recovery-boundary
    '("gxtest t/tutorial-feature-batch-test.ss: stage 15 error handling recovers local throw and adapter failure"))
   (alignment-gate-proof
    'stage-16-makefile-tool-workflow-descriptor
    '("gxtest t/tutorial-feature-batch-test.ss: stage 16 makefile tool workflow descriptor is public"))
   (alignment-gate-proof
    'stage-17-makefile-tool-descriptor-runtime-result
    '("gxtest t/tutorial-makefile-runtime-test.ss: stage 17 descriptor command drives makefile tool workflow"))
   (alignment-gate-proof
    'stage-18-makefile-tool-rust-cli-manifest
    '("gxtest t/tutorial-makefile-runtime-test.ss: stage 18 makefile tool descriptor manifest exposes rust cli handoff"))
   (alignment-gate-proof
    'stage-19-runtime-manifest-consumer
    '("gxtest t/runtime-manifest-test.ss: runtime command descriptor exports cli manifest"
      "gxtest t/runtime-manifest-test.ss: runtime command manifest consumer executes stdout protocol"
      "gxtest t/runtime-manifest-test.ss: runtime command manifest rejects unsupported protocol"))
   (alignment-gate-proof
    'stage-20-functional-flow-kernel-and-macro-authoring
    '("gxtest t/functional-flow-kernel-test.ss: functional flow kernel"))
   (alignment-gate-proof
    'stage-21-workflow-module-macro-authoring
    '("gxtest t/tutorial-feature-batch-test.ss: authors extension-owned workflows with Gerbil macros"
      "gxtest t/tutorial-makefile-runtime-test.ss: authors makefile runtime descriptor with Gerbil macros"))
   (alignment-gate-proof
    'stage-22-poo-tutorial-alignment-report
    '("gxtest t/funflow-tutorial-alignment-report-test.ss: funflow tutorial alignment report"))
   (alignment-gate-proof
    'stage-23-user-interface-marlin-handoff-projection
    '("gxtest t/user-interface-cicd-test.ss: projects user config into Marlin runtime handoff ABI"
      "gxtest t/funflow-tutorial-alignment-report-test.ss: user-interface Marlin handoff result gate"))))

;; : (-> PooFlowAlignmentGateProof Symbol)
(def (alignment-gate-proof-id gate-proof)
  (cdr (assoc 'id gate-proof)))

;; : (-> PooFlowAlignmentGateProof [String])
(def (alignment-gate-proof-commands gate-proof)
  (cdr (assoc 'proofs gate-proof)))

;;; Boundary: ids are projected from the proof catalog to prevent drift.
;;; Downstream code should consume ids and proofs from the same source.
;; : (-> Unit [Symbol])
(def (poo-flow-funflow-tutorial-alignment-gate-ids)
  (map alignment-gate-proof-id
       (poo-flow-funflow-tutorial-alignment-gate-proofs)))

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

;; : (-> Symbol Alist Integer)
(def (alignment-status-count-ref status counts)
  (let (entry (assoc status counts))
    (if entry (cdr entry) 0)))

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

;;; Boundary: gate proof count summarizes local verification coverage only.
;;; It does not replace executing the tests listed in the proof catalog.
;; : (-> [PooFlowAlignmentGateProof] Integer)
(def (alignment-gate-proof-count gate-proofs)
  (fold (lambda (gate-proof count)
          (+ count (length (alignment-gate-proof-commands gate-proof))))
        0
        gate-proofs))

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

;;; Boundary: source entries are optimized for upstream-to-local lookup.
;;; They deliberately omit proof strings so the index stays compact.
;; : (-> PooObject Alist)
(def (alignment-source-index-entry spec)
  (list (cons 'source (.ref spec 'source))
        (cons 'id (.ref spec 'id))
        (cons 'status (.ref spec 'status))
        (cons 'coverage (.ref spec 'coverage))))

;;; Boundary: source index preserves tutorial source order from the spec table.
;;; This is the fast path for checking which upstream file a report row covers.
;; : (-> [PooObject] [Alist])
(def (alignment-source-index specs)
  (map alignment-source-index-entry specs))

;;; Boundary: proof entries are detailed audit rows keyed by upstream source.
;;; They keep command receipts inert while linking proof coverage to runtime gaps.
;; : (-> PooObject Alist)
(def (alignment-source-proof-entry spec)
  (let (proofs (.ref spec 'proofs))
    (list (cons 'source (.ref spec 'source))
          (cons 'id (.ref spec 'id))
          (cons 'status (.ref spec 'status))
          (cons 'proof-count (length proofs))
          (cons 'proofs proofs)
          (cons 'runtime-owned (.ref spec 'runtime-owned))
          (cons 'deferred (.ref spec 'deferred)))))

;;; Boundary: source proof index preserves tutorial source order from specs.
;;; Use it for diagnostics that need proof strings; keep source-index compact.
;; : (-> [PooObject] [Alist])
(def (alignment-source-proof-index specs)
  (map alignment-source-proof-entry specs))

;;; Boundary: owner symbol collection is stable and spec-order preserving.
;;; Duplicate runtime owners collapse into the first observed matrix row.
;; : (-> [PooObject] [Symbol])
(def (alignment-runtime-owner-symbols specs)
  (fold (lambda (spec owners)
          (fold (lambda (owner seen)
                  (if (member owner seen)
                    seen
                    (append seen (list owner))))
                owners
                (.ref spec 'runtime-owned)))
        '()
        specs))

;;; Boundary: status filtering stays over normalized spec rows.
;;; It supports coverage matrix projections without changing the source table.
;; : (-> Symbol [PooObject] [PooObject])
(def (alignment-specs-with-status status specs)
  (filter (lambda (spec)
            (eq? status
                 (poo-flow-funflow-tutorial-alignment-spec-status spec)))
          specs))

;;; Boundary: status matrix rows expose source ids and paths for one status.
;;; The row is a report index, not another coverage authority.
;; : (-> Symbol [PooObject] Alist)
(def (alignment-status-source-entry status specs)
  (let* ((matching-specs (alignment-specs-with-status status specs))
         (matching-source-index (alignment-source-index matching-specs)))
    (list (cons 'status status)
          (cons 'count (length matching-specs))
          (cons 'ids (alignment-spec-ids matching-specs))
          (cons 'sources
                (map (lambda (entry) (cdr (assoc 'source entry)))
                     matching-source-index)))))

;;; Boundary: matrix order follows status-counts so summary and detail align.
;;; Consumers can compare counts without re-scanning the spec snapshots.
;; : (-> [PooObject] [Alist])
(def (alignment-status-source-matrix specs)
  (map (lambda (status-entry)
         (alignment-status-source-entry (car status-entry) specs))
       (alignment-status-counts specs)))

;;; Boundary: runtime owner matching is structural and data-only.
;;; It never executes the runtime operation named by the owner symbol.
;; : (-> Symbol PooObject Boolean)
(def (alignment-spec-has-runtime-owner? owner spec)
  (not (not (member owner (.ref spec 'runtime-owned)))))

;;; Boundary: runtime owner rows show handoff blast radius by backend concern.
;;; Statuses and deferred outputs stay attached so runtime readiness is visible.
;; : (-> Symbol [PooObject] Alist)
(def (alignment-runtime-owner-entry owner specs)
  (let* ((matching-specs
          (filter (lambda (spec)
                    (alignment-spec-has-runtime-owner? owner spec))
                  specs))
         (matching-source-index (alignment-source-index matching-specs)))
    (list (cons 'runtime-owner owner)
          (cons 'count (length matching-specs))
          (cons 'ids (alignment-spec-ids matching-specs))
          (cons 'statuses
                (map poo-flow-funflow-tutorial-alignment-spec-status
                     matching-specs))
          (cons 'sources
                (map (lambda (entry) (cdr (assoc 'source entry)))
                     matching-source-index))
          (cons 'deferred
                (fold (lambda (spec deferred)
                        (append deferred (.ref spec 'deferred)))
                      '()
                      matching-specs)))))

;;; Boundary: owner matrix groups runtime gaps by backend concern.
;;; It is diagnostic metadata for Marlin handoff, not an execution scheduler.
;; : (-> [PooObject] [Alist])
(def (alignment-runtime-owner-matrix specs)
  (map (lambda (owner)
         (alignment-runtime-owner-entry owner specs))
       (alignment-runtime-owner-symbols specs)))

;;; Boundary: readiness summary is a CI/user-interface snapshot.
;;; It summarizes existing report indexes without becoming a runtime scheduler.
;; : (-> Integer Alist [Alist] [Alist] Integer Integer Alist)
(def (alignment-handoff-readiness-summary source-count
                                          status-counts
                                          runtime-owner-matrix
                                          runtime-gap-index
                                          proof-count
                                          gate-proof-count)
  (let ((runtime-gap-count (length runtime-gap-index)))
    (list (cons 'runtime-owner "marlin-agent-core")
          (cons 'runtime-executed #f)
          (cons 'source-count source-count)
          (cons 'result-covered
                (alignment-status-count-ref 'result-covered status-counts))
          (cons 'runtime-manifest-covered
                (alignment-status-count-ref 'runtime-manifest-covered
                                            status-counts))
          (cons 'descriptor-covered
                (alignment-status-count-ref 'descriptor-covered status-counts))
          (cons 'runtime-gap-count runtime-gap-count)
          (cons 'runtime-owner-count (length runtime-owner-matrix))
          (cons 'proof-count proof-count)
          (cons 'gate-proof-count gate-proof-count)
          (cons 'handoff-required (> runtime-gap-count 0)))))

;;; Boundary: CI receipt manifest is inert user-interface data.
;;; It names local proof commands without becoming a command runner.
;; : (-> Alist Alist)
(def (alignment-ci-receipt-manifest handoff-readiness-summary)
  (list (cons 'schema
              'poo-flow.modules.funflow.tutorial-alignment.ci-receipts.v1)
        (cons 'expected-status 'pass)
        (cons 'runtime-executed #f)
        (cons 'handoff-readiness-summary handoff-readiness-summary)
        (cons 'result-gates
              '(alignment-report
                runtime-manifest
                functional-flow-kernel
                tutorial-feature-batch
                tutorial-makefile-runtime
                user-interface-marlin-handoff
                package-compile
                org-lint))
        (cons 'commands
              '("gxtest t/funflow-tutorial-alignment-report-test.ss"
                "gxtest t/runtime-manifest-test.ss"
                "gxtest t/functional-flow-kernel-test.ss"
                "gxtest t/tutorial-feature-batch-test.ss"
                "gxtest t/tutorial-makefile-runtime-test.ss"
                "gxtest t/user-interface-cicd-test.ss"
                "gxi build.ss compile"
                "asp org lint docs/10-19-design/10.04-funflow-tutorial-result-ladder.org"))))

;;; Boundary: this gate describes the user-interface handoff proof introduced
;;; after the workflow-owned Marlin ABI. It is metadata only; the actual user
;;; config projection is asserted by tests, not executed by this report.
;; : (-> Unit Alist)
(def (alignment-user-interface-handoff-result-gate)
  (list
   (cons 'schema
         'poo-flow.modules.funflow.tutorial-alignment.user-interface-handoff-gate.v1)
   (cons 'gate-id 'stage-23-user-interface-marlin-handoff-projection)
   (cons 'presentation-field 'workflow-cicd-marlin-runtime-handoff-abis)
   (cons 'summary-field 'workflow-cicd-marlin-runtime-handoff-summaries)
   (cons 'expected-abi-kind
         'poo-flow.workflow.cicd.marlin-runtime-handoff-abi)
   (cons 'runtime-owner "marlin-agent-core")
   (cons 'handoff-required #t)
   (cons 'runtime-executed #f)
   (cons 'runtime-parses-scheme-source #f)
   (cons 'scheme-manufactures-runtime-handlers #f)
   (cons 'proof-command
         "gxtest t/user-interface-cicd-test.ss: projects user config into Marlin runtime handoff ABI")))

;;; Boundary: runtime-gap detection stays structural and data-only.
;;; A gap means the source still delegates real work to Rust/Marlin runtime.
;; : (-> PooObject Boolean)
(def (alignment-runtime-gap-spec? spec)
  (or (not (null? (.ref spec 'runtime-owned)))
      (not (null? (.ref spec 'deferred)))))

;;; Boundary: gap entries keep source, owner, and deferred output in one row.
;;; This makes Docker/CAS/process/image gaps inspectable without running them.
;; : (-> PooObject Alist)
(def (alignment-runtime-gap-entry spec)
  (list (cons 'source (.ref spec 'source))
        (cons 'id (.ref spec 'id))
        (cons 'status (.ref spec 'status))
        (cons 'runtime-owned (.ref spec 'runtime-owned))
        (cons 'deferred (.ref spec 'deferred))))

;;; Boundary: runtime gap index is a report-only diagnostic projection.
;;; It does not imply the Scheme side can execute the listed runtime work.
;; : (-> [PooObject] [Alist])
(def (alignment-runtime-gap-index specs)
  (filter-map
   (lambda (spec)
     (if (alignment-runtime-gap-spec? spec)
       (alignment-runtime-gap-entry spec)
       #f))
   specs))

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
         (gate-proofs-value
          (poo-flow-funflow-tutorial-alignment-gate-proofs))
         (gate-ids-value (map alignment-gate-proof-id gate-proofs-value))
         (gate-proof-count-value
          (alignment-gate-proof-count gate-proofs-value))
         (spec-snapshots-value (map alignment-spec-snapshot specs))
         (source-index-value (alignment-source-index specs))
         (source-proof-index-value (alignment-source-proof-index specs))
         (status-source-matrix-value
          (alignment-status-source-matrix specs))
         (runtime-owner-matrix-value (alignment-runtime-owner-matrix specs))
         (runtime-gap-index-value (alignment-runtime-gap-index specs))
         (handoff-readiness-summary-value
          (alignment-handoff-readiness-summary source-count-value
                                                status-counts-value
                                                runtime-owner-matrix-value
                                                runtime-gap-index-value
                                                proof-count-value
                                                gate-proof-count-value))
         (ci-receipt-manifest-value
          (alignment-ci-receipt-manifest handoff-readiness-summary-value))
         (user-interface-handoff-result-gate-value
          (alignment-user-interface-handoff-result-gate)))
   (.o kind: (poo-flow-funflow-tutorial-alignment-report-kind)
       schema: (poo-flow-funflow-tutorial-alignment-schema)
        upstream: "tweag/funflow"
        upstream-revision: "356bc675"
        audited-surface: "funflow-tutorial/notebooks plus funflow-examples/makefile-tool"
        source-count: source-count-value
        spec-ids: ids-value
        specs: spec-snapshots-value
        source-index: source-index-value
        source-proof-index: source-proof-index-value
        status-source-matrix: status-source-matrix-value
        status-counts: status-counts-value
        deferred-ids: deferred-ids-value
        runtime-owner-matrix: runtime-owner-matrix-value
        handoff-readiness-summary: handoff-readiness-summary-value
        ci-receipt-manifest: ci-receipt-manifest-value
        user-interface-handoff-result-gate:
        user-interface-handoff-result-gate-value
        runtime-gap-index: runtime-gap-index-value
        runtime-gap-count: (length runtime-gap-index-value)
        proof-count: proof-count-value
        gate-count: (length gate-ids-value)
        gate-ids: gate-ids-value
        gate-proofs: gate-proofs-value
        gate-proof-count: gate-proof-count-value
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
