;;; -*- Gerbil -*-
;;; Boundary: tutorial result tests mirror Funflow's local/config outputs.
;;; Invariant: each stage proves a user-visible result, not only an API shape.

(import :std/test
        :poo-flow/src/core/api)

(export tutorial-result-test)

;; : (-> Unit Runner)
(def (tutorial-runner)
  (make-runner (make-local-eager-strategy)
               (make-request-only-adapter)))

;; : (-> Flow Value Value)
(def (tutorial-run flow input)
  (run-result-value (runner-run (tutorial-runner) flow input)))

;; : (-> String Nat String)
(def (repeat-string text count)
  (if (<= count 0)
    ""
    (string-append text (repeat-string text (- count 1)))))

;; : (-> [Symbol] Alist Alist)
(def (count-symbols words counts)
  (if (null? words)
    counts
    (let* ((word (car words))
           (entry (assoc word counts)))
      (count-symbols (cdr words)
                     (if entry
                       (cons (cons word (+ 1 (cdr entry)))
                             (remove-count word counts))
                       (cons (cons word 1) counts))))))

;; : (-> Symbol Alist Alist)
(def (remove-count word counts)
  (cond
   ((null? counts) '())
   ((eq? word (caar counts)) (cdr counts))
   (else (cons (car counts) (remove-count word (cdr counts))))))

;; : (-> Alist Symbol Value)
(def (count-ref counts word)
  (let (entry (assoc word counts))
    (if entry (cdr entry) 0)))

(def tutorial-result-test
  (test-suite "funflow tutorial result ladder"
    (test-case "stage 1 tutorial1 minimal pure flow returns 2"
      (let (flow (pure-flow 'plus-one (lambda (x) (+ x 1)) 'number 'number))
        (check-equal? (tutorial-run flow 1) 2)))
    (test-case "stage 2 quick reference hello and composition results"
      (let* ((hello (pure-flow 'hello
                               (lambda (input)
                                 (string-append "Hello " input " !"))
                               'string
                               'string))
             (flow1 (pure-flow 'literal-hello
                               (lambda (_input) "Hello")
                               'unit
                               'string))
             (flow2 (pure-flow 'append-world
                               (lambda (input)
                                 (string-append input " world"))
                               'string
                               'string))
             (pipeline (flow-then 'hello-world flow1 flow2)))
        (check-equal? (tutorial-run hello "Watson") "Hello Watson !")
        (check-equal? (tutorial-run pipeline #!void) "Hello world")))
    (test-case "stage 3 tutorial2 extension behavior repeats custom text"
      (let* ((custom (scheme-flow 'custom-repeat
                                  (lambda (input)
                                    (string-append input
                                                   (repeat-string "woop!" 7)))
                                  'string
                                  'string))
             (result (tutorial-run custom "Kangaroo goes ")))
        (check-equal? result "Kangaroo goes woop!woop!woop!woop!woop!woop!woop!")))
    (test-case "stage 4 word count exposes deterministic counts"
      (let* ((words '(a and it try words a and it try words a and it try words
                        lets this count give pipeline should lets this count
                        give pipeline should file))
             (count-flow (pure-flow 'count-words
                                    (lambda (input)
                                      (count-symbols input '()))
                                    'words
                                    'counts))
             (counts (tutorial-run count-flow words)))
        (check-equal? (count-ref counts 'a) 3)
        (check-equal? (count-ref counts 'and) 3)
        (check-equal? (count-ref counts 'lets) 2)
        (check-equal? (count-ref counts 'file) 1)))
    (test-case "stage 5 external config fails before runtime submission"
      (let* ((requirement (make-config-requirement 'env 'SECOND_GREETING #t))
             (config (make-run-config
                      'tutorial-missing-config
                      (make-local-eager-strategy)
                      (make-request-only-adapter)
                      (list (cons 'config-requirements (list requirement)))))
             (flow (external-flow 'echo
                                  'docker-echo
                                  '((image . "alpine:latest"))
                                  'unit
                                  'artifact))
             (failure (with-catch (lambda (failure) failure)
                                  (lambda ()
                                    (run-flow-with-config config flow #!void)))))
        (check-equal? (execution-failure? failure) #t)
        (check-equal? (execution-failure-code failure) 'missing-config-keys)))
    (test-case "stage 6 error handling try-flow routes thrown failures"
      (let* ((thrower (throw-string-flow 'throw-local
                                         "handled tutorial failure"
                                         'unit
                                         'string))
             (attempt (try-flow 'try-local thrower))
             (handled
              (flow-map 'handle-local-error
                        attempt
                        (lambda (result)
                          (if (try-left? result)
                            (string-append
                             "handled: "
                             (execution-failure-message
                              (try-result-value result)))
                            "unexpected success"))
                        'string))
             (success
              (try-flow 'try-success
                        (pure-flow 'success
                                   (lambda (value) value)
                                   'string
                                   'string)))
             (success-result (tutorial-run success "ok")))
        (check-equal? (tutorial-run handled #!void)
                      "handled: handled tutorial failure")
        (check-equal? (try-right? success-result) #t)
        (check-equal? (try-result-value success-result) "ok")))
    (test-case "stage 7 configured runtime command returns normalized result"
      (let* ((command (lambda (envelope)
                        (list (cons 'schema +runtime-response-schema+)
                              (cons 'request-id (cdr (assoc 'request-id envelope)))
                              (cons 'status 'completed)
                              (cons 'value "runtime-result")
                              (cons 'artifact-handle '(artifact tutorial))
                              (cons 'error #f)
                              (cons 'metadata '((tutorial . runtime-command))))))
             (config (make-rust-run-config
                      (list (cons 'runtime-command command))))
             (flow (external-flow 'runtime-demo
                                  'submit
                                  '((payload . tutorial))
                                  'unit
                                  'artifact))
             (result (run-result-value
                      (run-flow-with-config config flow #!void))))
        (check-equal? (adapter-result-status result) 'completed)
        (check-equal? (adapter-result-value result) "runtime-result")
        (check-equal? (adapter-result-artifact-handle result)
                      '(artifact tutorial))))))

(run-tests! tutorial-result-test)
