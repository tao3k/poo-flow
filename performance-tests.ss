#!/usr/bin/env gxi
;;; Native performance entrypoint using the same ASP scheduler as unit tests.

(import (only-in :clan/testing find-test-files)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-serial-resource-profile+
                 testing-test-selector
                 testing-interface-map-profile
                 testing-interface-run-test-batch!
                 testing-interface-test-file-serial?
                 testing-interface-test-file-batches)
        (only-in :std/srfi/1 filter partition)
        (only-in :std/srfi/13 string-prefix?))

(def +poo-flow-performance-testing-interface+
  (testing-interface-map-profile
   (testing-interface-map-profile
    +asp-testing-interface+
    (testing-test-selector
     'contains
     "module-system-poo-performance-test-support/objects-test.ss")
    +testing-serial-resource-profile+)
   (testing-test-selector
    'contains
    "module-objects-validation-summary-performance-test.ss")
   +testing-serial-resource-profile+))

(def +poo-flow-performance-test-files+
  (filter
   (lambda (path)
     (or (string-prefix? "./t/performance/" path)
         (string-prefix?
          "./t/module-system-poo-performance-test-support/"
          path)))
   (find-test-files "." "-test.ss$")))

(displayln "[poo-performance-testing] phase=entry-ready")
(force-output)
(let-values (((serial-files parallel-files)
              (partition
               (lambda (test-file)
                 (testing-interface-test-file-serial?
                  +poo-flow-performance-testing-interface+
                  test-file))
               +poo-flow-performance-test-files+)))
  (let (batches
        (append
         (testing-interface-test-file-batches
          +poo-flow-performance-testing-interface+
          parallel-files)
         (map list serial-files)))
  (displayln "[poo-performance-testing] phase=batch-plan fileCount="
             (length +poo-flow-performance-test-files+)
             " batchCount=" (length batches)
             " coreBudget="
             (or (getenv "GERBIL_BUILD_CORES" #f) "host"))
  (force-output)
  ;; Performance samples execute without inter-batch CPU contention. Batch
  ;; count and widths still come entirely from the ASP core-capacity policy.
  (for-each
   (lambda (batch)
     (testing-interface-run-test-batch!
      +poo-flow-performance-testing-interface+
      batch))
   batches)
  (displayln "[poo-performance-testing] phase=all-batches-complete fileCount="
             (length +poo-flow-performance-test-files+))
  (force-output)))
