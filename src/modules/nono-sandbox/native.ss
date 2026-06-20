;;; -*- Gerbil -*-
;;; Owner: native nono FFI live probes and receipts.
;;; Boundary: this module calls the package-managed Gambit FFI shim.
;;; Runtime contract: irreversible sandbox apply is not performed by default.

(import :gerbil/gambit
        :poo-flow/src/modules/agent-sandbox/alist
        :poo-flow/src/modules/nono-sandbox/c-binding-runtime
        :poo-flow/src/modules/modules-system-base
        ./_nono)

(export +nono-c-binding-native-live-test-receipt-schema+
        +nono-c-binding-selection-live-test-receipt-schema+
        +nono-c-binding-native-apply-null-error-code+
        nono-c-binding-native-library-candidates
        nono-c-binding-native-resolve-library
        nono-c-binding-native-open
        nono-c-binding-native-close
        nono-c-binding-selection-binding
        nono-c-binding-selection-live-test
        nono-c-binding-native-live-test)

;; : Symbol
(def +nono-c-binding-native-live-test-receipt-schema+
  'poo-flow.sandbox.nono-sandbox.c-binding.native-live-test.v1)

;; : Symbol
(def +nono-c-binding-selection-live-test-receipt-schema+
  'poo-flow.sandbox.nono-sandbox.c-binding.selection-live-test.v1)

;; : Integer
(def +nono-c-binding-native-apply-null-error-code+ -12)

;; : (-> [Alist] [String])
(def (nono-c-binding-native-library-candidates . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (library-path (agent-sandbox-alist-ref options 'library-path #f)))
    (if library-path
      (list library-path)
      '(".data/nono/target/debug/libnono_ffi.dylib"
        ".data/nono/target/release/libnono_ffi.dylib"
        ".data/nono/target/debug/libnono_ffi.so"
        ".data/nono/target/release/libnono_ffi.so"))))

;; nono-c-binding-native-resolve-library
;;   : (-> [Alist] (U String #f))
;;   | contract: returns the first existing native library candidate or #f.
;;   | doc m%
;;     # Examples
;;     ```scheme
;;     (nono-c-binding-native-resolve-library '((library-path . "/tmp/missing.dylib")))
;;     ;; result: #f when the path does not exist
;;     ```
;; : (-> [Alist] (U String #f))
(def (nono-c-binding-native-resolve-library . maybe-options)
  (let (candidates
        (apply nono-c-binding-native-library-candidates maybe-options))
    (find file-exists? candidates)))

;; : (-> String Alist)
(def (nono-c-binding-native-open library-path)
  (let ((status (nono_native_open library-path))
        (error (nono_native_last_error)))
    (list (cons 'ok? (zero? status))
          (cons 'status status)
          (cons 'library-path library-path)
          (cons 'loaded? (= (nono_native_is_loaded) 1))
          (cons 'error error))))

;; : (-> Unit Alist)
(def (nono-c-binding-native-close)
  (let (status (nono_native_close))
    (list (cons 'ok? (zero? status))
          (cons 'status status)
          (cons 'loaded? (= (nono_native_is_loaded) 1)))))

;; : (-> PooUserModuleSelection Symbol)
(def (nono-c-binding-selection-binding selection)
  (let (entry (poo-flow-user-module-selection-flag-entry selection ':binding))
    (cond
     ((and entry (pair? entry)) (cdr entry))
     ((poo-flow-user-module-selection-has-flag? selection '+native-ffi)
      'native-ffi)
     ((poo-flow-user-module-selection-has-flag? selection '+cli)
      'cli)
     (else 'native-ffi))))

;; : (-> PooUserModuleSelection Symbol Alist Alist)
(def (nono-c-binding-selection-receipt-prefix selection binding)
  (list (cons 'binding-source 'use-module)
        (cons 'selection-binding binding)
        (cons 'selection-key
              (poo-flow-user-module-selection-key selection))
        (cons 'selection-flags
              (poo-flow-user-module-selection-flags selection))))

;; : (-> PooUserModuleSelection Symbol RuntimeManifest Alist)
(def (nono-c-binding-selection-unsupported-receipt selection
                                                   binding
                                                   runtime-manifest)
  (append
   (nono-c-binding-selection-receipt-prefix selection binding)
   (list (cons 'schema +nono-c-binding-selection-live-test-receipt-schema+)
         (cons 'ok? #f)
         (cons 'enabled? #f)
         (cons 'skipped? #t)
         (cons 'skip-reason 'unsupported-nono-binding)
         (cons 'native-executed #f)
         (cons 'cli-executed #f)
         (cons 'runtime-executed #f)
         (cons 'would-apply? #f)
         (cons 'irreversible-apply? #f)
         (cons 'dry-run (nono-c-binding-dry-run runtime-manifest)))))

;; : (-> PooUserModuleSelection RuntimeManifest [AlistOrCommand] Alist)
(def (nono-c-binding-selection-live-test selection runtime-manifest . maybe-options)
  (let (binding (nono-c-binding-selection-binding selection))
    (cond
     ((eq? binding 'native-ffi)
      (append
       (nono-c-binding-selection-receipt-prefix selection binding)
       (apply nono-c-binding-native-live-test
              runtime-manifest
              maybe-options)))
     ((eq? binding 'cli)
      (let (receipt
            (apply nono-c-binding-live-test runtime-manifest maybe-options))
        (append
         (nono-c-binding-selection-receipt-prefix selection binding)
         (list (cons 'cli-executed
                     (agent-sandbox-alist-ref receipt 'live-executed #f))
               (cons 'native-executed #f))
         receipt)))
     (else
      (nono-c-binding-selection-unsupported-receipt
       selection
       binding
       runtime-manifest)))))

;; : (-> RuntimeManifest Alist Symbol Alist)
(def (nono-c-binding-native-skip-receipt runtime-manifest options reason)
  (list (cons 'schema +nono-c-binding-native-live-test-receipt-schema+)
        (cons 'ok? #t)
        (cons 'enabled? #f)
        (cons 'skipped? #t)
        (cons 'skip-reason reason)
        (cons 'library-candidates
              (nono-c-binding-native-library-candidates options))
        (cons 'native-executed #f)
        (cons 'native-loaded? #f)
        (cons 'cli-executed #f)
        (cons 'runtime-executed #f)
        (cons 'would-apply? #f)
        (cons 'irreversible-apply? #f)
        (cons 'dry-run (nono-c-binding-dry-run runtime-manifest))))

;; : (-> RuntimeManifest Alist String Alist Alist)
(def (nono-c-binding-native-failure-receipt runtime-manifest
                                            options
                                            library-path
                                            open-receipt)
  (list (cons 'schema +nono-c-binding-native-live-test-receipt-schema+)
        (cons 'ok? #f)
        (cons 'enabled? #t)
        (cons 'skipped? #f)
        (cons 'library-path library-path)
        (cons 'library-candidates
              (nono-c-binding-native-library-candidates options))
        (cons 'native-executed #f)
        (cons 'native-loaded?
              (agent-sandbox-alist-ref open-receipt 'loaded? #f))
        (cons 'cli-executed #f)
        (cons 'runtime-executed #f)
        (cons 'would-apply? #f)
        (cons 'irreversible-apply? #f)
        (cons 'error (agent-sandbox-alist-ref open-receipt 'error ""))
        (cons 'open open-receipt)
        (cons 'dry-run (nono-c-binding-dry-run runtime-manifest))))

;; : (-> String)
(def (nono-c-binding-native-safe-string value)
  (if (string? value) value ""))

;; : (-> RuntimeManifest Alist String Alist)
(def (nono-c-binding-native-success-receipt runtime-manifest options library-path)
  (let* ((support? (nono_native_sandbox_is_supported))
         (support-info-supported? (nono_native_support_is_supported))
         (platform
          (nono-c-binding-native-safe-string
           (nono_native_support_platform)))
         (details
          (nono-c-binding-native-safe-string
           (nono_native_support_details)))
         (capability-roundtrip-code
          (nono_native_capability_roundtrip))
         (apply-null-code (nono_native_apply_null))
         (ok? (and (>= support? 0)
                   (>= support-info-supported? 0)
                   (zero? capability-roundtrip-code)
                   (= apply-null-code
                      +nono-c-binding-native-apply-null-error-code+))))
    (nono-c-binding-native-close)
    (list (cons 'schema +nono-c-binding-native-live-test-receipt-schema+)
          (cons 'ok? ok?)
          (cons 'enabled? #t)
          (cons 'skipped? #f)
          (cons 'library-path library-path)
          (cons 'library-candidates
                (nono-c-binding-native-library-candidates options))
          (cons 'native-executed #t)
          (cons 'native-loaded? #t)
          (cons 'cli-executed #f)
          (cons 'runtime-executed #f)
          (cons 'would-apply? #f)
          (cons 'irreversible-apply? #f)
          (cons 'apply-symbol 'nono_sandbox_apply)
          (cons 'apply-null-only? #t)
          (cons 'apply-null-code apply-null-code)
          (cons 'capability-roundtrip-code capability-roundtrip-code)
          (cons 'support? (= support? 1))
          (cons 'support-info-supported? (= support-info-supported? 1))
          (cons 'platform platform)
          (cons 'details details)
          (cons 'dry-run (nono-c-binding-dry-run runtime-manifest)))))

;; : (-> RuntimeManifest [Alist] Alist)
(def (nono-c-binding-native-live-test runtime-manifest . maybe-options)
  (let* ((options (if (null? maybe-options) '() (car maybe-options)))
         (library-path
          (nono-c-binding-native-resolve-library options)))
    (if library-path
      (let (open-receipt (nono-c-binding-native-open library-path))
        (if (agent-sandbox-alist-ref open-receipt 'ok? #f)
          (nono-c-binding-native-success-receipt
           runtime-manifest
           options
           library-path)
          (nono-c-binding-native-failure-receipt
           runtime-manifest
           options
           library-path
           open-receipt)))
      (nono-c-binding-native-skip-receipt
       runtime-manifest
       options
       'native-library-not-found))))
