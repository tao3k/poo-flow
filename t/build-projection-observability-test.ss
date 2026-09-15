;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite test-case check-equal? check-exception)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/13 string-contains string-prefix?)
        (only-in :clan/poo/object .o)
        (only-in :gerbil/gambit spawn thread-join! thread-sleep!)
        (only-in "../src/module-system/observability/config.ss"
                 poo-flow-default-build-observability-policy)
        (only-in "../src/module-system/observability/interface.ss"
                 poo-flow-make-observed-package-spec-projector
                 poo-flow-admit-build-package-spec!
                 poo-flow-observe-build-projection)
        (only-in "../src/module-system/observability/build-projection.ss"
                 poo-flow-write-observation-line!
                 poo-flow-build-elapsed-milliseconds)
        (only-in "../src/module-system/observability/testing-extension.ss"
                 make-poo-flow-testing-observability-profile
                 poo-flow-testing-observability-profile-source-load-paths))

(export build-projection-observability-test)

(def (contains? text fragment)
  (and (string-contains text fragment) #t))

(def build-projection-observability-test
  (test-suite "POO PackageSpec projection observability"
    (test-case "public entry closure remains owned by the ASP projector"
      (let ((projected? #f)
            (port (open-output-string))
            (package-spec
             (.o (public-entry-modules '("src/core/api.ss")))))
        (parameterize ((current-output-port port))
          ((poo-flow-make-observed-package-spec-projector
            (lambda (_package-spec)
              (set! projected? #t)
              '("src/core/api.ss"))
            poo-flow-default-build-observability-policy)
           package-spec))
        (let (output (get-output-string port))
          (check-equal? projected? #t)
          (check-equal? (contains? output "phase=spec-input") #t)
          (check-equal? (contains? output "mode=public-entry-modules") #t)
          (check-equal?
           (contains? output "owner=asp-build-api/native-import-closure")
           #t))))

    (test-case "public interface rejects malformed roots before projection"
      (let ((projected? #f)
            (package-spec (.o (public-entry-modules 'malformed))))
        (check-exception
         (poo-flow-admit-build-package-spec!
          package-spec poo-flow-default-build-observability-policy)
         (lambda (_failure) #t))
        (check-exception
         ((poo-flow-make-observed-package-spec-projector
           (lambda (_package-spec)
             (set! projected? #t)
             '())
           poo-flow-default-build-observability-policy)
          package-spec)
         (lambda (_failure) #t))
        (check-equal? projected? #f)))

    (test-case "package build source declares complete public closure roots"
      (let (source (call-with-input-file "build.ss" read-all-as-string))
        (check-equal? (contains? source
                                 "(public-entry-modules +poo-flow-public-entry-modules+)")
                      #t)
        (check-equal? (contains? source
                                 "(modules +poo-flow-public-entry-modules+)")
                      #f)))
    (test-case "testing source roots are owned by the POO profile"
      (let (profile
            (make-poo-flow-testing-observability-profile
             'testing/source-root 1/100))
        (check-equal?
         (poo-flow-testing-observability-profile-source-load-paths profile)
         '(".gerbil/lib" "."))))

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
