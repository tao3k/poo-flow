(import :std/test
        :gslph/src/build-api/framework
        :gslph/src/testing/framework)

(def +cli-support-command-events+ '())

(def (cli-support-command-record! event)
  (set! +cli-support-command-events+
        (cons event +cli-support-command-events+)))

(def (cli-support-command-load!)
  (cli-support-command-record! 'load))

(define-build-options cli-support-command-options
  load!: cli-support-command-load!
  make: (lambda () (lambda arguments (cons 'options arguments))))

(define-build-commands
 (cli-support-command-spec!
  cli-support-command-compile!
  cli-support-command-clean!)
 load!: cli-support-command-load!
 spec: (lambda () (lambda (options) (list 'spec options)))
 compile: (lambda () (lambda (options) (list 'compile options)))
 clean: (lambda () (lambda () 'clean)))

(define-project-test cli-support-command-test!
  bootstrap!: (lambda () (cli-support-command-record! 'bootstrap))
  project: (lambda () 'project)
  run: (lambda (project files) (and (eq? project 'project) files))
  ok?: pair?)

(export cli-support-framework-command-macro-test)

(def cli-support-framework-command-macro-test
  (test-suite "cli-support-framework-command-macro"
    (test-case "standardizes build command load and dispatch"
      (set! +cli-support-command-events+ '())
      (check-equal? (cli-support-command-spec! 'options)
                    '(spec options))
      (check-equal? (cli-support-command-compile! 'options)
                    '(compile options))
      (check-equal? (cli-support-command-clean!) 'clean)
      (check-equal? +cli-support-command-events+
                    '(load load load)))
    (test-case "loads the package facade before constructing options"
      (set! +cli-support-command-events+ '())
      (check-equal? (cli-support-command-options 'release 'verbose)
                    '(options release verbose))
      (check-equal? +cli-support-command-events+ '(load)))
    (test-case "standardizes selected test bootstrap and status"
      (set! +cli-support-command-events+ '())
      (check-equal? (cli-support-command-test! '("t/example.ss")) 0)
      (check-equal? +cli-support-command-events+ '(bootstrap)))))
