;;; -*- Gerbil -*-
;;; Boundary: stable proof ABI tags for loop-engine user-interface projection.
;;; Invariant: this module exposes proof-facing constants and never runs proof
;;; or runtime work.

(export +poo-flow-loop-engine-proof-abi-version+
        +poo-flow-loop-engine-proof-obligation-schema-version+
        +poo-flow-loop-engine-proof-obligation-tags+
        +poo-flow-loop-engine-proof-obligation-domains+
        +poo-flow-loop-engine-proof-obligation-case-families+
        +poo-flow-loop-engine-proof-obligations+
        +poo-flow-loop-engine-proof-obligation-count+
        +poo-flow-loop-engine-proof-required-obligation-mask+
        +poo-flow-loop-engine-proof-abi-tag-width+
        poo-flow-loop-engine-proof-obligation
        poo-flow-loop-engine-proof-obligation-mask
        poo-flow-loop-engine-proof-c-abi
        poo-flow-loop-engine-proof-manifest)

;; : Fixnum
(def +poo-flow-loop-engine-proof-abi-version+ 1)

;; : Fixnum
(def +poo-flow-loop-engine-proof-obligation-schema-version+ 1)

;; : Symbol
(def +poo-flow-loop-engine-proof-abi-tag-width+ 'uint32)

;; : Alist
(def +poo-flow-loop-engine-proof-obligation-tags+
  '((ui-config-well-formed . 1)
    (ui-profile-policy-linked . 2)
    (loop-strategy-plan-well-formed . 4)
    (execution-policy-capability-bounded . 8)
    (policy-strategy-deterministic . 16)
    (runtime-command-inert . 32)
    (workflow-agreement-linked . 64)
    (sandbox-boundary-linked . 128)
    (runtime-handoff-owner-linked . 256)
    (proof-case-vector-complete . 512)))

;; : List
(def +poo-flow-loop-engine-proof-obligation-domains+
  '(user-interface profile policy strategy workflow sandbox runtime-handoff))

;; : List
(def +poo-flow-loop-engine-proof-obligation-case-families+
  '(ui-config profile-policy loop-strategy execution-policy workflow-agreement
              sandbox-boundary runtime-command proof-case-vector))

;; : Fixnum
(def +poo-flow-loop-engine-proof-obligation-count+
  (length +poo-flow-loop-engine-proof-obligation-tags+))

;; : (-> Symbol Symbol Symbol Symbol Symbol List Alist)
(def (poo-flow-loop-engine-proof-obligation name claim source domain case-family evidence-fields)
  (list
   (cons 'name name)
   (cons 'claim claim)
   (cons 'source source)
   (cons 'domain domain)
   (cons 'case-family case-family)
   (cons 'evidence-fields evidence-fields)
   (cons 'runtime-executed #f)))

;; : List
(def +poo-flow-loop-engine-proof-obligations+
  (list
   (poo-flow-loop-engine-proof-obligation
    'ui-config-well-formed
    'all-runtime-handoff-references-are-present
    'scheme-projection
    'user-interface
    'ui-config
    '(request-id artifact-handle object-families runtime-packet-contracts))
   (poo-flow-loop-engine-proof-obligation
    'ui-profile-policy-linked
    'profile-policy-selections-are-carried-into-proof-case
    'profile-policy-packet
    'profile
    'profile-policy
    '(object-families receipt-contracts policy-profile-refs))
   (poo-flow-loop-engine-proof-obligation
    'loop-strategy-plan-well-formed
    'loop-strategy-plan-has-explicit-owner-and-contract
    'loop-strategy-plan
    'strategy
    'loop-strategy
    '(strategy-owner strategy-contract execution-owner))
   (poo-flow-loop-engine-proof-obligation
    'execution-policy-capability-bounded
    'execution-policy-capabilities-are-bounded-by-profile
    'execution-policy
    'policy
    'execution-policy
    '(capabilities frontier cache-policy failure-policy))
   (poo-flow-loop-engine-proof-obligation
    'runtime-command-inert
    'scheme-emits-manifest-without-runtime-execution
    'runtime-command-manifest
    'runtime-handoff
    'runtime-command
    '(runtime-command-contract runtime-executed))
   (poo-flow-loop-engine-proof-obligation
    'policy-strategy-deterministic
    'policy-and-strategy-projection-has-stable-precedence
    'policy-profile-packet
    'policy
    'execution-policy
    '(policy strategy precedence profile))
   (poo-flow-loop-engine-proof-obligation
    'workflow-agreement-linked
    'workflow-agreement-is-carried-into-runtime-envelope
    'workflow-agreement
    'workflow
    'workflow-agreement
    '(workflow-agreement runtime-envelope))
   (poo-flow-loop-engine-proof-obligation
    'sandbox-boundary-linked
    'sandbox-handoff-agreement-is-carried-into-proof-scope
    'sandbox-handoff-agreement
    'sandbox
    'sandbox-boundary
    '(sandbox-handoff-agreement proof-scope))
   (poo-flow-loop-engine-proof-obligation
    'runtime-handoff-owner-linked
    'runtime-handoff-owner-remains-marlin-agent-core
    'runtime-handoff-manifest
    'runtime-handoff
    'runtime-command
    '(runtime-owner runtime-handoff runtime-executed))
   (poo-flow-loop-engine-proof-obligation
    'proof-case-vector-complete
    'proof-case-vector-covers-required-ui-policy-strategy-fields
    'proof-case-vector
    'user-interface
    'proof-case-vector
    '(obligation-tags obligations proof-scope c-abi))))

;; : (-> Alist Fixnum)
(def (poo-flow-loop-engine-proof-obligation-mask tags)
  (if (null? tags)
    0
    (+ (cdar tags)
       (poo-flow-loop-engine-proof-obligation-mask (cdr tags)))))

;; : Fixnum
(def +poo-flow-loop-engine-proof-required-obligation-mask+
  (poo-flow-loop-engine-proof-obligation-mask
   +poo-flow-loop-engine-proof-obligation-tags+))

;; : (-> Alist)
(def (poo-flow-loop-engine-proof-c-abi)
  (list
   (cons 'version +poo-flow-loop-engine-proof-abi-version+)
   (cons 'required-obligation-mask
         +poo-flow-loop-engine-proof-required-obligation-mask+)
   (cons 'obligation-count
         +poo-flow-loop-engine-proof-obligation-count+)
   (cons 'tag-width +poo-flow-loop-engine-proof-abi-tag-width+)
   (cons 'obligation-schema-version
         +poo-flow-loop-engine-proof-obligation-schema-version+)))

;; : (-> Any Any Symbol List List List Alist)
(def (poo-flow-loop-engine-proof-manifest request-id
                                          artifact-handle
                                          runtime-command-contract
                                          object-families
                                          receipt-contracts
                                          runtime-packet-contracts)
  (list
   (cons 'kind 'loop-engine-proof-manifest)
   (cons 'contract 'poo-flow.loop-engine.proof-manifest.v1)
   (cons 'source 'user-config-loop-engine)
   (cons 'proof-owner 'lean)
   (cons 'proof-checker 'axle)
   (cons 'runtime-owner "marlin-agent-core")
   (cons 'scheme-projection
         'poo-flow-user-loop-engine-intent-runtime-command-manifest)
   (cons 'proof-scope
         '(user-interface profile policy strategy workflow sandbox runtime-handoff))
   (cons 'obligation-schema-version
         +poo-flow-loop-engine-proof-obligation-schema-version+)
   (cons 'obligation-domains
         +poo-flow-loop-engine-proof-obligation-domains+)
   (cons 'obligation-case-families
         +poo-flow-loop-engine-proof-obligation-case-families+)
   (cons 'proof-case-vector-contract
         '(name claim source domain case-family evidence-fields runtime-executed))
   (cons 'request-id request-id)
   (cons 'artifact-handle artifact-handle)
   (cons 'runtime-command-contract runtime-command-contract)
   (cons 'object-families object-families)
   (cons 'receipt-contracts receipt-contracts)
   (cons 'runtime-packet-contracts runtime-packet-contracts)
   (cons 'c-abi (poo-flow-loop-engine-proof-c-abi))
   (cons 'obligation-tags +poo-flow-loop-engine-proof-obligation-tags+)
   (cons 'obligations +poo-flow-loop-engine-proof-obligations+)
   (cons 'lean-artifact-kind 'theorem-stubs)
   (cons 'runtime-executed #f)))
