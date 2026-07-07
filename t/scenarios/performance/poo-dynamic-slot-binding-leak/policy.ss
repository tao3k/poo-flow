;;; -*- Gerbil -*-
;;; Boundary: scenario-local policy for POO dynamic slot binding leaks.
;;;
;;; This file is static policy data. It must not import :clan/poo/object and
;;; must not execute `.o` or `.ref`; the purpose is to teach agents and tests
;;; which source shape is unsafe before runtime.

(export poo-dynamic-slot-binding-leak-policy
        poo-dynamic-slot-binding-leak-unsafe-form
        poo-dynamic-slot-binding-leak-safe-rewrite)

;; : Alist
(def poo-dynamic-slot-binding-leak-policy
  '((policy . forbid-poo-same-name-slot-value)
    (scope . downstream-scenario-first)
    (unsafe-shape . "(.o ... (slot slot) ...)")
    (reason . "The right-hand identifier can be captured by POO %with-slots and recursively force the same slot during .ref.")
    (repair . "Rename the lexical value binding before placing it in the .o slot form.")
    (ownership . "This downstream scenario classifies the boundary; it does not by itself prove an upstream defect.")))

;; : Sexp
(def poo-dynamic-slot-binding-leak-unsafe-form
  '(.o (kind 'poo-performance-prototype-composition-cache)
       (family 'poo-performance-prototype-composition-cache-family)
       (descriptor-count descriptor-count)
       (key-span key-span)
       (first-value key-span)
       (last-value last-value)
       (descriptor-checksum 0)))

;; : Sexp
(def poo-dynamic-slot-binding-leak-safe-rewrite
  '(let* ((descriptor-count-value descriptor-count)
          (key-span-value key-span)
          (first-value-value key-span)
          (last-value-value last-value))
     (.o (kind 'poo-performance-prototype-composition-cache)
         (family 'poo-performance-prototype-composition-cache-family)
         (descriptor-count descriptor-count-value)
         (key-span key-span-value)
         (first-value first-value-value)
         (last-value last-value-value)
         (descriptor-checksum 0))))
