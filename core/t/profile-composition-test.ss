;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal? check-exception)
        (only-in :clan/poo/object .o .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        :core/profile-composition/profile-bundle)

(export profile-composition-test)

(def audit-profile
  (.o identity: 'audit imports: '(evidence) capabilities: '(read)))

(def govern-profile
  (.o identity: 'govern imports: '(policy) capabilities: '(decide)))

(def profile-composition-test
  (test-suite "Core ProfileBundle composition"
    (poo-flow-test-case "direct Profiles compose without a Scenario runtime"
      (let (bundle (compose profiles audit-profile govern-profile))
        (check-equal? (poo-flow-profile-bundle? bundle) #t)
        (check-equal? (.ref bundle 'profile-identities) '(audit govern))
        (check-equal? (.ref bundle 'imports) '(evidence policy))
        (check-equal? (.ref bundle 'capabilities) '(read decide))
        (check-equal? (.ref bundle 'runtime-executed?) #f)))
    (poo-flow-test-case "same Profile identity is idempotent"
      (let (bundle (compose profiles audit-profile audit-profile))
        (check-equal? (.ref bundle 'profile-identities) '(audit))))
    (poo-flow-test-case "distinct values with one identity conflict"
      (check-exception
       (compose profiles audit-profile (.o identity: 'audit))
       true))
    (poo-flow-test-case "indexed Module exports remain inert"
      (let (exports
            (poo-flow-module-profiles
             (poo-flow-profile-export 'audit audit-profile)
             (poo-flow-profile-export 'govern govern-profile)))
        (check-equal? (map (lambda (value) (.ref value 'identity))
                           (.ref exports 'contributions))
                      '(audit govern))))))
