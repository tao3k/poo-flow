;;; -*- Gerbil -*-
;;; Boundary: stable proof ABI tags for loop-engine user-interface projection.
;;; Invariant: this module exposes proof-facing constants and never runs proof
;;; or runtime work.

(export +poo-flow-loop-engine-proof-abi-version+
        +poo-flow-loop-engine-proof-obligation-tags+
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

;; : Symbol
(def +poo-flow-loop-engine-proof-abi-tag-width+ 'uint32)

;; : Alist
(def +poo-flow-loop-engine-proof-obligation-tags+
  '((ui-config-well-formed . 1)
    (runtime-command-inert . 2)
    (policy-strategy-deterministic . 4)
    (workflow-agreement-linked . 8)
    (sandbox-boundary-linked . 16)))

;; : Fixnum
(def +poo-flow-loop-engine-proof-obligation-count+
  (length +poo-flow-loop-engine-proof-obligation-tags+))

;; : (-> Symbol Symbol Symbol Alist)
(def (poo-flow-loop-engine-proof-obligation name claim source)
  (list
   (cons 'name name)
   (cons 'claim claim)
   (cons 'source source)))

;; : List
(def +poo-flow-loop-engine-proof-obligations+
  (list
   (poo-flow-loop-engine-proof-obligation
    'ui-config-well-formed
    'all-runtime-handoff-references-are-present
    'scheme-projection)
   (poo-flow-loop-engine-proof-obligation
    'runtime-command-inert
    'scheme-emits-manifest-without-runtime-execution
    'runtime-command-manifest)
   (poo-flow-loop-engine-proof-obligation
    'policy-strategy-deterministic
    'policy-and-strategy-projection-has-stable-precedence
    'policy-profile-packet)
   (poo-flow-loop-engine-proof-obligation
    'workflow-agreement-linked
    'workflow-agreement-is-carried-into-runtime-envelope
    'workflow-agreement)
   (poo-flow-loop-engine-proof-obligation
    'sandbox-boundary-linked
    'sandbox-handoff-agreement-is-carried-into-proof-scope
    'sandbox-handoff-agreement)))

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
   (cons 'tag-width +poo-flow-loop-engine-proof-abi-tag-width+)))

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
         '(user-interface policy strategy workflow runtime-handoff))
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
