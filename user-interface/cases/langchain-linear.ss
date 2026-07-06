;;; -*- Gerbil -*-
;;; User Interface reusable case fragment: LangChain-style linear chain.
;;; Invariant: included by load!; the loader owns binding and export.

(use-composition langchain-linear-composition
  (modules
   (use-profile langchain #:as chain))
  (stage production
    (compose
     (profile chain memory)
     (profile chain prompt)
     (profile chain model)
     (profile chain parser)
     (profile chain no-tool))
    (graph langchain-linear-chain)
    (loop #:fuel 1 #:exit parsed-output)
    (prove chain-order
           prompt-before-model
           parser-after-model
           no-implicit-tool-branch)))
