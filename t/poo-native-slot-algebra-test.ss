;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Contract: domain noun slots compose through native gerbil-poo algebra.
;;; Invariant: refinements retain inherited declarations and never mutate their
;;; parent objects.

(import (only-in :std/test check-exception check-equal? test-case test-suite)
        (only-in :clan/poo/object .all-slots .def .get .o)
        (only-in :poo-flow/src/module-system/observability/effective-object
                 poo-flow-native-slot-view))

(export poo-native-slot-algebra-test)

(.def OntologyCase
  (profile-selection ? (.o))
  (events ? (.o))
  (trajectories ? (.o)))

(.def (PrescriptionCase @ OntologyCase)
  (profile-selection =>.+
    (.o common: (.o evidence: 'evidence-profile)
        healthcare: (.o base: 'healthcare-base-profile)))
  (events =>.+
    (.o prescription: 'prescription-event))
  (trajectories =>.+
    (.o safety: 'prescription-safety-trajectory)))

(.def (ReviewedPrescriptionCase @ PrescriptionCase)
  ;; Refinement is recursive: the outer slot retains named groups and the
  ;; inner slot retains entries inside the common group.
  (profile-selection =>.+
    (.o common: =>.+ (.o privacy: 'privacy-profile)))
  (events =>.+
    (.o prescription: 'reviewed-prescription-event
        review: 'clinical-review-event)))

(def fixture-prototype-labels
  (.o reviewed: ReviewedPrescriptionCase
      prescription: PrescriptionCase
      ontology: OntologyCase))

(def poo-native-slot-algebra-test
  (test-suite
   "native POO noun-slot algebra"

   (test-case "base collection defaults remain empty"
     (check-equal? (.all-slots (.get OntologyCase profile-selection)) '())
     (check-equal? (.all-slots (.get OntologyCase events)) '())
     (check-equal? (.all-slots (.get OntologyCase trajectories)) '()))

   (test-case "refinement retains identities and overrides one identity"
     (check-equal?
      (.get PrescriptionCase events prescription)
      'prescription-event)
     (check-equal?
      (.get ReviewedPrescriptionCase events prescription)
      'reviewed-prescription-event)
     (check-equal?
      (.get ReviewedPrescriptionCase events review)
      'clinical-review-event)
     (check-equal?
      (.get PrescriptionCase events prescription)
      'prescription-event))

   (test-case "selection recursively refines named groups"
     (check-equal?
      (.get ReviewedPrescriptionCase
            profile-selection common evidence)
      'evidence-profile)
     (check-equal?
      (.get ReviewedPrescriptionCase
            profile-selection common privacy)
      'privacy-profile)
     (check-equal?
      (.get ReviewedPrescriptionCase
            profile-selection healthcare base)
      'healthcare-base-profile))

   (test-case "unmentioned noun slots remain inherited"
     (check-equal?
      (.get ReviewedPrescriptionCase trajectories safety)
      'prescription-safety-trajectory))

   (test-case "effective value precedes its native slot declaration lineage"
     (let* ((events-view
             (poo-flow-native-slot-view
              ReviewedPrescriptionCase 'events fixture-prototype-labels))
            (trajectory-view
             (poo-flow-native-slot-view
              ReviewedPrescriptionCase 'trajectories fixture-prototype-labels)))
       (check-equal? (.get (.get events-view effective-value) prescription)
                     'reviewed-prescription-event)
       (check-equal? (.get events-view provenance)
                     '(reviewed prescription ontology))
       (check-equal? (.get trajectory-view provenance)
                     '(prescription ontology))))

   (test-case "incomplete provenance labels fail closed"
     (check-exception
      (poo-flow-native-slot-view
       ReviewedPrescriptionCase 'events
       (.o reviewed: ReviewedPrescriptionCase))
      true))

   (test-case "duplicate prototype labels fail closed"
     (check-exception
      (poo-flow-native-slot-view
       ReviewedPrescriptionCase 'events
       (.o reviewed: ReviewedPrescriptionCase
           duplicate: ReviewedPrescriptionCase
           prescription: PrescriptionCase
           ontology: OntologyCase))
      true))

   (test-case "missing native slot cannot be presented"
     (check-exception
      (poo-flow-native-slot-view
       ReviewedPrescriptionCase 'nonexistent fixture-prototype-labels)
      true))))
