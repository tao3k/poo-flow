(export poo-flow-model-core-fast-text-model
        poo-flow-model-core-tool-json-model
        poo-flow-model-core-default-catalog
        poo-flow-model-core-default-selection-policy)

(import :poo-flow/src/modules/model-core/objects)

(def poo-flow-model-core-fast-text-model
  (poo-flow-model-spec
   'fast-text
   'runtime-local
   "local-fast-text"
   '(chat text)
   '(text)
   32768
   4096
   "runtime-model-adapter"
   'model-complete
   'python-runtime
   '((profile . default-fast))))

(def poo-flow-model-core-tool-json-model
  (poo-flow-model-spec
   'tool-json
   'runtime-local
   "local-tool-json"
   '(chat text json tool-calling)
   '(text json)
   65536
   8192
   "runtime-model-adapter"
   'model-complete
   'python-runtime
   '((profile . default-tool-json))))

(def poo-flow-model-core-default-catalog
  (poo-flow-model-catalog
   'model-core-default
   (list poo-flow-model-core-fast-text-model
         poo-flow-model-core-tool-json-model)
   '((owner . model-core)
     (projection . runtime-facing))))

(def poo-flow-model-core-default-selection-policy
  (poo-flow-model-selection-policy
   'default-tool-aware
   '(tool-json fast-text)
   'fast-text
   '(chat text)
   'first-compatible
   '((max-cost-tier . default)
     (latency-class . interactive))
   '((owner . model-core)
     (policy . default))))
