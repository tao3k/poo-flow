;;; -*- Gerbil -*-
;;; Owner: nono-sandbox C binding build/probe metadata lives here.
;;; Boundary: this module describes host-side compile probes and include policy.
;;; Runtime contract: native loading lives in native.ss; irreversible apply is gated.

(import :gerbil/gambit
        (only-in :clan/poo/object .ref .mix object?)
        :poo-flow/src/core/api
        :poo-flow/src/modules/agent-sandbox/alist
        :poo-flow/src/modules/agent-sandbox/profile
        :poo-flow/src/modules/nono-sandbox/c-binding-descriptor)

(export +nono-c-binding-build-schema+
        +nono-c-binding-default-adapter-include-dirs+
        +nono-c-binding-default-upstream-include-dirs+
        +nono-c-binding-default-include-dirs+
        +nono-c-binding-default-compiler-options+
        +nono-c-binding-default-warning-options+
        nono-c-binding-build-prototype
        make-nono-c-binding-build
        nono-c-binding-build?
        nono-c-binding-build-schema
        nono-c-binding-build-name
        nono-c-binding-build-compiler
        nono-c-binding-build-standard
        nono-c-binding-build-compiler-options
        nono-c-binding-build-warning-options
        nono-c-binding-build-syntax-only?
        nono-c-binding-build-adapter-include-dirs
        nono-c-binding-build-upstream-include-dirs
        nono-c-binding-build-include-dirs
        nono-c-binding-build-probe-ref
        nono-c-binding-build-required-inputs
        nono-c-binding-build->contract
        nono-c-binding-build-validation-errors
        nono-c-binding-validate-build
        nono-c-binding-build-input-validation-errors
        nono-c-binding-validate-build-inputs
        nono-c-binding-build->probe-command
        nono-c-binding-compile-probe-command)

;;; Build schema is separate from the ABI descriptor. The descriptor names the
;;; native surface; this object names the package-managed host probe policy.
;; : Symbol
(def +nono-c-binding-build-schema+
  'poo-flow.sandbox.nono-sandbox.c-binding.build.v1)

;; : (List String)
(def +nono-c-binding-default-adapter-include-dirs+
  '("bindings/nono-c"))

;; : (List String)
(def +nono-c-binding-default-upstream-include-dirs+
  '())

;; : (List String)
(def +nono-c-binding-default-include-dirs+
  (append +nono-c-binding-default-adapter-include-dirs+
          +nono-c-binding-default-upstream-include-dirs+))

;; : (List String)
(def +nono-c-binding-default-compiler-options+
  '("-Qunused-arguments"))

;; : (List String)
(def +nono-c-binding-default-warning-options+
  '("-Wall" "-Wextra" "-Werror"))

;; | NonoCBindingPresentCandidate = (U Symbol String Pair Object Procedure Boolean)
;; : (-> NonoCBindingPresentCandidate Boolean)
(def (nono-c-binding-build-present? value)
  (and value #t))

;;; Boundary:
;;; - nono-c-binding-string-list? keeps host compiler argv validation pure.
;; nono-c-binding-string-list?
;;   : (-> NonoCBindingStringListCandidate Boolean)
;;   | type StringList = (List String)
;;   | doc m%
;;       `nono-c-binding-string-list? value` accepts only proper lists of strings.
;;
;;       # Examples
;;
;;       ```scheme
;;       (nono-c-binding-string-list? '("cc" "-Wall"))
;;       ;; => #t
;;       (nono-c-binding-string-list? '("cc" 1))
;;       ;; => #f
;;       ```
;;     %
(def (nono-c-binding-string-list? value)
  (and (list? value)
       (andmap string? value)))

;; : (-> String String)
(def (nono-c-binding-include-option include-dir)
  (string-append "-I" include-dir))

;;; This POO object is the extension point for host compiler policy. Backends
;;; can override compiler, include directories, or probe path without changing
;;; the runtime manifest projection.
;; : NonoCBindingBuildPrototype
(def nono-c-binding-build-prototype
  (.mix slots: (role-constant-slots
                (list (cons 'schema +nono-c-binding-build-schema+)
                      (cons 'name 'nono-c-binding-build)
                      (cons 'compiler "clang")
                      (cons 'standard "c11")
                      (cons 'compiler-options
                            +nono-c-binding-default-compiler-options+)
                      (cons 'warning-options
                            +nono-c-binding-default-warning-options+)
                      (cons 'syntax-only? #t)
                      (cons 'adapter-include-dirs
                            +nono-c-binding-default-adapter-include-dirs+)
                      (cons 'upstream-include-dirs
                            +nono-c-binding-default-upstream-include-dirs+)
                      (cons 'include-dirs
                            +nono-c-binding-default-include-dirs+)
                      (cons 'probe-ref
                            "bindings/nono-c/poo_flow_nono_binding_probe.c")
                      (cons 'validator
                            (lambda (build)
                              (nono-c-binding-validate-build build)))))
        execution-policy-role))

;;; Boundary: make nono c binding build is the policy-visible edge for sandbox
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> (List Pair) NonoCBindingBuild)
(def (make-nono-c-binding-build . maybe-overrides)
  (.mix slots: (role-constant-slots
                (if (null? maybe-overrides) '() (car maybe-overrides)))
        nono-c-binding-build-prototype))

;; : (-> NonoCBindingBuildCandidate Boolean)
(def (nono-c-binding-build? build)
  (object? build))

;;; Boundary: nono c binding build slot is the policy-visible edge for sandbox
;;; behavior, keeping validation, lookup, or projection responsibilities
;;; centralized for callers.
;; : (-> NonoCBindingBuild Symbol Value Value)
(def (nono-c-binding-build-slot build slot default)
  (if (nono-c-binding-build? build)
    (.ref build slot)
    default))

;; : (-> NonoCBindingBuild Symbol)
(def (nono-c-binding-build-schema build)
  (nono-c-binding-build-slot build 'schema #f))

;; : (-> NonoCBindingBuild Symbol)
(def (nono-c-binding-build-name build)
  (nono-c-binding-build-slot build 'name #f))

;; : (-> NonoCBindingBuild String)
(def (nono-c-binding-build-compiler build)
  (nono-c-binding-build-slot build 'compiler #f))

;; : (-> NonoCBindingBuild String)
(def (nono-c-binding-build-standard build)
  (nono-c-binding-build-slot build 'standard #f))

;; : (-> NonoCBindingBuild (List String))
(def (nono-c-binding-build-compiler-options build)
  (nono-c-binding-build-slot build 'compiler-options '()))

;; : (-> NonoCBindingBuild (List String))
(def (nono-c-binding-build-warning-options build)
  (nono-c-binding-build-slot build 'warning-options '()))

;; : (-> NonoCBindingBuild Boolean)
(def (nono-c-binding-build-syntax-only? build)
  (nono-c-binding-build-slot build 'syntax-only? #t))

;; : (-> NonoCBindingBuild (List String))
(def (nono-c-binding-build-adapter-include-dirs build)
  (nono-c-binding-build-slot build 'adapter-include-dirs '()))

;; : (-> NonoCBindingBuild (List String))
(def (nono-c-binding-build-upstream-include-dirs build)
  (nono-c-binding-build-slot build 'upstream-include-dirs '()))

;; : (-> NonoCBindingBuild (List String))
(def (nono-c-binding-build-include-dirs build)
  (nono-c-binding-build-slot build 'include-dirs '()))

;; : (-> NonoCBindingBuild String)
(def (nono-c-binding-build-probe-ref build)
  (nono-c-binding-build-slot build 'probe-ref #f))

;; : (-> Symbol String Alist)
(def (nono-c-binding-build-required-input kind path)
  (list (cons 'kind kind)
        (cons 'path path)))

;;; Required-dir inputs keep include directory expansion as a pure map from
;;; paths to receipt rows, preserving index/order for later diagnostics.
;; : (-> Symbol (List String) (List Alist))
(def (nono-c-binding-build-required-dir-inputs kind paths)
  (map (lambda (path)
         (nono-c-binding-build-required-input kind path))
       paths))

;;; Required inputs make the package-owned C binding resources explicit.
;;; Runtime receipts can report missing headers before a compiler emits opaque
;;; errors, without depending on a research checkout under `.data`.
;; : (-> NonoCBindingBuild (List Alist))
(def (nono-c-binding-build-required-inputs build)
  (let (valid-build (nono-c-binding-validate-build build))
    (append
     (nono-c-binding-build-required-dir-inputs
      'adapter-include-dir
      (nono-c-binding-build-adapter-include-dirs valid-build))
     (nono-c-binding-build-required-dir-inputs
      'upstream-include-dir
      (nono-c-binding-build-upstream-include-dirs valid-build))
     (list (nono-c-binding-build-required-input
            'probe
            (nono-c-binding-build-probe-ref valid-build))))))

;;; Build contracts are serializable receipts for package checks and runtime
;;; smoke probes. They keep host compile policy out of the runtime manifest.
;; : (-> NonoCBindingBuild (List NonoCBindingDescriptor) Alist)
(def (nono-c-binding-build->contract build . maybe-descriptor)
  (let ((valid-build (nono-c-binding-validate-build build))
        (descriptor (if (null? maybe-descriptor)
                      (make-nono-c-binding-descriptor)
                      (car maybe-descriptor))))
    (list (cons 'schema +nono-c-binding-build-schema+)
          (cons 'name (nono-c-binding-build-name valid-build))
          (cons 'binding
                (nono-c-binding-descriptor->contract descriptor))
          (cons 'compiler
                (nono-c-binding-build-compiler valid-build))
          (cons 'standard
                (nono-c-binding-build-standard valid-build))
          (cons 'compiler-options
                (nono-c-binding-build-compiler-options valid-build))
          (cons 'warning-options
                (nono-c-binding-build-warning-options valid-build))
          (cons 'syntax-only?
                (nono-c-binding-build-syntax-only? valid-build))
          (cons 'adapter-include-dirs
                (nono-c-binding-build-adapter-include-dirs valid-build))
          (cons 'upstream-include-dirs
                (nono-c-binding-build-upstream-include-dirs valid-build))
          (cons 'include-dirs
                (nono-c-binding-build-include-dirs valid-build))
          (cons 'probe-ref
                (nono-c-binding-build-probe-ref valid-build))
          (cons 'required-inputs
                (nono-c-binding-build-required-inputs valid-build))
          (cons 'inputs-ok?
                (null? (nono-c-binding-build-input-validation-errors
                        valid-build))))))

;;; Descriptor validation reports contract fields before path checks so missing
;;; checkout state does not mask malformed build descriptors.
;; : (-> NonoCBindingBuild (List ValidationError))
(def (nono-c-binding-build-validation-errors build)
  (if (nono-c-binding-build? build)
    (agent-sandbox-required-field-errors
     (list (cons 'schema (nono-c-binding-build-schema build))
           (cons 'name (nono-c-binding-build-name build))
           (cons 'compiler (nono-c-binding-build-compiler build))
           (cons 'standard (nono-c-binding-build-standard build))
           (cons 'compiler-options
                 (nono-c-binding-build-compiler-options build))
           (cons 'warning-options
                 (nono-c-binding-build-warning-options build))
           (cons 'syntax-only? (nono-c-binding-build-syntax-only? build))
           (cons 'adapter-include-dirs
                 (nono-c-binding-build-adapter-include-dirs build))
           (cons 'upstream-include-dirs
                 (nono-c-binding-build-upstream-include-dirs build))
           (cons 'include-dirs (nono-c-binding-build-include-dirs build))
           (cons 'probe-ref (nono-c-binding-build-probe-ref build)))
     (list (cons 'schema
                 (lambda (value)
                   (eq? value +nono-c-binding-build-schema+)))
           (cons 'name nono-c-binding-build-present?)
           (cons 'compiler string?)
           (cons 'standard string?)
           (cons 'compiler-options nono-c-binding-string-list?)
           (cons 'warning-options nono-c-binding-string-list?)
           (cons 'syntax-only? boolean?)
           (cons 'adapter-include-dirs nono-c-binding-string-list?)
           (cons 'upstream-include-dirs nono-c-binding-string-list?)
           (cons 'include-dirs nono-c-binding-string-list?)
           (cons 'probe-ref string?)))
    (list '((field . build) (code . not-poo-object)))))

;;; Boundary: nono c binding validate build is the policy-visible edge for
;;; sandbox behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> NonoCBindingBuild NonoCBindingBuild)
(def (nono-c-binding-validate-build build)
  (let (errors (nono-c-binding-build-validation-errors build))
    (if (null? errors)
      build
      (raise-control-plane-failure
       'nono-sandbox
       'invalid-nono-c-binding-build
       "invalid nono C binding build descriptor"
       (list (cons 'errors errors))))))

;;; Boundary: nono c binding build input validation error is the policy-visible
;;; edge for sandbox behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> Alist Integer (List ValidationError))
(def (nono-c-binding-build-input-validation-error input index)
  (let ((kind (agent-sandbox-alist-ref input 'kind #f))
        (path (agent-sandbox-alist-ref input 'path #f)))
    (cond
     ((not (string? path))
      (list (list (cons 'field 'build-input-path)
                  (cons 'index index)
                  (cons 'kind kind)
                  (cons 'code 'missing-or-invalid-path))))
     ((file-exists? path) '())
     (else
      (list (list (cons 'field 'build-input-path)
                  (cons 'index index)
                  (cons 'kind kind)
                  (cons 'path path)
                  (cons 'code 'path-not-found)))))))

;;; Input validation maps paths and generated indexes together; callers get
;;; stable row numbers without mutating the required-inputs receipt.
;; : (-> (List Alist) Integer (List ValidationError))
(def (nono-c-binding-build-inputs-validation-errors inputs index)
  (apply append
         (map nono-c-binding-build-input-validation-error
              inputs
              (iota (length inputs) index))))

;;; Input validation is deliberately separate from descriptor validation:
;;; package contracts may be inspected without a local nono checkout, while
;;; compile probes must fail before invoking the host C compiler.
;; : (-> NonoCBindingBuild (List ValidationError))
(def (nono-c-binding-build-input-validation-errors build)
  (nono-c-binding-build-inputs-validation-errors
   (nono-c-binding-build-required-inputs build)
   0))

;;; Boundary: nono c binding validate build inputs is the policy-visible edge
;;; for sandbox behavior, keeping validation, lookup, or projection
;;; responsibilities centralized for callers.
;; : (-> NonoCBindingBuild NonoCBindingBuild)
(def (nono-c-binding-validate-build-inputs build)
  (let ((valid-build (nono-c-binding-validate-build build))
        (errors (nono-c-binding-build-input-validation-errors build)))
    (if (null? errors)
      valid-build
      (raise-control-plane-failure
       'nono-sandbox
       'invalid-nono-c-binding-build-inputs
       "invalid nono C binding build inputs"
       (list (cons 'errors errors))))))

;;; The default command mirrors the package-managed C probe. It is argv data,
;;; not a shell string, so tests and runtime receipts can run it without
;;; escaping policy or command injection ambiguity.
;; : (-> (List NonoCBindingBuild) (List String))
(def (nono-c-binding-build->probe-command . maybe-build)
  (let* ((build (nono-c-binding-validate-build-inputs
                 (if (null? maybe-build)
                   (make-nono-c-binding-build)
                   (car maybe-build))))
         (standard-option
          (string-append "-std=" (nono-c-binding-build-standard build)))
         (syntax-options
          (if (nono-c-binding-build-syntax-only? build)
            '("-fsyntax-only")
            '()))
         (include-options
          (map nono-c-binding-include-option
               (nono-c-binding-build-include-dirs build))))
    (append
     (list (nono-c-binding-build-compiler build))
     (nono-c-binding-build-compiler-options build)
     (list standard-option)
     (nono-c-binding-build-warning-options build)
     syntax-options
     include-options
     (list (nono-c-binding-build-probe-ref build)))))

;; : (-> (List NonoCBindingBuild) (List String))
(def (nono-c-binding-compile-probe-command . maybe-build)
  (apply nono-c-binding-build->probe-command maybe-build))
