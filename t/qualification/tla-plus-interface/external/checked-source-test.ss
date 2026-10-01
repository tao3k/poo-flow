;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :clan/poo/object .ref)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/string/misc string-trim-eol)
        :std/test
        (only-in :poo-flow/modules/temporal-causality/interface
                 poo-flow-temporal-query poo-flow-temporal-model-classify)
        (only-in :poo-flow/modules/tla-plus/checked-source-objects
                 poo-flow-tla-checked-source-value)
        :poo-flow/modules/tla-plus/interface)
(export tla-checked-source-test)

(def spec
  "packages/proofs/tla/temporal-causality/TemporalConclusionSelectionCase.tla")
(def config
  "packages/proofs/tla/temporal-causality/TemporalConclusionSelectionCase.cfg")
(def (source-document)
  (poo-flow-tla-parse-source
   (call-with-input-file spec read-all-as-string)))
(def (write-text path value)
  (call-with-output-file path
    (lambda (port) (display value port))))
(def (copy-local-case directory)
  (for-each
   (lambda (name)
     (write-text
      (path-expand name directory)
      (call-with-input-file
       (path-expand name "packages/proofs/tla/temporal-causality")
       read-all-as-string)))
   '("TemporalConclusionSelectionCase.tla"
     "TemporalConclusionSelectionData.tla"
     "TemporalConclusionSelection.tla"
     "TemporalConclusionSelectionCase.cfg")))

(def (check-family-agreement data-name case-name)
  ;; The data module is projected through the parser-owned source contract.
  ;; TLC explores the matching case with its expected terminal classification.
  (let* ((root "packages/proofs/tla/temporal-causality")
         (source (path-expand (string-append data-name ".tla") root))
         (spec-path (path-expand (string-append case-name ".tla") root))
         (cfg-path (path-expand (string-append case-name ".cfg") root))
         (projection
          (poo-flow-tla-project-temporal-model
           (poo-flow-tla-parse-source
            (call-with-input-file source read-all-as-string))))
         (native
          (poo-flow-temporal-model-classify
           (.ref projection 'model)
           (poo-flow-temporal-query "finite-family-check" "via-a" #f)))
         (expected
          (string-append "ExpectedClassifications = {\""
                         (symbol->string (.ref native 'classification)) "\"}"))
         (cfg-source (call-with-input-file cfg-path read-all-as-string)))
    (check (and (string-contains cfg-source expected) #t) => #t)
    (check (.ref native 'exhausted?) => #t)
    (let (checked
          (poo-flow-tla-check-source!
           (poo-flow-tla-parse-source
            (call-with-input-file spec-path read-all-as-string))
           spec-path cfg-path workers: 1))
      (check (.ref checked 'source-checked?) => #t)
      (check (.ref checked 'states-left) => 0)
      (check (.ref checked 'semantic-refinement?) => #f))))

(def (generated-family-source source-a source-b result)
  (string-append
   "---- MODULE TemporalHypothesisFamily ----\n"
   "ClockDomains == {<<\"timeline\", \"logical-version\">>}\n"
   "Observations == {<<\"source-a\", \"timeline\", "
   (number->string source-a) ", \"ledger\", \"observed\">>, "
   "<<\"source-b\", \"timeline\", "
   (number->string source-b) ", \"ledger\", \"observed\">>, "
   "<<\"result\", \"timeline\", "
   (number->string result) ", \"ledger\", \"observed\">>}\n"
   "Hypotheses == {<<\"via-a\", \"source-a\", \"result\">>, "
   "<<\"via-b\", \"source-b\", \"result\">>}\n"
   "Constraints == {}\nFamilyComplete == TRUE\n====\n"))

(def (generated-family-config classification)
  (string-append
   "SPECIFICATION FairSpec\n"
   "CONSTANTS ExplorationLimit = 0\n"
   "          Target = \"via-a\"\n"
   "          ExpectedClassifications = {\""
   (symbol->string classification) "\"}\n"
   "INVARIANT InputInvariant\n"
   "INVARIANT PartitionInvariant\n"
   "INVARIANT StatusInvariant\n"
   "INVARIANT BoundInvariant\n"
   "INVARIANT TerminalAgreement\n"
   "PROPERTY EventuallyTerminal\n"
   "CHECK_DEADLOCK FALSE\n"))

(def (check-generated-family source-a source-b result expected)
  (let (directory (string-trim-eol (run-process ["mktemp" "-d"])))
    (unwind-protect
      (let* ((root "packages/proofs/tla/temporal-causality")
             (spec-path (path-expand "TemporalFamilyCase.tla" directory))
             (data-path (path-expand "TemporalHypothesisFamily.tla" directory))
             (cfg-path (path-expand "TemporalFamilyCase.cfg" directory)))
        (for-each
         (lambda (name)
           (write-text
            (path-expand name directory)
            (call-with-input-file (path-expand name root) read-all-as-string)))
         '("TemporalFamilyCase.tla" "TemporalFamilyExplorer.tla"
           "TemporalFamilySemantics.tla" "TemporalOrder.tla"))
        (write-text data-path
                    (generated-family-source source-a source-b result))
        (let* ((projection
                (poo-flow-tla-project-temporal-model
                 (poo-flow-tla-parse-source
                  (call-with-input-file data-path read-all-as-string))))
               (native
                (poo-flow-temporal-model-classify
                 (.ref projection 'model)
                 (poo-flow-temporal-query "generated-family-check" "via-a" #f))))
          (check (.ref native 'classification) => expected)
          (write-text cfg-path
                      (generated-family-config (.ref native 'classification)))
          (let (checked
                (poo-flow-tla-check-source!
                 (poo-flow-tla-parse-source
                  (call-with-input-file spec-path read-all-as-string))
                 spec-path cfg-path workers: 1))
            (check (.ref checked 'source-checked?) => #t)
            (check (.ref checked 'states-left) => 0))))
      (delete-file-or-directory directory #t))))

(def tla-checked-source-test
  (test-suite "typed checked TLA+ source receipt"
    (poo-flow-test-case "generated finite families agree across native and TLC"
      (check-generated-family 1 2 3 'possible)
      (check-generated-family 1 4 3 'necessary)
      (check-generated-family 4 1 3 'refuted))
    (poo-flow-test-case "projected finite family agrees with both TLC cases"
      (check-family-agreement "TemporalHypothesisFamily" "TemporalFamilyCase")
      (check-family-agreement "TemporalDiscriminatingFamily"
                              "TemporalDiscriminatingCase"))
    (poo-flow-test-case "exact parsed source and TLC output are bound"
      (let* ((document (source-document))
             (receipt (poo-flow-tla-check-source!
                       document spec config workers: 1)))
        (check (poo-flow-tla-checked-source? receipt) => #t)
        (check (.ref receipt 'source-digest)
               => (.ref document 'source-digest))
        (check (string? (.ref receipt 'source-set-digest)) => #t)
        (check (.ref receipt 'states-left) => 0)
        (check (.ref receipt 'source-checked?) => #t)
        (check (.ref receipt 'semantic-refinement?) => #f)
        (check (.ref receipt 'action-authorized?) => #f)
        (check (.ref (poo-flow-tla-checked-source-replay receipt document)
                     'semantic-digest)
               => (.ref receipt 'semantic-digest))
        (let (forged
              (poo-flow-tla-checked-source-value
               "sha256:forged" "sha256:forged"
               (.ref receipt 'source-digest)
               (.ref receipt 'source-set-digest)
               (.ref receipt 'config-digest)
               (.ref receipt 'qualification-schema)
               (.ref receipt 'syntax-contract) (.ref receipt 'tool-digest)
               (.ref receipt 'tlc-version) (.ref receipt 'output-digest)
               (.ref receipt 'workers) (.ref receipt 'states-generated)
               (.ref receipt 'distinct-states) (.ref receipt 'states-left)
               (.ref receipt 'graph-depth)))
          (check-exception
           (poo-flow-tla-checked-source-replay forged document) true))))
    (poo-flow-test-case "changed local import changes the run identity"
      (let (directory
            (string-trim-eol (run-process ["mktemp" "-d"])))
        (unwind-protect
          (begin
            (copy-local-case directory)
            (let* ((root (path-expand
                          "TemporalConclusionSelectionCase.tla" directory))
                   (cfg (path-expand
                         "TemporalConclusionSelectionCase.cfg" directory))
                   (import-path (path-expand
                                 "TemporalConclusionSelectionData.tla"
                                 directory))
                   (document (source-document))
                   (before (poo-flow-tla-check-source!
                            document root cfg workers: 1)))
              (write-text
               import-path
               (string-append
                "\\* changed local import bytes\n"
                (call-with-input-file import-path read-all-as-string)))
              (let (after (poo-flow-tla-check-source!
                           document root cfg workers: 1))
                (check (.ref before 'source-digest)
                       => (.ref after 'source-digest))
                (check (equal? (.ref before 'source-set-digest)
                               (.ref after 'source-set-digest))
                       => #f)
                (check (equal? (.ref before 'semantic-digest)
                               (.ref after 'semantic-digest))
                       => #f))))
          (delete-file-or-directory directory #t))))
    (poo-flow-test-case "another parsed source cannot borrow the run"
      (check-exception
       (poo-flow-tla-check-source!
        (poo-flow-tla-parse-source
         "---- MODULE Other ----\nX == 1\n====\n")
        spec config workers: 1)
       true))))
