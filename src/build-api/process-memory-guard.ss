;;; -*- Gerbil -*-
;;; Boundary: Build API fail-closed process RSS and elapsed-time guard.

(export #t)

(import :gerbil/gambit
        :clan/poo/object
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-trim-both string-tokenize)
        (only-in :std/text/json
                 json-object->string
                 write-json-sort-keys?)
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

(def (guard-smaps-rollup-pss-line-bytes line)
  (let (tokens (string-tokenize line))
    (and (pair? tokens)
         (string=? (car tokens) "Pss:")
         (pair? (cdr tokens))
         (let (kib (string->number (cadr tokens)))
           (and kib (* kib 1024))))))

(def (guard-linux-process-pss-bytes pid)
  (let (path
        (string-append "/proc/" (number->string pid) "/smaps_rollup"))
    (and (file-exists? path)
         (with-catch
          (lambda (_) #f)
          (lambda ()
            (let (port (open-input-file path))
              (unwind-protect
                (let loop ((line (read-line port)))
                  (if (eof-object? line)
                    #f
                    (or (guard-smaps-rollup-pss-line-bytes line)
                        (loop (read-line port)))))
                (close-input-port port))))))))

(def (guard-linux-process-present? pid)
  (file-exists? (string-append "/proc/" (number->string pid))))

(def (guard-process-memory-observation/from pid rows linux-pss?
                                            process-present? process-pss-bytes)
  (let (tree-pids (guard-process-tree-pids pid rows))
    (let lp ((rest rows)
             (memory 0)
             (rss 0)
             (largest-rss 0)
             (largest-pss 0)
             (process-count 0))
      (if (null? rest)
        (.o (memory-metric (if linux-pss? 'linux-pss 'rss-tree-fallback))
            (memory-bytes memory)
            (rss-bytes rss)
            (largest-process-rss-bytes largest-rss)
            (largest-process-pss-bytes largest-pss)
            (process-count process-count))
        (let* ((row (car rest))
               (row-pid (car row))
               (in-tree? (member row-pid tree-pids))
               (present? (or (not linux-pss?)
                             (process-present? row-pid))))
          (if (and in-tree? present?)
            (let* ((row-rss (caddr row))
                   (row-pss (and linux-pss? (process-pss-bytes row-pid)))
                   (row-memory (if linux-pss?
                                 (or row-pss row-rss)
                                 row-rss)))
              (lp (cdr rest)
                  (+ memory row-memory)
                  (+ rss row-rss)
                  (max largest-rss row-rss)
                  (max largest-pss (or row-pss 0))
                  (+ process-count 1)))
            (lp (cdr rest) memory rss largest-rss largest-pss
                process-count)))))))

(def (guard-process-memory-observation pid)
  (guard-process-memory-observation/from
   pid
   (guard-process-table)
   (file-exists? "/proc/self/smaps_rollup")
   guard-linux-process-present?
   guard-linux-process-pss-bytes))

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

(def (guard-receipt label outcome exit-code child-exit memory-metric
                    peak-memory peak-rss peak-largest-process-rss
                    peak-largest-process-pss peak-process-count sample-count
                    max-memory elapsed-ms timeout-ms)
  (object<-alist
   (list (cons 'kind +poo-flow-process-memory-guard-schema+)
         (cons 'schema +poo-flow-process-memory-guard-schema+)
         (cons 'label label)
         (cons 'outcome outcome)
         (cons 'exit-code exit-code)
         (cons 'child-exit-code child-exit)
         (cons 'memory-metric memory-metric)
         (cons 'peak-memory-bytes peak-memory)
         (cons 'peak-rss-bytes peak-rss)
         (cons 'peak-largest-process-rss-bytes peak-largest-process-rss)
         (cons 'peak-largest-process-pss-bytes peak-largest-process-pss)
         (cons 'peak-process-count peak-process-count)
         (cons 'sample-count sample-count)
         (cons 'max-memory-bytes max-memory)
         (cons 'max-rss-bytes max-memory)
         (cons 'elapsed-ms elapsed-ms)
         (cons 'timeout-ms timeout-ms))))

(def (poo-flow-process-memory-guard-receipt->alist receipt)
  (map (lambda (slot) (cons slot (.ref receipt slot)))
       '(schema label outcome exit-code child-exit-code peak-rss-bytes
                max-rss-bytes elapsed-ms timeout-ms)))

(def (poo-flow-process-memory-guard-json-value value)
  (cond
   ((symbol? value) (symbol->string value))
   ((pair? value)
    (map poo-flow-process-memory-guard-json-value value))
   ((null? value) [])
   (else value)))

(def (poo-flow-process-memory-guard-receipt->json-object receipt)
  (hash
   ("kind"
    (poo-flow-process-memory-guard-json-value (.ref receipt 'kind)))
   ("schema"
    (poo-flow-process-memory-guard-json-value (.ref receipt 'schema)))
   ("version" 1)
   ("label"
    (poo-flow-process-memory-guard-json-value (.ref receipt 'label)))
   ("outcome"
    (poo-flow-process-memory-guard-json-value (.ref receipt 'outcome)))
   ("exit-code" (.ref receipt 'exit-code))
   ("child-exit-code" (.ref receipt 'child-exit-code))
   ("memory-metric"
    (poo-flow-process-memory-guard-json-value
     (.ref receipt 'memory-metric)))
   ("peak-memory-bytes" (.ref receipt 'peak-memory-bytes))
   ("peak-rss-bytes" (.ref receipt 'peak-rss-bytes))
   ("peak-largest-process-rss-bytes"
    (.ref receipt 'peak-largest-process-rss-bytes))
   ("peak-largest-process-pss-bytes"
    (.ref receipt 'peak-largest-process-pss-bytes))
   ("peak-process-count" (.ref receipt 'peak-process-count))
   ("sample-count" (.ref receipt 'sample-count))
   ("max-memory-bytes" (.ref receipt 'max-memory-bytes))
   ("max-rss-bytes" (.ref receipt 'max-rss-bytes))
   ("elapsed-ms" (.ref receipt 'elapsed-ms))
   ("timeout-ms" (.ref receipt 'timeout-ms))))

(def (poo-flow-process-memory-guard-receipt->json-string receipt)
  (parameterize ((write-json-sort-keys? #t))
    (json-object->string
     (poo-flow-process-memory-guard-receipt->json-object receipt))))

(def (poo-flow-current-process-memory-bytes)
  (guard-process-rss-bytes (##os-getpid)))

(def (poo-flow-current-process-memory-guard-emit! receipt)
  (display "POO_FLOW_BUILD_GUARD_RECEIPT " (current-error-port))
  (display (poo-flow-process-memory-guard-receipt->json-string receipt)
           (current-error-port))
  (newline (current-error-port))
  (force-output (current-error-port)))

(def (poo-flow-current-process-memory-guard-start!
      label max-rss-bytes timeout-seconds . maybe-sample-seconds)
  (unless (and (> max-rss-bytes 0)
               (or (not timeout-seconds) (> timeout-seconds 0)))
    (error
     "current process memory guard requires a positive RSS limit and an optional positive timeout"))
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
                       (and timeout-seconds
                            (inexact->exact
                             (round (* timeout-seconds 1000))))))
                     (exit 70))
                    ((and timeout-seconds (> elapsed timeout-seconds))
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
           (let (timeout-seconds (.ref guard 'timeout-seconds))
             (and timeout-seconds
                  (inexact->exact
                   (round (* 1000 timeout-seconds)))))))
      (poo-flow-current-process-memory-guard-emit! receipt)
      receipt)))

(def (poo-flow-process-memory-guard-run label max-rss-bytes timeout-seconds argv
                                        . maybe-sample-seconds)
  (unless (and (pair? argv)
               (> max-rss-bytes 0)
               (or (not timeout-seconds) (> timeout-seconds 0)))
    (error
     "process memory guard requires a command, positive RSS limit, and optional positive timeout"))
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
         (memory-metric 'rss-tree-fallback)
         (peak-memory 0)
         (peak-rss 0)
         (peak-largest-process-rss 0)
         (peak-largest-process-pss 0)
         (peak-process-count 0)
         (sample-count 0)
         (outcome 'running)
         (guard-exit 0))
    (let loop ()
      (unless (vector-ref state 0)
        (let* ((observation (guard-process-memory-observation pid))
               (memory (.ref observation 'memory-bytes))
               (rss (.ref observation 'rss-bytes))
               (elapsed (- (guard-now-seconds) started)))
          (set! memory-metric (.ref observation 'memory-metric))
          (set! peak-memory (max peak-memory memory))
          (set! peak-rss (max peak-rss rss))
          (set! peak-largest-process-rss
                (max peak-largest-process-rss
                     (.ref observation 'largest-process-rss-bytes)))
          (set! peak-largest-process-pss
                (max peak-largest-process-pss
                     (.ref observation 'largest-process-pss-bytes)))
          (set! peak-process-count
                (max peak-process-count (.ref observation 'process-count)))
          (set! sample-count (+ sample-count 1))
          (cond
           ((> peak-memory max-rss-bytes)
            (set! outcome 'rss-limit-exceeded)
            (set! guard-exit 70)
            (guard-terminate! pid))
           ((and timeout-seconds (> elapsed timeout-seconds))
            (set! outcome 'timeout)
            (set! guard-exit 71)
            (guard-terminate! pid))
           (else
            (thread-sleep! sample-seconds)
            (loop))))))
    (thread-join! waiter)
      (let* ((child-exit (vector-ref state 1))
             (final-outcome
              (cond
               ((not (eq? outcome 'running)) outcome)
               ((zero? child-exit) 'completed)
               (else 'child-failed)))
             (final-exit (if (eq? outcome 'running) child-exit guard-exit))
           (elapsed-ms
            (inexact->exact
             (round (* 1000 (- (guard-now-seconds) started))))))
      (guard-receipt label final-outcome final-exit child-exit memory-metric
                     peak-memory peak-rss peak-largest-process-rss
                     peak-largest-process-pss peak-process-count sample-count
                     max-rss-bytes elapsed-ms
                     (and timeout-seconds
                          (inexact->exact
                           (round (* timeout-seconds 1000))))))))
