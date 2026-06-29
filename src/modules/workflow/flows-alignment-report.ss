;;; -*- Gerbil -*-
;;; Boundary: Funflow tutorial alignment report projections.
;;; Invariant: report rows summarize proof metadata and runtime gaps without execution.

(import (only-in :clan/poo/object .o .ref object<-alist)
        (only-in :std/srfi/1 filter-map fold)
        :poo-flow/src/modules/workflow/flows-alignment-specs)

(export poo-flow-funflow-tutorial-alignment-report)

;;; Boundary: alignment status count increment is the policy-visible edge for
;;; workflow behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
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

;;; Boundary: alignment status count ref is the policy-visible edge for
;;; workflow behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
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
   (cons 'bundle-field 'workflow-cicd-marlin-handoff-receipt-bundle)
   (cons 'expected-abi-kind
         'poo-flow.workflow.cicd.marlin-runtime-handoff-abi)
   (cons 'expected-bundle-kind
         'workflow-cicd-marlin-handoff-receipt-bundle)
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
   (object<-alist
    (list
     (cons 'kind (poo-flow-funflow-tutorial-alignment-report-kind))
     (cons 'schema (poo-flow-funflow-tutorial-alignment-schema))
     (cons 'upstream "tweag/funflow")
     (cons 'upstream-revision "356bc675")
     (cons 'audited-surface
           "funflow-tutorial/notebooks plus funflow-examples/makefile-tool")
     (cons 'source-count source-count-value)
     (cons 'spec-ids ids-value)
     (cons 'specs spec-snapshots-value)
     (cons 'source-index source-index-value)
     (cons 'source-proof-index source-proof-index-value)
     (cons 'status-source-matrix status-source-matrix-value)
     (cons 'status-counts status-counts-value)
     (cons 'deferred-ids deferred-ids-value)
     (cons 'runtime-owner-matrix runtime-owner-matrix-value)
     (cons 'handoff-readiness-summary handoff-readiness-summary-value)
     (cons 'ci-receipt-manifest ci-receipt-manifest-value)
     (cons 'user-interface-handoff-result-gate
           user-interface-handoff-result-gate-value)
     (cons 'runtime-gap-index runtime-gap-index-value)
     (cons 'runtime-gap-count (length runtime-gap-index-value))
     (cons 'proof-count proof-count-value)
     (cons 'gate-count (length gate-ids-value))
     (cons 'gate-ids gate-ids-value)
     (cons 'gate-proofs gate-proofs-value)
     (cons 'gate-proof-count gate-proof-count-value)
     (cons 'runtime-owner "marlin-agent-core")
     (cons 'runtime-executed #f)))))
