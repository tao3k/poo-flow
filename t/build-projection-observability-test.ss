;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite test-case check-equal?)
        (only-in :std/srfi/13 string-contains string-prefix?)
        (only-in :clan/poo/object .o)
        (only-in :gerbil/gambit spawn thread-join! thread-sleep!)
        (only-in "../src/module-system/observability/config.ss"
                 poo-flow-default-build-observability-policy)
        (only-in "../src/module-system/observability/build-projection.ss"
                 poo-flow-write-observation-line!
                 poo-flow-build-elapsed-milliseconds
                 poo-flow-observe-build-projection))

(export build-projection-observability-test)

(def (contains? text fragment)
  (and (string-contains text fragment) #t))

(def build-projection-observability-test
  (test-suite "POO PackageSpec projection observability"
    (test-case "default policy exposes an oversized native catalog"
      (let (port (open-output-string))
        (parameterize ((current-output-port port))
          (poo-flow-observe-build-projection
           poo-flow-default-build-observability-policy 257 3))
        (let (output (get-output-string port))
          (check-equal? (string-prefix? "\n[poo-flow]" output) #t)
          (check-equal? (contains? output "phase=spec-projected") #t)
          (check-equal? (contains? output "target-count=257") #t)
          (check-equal? (contains? output "reason=target-count") #t)
          (check-equal? (contains? output "action=observe") #t))))

    (test-case "derived POO policy overrides the budget without environment state"
      (let ((port (open-output-string))
            (policy
             (.o (:: @ poo-flow-default-build-observability-policy)
                 (id 'build-projection/test)
                 (target-budget 600))))
        (parameterize ((current-output-port port))
          (poo-flow-observe-build-projection policy 257 3))
        (let (output (get-output-string port))
          (check-equal? (contains? output "phase=spec-projected") #t)
          (check-equal? (contains? output "phase=spec-budget-exceeded") #f))))

    (test-case "concurrent Owner receipts remain complete line records"
      (let* ((worker-count 12)
             (records-per-worker 40)
             (port (open-output-string))
             (workers
              (map (lambda (worker-id)
                     (spawn
                      (lambda ()
                        (parameterize ((current-output-port port))
                          (let loop ((sequence 0))
                            (when (< sequence records-per-worker)
                              (poo-flow-write-observation-line!
                               "[poo-flow-test] worker=~a sequence=~a"
                               worker-id sequence)
                              (loop (+ sequence 1))))))))
                   (iota worker-count))))
        (for-each thread-join! workers)
        (let* ((output (get-output-string port))
               (lines (string-split output #\newline))
               (records (filter (lambda (line) (not (string=? line ""))) lines)))
          (check-equal? (length records) (* worker-count records-per-worker))
          (check-equal?
           (andmap (lambda (line)
                     (and (string-prefix? "[poo-flow-test] worker=" line)
                          (contains? line " sequence=")))
                   records)
           #t))))

    (test-case "Owner elapsed time is sampled from the wall clock"
      (let (started-jiffy (current-jiffy))
        (thread-sleep! 0.03)
        (check-equal?
         (>= (poo-flow-build-elapsed-milliseconds started-jiffy) 20)
         #t)))))
