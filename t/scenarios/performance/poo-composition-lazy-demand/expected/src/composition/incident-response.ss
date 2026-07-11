(import :clan/poo/object)

(def (shared-model-route-value)
  'triage-fast-path)

(def (shared-sandbox-image-value)
  'gerbil-runtime)

(def (unused-model-route-value)
  'cold-path)

(def shared-model-value
  (.o (kind 'model)
      (family 'incident-response-model)
      (route (shared-model-route-value))
      (context-window 'short)
      (cost-class 'interactive)))

(def shared-sandbox-value
  (.o (kind 'sandbox)
      (family 'incident-response-sandbox)
      (image (shared-sandbox-image-value))
      (network 'off)
      (cpu 'bounded)))

(def pull-request-agent-value
  (.o (kind 'agent)
      (family 'incident-response-agent)
      (role 'pull-request-triage)
      (model shared-model-value)
      (sandbox shared-sandbox-value)))

(def scheduled-audit-agent-value
  (.o (kind 'agent)
      (family 'incident-response-agent)
      (role 'scheduled-audit)
      (model shared-model-value)
      (sandbox shared-sandbox-value)))

(def unused-candidate-agent-value
  (.o (kind 'agent)
      (family 'incident-response-agent)
      (role 'unused-candidate)
      (model (.o (kind 'model)
                 (family 'incident-response-model)
                 (route (unused-model-route-value))
                 (context-window 'long)
                 (cost-class 'batch)))
      (sandbox shared-sandbox-value)))

(def incident-response-composition
  (.o (kind 'composition)
      (family 'poo-composition-lazy-demand-expected)
      (pull-request pull-request-agent-value)
      (scheduled-audit scheduled-audit-agent-value)
      (unused-candidate unused-candidate-agent-value)))
