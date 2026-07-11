;;; -*- Gerbil -*-
;;; User Interface reusable case fragment: LangChain-style linear chain.
;;; Invariant: included by load!; the loader owns binding and export.

(use-composition langchain
  (use-module langchain as chain
    (profiles memory prompt model parser no-tool))
  (compose
   (profiles chain memory prompt model parser no-tool))
  (stage production
    (graph langchain-linear-chain)
    (loop #:fuel 1 #:exit parsed-output)
    (prove chain-order
           prompt-before-model
           parser-after-model
           no-implicit-tool-branch)))
