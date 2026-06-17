;;; -*- Gerbil -*-
;;; Boundary: descriptor registries are policy extension surfaces.

(import :std/test
        :core/api)

(def descriptor-registry-test
  (test-suite "descriptor registries"
    (test-case "extends task family descriptors without editing defaults"
      (let* ((docker (make-task-family-descriptor 'docker
                                                  'docker
                                                  'adapter
                                                  'rust-or-external-runtime
                                                  'submit))
             (registry (task-family-registry-extend
                        default-task-family-registry
                        docker))
             (task (make-task 'build
                              'docker
                              '(docker build)
                              'artifact
                              'artifact
                              #f)))
        (check-equal? (task-family-registry? registry) #t)
        (check-equal? (task-family-name
                       (task-family-for-kind-in registry 'docker))
                      'docker)
        (check-equal? (task-route-in registry task) 'adapter)
        (check-equal? (task-runtime-owner-in registry task)
                      'rust-or-external-runtime)
        (check-equal? (task-adapter-operation-in registry task) 'submit)
        (check-equal? (length task-family-descriptors) 4)))
    (test-case "extends flow declarations without editing defaults"
      (let* ((remote (make-flow-declaration-descriptor 'remote-flow
                                                       'remote
                                                       'linear-dag
                                                       'extension))
             (registry (flow-declaration-registry-extend
                        default-flow-declaration-registry
                        remote))
             (inc (pure-flow 'inc (lambda (x) (+ x 1)) 'number 'number))
             (planner (strategy-planner-for-flow-in
                       (make-local-eager-strategy)
                       registry
                       inc))
             (plan (planner inc)))
        (check-equal? (flow-declaration-registry? registry) #t)
        (check-equal? (flow-declaration-name
                       (flow-declaration-for-kind-in registry 'remote))
                      'remote-flow)
        (check-equal? (flow-declaration-kind
                       (flow-declaration-descriptor-in registry inc))
                      'task)
        (check-equal? (execution-plan-node-ids plan)
                      '((node inc 0 pure inc)))
        (check-equal? (length flow-declaration-descriptors) 4)))))

(run-tests! descriptor-registry-test)
