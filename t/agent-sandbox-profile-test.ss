;;; -*- Gerbil -*-
;;; Boundary: agent-sandbox profile tests cover profile descriptors and defaults.
;;; Invariant: backend execution stays outside Scheme tests.

(import :std/test
        :core/api
        :modules/agent-sandbox/api
        :modules/agent-sandbox/nono
        :modules/agent-sandbox/cube)

;; : (-> Value Alist AdapterResult)
(def (runtime-result value artifact)
  (list (cons 'schema +runtime-response-schema+)
        (cons 'request-id '(runtime agent-sandbox-profile-test))
        (cons 'status 'completed)
        (cons 'value value)
        (cons 'artifact-handle artifact)
        (cons 'error #f)
        (cons 'metadata '((runtime . agent-sandbox-profile-test)))))

;; : (-> ExecutionRequest Alist)
(def (request-config request)
  (cadr (execution-request-request request)))

(run-tests!
 (test-suite "agent sandbox profile descriptors"
   (test-case "builds backend profiles for nono and CubeSandbox"
     (let ((nono (make-nono-agent-sandbox-profile 'always-further/opencode))
           (cube (make-cube-agent-sandbox-profile 'python-template)))
       (check-equal? (agent-sandbox-profile-ref nono 'schema #f)
                     +agent-sandbox-profile-schema+)
       (check-equal? (agent-sandbox-profile-backend-kind nono) 'nono)
       (check-equal? (agent-sandbox-profile-backend-ref nono)
                     'always-further/opencode)
       (check-equal? (agent-sandbox-profile-network-policy nono)
                     '((mode . proxy-only)))
       (check-equal? (agent-sandbox-profile-capabilities nono)
                     '((filesystem . scoped)
                       (credentials . injected)))
       (check-equal? (agent-sandbox-profile-backend-kind cube) 'cube)
       (check-equal? (agent-sandbox-profile-network-policy cube)
                     '((mode . egress-filtered)))
       (check-equal? (agent-sandbox-profile-capabilities cube)
                     '((isolation . kvm)
                       (api . e2b-compatible)))
       (check-equal? (agent-sandbox-profile-resource-policy cube)
                     '((snapshot . clone)
                       (resume . supported)))))
   (test-case "uses POO profile descriptors for backend overrides"
     (let* ((cube-descriptor
             (make-cube-agent-sandbox-profile-descriptor 'python-template))
            (override-descriptor
             (make-agent-sandbox-profile-descriptor
              'custom-profile
              'nono
              'base-profile
              '((mode . proxy-only))
              '((filesystem . scoped))
              '((startup . zero-latency))
              '((backend . custom))
              (list (cons 'backend-ref 'override-profile)
                    (cons 'metadata '((backend . override)
                                      (reason . test))))))
            (override-profile
             (agent-sandbox-profile-descriptor->profile override-descriptor)))
       (check-equal? (agent-sandbox-profile-descriptor? cube-descriptor) #t)
       (check-equal? (agent-sandbox-profile-descriptor-name cube-descriptor)
                     'cube-profile)
       (check-equal? (agent-sandbox-profile-descriptor-backend-kind
                      cube-descriptor)
                     'cube)
       (check-equal? (agent-sandbox-profile-backend-ref override-profile)
                     'override-profile)
       (check-equal? (agent-sandbox-profile-metadata override-profile)
                     '((backend . override)
                       (reason . test)))))
   (test-case "validates profile and request contracts before runtime"
     (let* ((invalid-profile
             (make-agent-sandbox-backend-profile 'nono #f '() '() '() '()))
            (profile-failure
             (with-catch (lambda (failure) failure)
                         (lambda ()
                           (agent-sandbox-validate-profile invalid-profile))))
            (valid-profile
             (make-agent-sandbox-backend-profile
              'nono
              'local-profile
              '()
              '()
              '()
              '()))
            (request-failure
             (with-catch (lambda (failure) failure)
                         (lambda ()
                           (make-agent-sandbox-request
                            valid-profile
                            #f
                            '()
                            '()
                            #f
                            '()
                            #f
                            #f
                            #f
                            'artifact
                            '())))))
       (check-equal? (execution-failure? profile-failure) #t)
       (check-equal? (execution-failure-code profile-failure)
                     'invalid-agent-sandbox-profile)
       (check-equal? (execution-failure? request-failure) #t)
       (check-equal? (execution-failure-code request-failure)
                     'invalid-agent-sandbox-request)))
   (test-case "builds requests with named-field macro contracts"
     (let* ((profile (make-nono-agent-sandbox-profile
                      'always-further/opencode))
            (request (agent-sandbox-request
                      profile
                      (command "opencode")
                      (args '("--print" "typed"))
                      (env '((OPENAI_API_KEY . redacted)))
                      (workdir "/workspace")
                      (mounts '(((path . ".") (mode . read-write))))
                      (network-policy '((mode . blocked)))
                      (output-policy 'artifact)
                      (metadata '((interface . named-fields)))))
            (field-failure
             (with-catch (lambda (failure) failure)
                         (lambda ()
                           (agent-sandbox-request
                            profile
                            (command "opencode")
                            (typo-field #t))))))
       (check-equal? (agent-sandbox-request? request) #t)
       (check-equal? (agent-sandbox-request-ref request 'command #f)
                     "opencode")
       (check-equal? (agent-sandbox-request-ref request 'args '())
                     '("--print" "typed"))
       (check-equal? (agent-sandbox-request-ref request 'network-policy '())
                     '((mode . blocked)))
       (check-equal? (agent-sandbox-request-ref request 'capabilities '())
                     '((filesystem . scoped)
                       (credentials . injected)))
       (check-equal? (execution-failure? field-failure) #t)
       (check-equal? (execution-failure-code field-failure)
                     'invalid-agent-sandbox-request-fields)))
   (test-case "profiled flow normalizes defaults and task overrides"
     (let (seen-request #f)
       (let* ((profile (make-nono-agent-sandbox-profile
                        'always-further/opencode
                        (list (cons 'resource-policy
                                    '((startup . zero-latency)
                                      (profile-timeout-ms . 120000))))))
              (command (lambda (envelope)
                         (set! seen-request (cdr (assoc 'request envelope)))
                         (runtime-result 'profiled '(artifact profiled-output))))
              (config (make-agent-sandbox-run-config
                       (list (cons 'runtime-command command))))
              (flow (profiled-agent-sandbox-flow
                     'profiled-agent
                     profile
                     "opencode"
                     '("--print" "hello")
                     '()
                     "/workspace"
                     '(((path . ".") (mode . read-write)))
                     'artifact
                     'unit
                     'artifact
                     (list (cons 'network-policy '((mode . blocked)))
                           (cons 'resource-policy '((task-timeout-ms . 30000)))
                           (cons 'metadata '((task . profiled-agent))))))
              (result (run-result-value
                       (run-flow-with-config config flow #!void)))
              (sandbox (request-config seen-request)))
         (check-equal? (adapter-result-status result) 'completed)
         (check-equal? (cdr (assoc 'schema sandbox))
                       +agent-sandbox-request-schema+)
         (check-equal? (cdr (assoc 'backend-kind sandbox)) 'nono)
         (check-equal? (cdr (assoc 'backend-ref sandbox))
                       'always-further/opencode)
         (check-equal? (cdr (assoc 'network-policy sandbox))
                       '((mode . blocked)))
         (check-equal? (cdr (assoc 'capabilities sandbox))
                       '((filesystem . scoped)
                         (credentials . injected)))
         (check-equal? (cdr (assoc 'resource-policy sandbox))
                       '((task-timeout-ms . 30000)
                         (startup . zero-latency)
                         (profile-timeout-ms . 120000)))
         (check-equal? (cdr (assoc 'metadata sandbox))
                       '((task . profiled-agent)
                         (backend . nono)
                         (profile . always-further/opencode))))))))
