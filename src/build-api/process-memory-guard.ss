;;; -*- Gerbil -*-
;;; Boundary: Build API fail-closed process RSS and elapsed-time guard.

(export #t)

(import :gerbil/gambit
        :clan/poo/object
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-trim-both)
        )

(def +poo-flow-process-memory-guard-schema+
  'poo-flow.process-memory-guard.v1)

(def (guard-now-seconds)
  (time->seconds (current-time)))

(def (guard-exit-code status)
  (cond ((< status 0) 1)
        ((> status 255) (quotient status 256))
        (else status)))

(def (guard-run-captured argv)
  (let (status 0)
    (let (output
          (run-process argv stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status exit-status))))
      (cons (guard-exit-code status) output))))

(def (guard-process-rss-bytes pid)
  (let* ((result (guard-run-captured
                  (list "ps" "-o" "rss=" "-p" (number->string pid))))
         (text (string-trim-both (cdr result)))
         (kib (and (= (car result) 0)
                   (not (string=? text ""))
                   (string->number text))))
    (if kib (* kib 1024) 0)))

(def (guard-terminate! pid)
  (guard-run-captured
   (list "kill" "-TERM" (number->string pid))))

(def (guard-receipt label outcome exit-code child-exit peak-rss max-rss
                    elapsed-ms timeout-ms)
  (object<-alist
   (list (cons 'kind +poo-flow-process-memory-guard-schema+)
         (cons 'schema +poo-flow-process-memory-guard-schema+)
         (cons 'label label)
         (cons 'outcome outcome)
         (cons 'exit-code exit-code)
         (cons 'child-exit-code child-exit)
         (cons 'peak-rss-bytes peak-rss)
         (cons 'max-rss-bytes max-rss)
         (cons 'elapsed-ms elapsed-ms)
         (cons 'timeout-ms timeout-ms))))

(def (poo-flow-process-memory-guard-receipt->alist receipt)
  (map (lambda (slot) (cons slot (.ref receipt slot)))
       '(schema label outcome exit-code child-exit-code peak-rss-bytes
                max-rss-bytes elapsed-ms timeout-ms)))

(def (poo-flow-process-memory-guard-run label max-rss-bytes timeout-seconds argv
                                        . maybe-sample-seconds)
  (unless (and (pair? argv) (> max-rss-bytes 0) (> timeout-seconds 0))
    (error "process memory guard requires command and positive limits"))
  (let* ((sample-seconds (if (pair? maybe-sample-seconds)
                           (car maybe-sample-seconds) 0.05))
         (started (guard-now-seconds))
         (child (open-process
                 (list path: (car argv)
                       arguments: (cdr argv)
                       stdin-redirection: #f
                       stdout-redirection: #f
                       stderr-redirection: #f)))
         (pid (process-pid child))
         (state (vector #f #f))
         (waiter
          (spawn
           (lambda ()
             (vector-set! state 1
                          (guard-exit-code (process-status child)))
             (vector-set! state 0 #t))))
         (peak-rss 0)
         (outcome 'running)
         (guard-exit 0))
    (let loop ()
      (unless (vector-ref state 0)
        (let* ((rss (guard-process-rss-bytes pid))
               (elapsed (- (guard-now-seconds) started)))
          (set! peak-rss (max peak-rss rss))
          (cond
           ((> peak-rss max-rss-bytes)
            (set! outcome 'rss-limit-exceeded)
            (set! guard-exit 70)
            (guard-terminate! pid))
           ((> elapsed timeout-seconds)
            (set! outcome 'timeout)
            (set! guard-exit 71)
            (guard-terminate! pid))
           (else
            (thread-sleep! sample-seconds)
            (loop))))))
    (thread-join! waiter)
    (let* ((child-exit (vector-ref state 1))
           (final-outcome (if (eq? outcome 'running) 'completed outcome))
           (final-exit (if (eq? outcome 'running) child-exit guard-exit))
           (elapsed-ms
            (inexact->exact
             (round (* 1000 (- (guard-now-seconds) started))))))
      (guard-receipt label final-outcome final-exit child-exit peak-rss
                     max-rss-bytes elapsed-ms
                     (inexact->exact (round (* timeout-seconds 1000)))))))
