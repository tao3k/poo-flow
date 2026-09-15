;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite test-case check)
        (only-in :std/misc/process run-process)
        (only-in :clan/timestamp call-with-timing))

(export package-spec-root-mode-ab-scenario-test)

(def +scenario-root+ "t/scenarios/building/package-spec-root-mode-ab")

(def (contract-ref contract key)
  (cdr (assq key contract)))

(def (project-build-spec script)
  (let-values (((elapsed-nanoseconds spec)
                (call-with-timing
                 (lambda ()
                   (run-process
                    ["gerbil" "interactive"
                     (path-expand script +scenario-root+) "spec"]
                    directory: (current-directory)
                    coprocess: read)))))
    (values elapsed-nanoseconds spec)))

(def package-spec-root-mode-ab-scenario-test
  (test-suite "POO PackageSpec direct roots versus complete package closure"
    (test-case "small direct-root specs are evidence of incomplete packaging"
      (let (contract
            (call-with-input-file
             (path-expand "contract.ss" +scenario-root+) read))
        (let-values (((modules-ns modules-spec)
                      (project-build-spec "modules-build.ss"))
                     ((closure-ns closure-spec)
                      (project-build-spec "closure-build.ss")))
          (displayln
           `((schema . poo-flow.package-spec-root-mode-ab.v1)
             (modules (elapsedNs . ,modules-ns)
                      (targetCount . ,(length modules-spec)))
             (closure (elapsedNs . ,closure-ns)
                      (targetCount . ,(length closure-spec)))))
          (check (length modules-spec) => (contract-ref contract 'rootCount))
          (check (>= (length closure-spec)
                     (contract-ref contract 'minimumClosureTargetCount))
                 => #t)
          (check (> (length closure-spec) (length modules-spec)) => #t)
          (check (< modules-ns
                    (contract-ref contract 'maxModulesSpecNanoseconds))
                 => #t))))))
