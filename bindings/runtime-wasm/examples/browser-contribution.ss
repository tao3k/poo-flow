(import :poo-flow/src/core/flow
        :poo-flow/src/core/plan
        :poo-flow/src/core/typescript-plan)

(def (identity value) value)

(def receive-request
  (scheme-flow 'receive-request identity 'request 'request))
(def select-profile
  (scheme-flow 'select-profile identity 'request 'profile))
(def compose-policy
  (scheme-flow 'compose-policy identity 'profile 'policy))
(def execute-scenario
  (scheme-flow 'execute-scenario identity 'policy 'scenario))
(def verify-proof
  (scheme-flow 'verify-proof identity 'scenario 'proof))
(def publish-contribution
  (scheme-flow 'publish-contribution identity 'proof 'contribution))

(def browser-contribution
  (flow-then
   'browser-contribution
   receive-request
   (flow-then
    'browser-contribution/profile
    select-profile
    (flow-then
     'browser-contribution/policy
     compose-policy
     (flow-then
      'browser-contribution/scenario
      execute-scenario
      (flow-then
       'browser-contribution/proof
       verify-proof
       publish-contribution))))))

(execution-plan->typescript-file!
 (flow->linear-plan browser-contribution)
 "generated/browser-contribution.generated.ts")
