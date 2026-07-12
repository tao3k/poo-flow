(import :poo-flow/src/contract/runtime-v0-abi-schema)

(def header-path
  "bindings/runtime-c/include/poo_flow/runtime_v0_contract.h")
(def vector-path
  "bindings/runtime-c/tests/vectors/runtime_v0_contract.txt")
(def event-vector-path
  "bindings/runtime-c/tests/vectors/runtime_v0_event_1.txt")

(def (read-text path)
  (let ((port (open-input-file path)) (out (open-output-string)))
    (let loop ()
      (let (value (read-char port))
        (unless (eof-object? value)
          (write-char value out)
          (loop))))
    (close-input-port port)
    (get-output-string out)))

(def (write-text path content)
  (let (port (open-output-file path))
    (display content port)
    (close-output-port port)))

(def header
  (poo-flow-runtime-v0-abi-schema->c-header
   +poo-flow-runtime-v0-abi-schema+))
(def vector
  (poo-flow-runtime-v0-abi-schema->vector
   +poo-flow-runtime-v0-abi-schema+))
(def event-vector
  (poo-flow-runtime-v0-abi-schema->event-vector
   +poo-flow-runtime-v0-abi-schema+))
(def check? (member "--check" (command-line)))

(if check?
  (unless (and (equal? (read-text header-path) header)
               (equal? (read-text vector-path) vector)
               (equal? (read-text event-vector-path) event-vector))
    (error "stale generated runtime v0 contract artifacts"))
  (begin (write-text header-path header)
         (write-text vector-path vector)
         (write-text event-vector-path event-vector)))
