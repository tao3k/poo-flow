;;; -*- Gerbil -*-
;;; Boundary: Funflow tutorial alignment is a POO report, not loose prose.
;;; Invariant: heavy Docker/CAS/process work remains runtime-owned.

(import :std/test
        (only-in :clan/poo/object .ref object?)
        :poo-flow/src/modules/workflow/flows)

(export funflow-tutorial-alignment-report-test)

;; : (-> Alist Symbol Value)
(def (alignment-test-alist-ref alist key)
  (let (entry (assoc key alist))
    (if entry (cdr entry) #f)))

;; : (-> Symbol [PooObject] (U PooObject #f))
(def (alignment-test-spec-by-id id specs)
  (cond
   ((null? specs) #f)
   ((eq? id (.ref (car specs) 'id)) (car specs))
   (else (alignment-test-spec-by-id id (cdr specs)))))

;; : (-> Symbol [Alist] (U Alist #f))
(def (alignment-test-gate-proof-by-id id gate-proofs)
  (cond
   ((null? gate-proofs) #f)
   ((eq? id (alignment-test-alist-ref (car gate-proofs) 'id))
    (car gate-proofs))
   (else (alignment-test-gate-proof-by-id id (cdr gate-proofs)))))

;; : (-> String [Alist] (U Alist #f))
(def (alignment-test-entry-by-source source entries)
  (cond
   ((null? entries) #f)
   ((equal? source (alignment-test-alist-ref (car entries) 'source))
    (car entries))
   (else (alignment-test-entry-by-source source (cdr entries)))))

(def funflow-tutorial-alignment-report-test
  (test-suite "funflow tutorial alignment report"
    (test-case "projects audited upstream tutorial coverage as a POO report"
      (let* ((report (poo-flow-funflow-tutorial-alignment-report))
             (spec-snapshots (.ref report 'specs))
             (source-index (.ref report 'source-index))
             (counts (.ref report 'status-counts)))
        (check-equal? (object? report) #t)
        (check-equal? (poo-flow-funflow-tutorial-alignment-report? report) #t)
(check-equal? (.ref report 'kind)
              (poo-flow-funflow-tutorial-alignment-report-kind))
(check-equal? (.ref report 'schema)
              (poo-flow-funflow-tutorial-alignment-schema))
        (check-equal? (.ref report 'upstream) "tweag/funflow")
        (check-equal? (.ref report 'source-count) 9)
        (check-equal? (length spec-snapshots) 9)
        (check-equal? (length source-index) 9)
        (check-equal? (alignment-test-alist-ref counts 'result-covered) 6)
        (check-equal? (alignment-test-alist-ref counts
                                                'runtime-manifest-covered)
                      2)
        (check-equal? (alignment-test-alist-ref counts 'descriptor-covered) 1)
        (check-equal? (> (.ref report 'proof-count) 15) #t)
        (check-equal? (.ref report 'gate-count) 22)
        (check-equal? (length (.ref report 'gate-proofs)) 22)
        (check-equal? (> (.ref report 'gate-proof-count) 25) #t)
        (check-equal? (.ref report 'runtime-gap-count) 5)
        (check-equal? (.ref report 'runtime-owner) "marlin-agent-core")
        (check-equal? (.ref report 'runtime-executed) #f)))
    (test-case "keeps runtime-heavy tutorial gaps explicit"
      (let* ((report (poo-flow-funflow-tutorial-alignment-report))
             (specs (poo-flow-funflow-tutorial-alignment-specs))
             (ccompilation (alignment-test-spec-by-id 'ccompilation specs))
             (tensorflow (alignment-test-spec-by-id 'tensorflow-docker specs))
             (makefile (alignment-test-spec-by-id 'makefile-tool specs)))
        (check-equal? (not (not ccompilation)) #t)
        (check-equal? (not (not tensorflow)) #t)
        (check-equal? (not (not makefile)) #t)
        (check-equal? (.ref ccompilation 'status) 'runtime-manifest-covered)
        (check-equal? (.ref tensorflow 'status) 'descriptor-covered)
        (check-equal? (.ref makefile 'status) 'runtime-manifest-covered)
        (check-equal? (not
                       (not
                        (member 'tensorflow-docker
                                (.ref report 'deferred-ids))))
                      #t)
        (check-equal? (not
                       (not
                        (member 'summary-png (.ref tensorflow 'deferred))))
                      #t)
        (check-equal? (not
                       (not
                        (member 'real-container-execution
                                (.ref ccompilation 'deferred))))
                      #t)
        (check-equal? (not
                       (not
                        (member 'real-hello-binary-output
                                (.ref makefile 'deferred))))
                      #t)))
    (test-case "indexes upstream sources and runtime-owned gaps"
      (let* ((report (poo-flow-funflow-tutorial-alignment-report))
             (source-index (.ref report 'source-index))
             (gap-index (.ref report 'runtime-gap-index))
             (external-config
              (alignment-test-entry-by-source
               "funflow-tutorial/notebooks/ExternalConfig/ExternalConfig.ipynb"
               source-index))
             (tensorflow
              (alignment-test-entry-by-source
               "funflow-tutorial/notebooks/TensorflowDocker/TensorflowDocker.ipynb"
               gap-index))
             (makefile
              (alignment-test-entry-by-source
               "funflow-examples/makefile-tool/README.md"
               gap-index)))
        (check-equal? (alignment-test-alist-ref external-config 'id)
                      'external-config)
        (check-equal? (alignment-test-alist-ref external-config 'status)
                      'result-covered)
        (check-equal? (not
                       (not
                        (member 'python-training
                                (alignment-test-alist-ref tensorflow
                                                          'runtime-owned))))
                      #t)
        (check-equal? (not
                       (not
                        (member 'summary-png
                                (alignment-test-alist-ref tensorflow
                                                          'deferred))))
                      #t)
        (check-equal? (alignment-test-alist-ref makefile 'status)
                      'runtime-manifest-covered)))
    (test-case "keeps proof receipts attached to result-covered tutorial specs"
      (let* ((specs (poo-flow-funflow-tutorial-alignment-specs))
             (tutorial1 (alignment-test-spec-by-id 'tutorial1 specs))
             (word-count (alignment-test-spec-by-id 'word-count specs))
             (external-config (alignment-test-spec-by-id 'external-config
                                                         specs)))
        (check-equal? (poo-flow-funflow-tutorial-alignment-spec? tutorial1)
                      #t)
        (check-equal? (.ref tutorial1 'status) 'result-covered)
        (check-equal? (.ref tutorial1 'coverage)
                      '(pure-flow runner-result))
        (check-equal? (length (.ref word-count 'proofs)) 2)
        (check-equal? (not
                       (not
                        (member 'argument-rendering
                                (.ref external-config 'coverage))))
                      #t)
        (check-equal? (not
                       (not
                        (member 'real-docker-echo-output
                                (.ref external-config 'deferred))))
                      #t)))
    (test-case "keeps late-stage proof gates visible in report metadata"
      (let* ((report (poo-flow-funflow-tutorial-alignment-report))
             (gate-ids (.ref report 'gate-ids))
             (gate-proofs (.ref report 'gate-proofs))
             (stage19 (alignment-test-gate-proof-by-id
                       'stage-19-runtime-manifest-consumer
                       gate-proofs))
             (stage20 (alignment-test-gate-proof-by-id
                       'stage-20-functional-flow-kernel-and-macro-authoring
                       gate-proofs))
             (stage21 (alignment-test-gate-proof-by-id
                       'stage-21-workflow-module-macro-authoring
                       gate-proofs))
             (stage22 (alignment-test-gate-proof-by-id
                       'stage-22-poo-tutorial-alignment-report
                       gate-proofs)))
        (check-equal? (not
                       (not
                        (member 'stage-19-runtime-manifest-consumer
                                gate-ids)))
                      #t)
        (check-equal? (not
                       (not
                        (member 'stage-20-functional-flow-kernel-and-macro-authoring
                                gate-ids)))
                      #t)
        (check-equal? (not
                       (not
                        (member 'stage-21-workflow-module-macro-authoring
                                gate-ids)))
                      #t)
        (check-equal? (not
                       (not
                        (member 'stage-22-poo-tutorial-alignment-report
                                gate-ids)))
                      #t)
        (check-equal? (not (not stage19)) #t)
        (check-equal? (not
                       (not
                        (member "gxtest t/runtime-manifest-test.ss: runtime command manifest consumer executes stdout protocol"
                                (alignment-test-alist-ref stage19 'proofs))))
                      #t)
        (check-equal? (not
                       (not
                        (member "gxtest t/functional-flow-kernel-test.ss: functional flow kernel"
                                (alignment-test-alist-ref stage20 'proofs))))
                      #t)
        (check-equal? (length (alignment-test-alist-ref stage21 'proofs)) 2)
        (check-equal? (alignment-test-alist-ref stage22 'proofs)
                      '("gxtest t/funflow-tutorial-alignment-report-test.ss: funflow tutorial alignment report"))))))

(run-tests! funflow-tutorial-alignment-report-test)
