;;; -*- Gerbil -*-
;;; Boundary: Build API fail-closed process RSS and elapsed-time guard.

(export #t)

(import :gerbil/gambit
        :clan/poo/object
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-trim-both string-tokenize)
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

(def (guard-process-row line)
  (let (tokens (string-tokenize line))
    (and (= (length tokens) 3)
         (let ((pid (string->number (car tokens)))
               (ppid (string->number (cadr tokens)))
               (rss-kib (string->number (caddr tokens))))
           (and pid ppid rss-kib
                (list pid ppid (* rss-kib 1024)))))))

(def (guard-process-table)
  (let (result
        (guard-run-captured (list "ps" "-axo" "pid=,ppid=,rss=")))
    (if (= (car result) 0)
      (let lp ((lines (string-split (cdr result) #\newline))
               (rows '()))
        (if (null? lines)
          (reverse rows)
          (let (row (guard-process-row (car lines)))
            (lp (cdr lines) (if row (cons row rows) rows)))))
      '())))

(def (guard-process-tree-pids root-pid rows)
  (let expand ((known (list root-pid)))
    (let lp ((rest rows) (next known) (changed? #f))
      (if (null? rest)
        (if changed? (expand next) next)
        (let* ((row (car rest))
               (pid (car row))
               (ppid (cadr row)))
          (if (and (member ppid next) (not (member pid next)))
            (lp (cdr rest) (cons pid next) #t)
            (lp (cdr rest) next changed?)))))))

(def (guard-process-rss-bytes pid)
  (let* ((rows (guard-process-table))
         (tree-pids (guard-process-tree-pids pid rows)))
    (let lp ((rest rows) (total 0))
      (if (null? rest)
        total
        (let (row (car rest))
          (lp (cdr rest)
              (if (member (car row) tree-pids)
                (+ total (caddr row))
                total)))))))

(def (guard-terminate! pid)
  (let (tree-pids
        (guard-process-tree-pids pid (guard-process-table)))
    (for-each
     (lambda (tree-pid)
       (guard-run-captured
        (list "kill" "-TERM" (number->string tree-pid))))
     tree-pids)
    (thread-sleep! 0.05)
    (for-each
     (lambda (tree-pid)
       (guard-run-captured
        (list "kill" "-KILL" (number->string tree-pid))))
     tree-pids)))

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

(def (poo-flow-current-process-memory-bytes)
  (let (statistics (##process-statistics))
    (inexact->exact
     (ceiling
      (max (f64vector-ref statistics 7)
           (f64vector-ref statistics 15))))))

(def (poo-flow-current-process-memory-guard-emit! receipt)
  (display "POO_FLOW_BUILD_GUARD_RECEIPT " (current-error-port))
  (write (poo-flow-process-memory-guard-receipt->alist receipt)
         (current-error-port))
  (newline (current-error-port))
  (force-output (current-error-port)))

(def (poo-flow-current-process-memory-guard-start!
      label max-rss-bytes timeout-seconds . maybe-sample-seconds)
  (unless (and (> max-rss-bytes 0) (> timeout-seconds 0))
    (error "current process memory guard requires positive limits"))
  (let* ((sample-seconds
          (if (pair? maybe-sample-seconds)
            (car maybe-sample-seconds)
            0.05))
         (started (guard-now-seconds))
         (state (vector #f 0 'running started))
         (watcher
          (spawn
           (lambda ()
             (let loop ()
               (unless (vector-ref state 0)
                 (let* ((rss (poo-flow-current-process-memory-bytes))
                        (elapsed (- (guard-now-seconds) started))
                        (peak (max (vector-ref state 1) rss)))
                   (vector-set! state 1 peak)
                   (cond
                    ((> peak max-rss-bytes)
                     (vector-set! state 2 'rss-limit-exceeded)
                     (poo-flow-current-process-memory-guard-emit!
                      (guard-receipt
                       label 'rss-limit-exceeded 70 70 peak max-rss-bytes
                       (inexact->exact (round (* elapsed 1000)))
                       (inexact->exact (round (* timeout-seconds 1000)))))
                     (exit 70))
                    ((> elapsed timeout-seconds)
                     (vector-set! state 2 'timeout)
                     (poo-flow-current-process-memory-guard-emit!
                      (guard-receipt
                       label 'timeout 71 71 peak max-rss-bytes
                       (inexact->exact (round (* elapsed 1000)))
                       (inexact->exact (round (* timeout-seconds 1000)))))
                     (exit 71))
                    (else
                     (thread-sleep! sample-seconds)
                     (loop))))))))))
    (object<-alist
     (list (cons 'kind 'poo-flow.current-process-memory-guard.v1)
           (cons 'schema 'poo-flow.current-process-memory-guard.v1)
           (cons 'label label)
           (cons 'max-rss-bytes max-rss-bytes)
           (cons 'timeout-seconds timeout-seconds)
           (cons 'state state)
           (cons 'watcher watcher)))))

(def (poo-flow-current-process-memory-guard-stop! guard)
  (let* ((state (.ref guard 'state))
         (watcher (.ref guard 'watcher))
         (started (vector-ref state 3)))
    (vector-set! state 0 #t)
    (thread-join! watcher)
    (let (receipt
          (guard-receipt
           (.ref guard 'label)
           'completed
           0
           0
           (vector-ref state 1)
           (.ref guard 'max-rss-bytes)
           (inexact->exact
            (round (* 1000 (- (guard-now-seconds) started))))
           (inexact->exact
            (round (* 1000 (.ref guard 'timeout-seconds))))))
      (poo-flow-current-process-memory-guard-emit! receipt)
      receipt)))

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
