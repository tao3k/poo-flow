;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite test-case check-equal?)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/13 string-contains string-prefix?)
        (only-in :clan/poo/object .o)
        (only-in :gerbil/gambit spawn thread-join! thread-sleep!)
        (only-in "../src/module-system/observability/config.ss"
                 poo-flow-default-build-observability-policy)
        (only-in "../src/module-system/observability/build-projection.ss"
                 poo-flow-make-observed-package-spec-projector
                 poo-flow-observe-build-projection
                 poo-flow-write-observation-line!
                 poo-flow-build-elapsed-milliseconds))

(export build-projection-observability-test)

(def (contains? text fragment)
  (and (string-contains text fragment) #t))

(def build-projection-observability-test
  (test-suite "POO PackageSpec projection observability"
    (test-case "native package catalog reaches the ASP projector unchanged"
      (let ((projected? #f)
            (port (open-output-string))
            (package-spec (.o)))
        (parameterize ((current-output-port port))
          ((poo-flow-make-observed-package-spec-projector
            (lambda (_package-spec)
              (set! projected? #t)
              '("src/core/api.ss" "src/module-system/api.ss"))
            poo-flow-default-build-observability-policy)
           package-spec))
        (let (output (get-output-string port))
          (check-equal? projected? #t)
          (check-equal? (contains? output "phase=spec-input") #f)
          (check-equal? (contains? output "phase=spec-projected") #t)
          (check-equal? (contains? output "target-count=2") #t)
          (check-equal? (contains? output "phase=executor-handoff") #t)
          (check-equal? (contains? output "phase=executor-active") #f))))

    (test-case "package build delegates the native public closure to ASP"
      (let (source (call-with-input-file "build.ss" read-all-as-string))
        (check-equal? (contains? source
                                 ":asp-gerbil-scheme/building-api")
                      #t)
        (check-equal? (contains? source
                                 ":asp-gerbil-scheme/build-api")
                      #f)
        (check-equal? (contains? source
                                 ":asp-gerbil-scheme/src/build-api/")
                      #f)
        (check-equal? (contains? source ":clan/building") #f)
        (check-equal? (contains? source
                                 "(public-entry-modules")
                      #t)
        (check-equal? (contains? source "\"src/core/api.ss\"") #t)
        (check-equal? (contains? source
                                 "\"src/module-system/api.ss\"")
                      #t)
        (check-equal? (contains? source
                                 "\"src/module-system/interface.ss\"")
                      #f)
        (check-equal? (contains? source
                                 "\"src/feature-system/interface.ss\"")
                      #t)
        (check-equal? (contains? source
                                 "(modules ")
                      #f)
        (check-equal? (contains? source "poo-flow-load-modules") #f)
        (check-equal? (contains? source "all-gerbil-modules") #f)
        (check-equal? (contains? source
                                 "(exclude-dirs +poo-flow-build-exclude-dirs+)")
                      #t)
        (check-equal? (contains? source "\"performance-tests.ss\"") #t)
        (check-equal? (contains? source "\"run-contribute-test.ss\"") #t)))

    (test-case "performance suite declares the POO testing extension"
      (let (performance-source
            (call-with-input-file "performance-tests.ss" read-all-as-string))
        (check-equal?
         (contains?
          performance-source
          "(poo-flow-testing-observability-extension +asp-testing-interface+)")
         #t)))

    (test-case "default policy measures catalog size without an invented limit"
      (let (port (open-output-string))
        (parameterize ((current-output-port port))
          (poo-flow-observe-build-projection
           poo-flow-default-build-observability-policy 601 3))
        (let (output (get-output-string port))
          (check-equal? (string-prefix? "\n[poo-flow]" output) #t)
          (check-equal? (contains? output "phase=spec-projected") #t)
          (check-equal? (contains? output "target-count=601") #t)
          (check-equal? (contains? output "reason=target-count") #f))))

    (test-case "derived POO policy overrides the budget without environment state"
      (let ((port (open-output-string))
            (policy
             (.o (:: @ poo-flow-default-build-observability-policy)
                 (id 'build-projection/test)
                 (target-budget 700))))
        (parameterize ((current-output-port port))
          (poo-flow-observe-build-projection policy 257 3))
        (let (output (get-output-string port))
          (check-equal? (contains? output "phase=spec-projected") #t)
          (check-equal? (contains? output "phase=spec-budget-exceeded") #f))))

    (test-case "derived POO policy can admit against measured package evidence"
      (let ((port (open-output-string))
            (policy
             (.o (:: @ poo-flow-default-build-observability-policy)
                 (id 'build-projection/qualification)
                 (target-budget 256)
                 (target-budget-action 'observe))))
        (parameterize ((current-output-port port))
          (poo-flow-observe-build-projection policy 257 3))
        (let (output (get-output-string port))
          (check-equal? (contains? output "phase=spec-budget-exceeded") #t)
          (check-equal? (contains? output "reason=target-count") #t)
          (check-equal? (contains? output "budget=256") #t))))

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
