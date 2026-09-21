;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; User Interface reusable Profile library: LangChain-style linear chain.

(import (only-in :clan/poo/object .def .o))
(export langchain)

(.def langchain
    (memory (.o (name 'langchain-stateless-memory)
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
