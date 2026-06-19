;;; -*- Gerbil -*-
;;; Owner: public facade for nono C binding contract projection.
;;; Boundary: public import path remains stable while descriptor/runtime owners split.
;;; Runtime contract: leaf modules emit data only; native execution stays outside Scheme.

(import :extensions/agent-sandbox-nono-c-binding-descriptor
        :extensions/agent-sandbox-nono-c-binding-runtime)

(export (import: :extensions/agent-sandbox-nono-c-binding-descriptor)
        (import: :extensions/agent-sandbox-nono-c-binding-runtime))
