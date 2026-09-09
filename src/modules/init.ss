;;; -*- Gerbil -*-
;;; Boundary: repository-maintained modules declared with the same hygienic
;;; syntax exported to downstream init.ss files.

(import (only-in "../module-system/load.ss"
                 poo-flow-modules!))

(export poo-flow-modules!
        poo-flow-maintained-module-bundles)

(def poo-flow-maintained-module-bundles
  (poo-flow-modules!
   :flow
   (funflow)
   (loop-engine)
   (workflow)
   (custom-task)
   (text)
   :session
   (session)
   (session-core)
   (tool-core)
   (memory-core)
   (model-core)
   :loop
   (governor)
   :sandbox
   (sandbox-core)
   (agent-sandbox)
   (docker)
   (nono-sandbox)
   (cubeSandbox)
   (docker-sandbox)))
