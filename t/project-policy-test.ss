;;; -*- Gerbil -*-
;;; Boundary: project policy must be visible from package tests, not only ASP.
;;; Invariant: the installed harness package owns the native check API.

(import (only-in :gerbil/gambit
                 with-output-to-string)
        (only-in :std/test
                 test-suite
                 test-case
                 check-equal?)
        (only-in :gslph/src/commands/check
                 check-main)
        (only-in :std/srfi/13 string-contains))

(export project-policy-test
        project-policy-check
        project-policy-status)

;; : (-> Unit PolicyResult)
(def project-policy-result #f)

;;; The check caches its native result so the suite and status helper share
;;; one harness invocation.
;; : (-> Unit PolicyResult)
(def (project-policy-check)
  (or project-policy-result
      (let (status 0)
        (let (output
              (with-output-to-string
               (lambda ()
                 (set! status (check-main '("--workspace" "." "--full"))))))
          (set! project-policy-result (cons status output))
          project-policy-result))))

;; : (-> String String Boolean)
(def (project-policy-output-contains? output needle)
  (not (not (string-contains output needle))))

;; : (-> PolicyResult Boolean)
(def (project-policy-hard-failure? result)
  (let ((status (car result))
        (output (cdr result)))
    (or (not (project-policy-output-contains? output "[gerbil-check]"))
        (project-policy-output-contains? output "cannot find library module")
        (not (or (= status 0)
                 (project-policy-output-contains? output "findings="))))))

;; : (-> Unit Integer)
(def (project-policy-status)
  (if (project-policy-hard-failure? (project-policy-check)) 1 0))

;; : (-> Unit TestSuite)
(def project-policy-test
  (test-suite "gerbil scheme project policy"
    (test-case "harness policy is visible from package tests"
      (let* ((result (project-policy-check))
             (status (car result))
             (output (cdr result)))
        (check-equal? (or (= status 0)
                          (project-policy-output-contains? output
                                                           "findings="))
                      #t)
        (check-equal? (project-policy-output-contains? output
                                                       "[gerbil-check]")
                      #t)
        (check-equal? (project-policy-output-contains? output
                                                       "cannot find library module")
                      #f)
        (check-equal? (project-policy-status) 0)))))
