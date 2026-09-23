;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite test-case check-equal?)
        (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/src/module-system/semantic-module/objects
                 poo-flow-semantic-identity
                 poo-flow-semantic-module)
        (only-in :poo-flow/src/module-system/profile-composition/profile-bundle
                 profiles compose poo-flow-profile-export
                 poo-flow-module-profiles)
        :poo-flow/src/module-system/profile-composition/binding-syntax)

(export profile-binding-syntax-test)

(def bounded-profile
  (.o identity: 'bounded name: 'bounded runtime-executed?: #f))

(def SyntaxModule
  (poo-flow-semantic-module
   (poo-flow-semantic-identity 'test 'syntax-module)
   profiles:
   (poo-flow-module-profiles
    (poo-flow-profile-export 'bounded bounded-profile))))

(user-composition syntax-root
  (compose profiles
    (use-module SyntaxModule bounded)))

(def default-selection
  (use-module SyntaxModule bounded))

(def aliased-selection
  (use-module SyntaxModule as secondary bounded))

(def profile-binding-syntax-test
  (test-suite
   "thin Profile composition bindings"
   (test-case "user-composition creates the only root binding"
     (check-equal? (.ref syntax-root 'name) 'syntax-root)
     (check-equal? (.ref syntax-root 'profiles) (list bounded-profile)))
   (test-case "default Module instance is the definition identity"
     (let (proof (car (.ref default-selection 'selection-proofs)))
       (check-equal? (eq? (.ref proof 'module-definition)
                          (.ref proof 'module-instance))
                     #t)))
   (test-case "explicit alias is a distinct instance identity"
     (let (proof (car (.ref aliased-selection 'selection-proofs)))
       (check-equal? (.ref proof 'module-instance) 'secondary)))))
