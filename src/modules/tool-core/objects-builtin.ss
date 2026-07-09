;;; -*- Gerbil -*-
;;; Boundary: builtin tool specs and default tool catalog.

(import :poo-flow/src/modules/tool-core/objects-core)

(export poo-flow-tool-core-builtin-read-workspace-file
        poo-flow-tool-core-builtin-write-workspace-file
        poo-flow-tool-core-builtin-run-shell-command
        poo-flow-tool-core-mcp-tool
        poo-flow-tool-core-default-catalog)

;; : PooToolSpec
(def poo-flow-tool-core-builtin-read-workspace-file
  (poo-flow-tool-spec
   'read-workspace-file
   'builtin-filesystem
   '(read)
   '((path . string) (mode . read-only))
   '((content-ref . artifact) (summary . string))
   "marlin-agent-core"
   'tool/read-workspace-file
   #t
   'agent/nono
   'marlin-tool-adapter
   '((builtin . #t))))

;; : PooToolSpec
(def poo-flow-tool-core-builtin-write-workspace-file
  (poo-flow-tool-spec
   'write-workspace-file
   'builtin-filesystem
   '(write)
   '((path . string) (content . string))
   '((artifact-ref . artifact))
   "marlin-agent-core"
   'tool/write-workspace-file
   #t
   'agent/nono
   'marlin-tool-adapter
   '((builtin . #t))))

;; : PooToolSpec
(def poo-flow-tool-core-builtin-run-shell-command
  (poo-flow-tool-spec
   'run-shell-command
   'builtin-command
   '(run)
   '((argv . list) (cwd . string))
   '((exit-status . integer) (stdout-ref . artifact) (stderr-ref . artifact))
   "marlin-agent-core"
   'tool/run-shell-command
   #t
   'agent/nono
   'marlin-tool-adapter
   '((builtin . #t))))

;; : (-> Symbol Symbol [Symbol] Alist Alist [Alist] PooToolSpec)
(def (poo-flow-tool-core-mcp-tool tool-ref
                                  server-ref
                                  actions
                                  input-schema
                                  output-schema
                                  . maybe-metadata)
  (poo-flow-tool-spec
   tool-ref
   'mcp
   actions
   input-schema
   output-schema
   "mcp-runtime"
   'tool/mcp-call
   #f
   #f
   server-ref
   (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : PooToolCatalog
(def poo-flow-tool-core-default-catalog
  (poo-flow-tool-catalog
   'tool-core/default
   (list poo-flow-tool-core-builtin-read-workspace-file
         poo-flow-tool-core-builtin-write-workspace-file
         poo-flow-tool-core-builtin-run-shell-command)
   '((source . poo-flow-tool-core)
     (runtime-executed . #f))))
