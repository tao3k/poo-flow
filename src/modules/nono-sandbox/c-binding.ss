;;; -*- Gerbil -*-
;;; Owner: public facade for nono-sandbox C binding contract projection.
;;; Boundary: C binding belongs to the sandbox/nono-sandbox module category.
;;; Runtime contract: leaf modules emit data only; native execution stays outside Scheme.

(import :poo-flow/src/modules/nono-sandbox/c-binding-descriptor
        :poo-flow/src/modules/nono-sandbox/c-binding-runtime)

(export (import: :poo-flow/src/modules/nono-sandbox/c-binding-descriptor)
        (import: :poo-flow/src/modules/nono-sandbox/c-binding-runtime))
