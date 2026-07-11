;;; -*- Gerbil -*-
;;; Boundary: POO-native runtime handoff manifest projections.

(import (only-in :clan/poo/object .ref object? object<-alist)
        :poo-flow/src/module-system/projection-syntax
        :poo-flow/src/modules/session/objects
        :poo-flow/src/modules/tool-core/objects-spec
        :poo-flow/src/modules/tool-core/objects-support)

(export +poo-flow-tool-core-handoff-manifest-kind+
        poo-flow-tool-handoff-manifest
        poo-flow-tool-handoff-manifest?
        poo-flow-tool-handoff-manifest->alist)

(def +poo-flow-tool-core-handoff-manifest-kind+
  'poo-flow.tool-core.handoff-manifest)

;; : (-> Symbol PooToolSpec [Alist] PooToolHandoffManifest)
(def (poo-flow-tool-handoff-manifest request-id spec . maybe-metadata)
  (poo-flow-session-require "tool handoff request id must be a symbol"
                            (symbol? request-id)
                            request-id)
  (poo-flow-session-require "tool handoff requires a tool spec"
                            (poo-flow-tool-spec? spec)
                            spec)
  (let* ((sandbox-required?
          (poo-flow-tool-spec-sandbox-required? spec))
         (sandbox-profile-ref
          (poo-flow-tool-spec-sandbox-profile-ref spec))
         (diagnostics
          (if (poo-flow-tool-valid-sandbox-profile-ref?
               sandbox-required?
               sandbox-profile-ref)
            '()
            (list
             (poo-flow-tool-field-rows
              (code 'tool-spec-missing-sandbox-profile)
              (tool-ref (poo-flow-tool-spec-ref spec))
              (severity 'error))))))
    (object<-alist
     (list
      (cons 'kind +poo-flow-tool-core-handoff-manifest-kind+)
      (cons 'schema 'poo-flow.modules.tool-core.handoff-manifest.v1)
      (cons 'request-id request-id)
      (cons 'tool-ref (poo-flow-tool-spec-ref spec))
      (cons 'tool-kind (poo-flow-tool-spec-tool-kind spec))
      (cons 'actions (poo-flow-tool-spec-actions spec))
      (cons 'operation (.ref spec 'handoff-operation))
      (cons 'input-schema (.ref spec 'input-schema))
      (cons 'output-schema (.ref spec 'output-schema))
      (cons 'runtime-owner (.ref spec 'runtime-owner))
      (cons 'runtime-backend (.ref spec 'runtime-backend))
      (cons 'sandbox-required? sandbox-required?)
      (cons 'sandbox-profile-ref sandbox-profile-ref)
      (cons 'handoff-ready? (null? diagnostics))
      (cons 'diagnostic-count (length diagnostics))
      (cons 'diagnostics diagnostics)
      (cons 'runtime-executed #f)
      (cons 'metadata (if (null? maybe-metadata)
                          '()
                          (car maybe-metadata)))))))

;; : (-> POOObject Boolean)
(def (poo-flow-tool-handoff-manifest? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            +poo-flow-tool-core-handoff-manifest-kind+)))

;; : (-> PooToolHandoffManifest Alist)
(defpoo-module-final-projection
  poo-flow-tool-handoff-manifest->alist (manifest)
  (bindings ((checked-manifest
              (poo-flow-session-require
               "tool handoff projection requires a handoff manifest"
               (poo-flow-tool-handoff-manifest? manifest)
               manifest))))
  (fields ((kind (.ref checked-manifest 'kind))
           (schema (.ref checked-manifest 'schema))
           (request-id (.ref checked-manifest 'request-id))
           (tool-ref (.ref checked-manifest 'tool-ref))
           (tool-kind (.ref checked-manifest 'tool-kind))
           (actions (.ref checked-manifest 'actions))
           (operation (.ref checked-manifest 'operation))
           (input-schema (.ref checked-manifest 'input-schema))
           (output-schema (.ref checked-manifest 'output-schema))
           (runtime-owner (.ref checked-manifest 'runtime-owner))
           (runtime-backend (.ref checked-manifest 'runtime-backend))
           (sandbox-required? (.ref checked-manifest 'sandbox-required?))
           (sandbox-profile-ref (.ref checked-manifest 'sandbox-profile-ref))
           (handoff-ready? (.ref checked-manifest 'handoff-ready?))
           (diagnostic-count (.ref checked-manifest 'diagnostic-count))
           (diagnostics (.ref checked-manifest 'diagnostics))
           (runtime-executed (.ref checked-manifest 'runtime-executed))
           (metadata (.ref checked-manifest 'metadata)))))
