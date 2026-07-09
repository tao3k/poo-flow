;;; Boundary: durable runtime manifests describe resumable runtime state at the
;;; Scheme control-plane edge before provider-specific recovery executes.
;;; Invariant: manifest serialization must remain bounded and deterministic for
;;; policy reports, Marlin handoff, and checkpoint replay.
(import :gerbil/gambit
        :poo-flow/src/module-system/durable-policy-manifest
        :poo-flow/src/module-system/durable-runtime-store
        :poo-flow/src/module-system/durable-runtime-store-backend)

(export +poo-flow-durable-runtime-envelope-schema+
        poo-flow-durable-runtime-manifest-alist
        poo-flow-durable-runtime-manifest-string
        poo-flow-durable-runtime-manifest-bytes)

(def +poo-flow-durable-runtime-envelope-schema+
  'poo-flow.durable.runtime-envelope.v1)

;;; Boundary: runtime manifest alists are the bounded ABI projection from
;;; internal durable runtime state into policy and handoff receipts.
;; poo-flow-durable-runtime-manifest-alist
;; : (-> PooDurablePolicy PooDurableRuntimeStoreContract PooDurableRuntimeStoreBackend Alist)
;; | doc m%
;;   Project durable policy, store, and backend receipts into one manifest row.
;;   # Examples
;;   ```scheme
;;   (poo-flow-durable-runtime-manifest-alist policy store backend)
;;   ;; => durable runtime envelope rows
;;   ```
(def (poo-flow-durable-runtime-manifest-alist policy store-contract backend)
  (let* ((policy-row
          (poo-flow-durable-policy-runtime-manifest-alist policy))
         (store-row
          (poo-flow-durable-runtime-store-contract-receipt->alist
           (poo-flow-durable-runtime-store-contract->receipt store-contract)))
         (backend-row
          (poo-flow-durable-runtime-store-backend-receipt->alist
           (poo-flow-durable-runtime-store-backend->receipt backend)))
         (operation-kinds
          (poo-flow-durable-runtime-manifest-ref backend-row 'operation-kinds '()))
         (backend-executable
          (poo-flow-durable-runtime-manifest-ref backend-row 'executable "")))
    `((schema . ,+poo-flow-durable-runtime-envelope-schema+)
      (owner . scheme)
      (policy-schema . ,(poo-flow-durable-runtime-manifest-ref policy-row 'schema #f))
      (policy-id . ,(poo-flow-durable-runtime-manifest-ref policy-row 'policy-id #f))
      (checkpoint-id-strategy
       . ,(poo-flow-durable-runtime-manifest-ref
           policy-row 'checkpoint-id-strategy #f))
      (checkpoint-store
       . ,(poo-flow-durable-runtime-manifest-ref policy-row 'checkpoint-store #f))
      (repair-mode . ,(poo-flow-durable-runtime-manifest-ref policy-row 'repair-mode #f))
      (action-classes
       . ,(poo-flow-durable-runtime-manifest-ref policy-row 'action-classes '()))
      (store-schema . ,(poo-flow-durable-runtime-manifest-ref store-row 'schema #f))
      (store-id . ,(poo-flow-durable-runtime-manifest-ref store-row 'store-id #f))
      (store-owner . ,(poo-flow-durable-runtime-manifest-ref store-row 'store-owner #f))
      (fact-log-ref . ,(poo-flow-durable-runtime-manifest-ref store-row 'fact-log-ref #f))
      (checkpoint-store-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'checkpoint-store-ref #f))
      (derived-index-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'derived-index-ref #f))
      (job-store-ref . ,(poo-flow-durable-runtime-manifest-ref store-row 'job-store-ref #f))
      (repair-journal-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'repair-journal-ref #f))
      (artifact-store-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'artifact-store-ref #f))
      (communication-ledger-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'communication-ledger-ref #f))
      (sandbox-ledger-ref
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'sandbox-ledger-ref #f))
      (ledger-kinds
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'ledger-kinds '()))
      (capability-flags
       . ,(poo-flow-durable-runtime-manifest-ref store-row 'capability-flags '()))
      (backend-schema . ,(poo-flow-durable-runtime-manifest-ref backend-row 'schema #f))
      (backend-id . ,(poo-flow-durable-runtime-manifest-ref backend-row 'backend-id #f))
      (backend-kind
       . ,(poo-flow-durable-runtime-manifest-ref backend-row 'backend-kind #f))
      (backend-executable . ,backend-executable)
      (backend-protocol
       . ,(poo-flow-durable-runtime-manifest-ref backend-row 'protocol #f))
      (operation-kinds . ,operation-kinds)
      (operation-count . ,(length operation-kinds))
      (negotiate-argv . ,(list backend-executable "durable-runtime-store" "negotiate"))
      (operations-argv . ,(list backend-executable "durable-runtime-store" "operations"))
      (runtime-owner
       . ,(poo-flow-durable-runtime-manifest-ref policy-row 'runtime-owner #f))
      (policy-valid . ,(poo-flow-durable-runtime-manifest-ref policy-row 'receipt-valid #f))
      (store-valid . ,(poo-flow-durable-runtime-manifest-ref store-row 'valid? #f))
      (backend-valid . ,(poo-flow-durable-runtime-manifest-ref backend-row 'valid? #f))
      (diagnostic-count
       . ,(+ (poo-flow-durable-runtime-manifest-ref policy-row 'receipt-diagnostic-count 0)
             (poo-flow-durable-runtime-manifest-ref store-row 'diagnostic-count 0)
             (poo-flow-durable-runtime-manifest-ref backend-row 'diagnostic-count 0)))
      (runtime-executed . #f))))

;; poo-flow-durable-runtime-manifest-string
;; : (-> PooDurablePolicy PooDurableRuntimeStoreContract PooDurableRuntimeStoreBackend String)
;; | doc m%
;;   Serialize the durable runtime envelope as line-oriented manifest text.
;;   # Examples
;;   ```scheme
;;   (poo-flow-durable-runtime-manifest-string policy store backend)
;;   ;; => manifest text
;;   ```
(def (poo-flow-durable-runtime-manifest-string policy store-contract backend)
  (poo-flow-durable-runtime-manifest-lines->string
   (poo-flow-durable-runtime-manifest-alist policy store-contract backend)))

;; poo-flow-durable-runtime-manifest-bytes
;; : (-> PooDurablePolicy PooDurableRuntimeStoreContract PooDurableRuntimeStoreBackend U8Vector)
;; | doc m%
;;   Serialize the durable runtime envelope as UTF-8 bytes for FFI handoff.
;;   # Examples
;;   ```scheme
;;   (poo-flow-durable-runtime-manifest-bytes policy store backend)
;;   ;; => UTF-8 manifest bytes
;;   ```
(def (poo-flow-durable-runtime-manifest-bytes policy store-contract backend)
  (string->utf8
   (poo-flow-durable-runtime-manifest-string policy store-contract backend)))

;; poo-flow-durable-runtime-manifest-ref
;; : (-> Alist Symbol Datum Datum)
;; | doc m%
;;   Read KEY from a manifest row list, returning DEFAULT when absent.
;;   # Examples
;;   ```scheme
;;   (poo-flow-durable-runtime-manifest-ref rows 'schema #f)
;;   ;; => schema value or #f
;;   ```
(def (poo-flow-durable-runtime-manifest-ref row key default)
  (let ((cell (assq key row)))
    (if cell (cdr cell) default)))

;; : (-> Alist String)
(def (poo-flow-durable-runtime-manifest-lines->string rows)
  (call-with-output-string
   (lambda (port)
     (for-each
      (lambda (row)
        (display (symbol->string (car row)) port)
        (display "=" port)
        (display (poo-flow-durable-runtime-manifest-value->string (cdr row)) port)
        (newline port))
      rows))))

;; : (-> Datum String)
(def (poo-flow-durable-runtime-manifest-value->string value)
  (cond
   ((not value) "")
   ((eq? value #t) "true")
   ((symbol? value) (symbol->string value))
   ((string? value) value)
   ((number? value) (number->string value))
   ((list? value) (poo-flow-durable-runtime-manifest-list->string value))
   (else (call-with-output-string
          (lambda (port) (write value port))))))

;; poo-flow-durable-runtime-manifest-list->string
;; : (-> [Datum] String)
;; | doc m%
;;   Serialize a list field as the comma-delimited runtime manifest value form.
;;   # Examples
;;   ```scheme
;;   (poo-flow-durable-runtime-manifest-list->string '(run repair))
;;   ;; => "run,repair"
;;   ```
(def (poo-flow-durable-runtime-manifest-list->string value)
  (call-with-output-string
   (lambda (port)
     (let loop ((rest value) (first? #t))
       (unless (null? rest)
         (unless first? (display "," port))
         (display (poo-flow-durable-runtime-manifest-value->string (car rest)) port)
         (loop (cdr rest) #f))))))
