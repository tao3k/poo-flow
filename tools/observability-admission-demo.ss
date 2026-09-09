;;; -*- Gerbil -*-
;;; Run: ./.devenv/devenv-profile-exec gxi tools/observability-admission-demo.ss
;;; A synthetic real Module error; no runtime resources or secrets are involved.
(import (only-in :clan/poo/object .cc .ref)
        "../src/module-system/observability/interface.ss"
        "../src/module-system/observability/debug.ss"
        "../src/module-system/semantic-module/objects.ss")

(def (demo-id name)
  (poo-flow-observation-identity 'demo name 'v1))

(def (run-observability-demo)
  (let* ((context
          (poo-flow-observation-context
           (demo-id 'admission-event) (demo-id 'sample-module) (demo-id 'generation-1)
           '() (poo-flow-observation-provenance
                (demo-id 'module-admission) (demo-id 'gerbil-poo) 'admission)))
         (module (poo-flow-semantic-module (poo-flow-semantic-identity 'demo 'sample-module)))
         (invalid (.cc module 'imports 'not-an-import-relation))
         (event (poo-flow-observe-contract-admission context SemanticModuleContract invalid))
         (explanation (poo-flow-observation-explain event))
         (first-failure (car (.ref explanation 'failures))))
    ;; Explicit local inspection of a known non-sensitive synthetic path.
    (write (list 'failure-path (.ref first-failure 'path)
                 'cause (.ref first-failure 'code)))
    (newline)
    ;; Both the typed printer and traced render method are upstream-owned.
    (poo-flow-observation-debug event (current-output-port) trace?: #t)
    (void)))

(run-observability-demo)
