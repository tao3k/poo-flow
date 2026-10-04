;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Repeatable hot-call witness: one-method and wide inapplicable method sets.

(import (only-in :clan/poo/object .o)
        (only-in :gerbil/runtime/gambit current-jiffy jiffies-per-second)
        :core/poo-clos/interface)

(def +iterations+ 2000)

(def (make-case method-count)
  (let* ((target (.o))
         (argument (.o (:: @ target))))
    (let loop ((index 0)
               (generic (poo-clos-generic-function 'dispatch-benchmark 1)))
      (if (= index method-count)
        (values generic argument)
        (let ((prototype (if (= index (- method-count 1)) target (.o))))
          (loop (+ index 1)
                (poo-clos-add-method
                 generic
                 (poo-clos-method
                  (string->symbol
                   (string-append "method-" (number->string index)))
                  (list (poo-clos-prototype-specializer prototype))
                  (lambda (_frame _argument) index)))))))))

(def (measure label thunk expected)
  (unless (= (thunk) expected)
    (error "dispatch benchmark semantic mismatch" label))
  (let warm ((index 0))
    (when (< index 100)
      (thunk)
      (warm (+ index 1))))
  (let ((start (current-jiffy)))
    (let run ((index 0) (last #f))
      (if (= index +iterations+)
        (begin
          (unless (= last expected)
            (error "dispatch benchmark result drift" label))
          (display label) (display "-ms-per-1000=")
          (display
           (/ (* (- (current-jiffy) start) 1000000)
              (* (jiffies-per-second) +iterations+)))
          (newline))
        (run (+ index 1) (thunk))))))

(display "schema=core.poo-clos-dispatch.v1\n")
(display "iterations=") (display +iterations+) (newline)
(let-values (((generic argument) (make-case 1)))
  (measure "single-call"
           (lambda () (poo-clos-call generic argument)) 0)
  (measure "single-applicable"
           (lambda ()
             (length (poo-clos-compute-applicable-methods generic argument))) 1))
(let-values (((generic argument) (make-case 64)))
  (measure "wide-call"
           (lambda () (poo-clos-call generic argument)) 63)
  (measure "wide-applicable"
           (lambda ()
             (length (poo-clos-compute-applicable-methods generic argument))) 1))
(display "accepted=#t\n")
