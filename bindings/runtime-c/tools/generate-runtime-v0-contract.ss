(import :poo-flow/src/contract/runtime-v0-abi-schema)

(def header-path
  "bindings/runtime-c/include/poo_flow/runtime_v0_contract.h")
(def vector-path
  "bindings/runtime-c/tests/vectors/runtime_v0_contract.txt")
(def event-vector-path
  "bindings/runtime-c/tests/vectors/runtime_v0_event_1.txt")

(def (command-line-option name default)
  (let loop ((rest (command-line)))
    (cond
     ((null? rest) default)
     ((equal? (car rest) name)
      (if (pair? (cdr rest))
        (cadr rest)
        (error "missing command-line option value" name)))
     (else (loop (cdr rest))))))

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
(def selected-header-path
  (command-line-option "--header-output" header-path))
(def selected-vector-path
  (command-line-option "--vector-output" vector-path))
(def selected-event-vector-path
  (command-line-option "--event-vector-output" event-vector-path))
(def check? (member "--check" (command-line)))

(if check?
  (unless (and (equal? (read-text selected-header-path) header)
               (equal? (read-text selected-vector-path) vector)
               (equal? (read-text selected-event-vector-path) event-vector))
    (error "stale generated runtime v0 contract artifacts"))
  (begin (write-text selected-header-path header)
         (write-text selected-vector-path vector)
         (write-text selected-event-vector-path event-vector)))
