;;; -*- Gerbil -*-
;;; Boundary: CI/CD sandbox profile inheritance and runtime-readiness facts.
;;; Invariant: unresolved profile refs stay visible; no fallback profile is fabricated.

(import (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/modules/agent-sandbox/config
                 poo-flow-sandbox-profile?
                 poo-flow-sandbox-profile-by-name
                 poo-flow-sandbox-profile-handoff-summary
                 poo-flow-sandbox-profile-name
                 poo-flow-sandbox-profile-runtime-summary)
        :poo-flow/src/modules/workflow/cicd-core)

(export poo-flow-cicd-check-profile-refs
        poo-flow-cicd-check-sandbox-runtime-summaries
        poo-flow-cicd-check-sandbox-handoff-summaries
        poo-flow-cicd-check-sandbox-unresolved-profile-refs
        poo-flow-cicd-check->runtime-manifest-readiness)

;;; Profile refs are an inheritance surface, not graph edges. This collector
;;; flattens symbol refs and inline profile objects into runtime catalog names.
;; : (-> PooFlowCicdProfileRef [Symbol] [Symbol])
(def (poo-flow-cicd-profile-refs/add profile refs)
  (cond
   ((symbol? profile)
    (poo-flow-cicd-symbol-add profile refs))
   ((poo-flow-sandbox-profile? profile)
    (poo-flow-cicd-symbol-add
     (poo-flow-sandbox-profile-name profile)
     refs))
   ((and (pair? profile) (list? profile))
    (poo-flow-cicd-profile-refs/list-add profile refs))
   (else refs)))

;;; Nested profile-ref lists preserve left-to-right inheritance order while
;;; flattening the runtime-facing catalog refs.
;; : (-> [PooFlowCicdProfileRef] [Symbol] [Symbol])
(def (poo-flow-cicd-profile-refs/list-add profiles refs)
  (cond
   ((null? profiles) refs)
   (else
    (poo-flow-cicd-profile-refs/list-add
     (cdr profiles)
     (poo-flow-cicd-profile-refs/add (car profiles) refs)))))

;; : (-> PooFlowCicdCheck [Symbol])
(def (poo-flow-cicd-check-profile-refs check)
  (poo-flow-cicd-profile-refs/add (poo-flow-cicd-check-profile check) '()))

;;; Sandbox profile lookup accepts inline POO profiles and catalog symbols. It
;;; never constructs fallback profiles, so unresolved refs remain visible.
;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] MaybePooSandboxProfile)
(def (poo-flow-cicd-profile-ref->sandbox-profile profile profile-catalog)
  (cond
   ((poo-flow-sandbox-profile? profile) profile)
   ((symbol? profile)
    (poo-flow-sandbox-profile-by-name profile-catalog profile))
   (else #f)))

;; : (-> [Value] [Value] [Value])
(def (poo-flow-cicd-profile-projection-values/rev values results)
  (let loop ((remaining-values values)
             (result-values results))
    (if (null? remaining-values)
      result-values
      (loop (cdr remaining-values)
            (cons (car remaining-values) result-values)))))

;; : (-> Procedure [PooFlowCicdProfileRef] [PooSandboxProfile] [Value] [Value])
(def (poo-flow-cicd-profile-projections/list-rev projector
                                                    profiles
                                                    profile-catalog
                                                    results)
  (cond
   ((null? profiles) results)
   (else
    (poo-flow-cicd-profile-projections/list-rev
     projector
     (cdr profiles)
     profile-catalog
     (poo-flow-cicd-profile-projections/rev
      projector
      (car profiles)
      profile-catalog
      results)))))

;; : (-> Procedure PooFlowCicdProfileRef [PooSandboxProfile] [Value] [Value])
(def (poo-flow-cicd-profile-projections/rev projector
                                            profile
                                            profile-catalog
                                            results)
  (if (and (pair? profile) (list? profile))
    (poo-flow-cicd-profile-projections/list-rev
     projector
     profile
     profile-catalog
     results)
    (poo-flow-cicd-profile-projection-values/rev
     (projector profile profile-catalog)
     results)))

;; : (-> Procedure PooFlowCicdProfileRef [PooSandboxProfile] [Value])
(def (poo-flow-cicd-profile-projections projector profile profile-catalog)
  (reverse
   (poo-flow-cicd-profile-projections/rev
    projector
    profile
    profile-catalog
    '())))

;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-profile-runtime-summary-values profile profile-catalog)
  (cond
   ((poo-flow-cicd-profile-ref->sandbox-profile profile profile-catalog)
    => (lambda (sandbox-profile)
         (list (poo-flow-sandbox-profile-runtime-summary sandbox-profile))))
   (else '())))

;;; Runtime summaries follow profile inheritance recursively. Missing catalog
;;; refs are skipped here and reported by the unresolved-ref projection.
;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-profile-runtime-summaries profile profile-catalog)
  (poo-flow-cicd-profile-projections
   poo-flow-cicd-profile-runtime-summary-values
   profile
   profile-catalog))

;;; Boundary: cicd check sandbox runtime summaries is the policy-visible edge
;;; for sandbox, workflow behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooFlowCicdCheck [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-check-sandbox-runtime-summaries check
                                                    . maybe-profile-catalog)
  (poo-flow-cicd-profile-runtime-summaries
   (poo-flow-cicd-check-profile check)
   (if (null? maybe-profile-catalog) '() (car maybe-profile-catalog))))

;;; Handoff summaries mirror runtime summaries so both report paths preserve
;;; the same inherited profile order.
;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-profile-handoff-summary-values profile profile-catalog)
  (cond
   ((poo-flow-cicd-profile-ref->sandbox-profile profile profile-catalog)
    => (lambda (sandbox-profile)
         (list (poo-flow-sandbox-profile-handoff-summary sandbox-profile))))
   (else '())))

;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-profile-handoff-summaries profile profile-catalog)
  (poo-flow-cicd-profile-projections
   poo-flow-cicd-profile-handoff-summary-values
   profile
   profile-catalog))

;;; Boundary: cicd check sandbox handoff summaries is the policy-visible edge
;;; for sandbox, workflow behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> PooFlowCicdCheck [PooSandboxProfile] [Alist])
(def (poo-flow-cicd-check-sandbox-handoff-summaries check
                                                    . maybe-profile-catalog)
  (poo-flow-cicd-profile-handoff-summaries
   (poo-flow-cicd-check-profile check)
   (if (null? maybe-profile-catalog) '() (car maybe-profile-catalog))))

;;; Unresolved profile refs are the safety signal for fake or incomplete CI
;;; profiles. Inline POO profiles are already resolved and never reported.
;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] [Symbol])
(def (poo-flow-cicd-profile-unresolved-ref-values profile profile-catalog)
  (cond
   ((symbol? profile)
    (if (poo-flow-sandbox-profile-by-name profile-catalog profile)
      '()
      (list profile)))
   ((poo-flow-sandbox-profile? profile) '())
   (else '())))

;; : (-> PooFlowCicdProfileRef [PooSandboxProfile] [Symbol])
(def (poo-flow-cicd-profile-unresolved-refs profile profile-catalog)
  (poo-flow-cicd-profile-projections
   poo-flow-cicd-profile-unresolved-ref-values
   profile
   profile-catalog))

;;; Boundary: cicd check sandbox unresolved profile refs is the policy-visible
;;; edge for sandbox, workflow behavior, keeping validation, lookup, or
;;; projection responsibilities centralized for callers.
;; : (-> PooFlowCicdCheck [PooSandboxProfile] [Symbol])
(def (poo-flow-cicd-check-sandbox-unresolved-profile-refs
      check
      . maybe-profile-catalog)
  (poo-flow-cicd-profile-unresolved-refs
   (poo-flow-cicd-check-profile check)
   (if (null? maybe-profile-catalog) '() (car maybe-profile-catalog))))

;;; Runtime readiness is a manifest-shaped promise. It is deliberately not a
;;; RuntimeCommandDescriptor because CI checks still need a sandbox/runtime owner
;;; to materialize the command envelope.
;; : (-> PooFlowCicdCheck [PooSandboxProfile] Alist)
(def (poo-flow-cicd-check->runtime-manifest-readiness check
                                                        . maybe-profile-catalog)
  (poo-flow-cicd-require "runtime manifest readiness requires a cicd check"
                         (poo-flow-cicd-check? check)
                         check)
  (let (profile-catalog (if (null? maybe-profile-catalog)
                          '()
                          (car maybe-profile-catalog)))
    (list (cons 'schema +poo-flow-cicd-runtime-manifest-readiness-schema+)
          (cons 'kind 'poo-flow.workflow.cicd.runtime-manifest-ready)
          (cons 'check (poo-flow-cicd-check-name check))
          (cons 'profile (poo-flow-cicd-check-profile check))
          (cons 'profile-refs (poo-flow-cicd-check-profile-refs check))
          (cons 'dependency-refs
                (poo-flow-cicd-check-dependency-refs check))
          (cons 'sandbox-runtime-summaries
                (poo-flow-cicd-check-sandbox-runtime-summaries
                 check
                 profile-catalog))
          (cons 'sandbox-handoff-summaries
                (poo-flow-cicd-check-sandbox-handoff-summaries
                 check
                 profile-catalog))
          (cons 'sandbox-unresolved-profile-refs
                (poo-flow-cicd-check-sandbox-unresolved-profile-refs
                 check
                 profile-catalog))
          (cons 'runtime (poo-flow-cicd-check-runtime check))
          (cons 'runtime-executed #f)
          (cons 'handoff-required #t)
          (cons 'command (poo-flow-cicd-check-command check))
          (cons 'argv (poo-flow-cicd-check-command check))
          (cons 'inputs (.ref check 'input-bindings))
          (cons 'config (.ref check 'config-sources))
          (cons 'artifacts (poo-flow-cicd-check-artifacts check))
          (cons 'durable-task-id
                (poo-flow-cicd-check-durable-task-id check))
          (cons 'action-class
                (poo-flow-cicd-check-action-class check))
          (cons 'artifact-refs
                (poo-flow-cicd-check-artifacts check))
          (cons 'artifact-retention
                (poo-flow-cicd-check-artifact-retention check))
          (cons 'sandbox-refs
                (poo-flow-cicd-check-profile-refs check))
          (cons 'checkpoint-ref
                (list 'workflow-cicd-check
                      (poo-flow-cicd-check-name check)))
          (cons 'compensation-refs
                (poo-flow-cicd-check-compensation-refs check))
          (cons 'cache (poo-flow-cicd-check-cache check))
          (cons 'secrets (poo-flow-cicd-check-secrets check))
          (cons 'result (.ref check 'result-protocol)))))
