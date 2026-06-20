;;; -*- Gerbil -*-
;;; Boundary: Marlin interface tests cover backend dispatch envelopes.
;;; Invariant: tests do not execute nono, Cube, or Marlin runtime code.

(import (only-in :std/test
                 check
                 check-eq?
                 check-equal?
                 check-false
                 check-not-equal?
                 check-output
                 check-true
                 run-tests!
                 test-case
                 test-error
                 test-suite)
        :poo-flow/src/core/api
        :poo-flow/src/modules/agent-sandbox/api
        :poo-flow/src/modules/agent-sandbox/cube
        :poo-flow/src/modules/agent-sandbox/nono
        :poo-flow/src/modules/nono-sandbox/c-binding)

(export agent-sandbox-marlin-interface-test)

;; : (-> Alist Symbol Value)
(def (test-ref alist key)
  (cdr (assoc key alist)))

;;; This suite keeps Marlin handoff contracts executable without requiring the
;;; Rust runtime to run in unit tests.
(def agent-sandbox-marlin-interface-test
  (test-suite "agent sandbox Marlin interface"
    (test-case "dispatches nono requests to C binding handoff manifests"
      (let* ((request (agent-sandbox-request
                       (make-nono-agent-sandbox-profile
                        'always-further/opencode)
                       (command "opencode")
                       (args '("--print" "hello"))
                       (workdir "/workspace")
                       (mounts '(((path . "/workspace")
                                  (mode . read-write))))
                       (network-policy '((mode . proxy-only)))
                       (output-policy 'artifact)
                       (metadata '((purpose . marlin-nono)))))
             (manifest
              (agent-sandbox-request->marlin-interface-manifest request))
             (handoff (test-ref manifest 'handoff)))
        (check-equal? (test-ref manifest 'schema)
                      +agent-sandbox-marlin-interface-schema+)
        (check-equal? (test-ref manifest 'backend-kind) 'nono)
        (check-equal? (test-ref manifest 'handoff-kind) 'nono-c-binding)
        (check-equal? (test-ref manifest 'handoff-schema)
                      +nono-c-binding-schema+)
        (check-equal? (test-ref handoff 'schema) +nono-c-binding-schema+)
        (check-equal? (test-ref (car (test-ref handoff 'capability-plan))
                                'function)
                      'nono_capability_set_new)))
    (test-case "dispatches Cube requests to lifecycle handoff manifests"
      (let* ((request (agent-sandbox-request
                       (make-cube-agent-sandbox-profile 'python-template)
                       (command "python")
                       (args '("-c" "print('cube')"))
                       (workdir "/workspace")
                       (mounts '(((path . "/workspace")
                                  (mode . read-write))))
                       (network-policy '((mode . egress-filtered)))
                       (resource-policy '((snapshot . clone)
                                          (resume . supported)))
                       (output-policy 'artifact)
                       (metadata '((purpose . marlin-cube)))))
             (manifest
              (agent-sandbox-request->marlin-interface-manifest request))
             (handoff (test-ref manifest 'handoff))
             (lifecycle (test-ref handoff 'lifecycle-plan)))
        (check-equal? (test-ref manifest 'backend-kind) 'cube)
        (check-equal? (test-ref manifest 'handoff-kind) 'cube-interface)
        (check-equal? (test-ref manifest 'handoff-schema)
                      +cube-interface-schema+)
        (check-equal? (test-ref handoff 'schema) +cube-interface-schema+)
        (check-equal? (test-ref (car lifecycle) 'operation)
                      'cube.template.resolve)
        (check-equal? (test-ref (list-ref lifecycle 4) 'operation)
                      'cube.process.exec)))
    (test-case "projects execution requests into Marlin admission envelopes"
      (let* ((task (make-profiled-agent-sandbox-task
                    'marlin-cube-admission
                    (make-cube-agent-sandbox-profile 'python-template)
                    "python"
                    '("-c" "print('admit')")
                    '((PYTHONUNBUFFERED . "1"))
                    "/workspace"
                    '(((path . "/workspace")
                       (mode . read-write)))
                    'artifact
                    'unit
                    'artifact
                    '((metadata . ((purpose . marlin-admission))))))
             (request (task-adapter-request
                       task
                       'input
                       'plan-marlin
                       'node-cube
                       '(node-cube)
                       'agent-sandbox-enabled
                       '((tenant . unit-test))))
             (envelope
              (agent-sandbox-execution-request->marlin-admission-envelope
               request
               'execute))
             (runtime-manifest (test-ref envelope 'runtime-manifest))
             (marlin-interface (test-ref envelope 'marlin-interface))
             (handoff (test-ref envelope 'handoff)))
        (check-equal? (agent-sandbox-marlin-admission-envelope-validation-errors
                       envelope)
                      '())
        (check-equal? (test-ref envelope 'schema)
                      +agent-sandbox-marlin-admission-schema+)
        (check-equal? (test-ref envelope 'runtime-request-schema)
                      +runtime-request-schema+)
        (check-equal? (test-ref envelope 'bridge-schema)
                      +agent-sandbox-bridge-schema+)
        (check-equal? (test-ref envelope 'operation) 'execute)
        (check-equal? (test-ref envelope 'request-id)
                      '(rust-request marlin-cube-admission agent-sandbox))
        (check-equal? (test-ref envelope 'artifact-handle)
                      '(rust-artifact plan-marlin node-cube))
        (check-equal? (test-ref envelope 'plan-id) 'plan-marlin)
        (check-equal? (test-ref envelope 'node-id) 'node-cube)
        (check-equal? (test-ref envelope 'policy)
                      '((tenant . unit-test)))
        (check-equal? (test-ref envelope 'backend-kind) 'cube)
        (check-equal? (test-ref envelope 'backend-ref) 'python-template)
        (check-equal? (test-ref envelope 'handoff-kind) 'cube-interface)
        (check-equal? (test-ref envelope 'handoff-schema)
                      +cube-interface-schema+)
        (check-equal? (test-ref runtime-manifest 'schema)
                      +agent-sandbox-runtime-manifest-schema+)
        (check-equal? (test-ref marlin-interface 'handoff) handoff)
        (check-equal? (test-ref handoff 'schema) +cube-interface-schema+)))
    (test-case "rejects invalid Marlin admission envelopes"
      (let (failure
            (with-catch (lambda (failure) failure)
                        (lambda ()
                          (agent-sandbox-marlin-validate-admission-envelope
                           '((schema . wrong))))))
        (check-equal? (execution-failure? failure) #t)
        (check-equal? (execution-failure-code failure)
                      'invalid-agent-sandbox-marlin-admission-envelope)))
    (test-case "rejects unsupported Marlin backend dispatch"
      (let* ((runtime-manifest
              (list (cons 'schema +agent-sandbox-runtime-manifest-schema+)
                    (cons 'backend
                          '((kind . docker)
                            (ref . docker-template)))
                    (cons 'process
                          '((command . "sh")
                            (args . ("-c" "true"))
                            (argv . ("sh" "-c" "true"))))
                    (cons 'filesystem '((mounts . ())))
                    (cons 'network-policy '())
                    (cons 'capabilities '())
                    (cons 'resource-policy '())
                    (cons 'metadata '())))
             (failure
              (with-catch (lambda (failure) failure)
                          (lambda ()
                            (agent-sandbox-runtime-manifest->marlin-interface-manifest
                             runtime-manifest)))))
        (check-equal? (execution-failure? failure) #t)
        (check-equal? (execution-failure-code failure)
                      'invalid-agent-sandbox-marlin-interface-manifest)))))

(run-tests! agent-sandbox-marlin-interface-test)
