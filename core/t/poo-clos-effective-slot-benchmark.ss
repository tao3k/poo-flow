;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Construction witness for inherited, overridden, and wide effective slots.

(import (only-in :clan/poo/object .ref)
        (only-in :gerbil/runtime/gambit current-jiffy jiffies-per-second)
        :core/poo-clos/interface)

(def +ancestors+ 8)
(def +slots-per-class+ 48)
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

(def (make-ancestor-chain)
  (let loop ((owner 0) (parent poo-clos-standard-object-class))
    (if (= owner +ancestors+)
      parent
      (loop (+ owner 1)
            (poo-clos-class
             (string->symbol
              (string-append "effective-slot-ancestor-" (number->string owner)))
             direct-superclasses: (list parent)
             direct-slots: (direct-slots owner))))))

(def (make-leaf parent index)
  (poo-clos-class
   (string->symbol
    (string-append "effective-slot-leaf-" (number->string index)))
   direct-superclasses: (list parent)
   direct-slots: (list (poo-clos-direct-slot-definition (slot-name 0 0)))))

(def parent (make-ancestor-chain))
(def expected (+ (* +ancestors+ +slots-per-class+) 0))

(def (check-leaf leaf)
  (let (slots (poo-clos-class-effective-slots leaf))
    (unless (= (length slots) expected)
      (error "effective slot count drift" (length slots) expected))
    (unless (eq? (.ref (car slots) 'identity) (slot-name 0 0))
      (error "effective slot order drift"))
    (unless (= (length (.ref (car slots) 'defining-classes)) 2)
      (error "effective slot override drift"))))

(display "schema=core.poo-clos-effective-slot.v1\n")
(display "ancestors=") (display +ancestors+) (newline)
(display "slots-per-class=") (display +slots-per-class+) (newline)
(display "samples=") (display +samples+) (newline)
(let ((start (current-jiffy)))
  (let loop ((index 0))
    (when (< index +samples+)
      (check-leaf (make-leaf parent index))
      (loop (+ index 1))))
  (display "leaf-construction-ms=")
  (display (/ (* (- (current-jiffy) start) 1000)
              (* (jiffies-per-second) +samples+)))
  (newline))
(display "accepted=#t\n")
