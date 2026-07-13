;;; -*- Gerbil -*-
;;; Boundary: AC-10 orchestration only; existing owners decide gate semantics.

(export #t)

(import :gerbil/gambit
        :clan/poo/object
        :std/crypto/digest
        :std/text/hex
        :poo-flow/src/build-api/process-memory-guard)

(def +poo-flow-ac10-release-gates+
  '(scheme-canonical-fixture runtime-v0-installed-consumer
    proof-case-installed-consumer python-production-runtime
    python-proof-installed-wheel lean-build lean-ffi-smoke))

(def (poo-flow-qualification-gate gate-id owner cwd argv installed-consumer?
                                  artifact max-rss-mib timeout-seconds modes)
  (object<-alist
   (list (cons 'kind 'poo-flow.qualification-gate.v1)
         (cons 'gate-id gate-id) (cons 'owner owner) (cons 'cwd cwd)
         (cons 'argv argv) (cons 'installed-consumer? installed-consumer?)
         (cons 'artifact artifact) (cons 'max-rss-mib max-rss-mib)
         (cons 'timeout-seconds timeout-seconds) (cons 'modes modes))))

(def (gate-canonical gate)
  (list 'poo-flow.qualification-gate.v1
        (.ref gate 'gate-id) (.ref gate 'owner) (.ref gate 'cwd)
        (.ref gate 'argv) (.ref gate 'installed-consumer?)
        (.ref gate 'artifact) (.ref gate 'max-rss-mib)
        (.ref gate 'timeout-seconds) (.ref gate 'modes)))

(def (poo-flow-qualification-gate-digest gate)
  (hex-encode
   (sha256
    (call-with-output-string
     (lambda (port) (write (gate-canonical gate) port))))))

(def (poo-flow-agentic-control-plane-gate-registry)
  (list
   (poo-flow-qualification-gate
    'scheme-canonical-fixture 'scheme "."
    '("gxi" "t/scenarios/agentic-control-plane-canonical-fixture-test.ss")
    #f "canonical-fixture" 512 15 '(focused release))
   (poo-flow-qualification-gate
    'runtime-v0-installed-consumer 'runtime-c "."
    '("npx" "-y" "@bazel/bazelisk" "test"
      "//bindings/runtime-c:runtime_v0_installed_consumer"
      "--nocache_test_results")
    #t "runtime-v0-installed-prefix" 2048 180 '(release))
   (poo-flow-qualification-gate
    'proof-case-installed-consumer 'runtime-c "."
    '("npx" "-y" "@bazel/bazelisk" "test"
      "//bindings/runtime-c:proof_case_v1_installed_consumer"
      "--nocache_test_results")
    #t "proof-case-v1-installed-prefix" 2048 180 '(release))
   (poo-flow-qualification-gate
    'python-production-runtime 'python "packages/python-runtime"
    '("uv" "run" "pytest" "-q")
    #f "python-production-suite" 2048 180 '(release))
   (poo-flow-qualification-gate
    'python-proof-installed-wheel 'python "packages/proof/python"
    '("env" "-u" "PYTHONPATH" "uv" "run" "pytest" "-q"
      "tests/test_installed_wheel.py")
    #t "isolated-proof-wheel" 2048 180 '(release))
   (poo-flow-qualification-gate
    'lean-build 'lean "packages/proof/lean"
    '("lake" "build") #f "lean-checked-artifact" 2048 180 '(release))
   (poo-flow-qualification-gate
    'lean-ffi-smoke 'lean "packages/proof/lean"
    '("lake" "exe" "ffiSmoke") #t "lean-native-ffi-smoke" 2048 180
    '(release))))

(def (gate-in-mode? gate mode)
  (memq mode (.ref gate 'modes)))

(def (poo-flow-qualification-run-gate gate source-revision)
  (let ((previous (current-directory))
        (process-receipt #f))
    (dynamic-wind
      (lambda () (current-directory (.ref gate 'cwd)))
      (lambda ()
        (set! process-receipt
              (poo-flow-process-memory-guard-run
               (.ref gate 'gate-id)
               (* (.ref gate 'max-rss-mib) 1024 1024)
               (.ref gate 'timeout-seconds)
               (.ref gate 'argv))))
      (lambda () (current-directory previous)))
    (object<-alist
     (list (cons 'kind 'poo-flow.qualification-gate-receipt.v1)
           (cons 'gate-id (.ref gate 'gate-id))
           (cons 'owner (.ref gate 'owner))
           (cons 'source-revision source-revision)
           (cons 'declaration-digest
                 (poo-flow-qualification-gate-digest gate))
           (cons 'artifact (.ref gate 'artifact))
           (cons 'installed-consumer? (.ref gate 'installed-consumer?))
           (cons 'accepted? (= (.ref process-receipt 'exit-code) 0))
           (cons 'process-receipt process-receipt)))))

(def (poo-flow-qualification-run registry source-revision mode)
  (let* ((selected (filter (lambda (gate) (gate-in-mode? gate mode)) registry))
         (receipts (map (lambda (gate)
                          (poo-flow-qualification-run-gate
                           gate source-revision))
                        selected)))
    (object<-alist
     (list (cons 'kind 'poo-flow.qualification-run-receipt.v1)
           (cons 'mode mode) (cons 'source-revision source-revision)
           (cons 'gate-receipts receipts)
           (cons 'accepted?
                 (andmap (lambda (receipt) (.ref receipt 'accepted?))
                         receipts))))))

(def (find-gate id gates)
  (find (lambda (gate) (eq? id (.ref gate 'gate-id))) gates))

(def (find-receipt id receipts)
  (find (lambda (receipt) (eq? id (.ref receipt 'gate-id))) receipts))

(def (poo-flow-qualification-verify-run registry run-receipt)
  (let* ((receipts (.ref run-receipt 'gate-receipts))
         (revision (.ref run-receipt 'source-revision))
         (release? (eq? (.ref run-receipt 'mode) 'release))
         (required (if release? +poo-flow-ac10-release-gates+
                       '(scheme-canonical-fixture)))
         (diagnostics '()))
    (def (reject! code gate-id)
      (set! diagnostics
            (cons (list (cons 'code code) (cons 'gate-id gate-id))
                  diagnostics)))
    (for-each
     (lambda (id)
       (let ((gate (find-gate id registry))
             (receipt (find-receipt id receipts)))
         (cond
          ((not gate) (reject! 'missing-gate-declaration id))
          ((not receipt) (reject! 'missing-gate-receipt id))
          ((not (equal? revision (.ref receipt 'source-revision)))
           (reject! 'stale-source-revision id))
          ((not (equal? (poo-flow-qualification-gate-digest gate)
                        (.ref receipt 'declaration-digest)))
           (reject! 'stale-gate-declaration id))
          ((not (.ref receipt 'accepted?)) (reject! 'gate-failed id))
          ((and release?
                (memq id '(runtime-v0-installed-consumer
                           proof-case-installed-consumer
                           python-proof-installed-wheel lean-ffi-smoke))
                (not (.ref receipt 'installed-consumer?)))
           (reject! 'installed-consumer-required id)))))
     required)
    (object<-alist
     (list (cons 'kind 'poo-flow.qualification-verification-receipt.v1)
           (cons 'accepted? (null? diagnostics))
           (cons 'code (if (null? diagnostics) 'verified 'rejected))
           (cons 'diagnostics (reverse diagnostics))))))

(def (poo-flow-qualification-run-receipt->alist receipt)
  (list
   (cons 'schema 'poo-flow.qualification-run-receipt.v1)
   (cons 'mode (.ref receipt 'mode))
   (cons 'source-revision (.ref receipt 'source-revision))
   (cons 'accepted? (.ref receipt 'accepted?))
   (cons 'gates
         (map
          (lambda (gate-receipt)
            (list
             (cons 'gate-id (.ref gate-receipt 'gate-id))
             (cons 'owner (.ref gate-receipt 'owner))
             (cons 'declaration-digest
                   (.ref gate-receipt 'declaration-digest))
             (cons 'artifact (.ref gate-receipt 'artifact))
             (cons 'installed-consumer?
                   (.ref gate-receipt 'installed-consumer?))
             (cons 'accepted? (.ref gate-receipt 'accepted?))
             (cons 'process
                   (poo-flow-process-memory-guard-receipt->alist
                    (.ref gate-receipt 'process-receipt)))))
          (.ref receipt 'gate-receipts)))))

(def (poo-flow-qualification-verification-receipt->alist receipt)
  (list (cons 'schema 'poo-flow.qualification-verification-receipt.v1)
        (cons 'accepted? (.ref receipt 'accepted?))
        (cons 'code (.ref receipt 'code))
        (cons 'diagnostics (.ref receipt 'diagnostics))))
