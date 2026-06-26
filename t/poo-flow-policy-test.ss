;;; -*- Gerbil -*-
;;; Boundary: static gxtest bridge for poo-flow CLI scoped policy checks.

(import :gerbil/gambit
        (only-in :std/test check test-case test-suite)
        (only-in :std/srfi/1 filter)
        (only-in :gslph/src/policy/gxtest
                 policy-report
                 display-project-policy-report)
        (only-in :gslph/src/types/facade type-finding-severity))

(export poo-flow-cli-policy-decode-test-files
        poo-flow-cli-policy-test-files
        poo-flow-cli-policy-error-findings
        poo-flow-cli-policy-error-report
        poo-flow-cli-policy-test-suite
        poo-flow-cli-policy-test)

;; : String
(def +poo-flow-cli-policy-files-env+
  "POO_FLOW_TEST_FILES")

;; : (-> MaybeString [String])
(def (poo-flow-cli-policy-decode-test-files value)
  (if (and value (not (string=? value "")))
    (let (datum (read (open-input-string value)))
      (if (list? datum) datum []))
    []))

;; : (-> Unit [String])
(def (poo-flow-cli-policy-test-files)
  (poo-flow-cli-policy-decode-test-files
   (getenv +poo-flow-cli-policy-files-env+ #f)))

;; : (-> [TypeFinding] [TypeFinding])
(def (poo-flow-cli-policy-error-findings findings)
  (filter (lambda (finding)
            (equal? (type-finding-severity finding) "error"))
          findings))

;; : (-> PolicyReport [TypeFinding] PolicyReport)
(def (poo-flow-cli-policy-error-report report errors)
  (hash (schemaId (hash-get report 'schemaId))
        (schemaVersion (hash-get report 'schemaVersion))
        (languageId (hash-get report 'languageId))
        (providerId (hash-get report 'providerId))
        (scope (hash-get report 'scope))
        (requestedFiles (hash-get report 'requestedFiles))
        (status "fail")
        (files (hash-get report 'files))
        (definitions (hash-get report 'definitions))
        (agentRepair (hash-get report 'agentRepair))
        (findings errors)))

;; : (-> [String] TestSuite)
(def (poo-flow-cli-policy-test-suite files)
  (test-suite "poo-flow scoped policy"
    (test-case "package policy has no error findings for test scope"
      (let* ((report (policy-report "." files))
             (findings (hash-get report 'findings))
             (errors (poo-flow-cli-policy-error-findings findings)))
        (when (not (null? errors))
          (display-project-policy-report
           (poo-flow-cli-policy-error-report report errors)))
        (check (length errors) => 0)))))

(def poo-flow-cli-policy-test
  (poo-flow-cli-policy-test-suite (poo-flow-cli-policy-test-files)))
