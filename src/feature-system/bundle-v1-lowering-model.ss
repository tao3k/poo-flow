;;; Boundary: declarative Bundle v1 wire-model constructors and validators;
;;; lowering algorithms and arena mutation remain in their dedicated owners.
(import (only-in :std/crypto/digest sha256)
        (only-in :std/sort stable-sort)
        (only-in :std/srfi/1 fold-right)
        (only-in :clan/poo/object .ref .slot? object? object<-alist)
        :poo-flow/src/utilities/functional)

(export (except-out #t define-poo-value))

(def +feature-bundle-v1-schema+ 'poo-flow.bundle.1)
(def +feature-bundle-v1-schema-major+ 1)
(def +feature-bundle-v1-schema-minor+ 0)
(def +feature-bundle-v1-descriptor-size+ 256)
(def +feature-bundle-v1-digest-bytes+ 32)
(def +feature-bundle-v1-symbol-row-size+ 32)
(def +feature-bundle-v1-component-row-size+ 200)
(def +feature-bundle-v1-edge-row-size+ 80)
(def +feature-bundle-v1-evidence-row-size+ 96)
(def +feature-bundle-v1-row-alignment+ 8)
(def +feature-bundle-v1-arena-alignment+ 64)
(def +feature-bundle-v1-descriptor-flags+ 3)
(def +feature-bundle-v1-component-enabled-flag+ 1)
(def +feature-bundle-v1-uint16-modulus+ 65536)
(def +feature-bundle-v1-uint64-modulus+ 18446744073709551616)

(def +feature-bundle-v1-no-capability-id+
  'poo-flow.bundle-v1.no-capability)
(def +feature-bundle-v1-no-policy-id+
  'poo-flow.bundle-v1.no-policy)
(def +feature-bundle-v1-no-strategy-id+
  'poo-flow.bundle-v1.no-strategy)
(def +feature-bundle-v1-no-adapter-id+
  'poo-flow.bundle-v1.no-adapter)
(def +feature-bundle-v1-no-projection-id+
  'poo-flow.bundle-v1.no-projection)

(def +feature-bundle-v1-compact-id-kind+
  'poo-flow.feature-bundle-v1-compact-id.v1)
(def +feature-bundle-v1-symbol-kind+
  'poo-flow.feature-bundle-v1-symbol.v1)
(def +feature-bundle-v1-component-kind+
  'poo-flow.feature-bundle-v1-component.v1)
(def +feature-bundle-v1-edge-kind+
  'poo-flow.feature-bundle-v1-edge.v1)
(def +feature-bundle-v1-evidence-kind+
  'poo-flow.feature-bundle-v1-evidence.v1)
(def +feature-bundle-v1-native-component-kind+
  'poo-flow.feature-bundle-v1-native-component.v1)
(def +feature-bundle-v1-native-symbol-kind+
  'poo-flow.feature-bundle-v1-native-symbol.v1)
(def +feature-bundle-v1-native-edge-kind+
  'poo-flow.feature-bundle-v1-native-edge.v1)
(def +feature-bundle-v1-native-evidence-kind+
  'poo-flow.feature-bundle-v1-native-evidence.v1)
(def +feature-bundle-v1-region-kind+
  'poo-flow.feature-bundle-v1-region.v1)
(def +feature-bundle-v1-descriptor-kind+
  'poo-flow.feature-bundle-v1-descriptor.v1)
(def +feature-bundle-v1-diagnostic-kind+
  'poo-flow.feature-bundle-v1-diagnostic.v1)
(def +feature-bundle-v1-lowering-plan-kind+
  'poo-flow.feature-bundle-v1-lowering-plan.v1)

;; define-poo-value
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `define-poo-value` defines a Bundle v1 lowering value constructor.
;;
;;       # Examples
;;
;;       ```scheme
;;       (define-poo-value (constructor field) value-kind)
;;       ;; => defines constructor
;;       ```
;;     %
(defsyntax define-poo-value
  (syntax-rules ()
    ((_ (name field ...) kind-value)
     (def (name field ...)
       (object<-alist
        (list (cons 'kind kind-value)
              (cons 'schema-version 1)
              (cons 'field field) ...))))))

(define-poo-value
  (feature-bundle-v1-compact-id domain source high low)
  +feature-bundle-v1-compact-id-kind+)

(define-poo-value
  (feature-bundle-v1-symbol domain source value symbol-kind)
  +feature-bundle-v1-symbol-kind+)

(define-poo-value
  (feature-bundle-v1-component
   case-id component-id object-id type-id contract-id role-id capability-id
   policy-id strategy-id adapter-id projection-id composition-order)
  +feature-bundle-v1-component-kind+)

(define-poo-value
  (feature-bundle-v1-edge
   case-id source-component-id target-component-id relation-id
   composition-order)
  +feature-bundle-v1-edge-kind+)

(define-poo-value
  (feature-bundle-v1-evidence
   case-id obligation-id contract-id evidence-type-id proof-system-id
   composition-order)
  +feature-bundle-v1-evidence-kind+)

(define-poo-value
  (feature-bundle-v1-native-component
   case-id component-id object-id type-id contract-id role-id capability-id
   policy-id strategy-id adapter-id projection-id composition-order flags
   reserved0 reserved1)
  +feature-bundle-v1-native-component-kind+)

(define-poo-value
  (feature-bundle-v1-native-symbol
   id byte-offset byte-length symbol-kind flags value-bytes)
  +feature-bundle-v1-native-symbol-kind+)

(define-poo-value
  (feature-bundle-v1-native-edge
   case-id source-component-id target-component-id relation-id
   composition-order flags reserved0)
  +feature-bundle-v1-native-edge-kind+)

(define-poo-value
  (feature-bundle-v1-native-evidence
   case-id obligation-id contract-id evidence-type-id proof-system-id
   composition-order flags reserved0)
  +feature-bundle-v1-native-evidence-kind+)

(define-poo-value
  (feature-bundle-v1-region name offset length stride alignment count)
  +feature-bundle-v1-region-kind+)

(define-poo-value
  (feature-bundle-v1-descriptor
   struct-size flags schema-major schema-minor reserved0 bundle-id digest
   bundle-epoch arena-bytes symbols components edges evidence-obligations
   metadata-bytes reserved symbol-rows metadata-image component-rows edge-rows
   evidence-rows)
  +feature-bundle-v1-descriptor-kind+)

(define-poo-value
  (feature-bundle-v1-diagnostic code subject detail)
  +feature-bundle-v1-diagnostic-kind+)

(define-poo-value
  (feature-bundle-v1-lowering-plan status accepted? descriptor diagnostics)
  +feature-bundle-v1-lowering-plan-kind+)

;; : (-> Object Symbol Boolean)
(def (poo-kind? value expected-kind)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) expected-kind)))

;; : (-> Object Boolean)
(def (feature-bundle-v1-compact-id? value)
  (poo-kind? value +feature-bundle-v1-compact-id-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-symbol? value)
  (poo-kind? value +feature-bundle-v1-symbol-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-component? value)
  (poo-kind? value +feature-bundle-v1-component-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-edge? value)
  (poo-kind? value +feature-bundle-v1-edge-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-evidence? value)
  (poo-kind? value +feature-bundle-v1-evidence-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-native-component? value)
  (poo-kind? value +feature-bundle-v1-native-component-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-native-symbol? value)
  (poo-kind? value +feature-bundle-v1-native-symbol-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-native-edge? value)
  (poo-kind? value +feature-bundle-v1-native-edge-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-native-evidence? value)
  (poo-kind? value +feature-bundle-v1-native-evidence-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-region? value)
  (poo-kind? value +feature-bundle-v1-region-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-descriptor? value)
  (poo-kind? value +feature-bundle-v1-descriptor-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-diagnostic? value)
  (poo-kind? value +feature-bundle-v1-diagnostic-kind+))

;; : (-> Object Boolean)
(def (feature-bundle-v1-lowering-plan? value)
  (poo-kind? value +feature-bundle-v1-lowering-plan-kind+))

;; : (-> Object Boolean)
(def (valid-uint64? value)
  (and (integer? value)
       (exact? value)
       (>= value 0)
       (< value +feature-bundle-v1-uint64-modulus+)))

;; : (-> Object Boolean)
(def (valid-semantic-id? value)
  (cond
   ((symbol? value) #t)
   ((string? value) (> (string-length value) 0))
   ((valid-uint64? value) #t)
   (else #f)))

;; : (-> Object String)
(def (semantic-id->string value)
  (cond
   ((symbol? value) (string-append "symbol:" (symbol->string value)))
   ((string? value) (string-append "string:" value))
   ((and (integer? value) (exact? value))
    (string-append "integer:" (number->string value)))
   (else (error "Bundle v1 semantic identity expected" value))))

;; : (-> U8Vector Integer Integer)
(def (digest-segment->uint64 digest start)
  (poo-flow-fold-left
   (lambda (byte accumulator)
     (modulo (+ (* accumulator 256) byte)
             +feature-bundle-v1-uint64-modulus+))
   0
   (u8vector->list (subu8vector digest start (+ start 8)))))

;; : (-> Symbol Object PooFeatureBundleV1CompactId)
(def (feature-bundle-v1-lower-compact-id domain source)
  (unless (and (symbol? domain) (valid-semantic-id? source))
    (error "Bundle v1 compact identity requires a domain and semantic id"
           domain source))
  (let* ((canonical
          (string-append "poo-flow.bundle-v1.id/"
                         (symbol->string domain)
                         "/"
                         (semantic-id->string source)))
         (digest (sha256 canonical)))
    (feature-bundle-v1-compact-id
     domain source
     (digest-segment->uint64 digest 0)
     (digest-segment->uint64 digest 8))))

;; : (-> PooFeatureBundleV1CompactId PooFeatureBundleV1CompactId Boolean)
(def (feature-bundle-v1-compact-id=? left right)
  (and (= (.ref left 'high) (.ref right 'high))
       (= (.ref left 'low) (.ref right 'low))))

;; : (-> PooFeatureBundleV1CompactId PooFeatureBundleV1CompactId Boolean)
(def (feature-bundle-v1-compact-id<? left right)
  (or (< (.ref left 'high) (.ref right 'high))
      (and (= (.ref left 'high) (.ref right 'high))
           (< (.ref left 'low) (.ref right 'low)))))

;; : (-> Object Boolean)
(def (valid-composition-order? value)
  (valid-uint64? value))

;; : (-> Object Boolean)
(def (valid-symbol-kind? value)
  (and (integer? value)
       (exact? value)
       (>= value 0)
       (< value +feature-bundle-v1-uint16-modulus+)))

;; : (-> POOObject [Symbol] Boolean)
(def (object-has-valid-ids? value slots)
  (poo-flow-all?
   (lambda (slot)
     (and (.slot? value slot)
          (valid-semantic-id? (.ref value slot))))
   slots))

;; : (-> Object Boolean)
(def (valid-component? value)
  (and (feature-bundle-v1-component? value)
       (object-has-valid-ids?
        value
        '(case-id component-id object-id type-id contract-id role-id
          capability-id policy-id strategy-id adapter-id projection-id))
       (.slot? value 'composition-order)
       (valid-composition-order? (.ref value 'composition-order))))

;; : (-> Object Boolean)
(def (valid-symbol? value)
  (and (feature-bundle-v1-symbol? value)
       (.slot? value 'domain)
       (symbol? (.ref value 'domain))
       (.slot? value 'source)
       (valid-semantic-id? (.ref value 'source))
       (.slot? value 'value)
       (string? (.ref value 'value))
       (> (string-length (.ref value 'value)) 0)
       (.slot? value 'symbol-kind)
       (valid-symbol-kind? (.ref value 'symbol-kind))))

;; : (-> Object Boolean)
(def (valid-edge? value)
  (and (feature-bundle-v1-edge? value)
       (object-has-valid-ids?
        value
        '(case-id source-component-id target-component-id relation-id))
       (.slot? value 'composition-order)
       (valid-composition-order? (.ref value 'composition-order))))

;; : (-> Object Boolean)
(def (valid-evidence? value)
  (and (feature-bundle-v1-evidence? value)
       (object-has-valid-ids?
        value
        '(case-id obligation-id contract-id evidence-type-id proof-system-id))
       (.slot? value 'composition-order)
       (valid-composition-order? (.ref value 'composition-order))))

;; : (-> PooFeatureBundleV1Component PooFeatureBundleV1NativeComponent)
(def (lower-component value)
  (feature-bundle-v1-native-component
   (feature-bundle-v1-lower-compact-id 'case (.ref value 'case-id))
   (feature-bundle-v1-lower-compact-id 'component (.ref value 'component-id))
   (feature-bundle-v1-lower-compact-id 'object (.ref value 'object-id))
   (feature-bundle-v1-lower-compact-id 'type (.ref value 'type-id))
   (feature-bundle-v1-lower-compact-id 'contract (.ref value 'contract-id))
   (feature-bundle-v1-lower-compact-id 'role (.ref value 'role-id))
   (feature-bundle-v1-lower-compact-id
    'capability (.ref value 'capability-id))
   (feature-bundle-v1-lower-compact-id 'policy (.ref value 'policy-id))
   (feature-bundle-v1-lower-compact-id 'strategy (.ref value 'strategy-id))
   (feature-bundle-v1-lower-compact-id 'adapter (.ref value 'adapter-id))
   (feature-bundle-v1-lower-compact-id
    'projection (.ref value 'projection-id))
   (.ref value 'composition-order)
   +feature-bundle-v1-component-enabled-flag+
   0
   0))

;; : (-> PooFeatureBundleV1Symbol PooFeatureBundleV1NativeSymbol)
(def (lower-symbol value)
  (let (value-bytes (string->utf8 (.ref value 'value)))
    (feature-bundle-v1-native-symbol
     (feature-bundle-v1-lower-compact-id
      (.ref value 'domain)
      (.ref value 'source))
     0
     (u8vector-length value-bytes)
     (.ref value 'symbol-kind)
     0
     value-bytes)))

;; : (-> PooFeatureBundleV1NativeSymbol Integer PooFeatureBundleV1NativeSymbol)
(def (symbol-with-offset value byte-offset)
  (feature-bundle-v1-native-symbol
   (.ref value 'id)
   byte-offset
   (.ref value 'byte-length)
   (.ref value 'symbol-kind)
   (.ref value 'flags)
   (.ref value 'value-bytes)))

;; : (-> [PooFeatureBundleV1NativeSymbol] [PooFeatureBundleV1NativeSymbol])
(def (assign-symbol-offsets values)
  (let (state
        (poo-flow-fold-left
         (lambda (value state)
           (let ((byte-offset (car state))
                 (out (cdr state)))
             (cons (+ byte-offset (.ref value 'byte-length))
                   (cons (symbol-with-offset value byte-offset) out))))
         (cons 0 '())
         values))
    (reverse (cdr state))))

;; : (-> PooFeatureBundleV1Edge PooFeatureBundleV1NativeEdge)
(def (lower-edge value)
  (feature-bundle-v1-native-edge
   (feature-bundle-v1-lower-compact-id 'case (.ref value 'case-id))
   (feature-bundle-v1-lower-compact-id
    'component (.ref value 'source-component-id))
   (feature-bundle-v1-lower-compact-id
    'component (.ref value 'target-component-id))
   (feature-bundle-v1-lower-compact-id 'relation (.ref value 'relation-id))
   (.ref value 'composition-order)
   0
   0))

;; : (-> PooFeatureBundleV1Evidence PooFeatureBundleV1NativeEvidence)
(def (lower-evidence value)
  (feature-bundle-v1-native-evidence
   (feature-bundle-v1-lower-compact-id 'case (.ref value 'case-id))
   (feature-bundle-v1-lower-compact-id
    'obligation (.ref value 'obligation-id))
   (feature-bundle-v1-lower-compact-id 'contract (.ref value 'contract-id))
   (feature-bundle-v1-lower-compact-id
    'evidence-type (.ref value 'evidence-type-id))
   (feature-bundle-v1-lower-compact-id
    'proof-system (.ref value 'proof-system-id))
   (.ref value 'composition-order)
   0
   0))
