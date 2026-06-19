;;; -*- Gerbil -*-
;;; Owner: public facade for nono-sandbox C binding contract projection.
;;; Boundary: C binding belongs to the sandbox/nono-sandbox module category.
;;; Runtime contract: leaf modules emit data only; native execution stays outside Scheme.

(import :modules/nono-sandbox/c-binding-descriptor
        :modules/nono-sandbox/c-binding-runtime)

(export (import: :modules/nono-sandbox/c-binding-descriptor)
        (import: :modules/nono-sandbox/c-binding-runtime))
