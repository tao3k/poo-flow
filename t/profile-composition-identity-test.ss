;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test check-equal? check-exception test-case test-suite)
        :poo-flow/src/module-system/profile-composition/identity)

(export profile-composition-identity-test)

(def profile-composition-identity-test
  (test-suite
   "POO Flow Composition identity"

   (test-case "admits an unqualified official Composition selector"
     (let (identity (poo-flow-official-composition-identity 'aitia))
       (check-equal? (poo-flow-composition-identity? identity) #t)
       (check-equal? (poo-flow-composition-identity-qualified-name identity)
                     'aitia)
       (check-equal? (poo-flow-composition-identity-official? identity) #t)))

   (test-case "admits a qualified user Composition identity"
     (let (identity
           (poo-flow-user-composition-identity
            'acme 'flight-software
            '(gitops sdlc ADR assurance)
            '(aitia)))
       (check-equal? (poo-flow-composition-identity-qualified-name identity)
                     'acme/flight-software)
       (check-equal? (poo-flow-composition-identity-namespace identity) 'acme)
       (check-equal? (poo-flow-composition-identity-local-name identity)
                     'flight-software)
       (check-equal? (poo-flow-composition-identity-official? identity) #f)))

   (test-case "rejects a reserved Composition namespace"
     (check-exception
      (poo-flow-user-composition-identity
       'aitia 'custom '(gitops sdlc) '(aitia))
      true))

   (test-case "rejects a namespace equal to a Module namespace"
     (check-exception
      (poo-flow-user-composition-identity
       'gitops 'custom '(gitops sdlc ADR assurance) '(aitia))
      true))))
