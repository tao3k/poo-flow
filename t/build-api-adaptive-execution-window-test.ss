(import :std/test
        :std/text/json
        (only-in :std/misc/path path-normalize)
        (only-in :clan/poo/object .ref)
        (only-in :gslph/src/building/facade
                 package-source-stage-batched?)
        (only-in :gslph/src/building/std-builder
                 execution-window-controller-next-state
                 execution-window-controller-window-size
                 make-execution-window-observation)
        "../src/build-api/adaptive-execution-window.ss"
        "../src/build-api/process-memory-guard.ss"
        "../src/cli-support/project-build.ss")

(def +test-gibibyte+ (* 1024 1024 1024))
(def +test-mebibyte+ (* 1024 1024))
(def +test-hard-max-rss-bytes+ (* 8 +test-gibibyte+))
(def +test-headroom-bytes+ +test-gibibyte+)

(def (test-observation outcome baseline peak (elapsed-ms 10))
  (make-execution-window-observation
   'test-result
   outcome
   baseline
   peak
   +test-hard-max-rss-bytes+
   elapsed-ms))

(def build-api-adaptive-execution-window-test
  (test-suite "POO Flow adaptive execution windows"
    (test-case "high startup window shrinks to measured capacity"
      (let* ((controller
              (make-poo-flow-adaptive-execution-window-controller
               4 +test-hard-max-rss-bytes+ +test-headroom-bytes+))
             (shrunk
              (poo-flow-adaptive-execution-window-controller-next-state/with-current-rss
               controller
               (test-observation
                'completed 1000 (+ 1000 (* 4 +test-gibibyte+)))
               4
               (* 4 +test-gibibyte+))))
        (check (execution-window-controller-window-size controller) => 4)
        (check (execution-window-controller-window-size shrunk) => 3)
        (check (.ref shrunk 'last-estimated-bytes-per-spec)
               => +test-gibibyte+)
        (check (.ref shrunk 'baseline-rss-bytes)
               => (* 4 +test-gibibyte+))
        (check (.ref shrunk 'window-index) => 1)))

    (test-case "small low-transient window recovers by one worker quantum"
      (let* ((controller
              (make-poo-flow-adaptive-execution-window-controller
               4 +test-hard-max-rss-bytes+ +test-headroom-bytes+))
             (shrunk
              (poo-flow-adaptive-execution-window-controller-next-state/with-current-rss
               controller
               (test-observation
                'completed 1000 (+ 1000 (* 4 +test-gibibyte+)))
               4
               (* 4 +test-gibibyte+)))
             (recovered
              (poo-flow-adaptive-execution-window-controller-next-state/with-current-rss
               shrunk
               (test-observation
                'completed
                (* 4 +test-gibibyte+)
                (+ (* 4 +test-gibibyte+) (* 300 +test-mebibyte+)))
               3
               +test-gibibyte+)))
        (check (execution-window-controller-window-size shrunk) => 3)
        (check (execution-window-controller-window-size recovered) => 7)
        (check (- (execution-window-controller-window-size recovered)
                  (execution-window-controller-window-size shrunk))
               => 4)
        (check (.ref recovered 'last-estimated-bytes-per-spec)
               => (* 100 +test-mebibyte+))
        (check (.ref recovered 'window-index) => 2)))

    (test-case "safe large windows grow geometrically"
      (let* ((controller
              (make-poo-flow-adaptive-execution-window-controller
               4 +test-hard-max-rss-bytes+ +test-headroom-bytes+))
             (first-growth
              (poo-flow-adaptive-execution-window-controller-next-state/with-current-rss
               controller
               (test-observation
                'completed
                +test-gibibyte+
                (+ +test-gibibyte+ (* 4 +test-mebibyte+)))
               4
               +test-gibibyte+))
             (second-growth
              (poo-flow-adaptive-execution-window-controller-next-state/with-current-rss
               first-growth
               (test-observation
                'completed
                +test-gibibyte+
                (+ +test-gibibyte+ (* 8 +test-mebibyte+)))
               8
               +test-gibibyte+)))
        (check (execution-window-controller-window-size first-growth) => 8)
        (check (execution-window-controller-window-size second-growth) => 16)
        (check (.ref second-growth 'last-estimated-bytes-per-spec)
               => +test-mebibyte+)
        (check (.ref second-growth 'window-index) => 2)))

    (test-case "safe 377-spec growth needs logarithmic decisions"
      (let loop
          ((controller
            (make-poo-flow-adaptive-execution-window-controller
             4 +test-hard-max-rss-bytes+ +test-headroom-bytes+))
           (remaining 377)
           (decision-count 0))
        (if (= remaining 0)
          (check decision-count => 7)
          (let* ((window-size
                  (min remaining
                       (execution-window-controller-window-size controller)))
                 (next-controller
                  (poo-flow-adaptive-execution-window-controller-next-state/with-current-rss
                   controller
                   (test-observation
                    'completed
                    +test-gibibyte+
                    (+ +test-gibibyte+
                       (* window-size +test-mebibyte+)))
                   window-size
                   +test-gibibyte+)))
            (loop next-controller
                  (- remaining window-size)
                  (+ decision-count 1))))))

    (test-case "constructor rejects cap below live baseline plus headroom"
      (let (blocked?
            (with-catch
             (lambda (_exception) #t)
             (lambda ()
               (make-poo-flow-adaptive-execution-window-controller 1 1 0)
               #f)))
        (check blocked? => #t)))

    (test-case "non-completed observation fails closed"
      (let* ((controller
              (make-poo-flow-adaptive-execution-window-controller
               4 +test-hard-max-rss-bytes+ +test-headroom-bytes+))
             (blocked?
              (with-catch
               (lambda (_exception) #t)
               (lambda ()
                 (execution-window-controller-next-state
                  controller
                  (test-observation
                   'rss-limit-exceeded 1000
                   (+ +test-hard-max-rss-bytes+ 1))
                  1)
                 #f))))
        (check blocked? => #t)))

    (test-case "process guard receipt is canonical native Scheme JSON"
      (let* ((guard
              (poo-flow-current-process-memory-guard-start!
               'adaptive-json-test (* 8 1024 1024 1024) #f 0.001))
             (receipt
              (poo-flow-current-process-memory-guard-stop! guard))
             (json-string
              (poo-flow-process-memory-guard-receipt->json-string receipt))
             (object (string->json-object json-string)))
        (check (hash-get object "schema")
               => "poo-flow.process-memory-guard.v1")
        (check (hash-get object "kind")
               => "poo-flow.process-memory-guard.v1")
        (check (hash-get object "version") => 1)
        (check (hash-get object "outcome") => "completed")
        (check
         (parameterize ((write-json-sort-keys? #t))
           (json-object->string object))
         => json-string)))

    (test-case "explicit POO controller activates runtime and UI stages"
      (poo-flow-project-configure-build-root! ".")
      (let* ((controller
              (make-poo-flow-adaptive-execution-window-controller
               2 (* 8 1024 1024 1024) (* 128 1024 1024)))
             (default-stages (poo-flow-project-source-stages #f))
             (stages (poo-flow-project-source-stages #f controller)))
        (check (poo-flow-project-adaptive-cold-gate-available? controller)
               => #t)
        (check (length stages) => 2)
        (check
         (andmap
          (lambda (stage)
            (eq? (package-source-stage-batched? stage) 'topology))
          default-stages)
         => #t)
        (check
         (andmap
          (lambda (stage)
            (eq? (package-source-stage-batched? stage) controller))
         stages)
         => #t)))

    (test-case "configured build root crosses Gerbil module instances"
      (poo-flow-project-configure-build-root! ".")
      (check
       (getenv "POO_FLOW_PROJECT_BUILD_ROOT" #f)
       => (path-normalize ".")))

    (test-case "environment activation accepts zero caller headroom"
      (setenv "POO_FLOW_BUILD_MAX_RSS_BYTES"
              (number->string (* 8 +test-gibibyte+)))
      (setenv "POO_FLOW_BUILD_RSS_HEADROOM_BYTES" "0")
      (let (controller
            (poo-flow/src/cli-support/project-build#poo-flow-project-adaptive-controller-from-env))
        (check (.ref controller 'headroom-bytes) => 0)
        (check (execution-window-controller-window-size controller)
               => (.ref controller 'worker-count))))))

(run-tests! build-api-adaptive-execution-window-test)
