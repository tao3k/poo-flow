;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: compiler-process A/B for equivalent static POO prototype families.

(import (only-in :gerbil/expander
                 current-expander-compiling?
                 import-module)
        (only-in :clan/timestamp call-with-timing)
        (only-in :std/misc/path path-expand))

(export static-poo-prototype-lowering-benchmark)

(def +static-poo-prototype-count+ 2)

(def +static-poo-prototype-scenario-root+
  "t/scenarios/performance/static-poo-prototype-lowering")

(def (static-poo-prototype-source-path name)
  (path-expand
   name
   (path-expand +static-poo-prototype-scenario-root+ (current-directory))))

(def (static-poo-prototype-expansion-elapsed-ms path)
  (let-values (((elapsed-nanoseconds ignored-result)
                (call-with-timing
                 (lambda () (import-module path #t #f)))))
    (/ elapsed-nanoseconds 1000000.0)))

(def (static-poo-prototype-lowering-benchmark)
  (parameterize ((current-expander-compiling? #f))
    (let* ((native-ms
            (static-poo-prototype-expansion-elapsed-ms
             (static-poo-prototype-source-path "native-case.ss")))
           (lowered-ms
            (static-poo-prototype-expansion-elapsed-ms
             (static-poo-prototype-source-path "lowered-case.ss")))
           (ratio (if (zero? native-ms) 1.0 (/ lowered-ms native-ms))))
      (list (cons 'prototype-count +static-poo-prototype-count+)
            (cons 'slots-per-prototype 24)
            (cons 'native-ms native-ms)
            (cons 'lowered-ms lowered-ms)
            (cons 'lowered/native-ratio ratio)
            (cons 'same-source-shape #t)
            (cons 'writes-compiled-artifacts #f)
            (cons 'pass (and (< lowered-ms native-ms)
                             (< ratio 0.75)))))))
