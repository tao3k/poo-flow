;;; -*- Gerbil -*-
;;; Boundary: focused CLI build performance gates cover package-local loadpath routing.
;;; Invariant: full package builds remain owned by gxpkg build, not this test.

(import :gerbil/gambit
        (only-in :std/test
                 check-equal?
                 test-case
                 test-suite)
        (only-in :gslph/src/benchmark/gate
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        (only-in :poo-flow/src/cli-support/build
                 poo-flow-cli-build)
        (only-in :poo-flow/src/cli-support/support
                 poo-flow-cli-gerbil-env-argv
                 poo-flow-cli-string-contains?
                 poo-flow-cli-string-prefix?))

(export cli-build-performance-test)

;; : String
(def focused-build-loadpath-fixture-path
  "t/scenarios/performance/focused-build-loadpath/benchmark.ss")

;; : Alist
(def focused-build-loadpath-fixture
  (call-with-input-file focused-build-loadpath-fixture-path read))

;; : String
(def package-build-status-fixture-path
  "t/scenarios/performance/package-build-status-fast-path/benchmark.ss")

;; : Alist
(def package-build-status-fixture
  (call-with-input-file package-build-status-fixture-path read))

;; : String
(def focused-build-loadpath-module
  "src/cli-support/support.ss")

;; : (-> [String])
(def (focused-build-loadpath-argv)
  (poo-flow-cli-gerbil-env-argv
   "gxc"
   [focused-build-loadpath-module]))

;; : (-> Alist Void)
(def (focused-build-loadpath-display-receipt receipt)
  (display "[poo-flow-benchmark] focused-build-loadpath ")
  (write receipt)
  (newline))

;; : (-> String)
(def (package-build-status-output)
  (call-with-output-string
   (lambda (port)
     (let (status #f)
       (parameterize ((current-output-port port)
                      (current-error-port port))
         (set! status (poo-flow-cli-build ["package-status" "--tests"])))
       (unless (= status 0)
         (error "poo-flow package-status fast path is stale" status))))))

;; : (-> Void)
(def (package-build-status-fast-path)
  (let (output (package-build-status-output))
    (unless (poo-flow-cli-string-contains? "status=current" output)
      (error "poo-flow package-status did not report current" output))))

;; : (-> Alist Void)
(def (package-build-status-display-receipt receipt)
  (display "[poo-flow-benchmark] package-build-status-fast-path ")
  (write receipt)
  (newline))

(def cli-build-performance-test
  (test-suite "cli build performance"
    (test-case "keeps focused build commands on package-local loadpath"
      (let* ((argv (focused-build-loadpath-argv))
             (loadpath (cadr argv))
             (receipt
              (benchmark-run
               focused-build-loadpath-fixture
               focused-build-loadpath-argv)))
        (check-equal?
         (benchmark-fixture-contract-pass? focused-build-loadpath-fixture)
         #t)
        (check-equal? (car argv) "env")
        (check-equal? (caddr argv) "gxc")
        (check-equal? (cadddr argv) focused-build-loadpath-module)
        (check-equal?
         (poo-flow-cli-string-prefix?
          "GERBIL_LOADPATH=.:.gerbil/lib"
          loadpath)
         #t)
        (check-equal?
         (poo-flow-cli-string-contains? "~/.gerbil/lib" loadpath)
         #f)
        (focused-build-loadpath-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))
    (test-case "keeps package build status on compiled receipt fast path"
      (let (receipt
            (benchmark-run
             package-build-status-fixture
             package-build-status-fast-path))
        (check-equal?
         (benchmark-fixture-contract-pass? package-build-status-fixture)
         #t)
        (check-equal?
         (poo-flow-cli-string-contains?
          "status=current"
          (package-build-status-output))
         #t)
        (package-build-status-display-receipt receipt)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
