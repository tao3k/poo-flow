(import (only-in :clan/poo/object .o)
        :poo-flow/src/module-system/profile-composition
        :poo-flow/src/module-system/tool-calling-control)

(def tool-calling
  (eval (call-with-input-file "user-interface/profiles/tool-calling.ss" read)))

(def poo-flow-custom-module-tool-calling-module tool-calling)

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

(def tool-call-facts
  (poo-flow-tool-call-runtime-validation-proof-facts tool-call-plan
                                                     tool-call-receipt))

(def tool-call-fact-family
  (poo-flow-tool-call-fact-family
   'poo-flow-tool-call-runtime-validation-proof-facts
   'poo-flow.tool-calling.control.runtime))

(unless (equal? (poo-flow-tool-call-fact-ref tool-call-facts 'fact-family)
                'poo-flow-tool-call-runtime-validation-proof-facts)
  (error "Tool calling facts should carry reusable fact family identity"))

(unless (poo-flow-tool-call-fact-family-ref tool-call-fact-family
                                            tool-call-facts
                                            'plan-valid)
  (error "Tool calling fact family should read matching fact sets"))

(unless (poo-flow-tool-call-fact-ref tool-call-facts 'plan-valid)
  (error "Tool calling plan should be valid"))

(unless (poo-flow-tool-call-fact-ref tool-call-facts
                                     'runtime-receipt-matches-tool-plan)
  (error "Tool calling runtime facts should prove receipt/plan match"))

(unless (poo-flow-tool-call-fact-ref tool-call-facts
                                     'tool-output-cannot-authorize-policy)
  (error "Tool output must not authorize policy"))

(void)
