(import :clan/poo/object)

(def model-fast
  (.o (kind 'model)
      (family 'incident-response-model)
      (route 'triage-fast-path)
      (context-window 'short)
      (cost-class 'interactive)))

(def model-batch
  (.o (kind 'model)
      (family 'incident-response-model)
      (route 'triage-fast-path)
      (context-window 'short)
      (cost-class 'interactive)))

(def sandbox-fast
  (.o (kind 'sandbox)
      (family 'incident-response-sandbox)
      (image 'gerbil-runtime)
      (network 'off)
      (cpu 'bounded)))

(def sandbox-batch
  (.o (kind 'sandbox)
      (family 'incident-response-sandbox)
      (image 'gerbil-runtime)
      (network 'off)
      (cpu 'bounded)))

(def pull-request-agent
  (.o (kind 'agent)
      (family 'incident-response-agent)
      (role 'pull-request-triage)
      (model model-fast)
      (sandbox sandbox-fast)))

(def scheduled-audit-agent
  (.o (kind 'agent)
      (family 'incident-response-agent)
      (role 'scheduled-audit)
      (model model-batch)
      (sandbox sandbox-batch)))

(def incident-response-composition
  (.o (kind 'composition)
      (family 'poo-composition-lazy-demand-input)
      (pull-request pull-request-agent)
      (scheduled-audit scheduled-audit-agent)))
