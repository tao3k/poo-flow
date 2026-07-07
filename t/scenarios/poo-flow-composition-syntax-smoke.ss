;;; -*- Gerbil -*-
;;; Boundary: direct syntax smoke for POO-native composition macros.

(import (only-in :clan/poo/object .o .ref)
        :poo-flow/src/module-system/profile-composition)

(def session-module
  (.o (hardened (.o (name 'session-hardened)))))

(def sandbox-module
  (.o (restricted (.o (name 'sandbox-restricted)))))

(def syntax-smoke-composition
  (poo-flow-composition syntax-smoke
    (modules
     (use-module session-module #:as session)
     (use-module sandbox-module #:as sandbox))
    (stage production
      (compose
       (profile session hardened)
       (profile sandbox restricted))
      (graph guarded-flow)
      (loop #:fuel 2 #:exit done))))

(unless (poo-flow-composition? syntax-smoke-composition)
  (error "syntax smoke did not build a composition object"))

(let* ((stage (car (poo-flow-composition-stages syntax-smoke-composition)))
       (profiles (poo-flow-composition-stage-compose-profiles stage)))
  (unless (equal? (map (lambda (profile) (.ref profile 'name)) profiles)
                  '(session-hardened sandbox-restricted))
    (error "syntax smoke selected the wrong profile slots")))

(def report/base
  (.o (name 'report/base)
      (kind 'report)
      (scope '(session human-handoff publish-channel))
      (storage '(file object vector))
      (analysis '(checksum schema))
      (publish '(human-approved proof-gated))))

(def (with-audit-retention profile)
  (.o (:extends profile)
      (retention '(project-retained audit-log))
      (analysis (append (.ref profile 'analysis)
                        '(provenance citation-trace)))))

(def enterprise-report
  (.o (:extends report/base)
      (name 'enterprise-report)
      (publish '(human-approved legal-review proof-gated))
      (retention '(seven-years audit-log))))

(def native-poo-extension-composition
  (use-composition native-poo-extension
    (use-module artifact
      (profile research-report
        :extends report/base
        :analysis (checksum schema provenance)
        :publish (human-approved proof-gated))
      (profile audited-report
        :extends report/base
        :with (with-audit-retention)
        :publish (human-approved proof-gated internal-registry))
      (profile enterprise-report))
    (stage production
      (compose
       (profiles artifact
         research-report
         audited-report
         enterprise-report))
      (graph artifact-control-plane)
      (loop #:fuel 1 #:exit publish-ready)
      (prove artifact-scope-contained
             audit-retention-attached
             native-poo-object-reused))))

(let* ((artifact
        (cdr (car (poo-flow-composition-modules
                   native-poo-extension-composition))))
       (research-report (.ref artifact 'research-report))
       (audited-report (.ref artifact 'audited-report))
       (enterprise-report* (.ref artifact 'enterprise-report))
       (stage (car (poo-flow-composition-stages
                    native-poo-extension-composition)))
       (profiles (poo-flow-composition-stage-compose-profiles stage)))
  (unless (and (equal? (.ref research-report 'scope)
                       '(session human-handoff publish-channel))
               (equal? (.ref research-report 'analysis)
                       '(checksum schema provenance)))
    (error "inline :extends did not inherit base fields with local overrides"))
  (unless (and (equal? (.ref audited-report 'retention)
                       '(project-retained audit-log))
               (equal? (.ref audited-report 'analysis)
                       '(checksum schema provenance citation-trace)))
    (error "inline :with did not apply native POO profile hook"))
  (unless (eq? enterprise-report* enterprise-report)
    (error "inline profile did not reuse the native POO object"))
  (unless (equal? (map (lambda (profile) (.ref profile 'name)) profiles)
                  '(research-report audited-report enterprise-report))
    (error "native POO extension composition selected wrong profiles")))
