;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite test-case check-equal? check-exception)
        (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/src/module-system/semantic-module/objects
                 poo-flow-semantic-identity
                 poo-flow-semantic-module)
        :poo-flow/src/module-system/profile-composition/profile-bundle)

(export profile-bundle-test)

(def audit-profile
  (.o identity: 'audit
      name: 'audit
      stages: '()
      runtime-executed?: #f))

(def governed-profile
  (.o identity: 'governed
      name: 'governed
      stages: '()
      runtime-executed?: #f))

(def module-profiles
  (poo-flow-module-profiles
   (poo-flow-profile-export
    'audit audit-profile
    dependency-roots: '(observability)
    capability-requirements: '(read-receipts)
    revision: 'r1
    generation: 'g1
    provenance: 'test/audit)
   (poo-flow-profile-export
    'governed governed-profile
    dependency-roots: '(governance)
    capability-requirements: '(evaluate-policy)
    revision: 'r1
    generation: 'g1
    provenance: 'test/governed)))

(def test-module
  (poo-flow-semantic-module
   (poo-flow-semantic-identity 'test 'assurance)
   profiles: module-profiles))

(def profile-bundle-test
  (test-suite
   "POO-native ProfileBundle algebra"
   (test-case "Module selection uses an indexed export surface"
     (let (bundle
           (poo-flow-select-module-profiles
            test-module 'assurance '(audit governed)))
       (check-equal? (poo-flow-profile-bundle? bundle) #t)
       (check-equal? (.ref bundle 'profiles)
                     (list audit-profile governed-profile))
       (check-equal? (.ref bundle 'profile-identities) '(audit governed))
       (check-equal? (.ref bundle 'imports)
                     '(observability governance))
       (check-equal? (.ref bundle 'capabilities)
                     '(read-receipts evaluate-policy))
       (check-equal? (length (.ref bundle 'selection-proofs)) 2)
       (check-equal? (.ref bundle 'runtime-executed?) #f)))
   (test-case "selection fails closed for an unexported Profile"
     (check-exception
      (poo-flow-select-module-profiles
       test-module 'assurance '(missing))
      true))
   (test-case "profiles composition is idempotent for one Module instance"
     (let* ((selected
             (poo-flow-select-module-profiles
              test-module 'assurance '(audit governed)))
            (composed (compose profiles selected selected)))
       (check-equal? (.ref composed 'profile-identities) '(audit governed))
       (check-equal? (length (.ref composed 'selection-proofs)) 2)
       (check-equal? (length (.ref composed 'module-bindings)) 1)
       (check-equal? (.ref composed 'imports)
                     '(observability governance))
       (check-equal? (.ref composed 'capabilities)
                     '(read-receipts evaluate-policy))
       (check-equal? (.ref composed 'runtime-executed?) #f)))
   (test-case "explicit Module instances remain distinct"
     (let* ((primary
             (poo-flow-select-module-profiles
              test-module 'primary '(audit)))
            (secondary
             (poo-flow-select-module-profiles
              test-module 'secondary '(audit)))
            (composed (compose profiles primary secondary)))
       (check-equal? (.ref composed 'profile-identities) '(audit audit))
       (check-equal?
        (map (lambda (proof) (.ref proof 'module-instance))
             (.ref composed 'selection-proofs))
        '(primary secondary))))
   (test-case "root projection happens exactly after value composition"
     (let* ((bundle (compose profiles audit-profile governed-profile))
            (root (poo-flow-profile-bundle-root 'assurance-root bundle)))
       (check-equal? (.ref root 'name) 'assurance-root)
       (check-equal? (.ref root 'profiles)
                     (list audit-profile governed-profile))
       (check-equal? (eq? (.ref root 'profile-bundle) bundle) #t)
       (check-equal? (.ref root 'runtime-executed?) #f)))))
