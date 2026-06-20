;;; -*- Gerbil -*-
;;; Owner: public facade for nono-sandbox C binding contract projection.
;;; Boundary: C binding belongs to the sandbox/nono-sandbox module category.
;;; Runtime contract: manifest owners emit data; native.ss owns gated FFI probes.

(import :poo-flow/src/modules/nono-sandbox/c-binding-build
        :poo-flow/src/modules/nono-sandbox/c-binding-descriptor
        :poo-flow/src/modules/nono-sandbox/c-binding-runtime
        :poo-flow/src/modules/nono-sandbox/native)

(export (import: :poo-flow/src/modules/nono-sandbox/c-binding-build)
        (import: :poo-flow/src/modules/nono-sandbox/c-binding-descriptor)
        (import: :poo-flow/src/modules/nono-sandbox/c-binding-runtime)
        (import: :poo-flow/src/modules/nono-sandbox/native))
