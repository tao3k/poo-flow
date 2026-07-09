;;; Boundary: durable policy manifests keep the Scheme control-plane receipt stable
;;; across runtime handoff code and parser-owned policy checks.
;;; Invariant: this module must describe durable policy surfaces without
;;; depending on provider-specific recovery execution.
(import :gerbil/gambit
        :poo-flow/src/module-system/durable-policy)

(export +poo-flow-durable-runtime-policy-manifest-schema+
        poo-flow-durable-policy-runtime-manifest-alist
        poo-flow-durable-policy-runtime-manifest-string
        poo-flow-durable-policy-runtime-manifest-bytes)

(def +poo-flow-durable-runtime-policy-manifest-schema+
  'poo-flow.durable.runtime-policy-manifest.v1)

;; poo-flow-durable-policy-runtime-manifest-alist
;; : (-> PooDurablePolicy Alist)
;; | doc m%
;;   Project a durable policy into the runtime manifest row format.
;;   # Examples
;;   ```scheme
;;   (poo-flow-durable-policy-runtime-manifest-alist policy)
;;   ;; => durable policy manifest rows
;;   ```
(def (poo-flow-durable-policy-runtime-manifest-alist policy)
  (let* ((receipt (poo-flow-durable-policy->receipt policy))
         (diagnostics (poo-flow-durable-policy-receipt-diagnostics receipt)))
    `((schema . ,+poo-flow-durable-runtime-policy-manifest-schema+)
      (owner . scheme)
      (policy-id . ,(poo-flow-durable-policy-receipt-policy-id receipt))
      (checkpoint-id-strategy . runtime-generated)
      (require-plan-digest-match . #t)
      (history-retention-limit . #f)
      (checkpoint-store . ,(poo-flow-durable-policy-receipt-checkpoint-store receipt))
      (repair-mode . ,(poo-flow-durable-policy-receipt-repair-mode receipt))
      (action-classes . ,(poo-flow-durable-policy-receipt-action-classes receipt))
      (runtime-owner . ,(poo-flow-durable-policy-receipt-runtime-owner receipt))
      (receipt-schema . ,+poo-flow-durable-policy-receipt-schema+)
      (receipt-kind . ,+poo-flow-durable-policy-kind+)
      (receipt-valid . ,(poo-flow-durable-policy-receipt-valid? receipt))
      (receipt-diagnostic-count . ,(length diagnostics)))))

;; poo-flow-durable-policy-runtime-manifest-string
;; : (-> PooDurablePolicy String)
;; | doc m%
;;   Serialize a durable policy manifest as line-oriented text.
;;   # Examples
;;   ```scheme
;;   (poo-flow-durable-policy-runtime-manifest-string policy)
;;   ;; => manifest text
;;   ```
(def (poo-flow-durable-policy-runtime-manifest-string policy)
  (poo-flow-durable-manifest-lines->string
   (poo-flow-durable-policy-runtime-manifest-alist policy)))

;; poo-flow-durable-policy-runtime-manifest-bytes
;; : (-> PooDurablePolicy U8Vector)
;; | doc m%
;;   Serialize a durable policy manifest as UTF-8 bytes for FFI handoff.
;;   # Examples
;;   ```scheme
;;   (poo-flow-durable-policy-runtime-manifest-bytes policy)
;;   ;; => UTF-8 manifest bytes
;;   ```
(def (poo-flow-durable-policy-runtime-manifest-bytes policy)
  (string->utf8 (poo-flow-durable-policy-runtime-manifest-string policy)))

;; : (-> Alist String)
(def (poo-flow-durable-manifest-lines->string rows)
  (call-with-output-string
   (lambda (port)
     (for-each
      (lambda (row)
        (display (symbol->string (car row)) port)
        (display "=" port)
        (display (poo-flow-durable-manifest-value->string (cdr row)) port)
        (newline port))
      rows))))

;; : (-> Datum String)
(def (poo-flow-durable-manifest-value->string value)
  (cond
   ((not value) "")
   ((eq? value #t) "true")
   ((symbol? value) (symbol->string value))
   ((string? value) value)
   ((number? value) (number->string value))
   ((list? value) (poo-flow-durable-manifest-list->string value))
   (else (call-with-output-string
          (lambda (port) (write value port))))))

;; poo-flow-durable-manifest-list->string
;; : (-> [Datum] String)
;; | doc m%
;;   Serialize a list field as the comma-delimited manifest value form.
;;   # Examples
;;   ```scheme
;;   (poo-flow-durable-manifest-list->string '(a b))
;;   ;; => "a,b"
;;   ```
(def (poo-flow-durable-manifest-list->string value)
  (call-with-output-string
   (lambda (port)
     (let loop ((rest value) (first? #t))
       (unless (null? rest)
         (unless first? (display "," port))
         (display (poo-flow-durable-manifest-value->string (car rest)) port)
         (loop (cdr rest) #f))))))
