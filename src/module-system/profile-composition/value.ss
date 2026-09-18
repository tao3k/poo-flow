;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: generic POO-native Composition values and pure selection.
;;; Invariant: selecting a Composition constructs one closed Case and never
;;; starts a Runtime Session.

(import (only-in :clan/poo/object .mix .o .ref object?)
        (only-in :poo-flow/src/module-system/profile-composition/identity
                 poo-flow-composition-identity?)
        (only-in :poo-flow/src/module-system/profile-composition/scenario-case
                 poo-flow-scenario-case?))

(export +poo-flow-composition-kind+
        poo-flow-composition
        poo-flow-composition?
        poo-flow-composition-select
        poo-flow-composition-select/overrides)

(def +poo-flow-composition-kind+
  'poo-flow.composition)

(def (poo-flow-composition? value)
  (and (object? value)
       (with-catch
        (lambda (_failure) #f)
        (lambda ()
          (eq? (.ref value 'kind)
               +poo-flow-composition-kind+)))))

;;; A package-owned Composition supplies its identity, default Profile and a
;;; pure Case constructor. The constructor is deliberately a value-level POO
;;; slot: package registration is separate from the public selector syntax.
(def (poo-flow-composition identity default-profile instantiate)
  (unless (poo-flow-composition-identity? identity)
    (error "Composition requires a typed Composition identity" identity))
  (unless (object? default-profile)
    (error "Composition requires a POO-native default Profile"
           default-profile))
  (unless (procedure? instantiate)
    (error "Composition requires a Case constructor" instantiate))
  (let ((identity-value identity)
        (default-profile-value default-profile)
        (instantiate-value instantiate))
    (.o (kind +poo-flow-composition-kind+)
        (identity identity-value)
        (default-profile default-profile-value)
        (instantiate instantiate-value)
        (runtime-executed? #f))))

;;; This is the generic value operation behind the short public form
;;;   (use-composition official-composition)
;;; It evaluates the selected Composition once and returns exactly one Case.
(def (poo-flow-composition-instantiate composition profile)
  (unless (poo-flow-composition? composition)
    (error "use-composition requires a POO Flow Composition value"
           composition))
  (let (case-value
        ((.ref composition 'instantiate)
         profile))
    (unless (poo-flow-scenario-case? case-value)
      (error "Composition constructor did not return a Scenario Case"
             case-value))
    case-value))

(def (poo-flow-composition-select/overrides composition overrides)
  (unless (object? overrides)
    (error "Composition overrides must be a POO-native object" overrides))
  (poo-flow-composition-instantiate
   composition
   (.mix overrides (.ref composition 'default-profile))))

(def (poo-flow-composition-select composition)
  (poo-flow-composition-instantiate
   composition
   (.ref composition 'default-profile)))
