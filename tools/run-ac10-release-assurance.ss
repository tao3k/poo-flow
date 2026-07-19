;;; -*- Gerbil -*-
(import :gerbil/gambit
        :clan/poo/object
        :poo-flow/src/contract/release-assurance-manifest
        :poo-flow/src/qualification/agentic-control-plane-fixture
        :poo-flow/src/qualification/release-assurance
        :poo-flow/src/qualification/runner)

(def args (cddr (command-line)))
(unless (= (length args) 1)
  (displayln "usage: gxi tools/run-ac10-release-assurance.ss SOURCE_REVISION")
  (exit 64))

(def revision (car args))
(def registry (poo-flow-agentic-control-plane-gate-registry))
(def run (poo-flow-qualification-run registry revision 'release))
(def fixture (poo-flow-agentic-control-plane-canonical-fixture))
(def assurance
  (poo-flow-ac10-release-assurance-assemble
   run fixture 'darwin-arm64
   '((gerbil . "0.18.2") (python . "3.13.11") (lean . "locked-lake"))))
(def identity (.ref assurance 'manifest-identity))
(write
 (list (cons 'schema 'poo-flow.ac10-release-assurance-receipt.v1)
       (cons 'accepted? (.ref assurance 'accepted?))
       (cons 'source-revision revision)
       (cons 'manifest-digest (.ref identity 'digest))
       (cons 'claim-count
             (length
              (poo-flow-release-assurance-manifest-claims
               (.ref assurance 'manifest))))
       (cons 'gate-count
             (length (.ref run 'gate-receipts)))
       (cons 'abi-v1-frozen? #f)))
(newline)
(exit 0)
