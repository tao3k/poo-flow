;;; -*- Gerbil -*-
;;; Boundary: project policy must be visible from package tests, not only ASP.

(import :std/test
        (only-in :std/misc/process run-process))

(export project-policy-test
        project-policy-check
        project-policy-status)

(def harness-root
  ".gerbil/pkg/github.com/tao3k/gerbil-scheme-language-project-harness")

(def (home-path path)
  (path-expand path (getenv "HOME")))

(def (project-path path)
  (path-expand path (current-directory)))

(def (harness-binary)
  (home-path (string-append harness-root "/.bin/gerbil-scheme-harness")))

(def (harness-loadpath)
  (string-join
   (append
    (map project-path
         (list "src"
               "t"))
    (map home-path
         (list ".gerbil/pkg/git.cons.io/mighty-gerbils/gerbil-poo"
               ".gerbil/pkg/git.cons.io/mighty-gerbils/gerbil-utils"
               (string-append harness-root "/src"))))
   ":"))

(def project-policy-result #f)

(def (project-policy-check)
  (or project-policy-result
      (let (status 0)
        (let (output
              (run-process
               (list "env"
                     (string-append "GERBIL_LOADPATH=" (harness-loadpath))
                     (harness-binary)
                     "check"
                     "--full")
               stderr-redirection: #t
               check-status:
               (lambda (exit-status _settings)
                 (set! status exit-status))))
          (set! project-policy-result (cons status output))
          project-policy-result))))

(def (project-policy-status)
  (car (project-policy-check)))

(def project-policy-test
  (test-suite "gerbil scheme project policy"
    (test-case "harness policy passes through package tests"
      (let* ((result (project-policy-check))
             (status (car result))
             (output (cdr result)))
        (display output)
        (check status => 0)))))
