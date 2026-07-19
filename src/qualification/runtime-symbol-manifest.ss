;;; -*- Gerbil -*-
;;; Boundary: Scheme owns JSON symbol-manifest validation; shell only collects nm.

(export #t)

(import :clan/poo/object
        :std/sort
        (only-in :std/misc/walist walist? walist->alist)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/text/json
                 read-json
                 read-json-array-as-vector?
                 read-json-key-as-symbol?
                 read-json-object-as-walist?))

(def +poo-flow-runtime-symbol-manifest-schema+
  "poo-flow.runtime-symbol-manifest.v1")
(def +poo-flow-runtime-symbol-manifest-version+ 1)

(def (symbol-manifest-ref rows key default)
  (let (entry (assq key rows))
    (if entry (cdr entry) default)))

(def (symbol-string-list? values)
  (and (list? values) (andmap string? values)))

(def (canonical-symbols values)
  (sort (append values '()) string<?))

(def (invalid-symbol-manifest)
  (object<-alist
   '((kind . poo-flow.runtime-symbol-manifest.v1)
     (schema . #f)
     (schema-version . #f)
     (abi . #f)
     (required-symbols . #f)
     (forbidden-fragments . #f)
     (owners . #f))))

(def (poo-flow-runtime-symbol-manifest-read port)
  (with-catch
   (lambda (_failure) (invalid-symbol-manifest))
   (lambda ()
     (let (decoded
           (parameterize ((read-json-key-as-symbol? #t)
                          (read-json-object-as-walist? #t)
                          (read-json-array-as-vector? #f))
             (read-json port)))
       (if (not (walist? decoded))
           (invalid-symbol-manifest)
           (let (rows (walist->alist decoded))
             (object<-alist
              (list
               (cons 'kind 'poo-flow.runtime-symbol-manifest.v1)
               (cons 'schema (symbol-manifest-ref rows 'schema #f))
               (cons 'schema-version
                     (symbol-manifest-ref rows 'schemaVersion #f))
               (cons 'abi (symbol-manifest-ref rows 'abi #f))
               (cons 'required-symbols
                     (symbol-manifest-ref rows 'requiredSymbols #f))
               (cons 'forbidden-fragments
                     (symbol-manifest-ref rows 'forbiddenFragments #f))
               (cons 'owners (symbol-manifest-ref rows 'owners #f))))))))))

(def (poo-flow-runtime-symbol-manifest-read-file path)
  (call-with-input-file path poo-flow-runtime-symbol-manifest-read))

(def (poo-flow-runtime-symbol-manifest-verify manifest actual-symbols)
  (let* ((required (.ref manifest 'required-symbols))
         (forbidden (.ref manifest 'forbidden-fragments))
         (shape-valid?
          (and (equal? (.ref manifest 'schema)
                       +poo-flow-runtime-symbol-manifest-schema+)
               (equal? (.ref manifest 'schema-version)
                       +poo-flow-runtime-symbol-manifest-version+)
               (string? (.ref manifest 'abi))
               (symbol-string-list? required)
               (symbol-string-list? forbidden)
               (symbol-string-list? (.ref manifest 'owners))
               (symbol-string-list? actual-symbols)))
         (expected (if shape-valid? (canonical-symbols required) '()))
         (actual (if shape-valid? (canonical-symbols actual-symbols) '()))
         (forbidden-symbols
          (if shape-valid?
              (filter (lambda (symbol)
                        (ormap (lambda (fragment)
                                 (string-contains symbol fragment))
                               forbidden))
                      actual)
              '()))
         (accepted?
          (and shape-valid? (equal? expected actual)
               (null? forbidden-symbols))))
    (object<-alist
     (list
      (cons 'kind 'poo-flow.runtime-symbol-manifest-receipt.v1)
      (cons 'schema "poo-flow.runtime-symbol-manifest-receipt.v1")
      (cons 'schema-version 1)
      (cons 'accepted? accepted?)
      (cons 'abi (if shape-valid? (.ref manifest 'abi) #f))
      (cons 'expected-symbols expected)
      (cons 'actual-symbols actual)
      (cons 'forbidden-symbols forbidden-symbols)
      (cons 'diagnostics
            (cond
             ((not shape-valid?) '(invalid-or-unknown-manifest))
             ((not (equal? expected actual)) '(exported-symbol-drift))
             ((pair? forbidden-symbols) '(forbidden-symbol))
             (else '())))))))
