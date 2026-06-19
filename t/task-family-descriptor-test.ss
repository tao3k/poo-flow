;;; -*- Gerbil -*-
;;; Boundary: task-family descriptor tests stay separate from flow execution.

(import :std/test
        :core/api
        :workflow/store)

(def task-family-descriptor-test
  (test-suite "task family descriptors"
    (test-case "declares POO-backed task family policy"
      (check-equal? (task-family-descriptor? pure-task-family-descriptor) #t)
      (check-equal? (role-object? store-task-family-descriptor) #t)
      (check-equal? (task-family-name scheme-task-family-descriptor) 'scheme)
      (check-equal? (task-family-capability store-task-family-descriptor) 'store)
      (check-equal? (task-family-route pure-task-family-descriptor) 'local)
      (check-equal? (task-family-route external-task-family-descriptor) 'adapter)
      (check-equal? (task-family-runtime-owner store-task-family-descriptor)
                    'rust-or-external-runtime)
      (check-equal? (task-family-adapter-dispatch external-task-family-descriptor)
                    'submit))
    (test-case "routes tasks through descriptor policy"
      (let ((registry (make-store-task-family-registry))
            (pure (make-pure-task 'inc (lambda (x) (+ x 1)) 'number 'number))
            (put (make-store-task 'put-cache 'put 'cache-handle 'artifact 'artifact))
            (get (make-store-task 'get-cache 'get 'cache-handle 'artifact 'artifact))
            (external (make-external-task 'compile 'rust-build '((crate . "poo-flow")) 'artifact 'artifact)))
        (check-equal? (task-family-name (task-descriptor pure)) 'pure)
        (check-equal? (task-capability-in registry put) 'store)
        (check-equal? (task-route pure) 'local)
        (check-equal? (task-route external) 'adapter)
        (check-equal? (task-runtime-owner external) 'rust-or-external-runtime)
        (check-equal? (task-adapter-operation-in registry put) 'store-put)
        (check-equal? (task-adapter-operation-in registry get) 'store-get)
        (check-equal? (task-adapter-operation external) 'submit)))))

(run-tests! task-family-descriptor-test)
