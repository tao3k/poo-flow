;;; -*- Gerbil -*-
;;; Boundary: Funflow tutorial alignment is a POO report, not loose prose.
;;; Invariant: heavy Docker/CAS/process work remains runtime-owned.

(import :std/test
        (only-in :clan/poo/object .ref object?)
        :modules/workflow/flows)

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

(def funflow-tutorial-alignment-report-test
  (test-suite "funflow tutorial alignment report"
    (test-case "projects audited upstream tutorial coverage as a POO report"
      (let* ((report (poo-flow-funflow-tutorial-alignment-report))
             (spec-snapshots (.ref report 'specs))
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
        (check-equal? (alignment-test-alist-ref counts 'result-covered) 6)
        (check-equal? (alignment-test-alist-ref counts
                                                'runtime-manifest-covered)
                      2)
        (check-equal? (alignment-test-alist-ref counts 'descriptor-covered) 1)
        (check-equal? (> (.ref report 'proof-count) 15) #t)
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
                      #t)))))

(run-tests! funflow-tutorial-alignment-report-test)
