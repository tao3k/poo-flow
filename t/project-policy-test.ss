;;; -*- Gerbil -*-
;;; Boundary: project policy must be visible from package tests, not only ASP.
;;; Invariant: the installed harness command owns its dependency load path.

(import :std/test
        (only-in :std/misc/process run-process))

(export project-policy-test
        project-policy-check
        project-policy-status)

;; : (-> Unit String)
(def (harness-binary)
  "gerbil-scheme-harness")

;; : (-> Unit PolicyResult)
(def project-policy-result #f)

;;; The check caches its process result so the suite and status helper share
;;; one harness invocation.
;; : (-> Unit PolicyResult)
(def (project-policy-check)
  (or project-policy-result
      (let (status 0)
        (let (output
              (run-process
               (list (harness-binary)
                     "check"
                     "--full")
               stderr-redirection: #t
               check-status:
               (lambda (exit-status _settings)
                 (set! status exit-status))))
          (set! project-policy-result (cons status output))
          project-policy-result))))

;; : (-> Unit Integer)
(def (project-policy-status)
  (car (project-policy-check)))

;; : (-> Unit TestSuite)
(def project-policy-test
  (test-suite "gerbil scheme project policy"
    (test-case "harness policy passes through package tests"
      (let* ((result (project-policy-check))
             (status (car result))
             (output (cdr result)))
        (display output)
        (check status => 0)))))
