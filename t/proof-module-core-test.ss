;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .cc .o .ref)
        :poo-flow/src/modules/proof/interface)

(export proof-module-core-test)

(def proof-module-core-test
  (test-suite
   "POO Proof Module core"
   (test-case "admits exact artifact receipts and refinement bindings"
     (let* ((tla
             (poo-flow-proof-artifact
              "test/tla" 'tlc 'tla-plus "test/model.tla"
              (poo-flow-proof-digest 'tla-source)
              '(SafetyInvariant) (.o)))
            (lean
             (poo-flow-proof-artifact
              "test/lean" 'lean 'lean "test/Refinement.lean"
              (poo-flow-proof-digest 'lean-source)
              '(safetyRefinement) (.o)))
            (receipt
             (poo-flow-proof-receipt
              "test/lean/receipt" lean 'lean '(safetyRefinement)
              (poo-flow-proof-digest 'lean-build-receipt) #t))
            (impact
             (poo-flow-proof-impact-binding
              "test/tla-to-lean" tla lean
              (.o SafetyInvariant: '(safetyRefinement))))
            (refinement
             (poo-flow-proof-refinement-binding
              "test/refinement" tla lean receipt impact))
            (assurance
             ((.ref PooFlowProofModule. '.admit-assurance)
              "test/assurance" (list tla lean) (list receipt)
              (list refinement))))
       (check (poo-flow-proof-module? PooFlowProofModule.) => #t)
       (check (.ref PooFlowProofModule. 'required-slots)
              => '(artifacts receipts refinements))
       (check (poo-flow-proof-assurance? assurance) => #t)
       (check (.ref assurance 'current?) => #t)
       (check (.ref assurance 'admitted?) => #t)
       (check (hash-get (.ref assurance 'artifact-index) "test/tla")
              => tla)))
   (test-case "changed upstream digest invalidates the exact refinement"
     (let* ((tla
             (poo-flow-proof-artifact
              "test/tla" 'tlc 'tla-plus "test/model.tla"
              (poo-flow-proof-digest 'tla-source)
              '(SafetyInvariant) (.o)))
            (lean
             (poo-flow-proof-artifact
              "test/lean" 'lean 'lean "test/Refinement.lean"
              (poo-flow-proof-digest 'lean-source)
              '(safetyRefinement) (.o)))
            (receipt
             (poo-flow-proof-receipt
              "test/lean/receipt" lean 'lean '(safetyRefinement)
              (poo-flow-proof-digest 'lean-build-receipt) #t))
            (impact
             (poo-flow-proof-impact-binding
              "test/tla-to-lean" tla lean
              (.o SafetyInvariant: '(safetyRefinement))))
            (refinement
             (poo-flow-proof-refinement-binding
              "test/refinement" tla lean receipt impact))
            (changed-tla
             (.cc tla 'content-digest
                  (poo-flow-proof-digest 'changed-tla-source)))
            (assurance
             (poo-flow-proof-assurance
              "test/stale" (list changed-tla lean) (list receipt)
              (list refinement))))
       (check (.ref assurance 'current?) => #f)
       (check (.ref assurance 'admitted?) => #f)))))
