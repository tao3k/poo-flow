;;; -*- Gerbil -*-
;;; Boundary: Docker descriptor tests cover tutorial-shaped request data only.
;;; Invariant: Scheme never pulls images, mounts volumes, or executes Docker.

(import :std/test
        :core/api
        :extensions/docker)

(export docker-descriptor-test)

;; AdapterResult <- Value Alist
(def (runtime-result value artifact)
  (list (cons 'schema +runtime-response-schema+)
        (cons 'request-id '(runtime docker-test))
        (cons 'status 'completed)
        (cons 'value value)
        (cons 'artifact-handle artifact)
        (cons 'error #f)
        (cons 'metadata '((runtime . docker-descriptor-test)))))

;; Alist <- ExecutionRequest
(def (request-config request)
  (cadr (execution-request-request request)))

(def docker-descriptor-test
  (test-suite "docker task descriptor"
    (test-case "captures CCompilation-style docker payload"
      (let (seen-request #f)
        (let* ((command (lambda (envelope)
                          (set! seen-request (cdr (assoc 'request envelope)))
                          (runtime-result 15 '(artifact ccompilation-output))))
               (config (make-docker-run-config
                        (list (cons 'runtime-command command))))
               (flow (docker-flow 'compile-c
                                  "gcc:9.3.0"
                                  "gcc"
                                  '("/example/double.c" "/example/main.c" "-o" "/output/main")
                                  '(((store-item . example-src)
                                     (mount-path . "/example"))
                                    ((store-item . output-dir)
                                     (mount-path . "/output")))
                                  'process-handle
                                  'integer
                                  'process-handle))
               (result (run-result-value
                        (run-flow-with-config config flow 3)))
               (docker (request-config seen-request)))
          (check-equal? (adapter-result-status result) 'completed)
          (check-equal? (adapter-result-value result) 15)
          (check-equal? (execution-request-kind seen-request) 'docker)
          (check-equal? (cdr (assoc 'image docker)) "gcc:9.3.0")
          (check-equal? (cdr (assoc 'command docker)) "gcc")
          (check-equal? (cdr (assoc 'output-policy docker)) 'process-handle))))
    (test-case "captures ExternalConfig-style rendered arguments"
      (let (seen-request #f)
        (let* ((source (list (cons 'env
                                   (list (cons 'SECOND_GREETING "I'm from an env var!")))
                             (cons 'file
                                   (list (cons 'ourMessage "Hello from the flow.yaml")))))
               (arguments (list (make-config-argument 'file 'ourMessage #f)
                                (make-config-argument 'env 'SECOND_GREETING #f)
                                (make-config-argument 'placeholder 'par3 #f)))
               (rendered (render-config-arguments source arguments))
               (command (lambda (envelope)
                          (set! seen-request (cdr (assoc 'request envelope)))
                          (runtime-result "Hello from the flow.yaml I'm from an env var! hello-from-placeholder"
                                          '(artifact external-config-output))))
               (config (make-docker-run-config
                        (list (cons 'runtime-command command))))
               (flow (docker-flow 'configured-echo
                                  "alpine:latest"
                                  "echo"
                                  rendered
                                  '()
                                  'empty-store-item
                                  'unit
                                  'artifact))
               (result (run-result-value
                        (run-flow-with-config config flow #!void)))
               (docker (request-config seen-request)))
          (check-equal? (adapter-result-status result) 'completed)
          (check-equal? (adapter-result-value result)
                        "Hello from the flow.yaml I'm from an env var! hello-from-placeholder")
          (check-equal? (cdr (assoc 'image docker)) "alpine:latest")
          (check-equal? (cdr (assoc 'command docker)) "echo")
          (check-equal? (cdr (assoc 'args docker))
                        '("Hello from the flow.yaml"
                          "I'm from an env var!"
                          ((placeholder . par3)))))))))

(run-tests! docker-descriptor-test)
