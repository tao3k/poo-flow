;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Dependent C4 projection and commit witness for real slot-layout changes.

(import (only-in :gerbil/runtime/gambit current-jiffy jiffies-per-second)
        :core/poo-clos/interface)

(def +dependent-depth+ 16)
(def +slots-per-class+ 16)
(def +samples+ 12)

(def (slot-name owner index)
  (string->symbol
   (string-append "slot-" (number->string owner) "-" (number->string index))))

(def (direct-slots owner)
  (let loop ((index 0) (result '()))
    (if (= index +slots-per-class+)
      (reverse result)
      (loop (+ index 1)
            (cons (poo-clos-direct-slot-definition (slot-name owner index))
                  result)))))

(def root-slots (direct-slots 0))
(def extended-root-slots
  (append root-slots (list (poo-clos-direct-slot-definition 'extra))))
(def root (poo-clos-class 'redefinition-benchmark-root
                          direct-slots: root-slots))
(def classes
  (let loop ((index 0) (parent root) (result-rev (list root)))
    (if (= index +dependent-depth+)
      (reverse result-rev)
      (let (child
            (poo-clos-class
             (string->symbol
              (string-append "redefinition-benchmark-child-"
                             (number->string index)))
             direct-superclasses: (list parent)
             direct-slots: (direct-slots (+ index 1))))
        (loop (+ index 1) child (cons child result-rev))))))
(def leaf (car (reverse classes)))

(def (check-projection generation extra?)
  (unless (and (andmap (lambda (class-value)
                        (= (poo-clos-class-generation class-value) generation))
                      classes)
               (= (length (poo-clos-class-effective-slots leaf))
                  (+ (* (+ +dependent-depth+ 1) +slots-per-class+)
                     (if extra? 1 0))))
    (error "dependent redefinition projection drift" generation extra?)))

;; Warm the same propagation path before timing; all samples change layout.
(poo-clos-redefine-class root direct-slots: extended-root-slots)
(check-projection 1 #t)

(display "schema=core.poo-clos-redefinition.v1\n")
(display "dependent-depth=") (display +dependent-depth+) (newline)
(display "slots-per-class=") (display +slots-per-class+) (newline)
(display "samples=") (display +samples+) (newline)
(let (start (current-jiffy))
  (let loop ((index 0))
    (when (< index +samples+)
      (let (extra? (odd? index))
        (poo-clos-redefine-class
         root direct-slots: (if extra? extended-root-slots root-slots))
        (check-projection (+ index 2) extra?)
        (loop (+ index 1)))))
  (display "redefinition-ms=")
  (display (/ (* (- (current-jiffy) start) 1000)
              (* (jiffies-per-second) +samples+)))
  (newline))
(display "accepted=#t\n")
