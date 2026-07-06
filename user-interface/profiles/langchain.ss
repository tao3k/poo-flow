;;; -*- Gerbil -*-
;;; User Interface reusable profile fragment: LangChain-style linear chain.
;;; Invariant: included by load!; the loader owns imports and generated export.

(.o (memory (.o (name 'langchain-stateless-memory)
                (contract 'no-cross-turn-state)
                (policy 'memory-is-optional)))
    (prompt (.o (name 'langchain-prompt-template)
                (contract 'input-to-prompt)
                (policy 'prompt-before-model)))
    (model (.o (name 'langchain-chat-model)
               (contract 'single-turn-input-output)
               (policy 'model-call-is-terminal)))
    (parser (.o (name 'langchain-output-parser)
                (contract 'model-output-to-value)
                (policy 'parser-after-model)))
    (no-tool (.o (name 'langchain-no-tool)
                 (contract 'model-only-chain)
                 (policy 'no-tool-call-branch))))
