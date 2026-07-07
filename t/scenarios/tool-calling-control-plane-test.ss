(import (only-in :clan/poo/object .o)
        :poo-flow/src/module-system/profile-composition
        :poo-flow/src/module-system/tool-calling-control)

(load "user-interface/profiles/tool-calling.ss")

(def poo-flow-custom-module-tool-calling-module
  (.o (tool-request (.o (name 'tool-calling-request)))
      (tool-schema (.o (name 'tool-calling-schema)))
      (tool-permission (.o (name 'tool-calling-permission)))
      (sandbox-scope (.o (name 'tool-calling-sandbox-scope)))
      (argument-validation (.o (name 'tool-calling-argument-validation)))
      (untrusted-observation (.o (name 'tool-calling-untrusted-observation)))
      (tool-cooldown (.o (name 'tool-calling-cooldown)))
      (result-contract (.o (name 'tool-calling-result-contract)))
      (runtime-binding (.o (name 'tool-calling-runtime-binding)))
      (receipt-gate (.o (name 'tool-calling-receipt-gate)))
      (observability (.o (name 'tool-calling-observability)))))

(def tool-calling-composition-fragment
  (load "user-interface/cases/tool-calling-agent-loop.ss"))

(unless poo-flow-custom-module-tool-calling-module
  (error "Tool calling profile module did not load"))

(unless tool-calling-composition-fragment
  (error "Tool calling composition fragment did not load"))

(def tool-call-plan
  (poo-flow-tool-call-plan
   'tool-calling-agent-loop
   'session-1
   'search-tool
   '(query limit)
   '(query)
   'allow-search
   'sandbox-readonly
   'retry-after-policy-window
   'search-result
   'python-runtime-tool-plane
   '(tool-request permission-check argument-validation runtime-call tool-result)))

(def tool-call-receipt
  (poo-flow-tool-call-runtime-receipt
   'tool-calling-agent-loop
   'session-1
   'search-tool
   '(query limit)
   #t
   #t
   #t
   #t
   #t
   'python-runtime-tool-plane
   '(tool-request permission-check argument-validation runtime-call tool-result)
   #f
   'completed))

(unless (poo-flow-tool-call-plan-valid? tool-call-plan)
  (error "Tool calling plan should be valid"))

(unless (poo-flow-tool-call-receipt-matches-plan? tool-call-plan tool-call-receipt)
  (error "Tool calling runtime receipt should match plan"))

(def tool-call-facts
  (poo-flow-tool-call-runtime-proof-facts tool-call-plan tool-call-receipt))

(unless (poo-flow-tool-call-fact-ref tool-call-facts
                                     'runtime-receipt-matches-tool-plan)
  (error "Tool calling runtime facts should prove receipt/plan match"))

(unless (poo-flow-tool-call-fact-ref tool-call-facts
                                     'tool-output-cannot-authorize-policy)
  (error "Tool output must not authorize policy"))

(void)
