;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Contract: domain nouns compose through native gerbil-poo slot algebra.
;;; Invariant: refinements retain inherited declarations and never mutate their
;;; parent objects.

(import (only-in :std/test check-equal? test-case test-suite)
        (only-in :clan/poo/object .all-slots .def .get .o))

(export poo-native-slot-algebra-test)

(.def NativeCase
  (profile-selection ? (.o))
  (events ? (.o))
  (trajectories ? (.o)))

(.def (NativePrescriptionCase @ NativeCase)
  (profile-selection =>.+
    (.o common: (.o evidence: 'evidence-profile)
        healthcare: (.o base: 'healthcare-base-profile)))
  (events =>.+
    (.o prescription: 'prescription-event))
  (trajectories =>.+
    (.o safety: 'prescription-safety-trajectory)))

(.def (NativeReviewedPrescriptionCase @ NativePrescriptionCase)
  ;; Refinement is recursive: the outer slot retains named groups and the
  ;; inner slot retains entries inside the common group.
  (profile-selection =>.+
    (.o common: =>.+ (.o privacy: 'privacy-profile)))
  (events =>.+
    (.o prescription: 'reviewed-prescription-event
        review: 'clinical-review-event)))

(def poo-native-slot-algebra-test
  (test-suite
   "native POO noun-slot algebra"

   (test-case "base collection defaults remain empty"
     (check-equal? (.all-slots (.get NativeCase profile-selection)) '())
     (check-equal? (.all-slots (.get NativeCase events)) '())
     (check-equal? (.all-slots (.get NativeCase trajectories)) '()))

   (test-case "refinement retains identities and overrides one identity"
     (check-equal?
      (.get NativePrescriptionCase events prescription)
      'prescription-event)
     (check-equal?
      (.get NativeReviewedPrescriptionCase events prescription)
      'reviewed-prescription-event)
     (check-equal?
      (.get NativeReviewedPrescriptionCase events review)
      'clinical-review-event)
     (check-equal?
      (.get NativePrescriptionCase events prescription)
      'prescription-event))

   (test-case "selection recursively refines named groups"
     (check-equal?
      (.get NativeReviewedPrescriptionCase
            profile-selection common evidence)
      'evidence-profile)
     (check-equal?
      (.get NativeReviewedPrescriptionCase
            profile-selection common privacy)
      'privacy-profile)
     (check-equal?
      (.get NativeReviewedPrescriptionCase
            profile-selection healthcare base)
      'healthcare-base-profile))

   (test-case "unmentioned noun slots remain inherited"
     (check-equal?
      (.get NativeReviewedPrescriptionCase trajectories safety)
      'prescription-safety-trajectory))))
