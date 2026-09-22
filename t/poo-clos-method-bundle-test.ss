;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .ref)
        (only-in :clan/poo/mop element?)
        "../src/module-system/poo-clos/interface.ss")

(export poo-clos-method-bundle-test)

(def protocol (poo-clos-generic-protocol 'render))
(def other-protocol (poo-clos-generic-protocol 'other))

(def base-method
  (poo-clos-method
   'base (list (poo-clos-any-specializer))
   (lambda (_frame value) (list 'base value))))

(.defmethod-bundle render-methods protocol base-method)

(def (fresh-method identity tag)
  (poo-clos-method
   identity (list (poo-clos-any-specializer))
   (lambda (_frame value) (list tag value))))

(def (fresh-bundle identity protocol-value method-identity tag)
  (poo-clos-method-bundle
   identity protocol-value (list (fresh-method method-identity tag))))

(def poo-clos-method-bundle-test
  (test-suite "POO CLOS generic protocol and method bundle composition"
    (test-case "thin defrule produces a native checked bundle"
      (check (element? ClosMethodBundle render-methods) => #t)
      (check (.ref render-methods 'protocol) => protocol)
      (check (.ref render-methods 'methods) => (list base-method)))
    (test-case "one protocol composes a bundle into generic dispatch"
      (let ((generic (poo-clos-generic-function 'render 1 protocol: protocol))
            (bundle (fresh-bundle 'base protocol 'base 'base)))
        (check (poo-clos-compose-method-bundle generic bundle) => generic)
        (check (poo-clos-call generic 'payload) => '(base payload))))
    (test-case "several bundles preserve ordinary replacement admission"
      (let* ((generic (poo-clos-generic-function 'render 1 protocol: protocol))
             (base-bundle (fresh-bundle 'base protocol 'base 'base))
             (replacement-bundle
              (fresh-bundle 'replacement protocol
                            'replacement 'replacement)))
        (check (poo-clos-compose-method-bundles
                generic (list base-bundle replacement-bundle))
               => generic)
        (check (poo-clos-call generic 'payload) => '(replacement payload))))
    (test-case "protocol identity mismatch fails before method ownership changes"
      (let* ((generic (poo-clos-generic-function 'render 1 protocol: protocol))
             (bundle (fresh-bundle 'wrong other-protocol 'wrong 'wrong)))
        (check-exception
         (poo-clos-compose-method-bundle generic bundle)
         (lambda (failure)
           (and (poo-clos-failure? failure)
                (eq? (.ref failure 'code)
                     'method-bundle-protocol-mismatch))))
        (check (poo-clos-generic-methods generic) => '())))))
