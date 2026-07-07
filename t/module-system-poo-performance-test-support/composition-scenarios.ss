;;; -*- Gerbil -*-
;;; Boundary: reusable POO composition performance scenarios and gates.

(import (only-in :clan/poo/object .o .ref)
        :poo-flow/t/support/poo-performance
        :poo-flow/src/module-system/profile-composition)

(export poo-performance-composition-profile-declaration-valid-count
        poo-performance-composition-profile-declaration-gate-receipt
        poo-performance-composition-profiles-bulk-valid-count
        poo-performance-composition-profiles-bulk-gate-receipt
        poo-performance-composition-local-override-valid-count
        poo-performance-composition-local-override-gate-receipt
        poo-performance-composition-hook-override-valid-count
        poo-performance-composition-hook-override-gate-receipt
        poo-performance-composition-native-object-reuse-valid-count
        poo-performance-composition-native-object-reuse-gate-receipt
        poo-performance-composition-construction-count
        poo-performance-composition-reset-construction-count!)

(def poo-performance-composition-construction-count-value 0)

(def (poo-performance-composition-note-construction!)
  (set! poo-performance-composition-construction-count-value
        (+ poo-performance-composition-construction-count-value 1)))

(def (poo-performance-composition-construction-count)
  poo-performance-composition-construction-count-value)

(def (poo-performance-composition-reset-construction-count!)
  (set! poo-performance-composition-construction-count-value 0))

(def poo-performance-composition-library
  (.o (agent (.o (name 'agent) (scope '(session))))
      (task (.o (name 'task) (scope '(workflow))))
      (memory (.o (name 'memory)
                  (scope '(session workflow))
                  (analysis '(checksum))
                  (retention '(checkpoint-linked))))
      (guardrail (.o (name 'guardrail) (scope '(workflow))))
      (runtime-handoff (.o (name 'runtime-handoff) (scope '(runtime))))))

(def poo-performance-native-enterprise-profile
  (.o (name 'enterprise-report)
      (scope '(session publish-channel))
      (publish '(human-approved legal-review proof-gated))
      (retention '(seven-years audit-log))))

(def (poo-performance-audit-retention-hook profile)
  (.o (:extends profile)
      (name (.ref profile 'name))
      (analysis '(checksum provenance citation-trace))
      (retention '(project-retained audit-log))))

(def (poo-performance-composition-profile-declaration)
  (poo-performance-composition-note-construction!)
  (use-composition profile-declaration-performance
    (use-module declared
      (profile agent :scope (session))
      (profile task :scope (workflow))
      (profile memory
        :scope (session workflow)
        :analysis (checksum)
        :retention (checkpoint-linked)))
    (stage production
      (compose (profiles declared agent task memory))
      (prove declared-profile-object profile-payload-projected))))

(def (poo-performance-composition-profiles-bulk)
  (poo-performance-composition-note-construction!)
  (use-composition profiles-bulk-performance
    (use-module crew
      (profiles poo-performance-composition-library
        agent task memory guardrail runtime-handoff))
    (stage production
      (compose (profiles crew agent task memory guardrail runtime-handoff))
      (prove grouped-profile-import grouped-profile-compose))))

(def (poo-performance-composition-local-override)
  (poo-performance-composition-note-construction!)
  (use-composition local-override-performance
    (use-module crew
      (profiles poo-performance-composition-library agent task)
      (profile audited-memory
        :extends (poo-flow-profile-ref
                  poo-performance-composition-library
                  'memory)
        :retention (project-retained audit-log)))
    (stage production
      (compose (profiles crew agent task audited-memory))
      (prove local-override-native-poo))))

(def (poo-performance-composition-hook-override)
  (poo-performance-composition-note-construction!)
  (use-composition hook-override-performance
    (use-module crew
      (profiles poo-performance-composition-library agent task)
      (profile audited-memory
        :extends (poo-flow-profile-ref
                  poo-performance-composition-library
                  'memory)
        :with (poo-performance-audit-retention-hook)))
    (stage production
      (compose (profiles crew agent task audited-memory))
      (prove hook-override-native-poo))))

(def (poo-performance-composition-native-object-reuse)
  (poo-performance-composition-note-construction!)
  (use-composition native-object-reuse-performance
    (use-module artifact
      (profile enterprise-report
        :extends poo-performance-native-enterprise-profile))
    (stage production
      (compose (profile artifact enterprise-report))
      (prove native-object-reused-directly))))

(def (poo-performance-composition-valid-count composition rounds)
  (let* ((stage (car (poo-flow-composition-stages composition)))
         (clause (car (poo-flow-composition-stage-clauses stage)))
         (payload (.ref clause 'payload))
         (payload-count (length payload)))
    (let loop ((round 0) (accepted 0))
      (if (>= round rounds)
        accepted
        (loop (+ round 1)
              (if (> payload-count 0) (+ accepted 1) accepted))))))

(def (poo-performance-composition-profile-declaration-valid-count rounds)
  (poo-performance-composition-valid-count
   (poo-performance-composition-profile-declaration)
   rounds))

(def (poo-performance-composition-profile-declaration-gate-receipt rounds)
  (let (composition (poo-performance-composition-profile-declaration))
    (poo-performance-family-run-gate
     +poo-performance-benchmark-receipt-family+
     (poo-performance-composition-profile-declaration-fixture)
     (lambda () (poo-performance-composition-valid-count composition rounds)))))

(def (poo-performance-composition-profiles-bulk-valid-count rounds)
  (poo-performance-composition-valid-count
   (poo-performance-composition-profiles-bulk)
   rounds))

(def (poo-performance-composition-profiles-bulk-gate-receipt rounds)
  (let (composition (poo-performance-composition-profiles-bulk))
    (poo-performance-family-run-gate
     +poo-performance-benchmark-receipt-family+
     (poo-performance-composition-profiles-bulk-fixture)
     (lambda () (poo-performance-composition-valid-count composition rounds)))))

(def (poo-performance-composition-local-override-valid-count rounds)
  (poo-performance-composition-valid-count
   (poo-performance-composition-local-override)
   rounds))

(def (poo-performance-composition-local-override-gate-receipt rounds)
  (let (composition (poo-performance-composition-local-override))
    (poo-performance-family-run-gate
     +poo-performance-benchmark-receipt-family+
     (poo-performance-composition-local-override-fixture)
     (lambda () (poo-performance-composition-valid-count composition rounds)))))

(def (poo-performance-composition-hook-override-valid-count rounds)
  (poo-performance-composition-valid-count
   (poo-performance-composition-hook-override)
   rounds))

(def (poo-performance-composition-hook-override-gate-receipt rounds)
  (let (composition (poo-performance-composition-hook-override))
    (poo-performance-family-run-gate
     +poo-performance-benchmark-receipt-family+
     (poo-performance-composition-hook-override-fixture)
     (lambda () (poo-performance-composition-valid-count composition rounds)))))

(def (poo-performance-composition-native-object-reuse-valid-count rounds)
  (poo-performance-composition-valid-count
   (poo-performance-composition-native-object-reuse)
   rounds))

(def (poo-performance-composition-native-object-reuse-gate-receipt rounds)
  (let (composition (poo-performance-composition-native-object-reuse))
    (poo-performance-family-run-gate
     +poo-performance-benchmark-receipt-family+
     (poo-performance-composition-native-object-reuse-fixture)
     (lambda () (poo-performance-composition-valid-count composition rounds)))))
