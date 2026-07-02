;;; -*- Gerbil -*-
;;; Boundary: runtime command invocation and response normalization.
;;; Invariant: command execution is adapter-owned; descriptors live elsewhere.

(import :poo-flow/src/core/projection-syntax
        :poo-flow/src/core/runtime-protocol
        (only-in :std/misc/process run-process))

(export make-runtime-command
        runtime-command?
        runtime-command-name
        runtime-command-kind
        runtime-command-invoker
        runtime-command-metadata
        make-procedure-runtime-command
        make-process-runtime-command
        runtime-command-read-response
        make-stdout-runtime-command
        runtime-command-call
        runtime-command-result
        runtime-command-failure-response
        runtime-command-field-rows/tail)

;;; Runtime commands describe the replaceable command/IPC boundary behind the
;;; Rust adapter. The current Scheme tests can install a procedure command;
;;; later Rust or process-backed commands should keep this call shape stable.
;; : (-> Symbol Symbol Invoker Alist RuntimeCommand)
(defstruct runtime-command
  (name
   kind
   invoker
   metadata)
  transparent: #t)

;; : (-> Symbol Invoker [Alist] RuntimeCommand)
(def (make-procedure-runtime-command name invoker . maybe-metadata)
  (make-runtime-command name
                        'procedure
                        invoker
                        (if (null? maybe-metadata) '() (car maybe-metadata))))

;; : (-> Symbol Alist Alist)
(defpoo-core-receipt-projection
  runtime-command-error (code detail)
  (bindings ())
  (fields ((code code)
           (detail detail))))

;; : (-> Alist Symbol Value Alist RuntimeResponseLike)
(defpoo-core-receipt-projection
  runtime-command-failure-response (envelope code detail metadata)
  (bindings ())
  (fields ((schema +runtime-response-schema+)
           (request-id (runtime-alist-ref envelope 'request-id #f))
           (status 'failed)
           (value #f)
           (artifact-handle
            (runtime-alist-ref envelope 'artifact-handle #f))
           (error (runtime-command-error code detail))
           (metadata metadata))))

;;; Runtime command row assembly is a projection-only helper. It keeps row
;;; ordering explicit at call sites while avoiding a second runtime adapter DSL.
;; runtime-command-rows/tail
;;   : (-> Alist Alist Alist)
;;   | contract: ordered runtime-command projection rows followed by tail rows
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (runtime-command-rows/tail '((name . rust)) '((metadata)))
;;       ;; => ((name . rust) (metadata))
;;       ```
;;     %
(def (runtime-command-rows/tail rows tail)
  (append rows tail))

;; runtime-command-field-rows/tail
;;   : (-> Alist RuntimeCommandFieldRow... Alist)
;;   | contract: lower fixed field clauses and append caller-owned tail rows
;;   | doc m%
;;       # Examples
;;
;;       ```scheme
;;       (runtime-command-field-rows/tail '((tail . value)) (name 'rust))
;;       ;; => ((name . rust) (tail . value))
;;       ```
;;     %
(defrules runtime-command-field-rows/tail ()
  ((_ tail (field value) ...)
   (runtime-command-rows/tail
    (list (cons 'field value) ...)
    tail)))

;; : (-> Symbol Path ArgumentsBuilder ResponseDecoder [Alist] RuntimeCommand)
(def (make-process-runtime-command name executable arguments response-decoder . maybe-metadata)
  (let (metadata
        (runtime-command-field-rows/tail
         (if (null? maybe-metadata) '() (car maybe-metadata))
         (executable executable)))
    (make-runtime-command
     name
     'process
     (lambda (envelope)
       (let* ((argv (cons executable
                          (if (procedure? arguments)
                            (arguments envelope)
                            arguments)))
              (stdout (run-process argv)))
         (response-decoder envelope stdout)))
     metadata)))

;;; Stdout protocol commands print one runtime-response s-expression. This keeps
;;; process-backed tests close to the future Rust CLI contract without forcing
;;; each caller to install a custom decoder.
;; : (-> Alist String RuntimeResponseLike)
(def (runtime-command-read-response envelope stdout)
  (with-catch
   (lambda (failure)
     (runtime-command-failure-response envelope
                                       'invalid-runtime-command-stdout
                                       failure
                                       '()))
   (lambda ()
     (call-with-input-string stdout read))))

;; : (-> Symbol Path ArgumentsBuilder [Alist] RuntimeCommand)
(def (make-stdout-runtime-command name executable arguments . maybe-metadata)
  (apply make-process-runtime-command
         name
         executable
         arguments
         runtime-command-read-response
         maybe-metadata))

;; : (-> RuntimeCommandCandidate Alist RuntimeResponseLike)
(def (runtime-command-call command envelope)
  (cond
   ((runtime-command? command)
    ((runtime-command-invoker command) envelope))
   ((procedure? command)
    (command envelope))
   (else
    (runtime-command-failure-response envelope
                                      'invalid-runtime-command
                                      command
                                      '()))))

;;; Runtime command invocation is the narrow process/IPC boundary: the command
;;; sees one stable request envelope and must return a normalizable response.
;; : (-> RuntimeCommand Alist AdapterResult)
(def (runtime-command-result command envelope)
  (with-catch
   (lambda (failure)
     (make-adapter-result
      (runtime-alist-ref envelope 'request-id #f)
      'failed
      #f
      (runtime-alist-ref envelope 'artifact-handle #f)
      (list (cons 'code 'runtime-command-error)
            (cons 'error failure))))
   (lambda ()
     (normalize-runtime-response envelope (runtime-command-call command envelope)))))
