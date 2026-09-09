;;; -*- Gerbil -*-
;;; Boundary: repository-maintained modules declared with the same hygienic
;;; syntax exported to downstream init.ss files.

(import "../module-system/load.ss")

(export (import: "../module-system/load.ss")
        poo-flow-maintained-module-bundles)

(def poo-flow-maintained-module-bundles
  (poo-flow-modules!
   :core
   (poo-method-combination)
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
