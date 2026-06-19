;;; -*- Gerbil -*-
;;; Boundary: nono-sandbox C binding tests cover ABI contracts and manifest projection.
;;; Invariant: tests do not load or execute the C library.

(import :std/test
        :core/api
        :modules/agent-sandbox/api
        :modules/agent-sandbox/nono
        :modules/agent-sandbox/cube
        :modules/nono-sandbox/c-binding)

(export nono-sandbox-c-binding-test)

;; : (-> Alist Symbol Value)
(def (test-ref alist key)
  (cdr (assoc key alist)))

(def nono-sandbox-c-binding-test
  (test-suite "nono-sandbox C binding contract"
    (test-case "declares POO descriptor for the generated nono C ABI"
      (let* ((descriptor (make-nono-c-binding-descriptor))
             (contract (nono-c-binding-descriptor->contract descriptor))
             (override (make-nono-c-binding-descriptor
                        (list (cons 'library "nono_ffi_test")))))
        (check-equal? (nono-c-binding-descriptor? descriptor) #t)
        (check-equal? (test-ref contract 'schema)
                      +nono-c-binding-schema+)
        (check-equal? (test-ref contract 'package) "nono-ffi")
        (check-equal? (test-ref contract 'library) "nono_ffi")
        (check-equal? (test-ref contract 'adapter-header)
                      "poo_flow_nono_binding.h")
        (check-equal? (test-ref contract 'adapter-include-ref)
                      "bindings/nono-c/poo_flow_nono_binding.h")
        (check-equal? (test-ref contract 'header) "nono.h")
        (check-equal? (test-ref contract 'include-ref)
                      ".data/nono/bindings/c/include/nono.h")
        (check-equal? (test-ref contract 'probe-ref)
                      "bindings/nono-c/poo_flow_nono_binding_probe.c")
        (check-equal? (and (memq 'nono_capability_set_allow_path
                                 (test-ref contract 'functions))
                           #t)
                      #t)
        (check-equal? (and (memq 'nono_sandbox_apply
                                 (test-ref contract 'functions))
                           #t)
                      #t)
        (check-equal? (nono-c-binding-descriptor-library override)
                      "nono_ffi_test")))
    (test-case "projects nono runtime manifests into C capability plans"
      (let* ((profile (make-nono-agent-sandbox-profile
                       'always-further/opencode))
             (request (agent-sandbox-request
                       profile
                       (command "opencode")
                       (args '("--print" "hello"))
                       (env '((OPENAI_API_KEY . redacted)))
                       (workdir "/workspace")
                       (mounts '(((path . "/workspace")
                                  (mode . read-write))
                                 ((path . "/workspace/config.json")
                                  (kind . file)
                                  (mode . read))))
                       (network-policy '((mode . proxy-only)
                                         (proxy-port . 11434)))
                       (capabilities '((allow-commands . ("opencode"))
                                       (block-commands . ("curl"))))
                       (resource-policy '((timeout-ms . 30000)))
                       (output-policy 'artifact)
                       (metadata '((agent . opencode)))))
             (manifest
              (agent-sandbox-request->nono-c-binding-manifest request))
             (binding (test-ref manifest 'binding))
             (backend (test-ref manifest 'backend))
             (process (test-ref manifest 'process))
             (plan (test-ref manifest 'capability-plan))
             (path-call (cadr plan))
             (file-call (caddr plan))
             (network-call (cadddr plan))
             (proxy-call (car (cddddr plan))))
        (check-equal? (test-ref manifest 'schema)
                      +nono-c-binding-schema+)
        (check-equal? (test-ref binding 'library) "nono_ffi")
        (check-equal? (test-ref backend 'kind) 'nono)
        (check-equal? (test-ref process 'argv)
                      '("opencode" "--print" "hello"))
        (check-equal? (test-ref (car plan) 'function)
                      'nono_capability_set_new)
        (check-equal? (test-ref path-call 'function)
                      'nono_capability_set_allow_path)
        (check-equal? (test-ref path-call 'access-constant)
                      'NONO_ACCESS_MODE_READ_WRITE)
        (check-equal? (test-ref file-call 'function)
                      'nono_capability_set_allow_file)
        (check-equal? (test-ref file-call 'access-constant)
                      'NONO_ACCESS_MODE_READ)
        (check-equal? (test-ref network-call 'network-constant)
                      'NONO_NETWORK_MODE_PROXY_ONLY)
        (check-equal? (test-ref proxy-call 'function)
                      'nono_capability_set_set_proxy_port)
        (check-equal? (test-ref (test-ref manifest 'query-plan)
                                'query-path)
                      'nono_query_context_query_path)
        (check-equal? (test-ref (test-ref manifest 'apply-plan)
                                'apply)
                      'nono_sandbox_apply)))
    (test-case "dry-runs and smoke-tests nono C binding manifests without applying sandbox"
      (let* ((request (agent-sandbox-request
                       (make-nono-agent-sandbox-profile
                        'always-further/opencode)
                       (command "opencode")
                       (args '("--print" "hello"))
                       (workdir "/workspace")
                       (mounts '(((path . "/workspace")
                                  (mode . read-write))))
                       (network-policy '((mode . blocked)))))
             (runtime-manifest
              (agent-sandbox-request->runtime-manifest request))
             (dry-run
              (nono-c-binding-dry-run runtime-manifest))
             (smoke
              (nono-c-binding-smoke-test
               runtime-manifest
               '("sh" "-c" "printf nono-smoke"))))
        (check-equal? (test-ref dry-run 'schema)
                      +nono-c-binding-dry-run-receipt-schema+)
        (check-equal? (test-ref dry-run 'ok?) #t)
        (check-equal? (test-ref dry-run 'would-apply?) #f)
        (check-equal? (test-ref dry-run 'runtime-executed) #f)
        (check-equal? (test-ref dry-run 'apply-function)
                      'nono_sandbox_apply)
        (check-equal? (> (test-ref dry-run 'capability-plan-count) 0)
                      #t)
        (check-equal? (test-ref smoke 'schema)
                      +nono-c-binding-smoke-test-receipt-schema+)
        (check-equal? (test-ref smoke 'ok?) #t)
        (check-equal? (test-ref smoke 'status) 0)
        (check-equal? (test-ref smoke 'output) "nono-smoke")
        (check-equal? (test-ref smoke 'runtime-executed) #f)
        (check-equal? (test-ref (test-ref smoke 'dry-run) 'would-apply?)
                      #f)))
    (test-case "rejects non-nono and unsupported C binding policy"
      (let* ((cube-request
              (agent-sandbox-request
               (make-cube-agent-sandbox-profile 'python-template)
               (command "python")
               (args '("-c" "print(1)"))
               (workdir "/workspace")
               (mounts '(((path . "/workspace") (mode . read))))))
             (nono-request
              (agent-sandbox-request
               (make-nono-agent-sandbox-profile 'always-further/opencode)
               (command "opencode")
               (mounts '(((path . "/workspace") (mode . execute))))))
             (cube-failure
              (with-catch (lambda (failure) failure)
                          (lambda ()
                            (agent-sandbox-request->nono-c-binding-manifest
                             cube-request))))
             (mode-failure
              (with-catch (lambda (failure) failure)
                          (lambda ()
                            (agent-sandbox-request->nono-c-binding-manifest
                             nono-request)))))
        (check-equal? (execution-failure? cube-failure) #t)
        (check-equal? (execution-failure-code cube-failure)
                      'invalid-nono-c-binding-manifest)
        (check-equal? (execution-failure? mode-failure) #t)
        (check-equal? (execution-failure-code mode-failure)
                      'invalid-nono-c-binding-manifest)))))

(run-tests! nono-sandbox-c-binding-test)
