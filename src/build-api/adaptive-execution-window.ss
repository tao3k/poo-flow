;;; -*- Gerbil -*-
;;; Boundary: POO-native adaptive std/make execution-window policy.

(export make-poo-flow-adaptive-execution-window-controller
        poo-flow-adaptive-execution-window-controller?
        poo-flow-adaptive-execution-window-controller-next-state/with-current-rss)

(import :gerbil/gambit
        (only-in :clan/poo/object object<-alist .has? .ref)
        (only-in :gslph/src/building/std-builder
                 execution-window-controller?
                 execution-window-controller-hard-max-rss-bytes
                 execution-window-controller-headroom-bytes
                 execution-window-controller-window-size
                 execution-window-controller-worker-count
                 execution-window-observation-baseline-rss-bytes
                 execution-window-observation-elapsed-ms
                 execution-window-observation-max-rss-bytes
                 execution-window-observation-outcome
                 execution-window-observation-peak-rss-bytes
                 execution-window-observation?
                 make-execution-window-observation)
        "./process-memory-guard.ss")

(def (poo-flow-adaptive-positive-integer value label)
  (unless (and (exact-integer? value) (> value 0))
    (error "adaptive execution-window value must be positive" label value))
  value)

(def (poo-flow-adaptive-nonnegative-integer value label)
  (unless (and (exact-integer? value) (>= value 0))
    (error "adaptive execution-window value must be nonnegative" label value))
  value)

(def (poo-flow-adaptive-observation-completed? observation)
  (memq (execution-window-observation-outcome observation)
        '(completed ok)))

(def (poo-flow-adaptive-ceiling-quotient numerator denominator)
  (quotient (+ numerator denominator -1) denominator))

(def (poo-flow-adaptive-estimated-bytes-per-spec observation spec-count)
  (poo-flow-adaptive-positive-integer spec-count 'spec-count)
  (let (observed-growth
        (max 0
             (- (execution-window-observation-peak-rss-bytes observation)
                (execution-window-observation-baseline-rss-bytes
                 observation))))
    (max 1
         (poo-flow-adaptive-ceiling-quotient
          observed-growth
          spec-count))))

(def (poo-flow-adaptive-next-window-size
      controller estimated-bytes-per-spec current-rss-bytes)
  (let* ((hard-max-rss-bytes
          (execution-window-controller-hard-max-rss-bytes controller))
         (headroom-bytes
          (execution-window-controller-headroom-bytes controller))
         (worker-count
          (execution-window-controller-worker-count controller))
         (current-window-size
          (execution-window-controller-window-size controller))
         (available-bytes
          (max 0
               (- hard-max-rss-bytes
                  current-rss-bytes
                  headroom-bytes)))
         (capacity
          (max 1 (quotient available-bytes estimated-bytes-per-spec)))
         (growth-limit (+ current-window-size worker-count)))
    (max 1 (min capacity growth-limit))))

(def (poo-flow-adaptive-execution-window-controller?
      controller)
  (and (execution-window-controller? controller)
       (.has? controller owner)
       (eq? (.ref controller 'owner)
            'poo-flow.adaptive-execution-window.v1)))

(def (make-poo-flow-adaptive-execution-window-controller/state
      worker-count
      hard-max-rss-bytes
      headroom-bytes
      window-size
      baseline-rss-bytes
      last-estimated-bytes-per-spec
      window-index)
  (poo-flow-adaptive-positive-integer worker-count 'worker-count)
  (poo-flow-adaptive-positive-integer hard-max-rss-bytes
                                      'hard-max-rss-bytes)
  (poo-flow-adaptive-nonnegative-integer headroom-bytes 'headroom-bytes)
  (poo-flow-adaptive-positive-integer window-size 'window-size)
  (poo-flow-adaptive-nonnegative-integer baseline-rss-bytes
                                         'baseline-rss-bytes)
  (unless (> hard-max-rss-bytes
             (+ baseline-rss-bytes headroom-bytes))
    (error
     "adaptive RSS cap must exceed baseline plus caller headroom"
     `((hard-max-rss-bytes . ,hard-max-rss-bytes)
       (baseline-rss-bytes . ,baseline-rss-bytes)
       (headroom-bytes . ,headroom-bytes))))
  (when last-estimated-bytes-per-spec
    (poo-flow-adaptive-positive-integer last-estimated-bytes-per-spec
                                        'last-estimated-bytes-per-spec))
  (poo-flow-adaptive-nonnegative-integer window-index 'window-index)
  (letrec
      ((controller
        (object<-alist
         `((kind . gslph.execution-window-controller.v1)
           (owner . poo-flow.adaptive-execution-window.v1)
           (worker-count . ,worker-count)
           (hard-max-rss-bytes . ,hard-max-rss-bytes)
           (headroom-bytes . ,headroom-bytes)
           (window-size . ,window-size)
           (baseline-rss-bytes . ,baseline-rss-bytes)
           (last-estimated-bytes-per-spec .
                                          ,last-estimated-bytes-per-spec)
           (window-index . ,window-index)
           (.observe-run! .
            ,(lambda (label thunk)
               (poo-flow-adaptive-execution-window-observe-run!
                controller label thunk)))
           (.next-state .
            ,(lambda (observation spec-count)
               (poo-flow-adaptive-execution-window-controller-next-state/with-current-rss
                controller
                observation
                spec-count
                (poo-flow-current-process-memory-bytes))))))))
    controller))

(def (make-poo-flow-adaptive-execution-window-controller
      worker-count hard-max-rss-bytes headroom-bytes)
  (make-poo-flow-adaptive-execution-window-controller/state
   worker-count
   hard-max-rss-bytes
   headroom-bytes
   worker-count
   (poo-flow-current-process-memory-bytes)
   #f
   0))

(def (poo-flow-adaptive-execution-window-observe-run!
      controller label thunk)
  (let* ((baseline-rss-bytes
          (poo-flow-current-process-memory-bytes))
         (hard-max-rss-bytes
          (execution-window-controller-hard-max-rss-bytes controller))
         (guard
          (poo-flow-current-process-memory-guard-start!
           label hard-max-rss-bytes #f))
         (stopped? #f)
         (guard-receipt #f))
    (letrec
        ((stop!
          (lambda ()
            (unless stopped?
              (set! guard-receipt
                    (poo-flow-current-process-memory-guard-stop! guard))
              (set! stopped? #t))
            guard-receipt)))
      (dynamic-wind
        (lambda () #!void)
        (lambda ()
          (let* ((result (thunk))
                 (receipt (stop!))
                 (peak-rss-bytes
                  (max baseline-rss-bytes
                       (.ref receipt 'peak-rss-bytes))))
            (make-execution-window-observation
             result
             (.ref receipt 'outcome)
             baseline-rss-bytes
             peak-rss-bytes
             (.ref receipt 'max-rss-bytes)
             (.ref receipt 'elapsed-ms))))
        (lambda () (stop!))))))

(def (poo-flow-adaptive-execution-window-controller-next-state/with-current-rss
      controller observation spec-count current-rss-bytes)
  (unless (poo-flow-adaptive-execution-window-controller? controller)
    (error "invalid POO Flow adaptive execution-window controller"
           controller))
  (unless (poo-flow-adaptive-observation-completed? observation)
    (error "adaptive execution-window observation failed closed"
           (execution-window-observation-outcome observation)))
  (unless (= (execution-window-observation-max-rss-bytes observation)
             (execution-window-controller-hard-max-rss-bytes controller))
    (error "adaptive observation hard RSS cap changed" observation))
  (poo-flow-adaptive-nonnegative-integer current-rss-bytes
                                         'current-rss-bytes)
  (let* ((estimated-bytes-per-spec
          (poo-flow-adaptive-estimated-bytes-per-spec
           observation spec-count))
         (next-window-size
          (poo-flow-adaptive-next-window-size
           controller estimated-bytes-per-spec current-rss-bytes)))
    (make-poo-flow-adaptive-execution-window-controller/state
     (execution-window-controller-worker-count controller)
     (execution-window-controller-hard-max-rss-bytes controller)
     (execution-window-controller-headroom-bytes controller)
     next-window-size
     current-rss-bytes
     estimated-bytes-per-spec
     (+ 1 (.ref controller 'window-index)))))
