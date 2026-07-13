(import :std/test
        :gslph/src/testing/memory-profile
        :clan/poo/object
        :poo-flow/src/qualification/runtime-symbol-manifest)

(declare-gxtest-memory-exception '((maxHeapMiB . 512)))

(def (read-manifest json)
  (poo-flow-runtime-symbol-manifest-read (open-input-string json)))

(def valid-json
  "{\"schema\":\"poo-flow.runtime-symbol-manifest.v1\",\"schemaVersion\":1,\"abi\":\"runtime-v0.1\",\"requiredSymbols\":[\"poo_flow_runtime_v0_open\"],\"forbiddenFragments\":[\"graph\",\"compat\",\"legacy\"],\"owners\":[\"runtime_v0.h\"]}")

(def runtime-symbol-manifest-test
  (test-suite "AC-11 runtime symbol JSON manifest"
    (test-case "valid manifest and exact symbols pass"
      (let (receipt
            (poo-flow-runtime-symbol-manifest-verify
             (read-manifest valid-json)
             '("poo_flow_runtime_v0_open")))
        (check (.ref receipt 'accepted?) => #t)
        (check (.ref receipt 'diagnostics) => '())))
    (test-case "symbol drift fails closed"
      (let (receipt
            (poo-flow-runtime-symbol-manifest-verify
             (read-manifest valid-json)
             '("poo_flow_runtime_v0_open" "poo_flow_runtime_v0_extra")))
        (check (.ref receipt 'accepted?) => #f)
        (check (.ref receipt 'diagnostics) => '(exported-symbol-drift))))
    (test-case "unknown schema version fails closed"
      (let (receipt
            (poo-flow-runtime-symbol-manifest-verify
             (read-manifest
              "{\"schema\":\"poo-flow.runtime-symbol-manifest.v1\",\"schemaVersion\":2,\"abi\":\"runtime-v0.1\",\"requiredSymbols\":[],\"forbiddenFragments\":[],\"owners\":[]}")
             '()))
        (check (.ref receipt 'accepted?) => #f)
        (check (.ref receipt 'diagnostics)
               => '(invalid-or-unknown-manifest))))
    (test-case "malformed manifest shape fails closed"
      (let (receipt
            (poo-flow-runtime-symbol-manifest-verify
             (read-manifest
              "{\"schema\":\"poo-flow.runtime-symbol-manifest.v1\",\"schemaVersion\":1}")
             '()))
        (check (.ref receipt 'accepted?) => #f)
        (check (.ref receipt 'diagnostics)
               => '(invalid-or-unknown-manifest))))
    (test-case "malformed JSON fails closed"
      (let (receipt
            (poo-flow-runtime-symbol-manifest-verify
             (read-manifest "{\"schema\":") '()))
        (check (.ref receipt 'accepted?) => #f)
        (check (.ref receipt 'diagnostics)
               => '(invalid-or-unknown-manifest))))))

(run-tests! runtime-symbol-manifest-test)
