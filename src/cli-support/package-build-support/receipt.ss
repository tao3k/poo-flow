;;; -*- Gerbil -*-
;;; Local package build freshness receipts for the POO Flow builder.

(import :gerbil/gambit)

(export #t)

;; : Symbol
(def poo-flow-package-build-receipt-version
  'poo-flow-package-build-receipt.v1)

;; : (forall (a) (-> PackageReceipt Symbol a a))
;; | type PackageReceipt = Alist
;; | type a = PackageReceiptValue
(def (poo-flow-package-build-receipt-ref receipt key default)
  (let (entry (assq key receipt))
    (if entry (cdr entry) default)))

;; : (-> PackageReceiptPathListCandidate Boolean)
(def (poo-flow-package-build-receipt-path-list? value)
  (and (list? value)
       (andmap string? value)))

;; : (-> String Integer)
(def (poo-flow-package-build-receipt-file-seconds path)
  (time->seconds (file-info-last-modification-time (file-info path))))

;; : (-> String String Boolean)
(def (poo-flow-package-build-receipt-file-newer-than? path stamp)
  (> (poo-flow-package-build-receipt-file-seconds path)
     (poo-flow-package-build-receipt-file-seconds stamp)))

;; : (-> [String] Boolean)
(def (poo-flow-package-build-receipt-all-exist? paths)
  (andmap file-exists? paths))

;; : (-> String [String] [String] version: Symbol metadata: Alist Void)
(def (poo-flow-package-build-receipt-write stamp sources outputs
                                           version: (version
                                                     poo-flow-package-build-receipt-version)
                                           metadata: (metadata []))
  (call-with-output-file stamp
    (lambda (port)
      (write (append
              `((version . ,version)
                (sources . ,sources)
                (outputs . ,outputs))
              metadata)
             port)
      (newline port))))

;; : (-> String version: Symbol MaybeAlist)
(def (poo-flow-package-build-receipt-read/raw stamp
                                              version: (version
                                                        poo-flow-package-build-receipt-version))
  (and (file-exists? stamp)
       (with-exception-catcher
        (lambda (_) #f)
        (lambda ()
          (let* ((receipt (call-with-input-file stamp read))
                 (receipt-version
                  (and (list? receipt)
                       (poo-flow-package-build-receipt-ref receipt
                                                           'version
                                                           #f)))
                 (sources
                  (and (list? receipt)
                       (poo-flow-package-build-receipt-ref receipt
                                                           'sources
                                                           #f)))
                 (outputs
                  (and (list? receipt)
                       (poo-flow-package-build-receipt-ref receipt
                                                           'outputs
                                                           #f))))
            (and (eq? receipt-version version)
                 (poo-flow-package-build-receipt-path-list? sources)
                 (poo-flow-package-build-receipt-path-list? outputs)
                 receipt))))))

;; : (-> String version: Symbol MaybePair)
(def (poo-flow-package-build-receipt-read stamp
                                          version: (version
                                                    poo-flow-package-build-receipt-version))
  (let (receipt (poo-flow-package-build-receipt-read/raw stamp
                                                         version: version))
    (and receipt
         (cons (poo-flow-package-build-receipt-ref receipt 'sources [])
               (poo-flow-package-build-receipt-ref receipt 'outputs [])))))

;; : (-> [String] [String] Boolean)
(def (poo-flow-package-build-receipt-populated? sources outputs)
  (and (pair? sources) (pair? outputs)))

;; : (-> [String] [String] MaybeStringList MaybeStringList Boolean)
(def (poo-flow-package-build-receipt-expected-shape? sources
                                                     outputs
                                                     expected-sources
                                                     expected-outputs)
  (and (or (not expected-sources) (equal? sources expected-sources))
       (or (not expected-outputs) (equal? outputs expected-outputs))))

;; : (-> String String Boolean)
(def (poo-flow-package-build-receipt-source-current? stamp source)
  (and (file-exists? source)
       (not (poo-flow-package-build-receipt-file-newer-than? source stamp))))

;; : (-> String [String] Boolean)
(def (poo-flow-package-build-receipt-sources-current? stamp sources)
  (cond
   ((null? sources) #t)
   ((poo-flow-package-build-receipt-source-current? stamp (car sources))
    (poo-flow-package-build-receipt-sources-current? stamp (cdr sources)))
   (else #f)))

;; : (-> String Pair expected-sources: MaybeStringList expected-outputs: MaybeStringList Boolean)
(def (poo-flow-package-build-receipt-current? stamp receipt
                                              expected-sources: (expected-sources #f)
                                              expected-outputs: (expected-outputs #f))
  (let ((sources (car receipt))
        (outputs (cdr receipt)))
    (and (poo-flow-package-build-receipt-populated? sources outputs)
         (poo-flow-package-build-receipt-expected-shape? sources
                                                         outputs
                                                         expected-sources
                                                         expected-outputs)
         (poo-flow-package-build-receipt-all-exist? outputs)
         (poo-flow-package-build-receipt-sources-current? stamp sources))))

;; : (-> PackageReceiptEntry Boolean)
(def (poo-flow-package-build-receipt-debug-metadata-entry? entry)
  (not (memq (car entry) '(version sources outputs))))

;; : (-> Alist Alist Alist)
(def (poo-flow-package-build-receipt-debug-metadata/rev receipt metadata-rev)
  (match receipt
    ([]
     metadata-rev)
    ([entry . rest]
     (poo-flow-package-build-receipt-debug-metadata/rev
      rest
      (if (poo-flow-package-build-receipt-debug-metadata-entry? entry)
        (cons entry metadata-rev)
        metadata-rev)))))

;; : (-> MaybeAlist Alist)
(def (poo-flow-package-build-receipt-debug-metadata receipt)
  (if receipt
    (reverse
     (poo-flow-package-build-receipt-debug-metadata/rev receipt []))
    []))

;; : (-> Symbol Symbol String MaybePair metadata: Alist Alist)
(def (poo-flow-package-build-receipt-make-status status
                                                 reason
                                                 stamp
                                                 receipt
                                                 metadata: (metadata []))
  (append
   `((status . ,status)
     (reason . ,reason)
     (sources . ,(if receipt (length (car receipt)) 0))
     (outputs . ,(if receipt (length (cdr receipt)) 0))
     (stamp . ,stamp))
   metadata))

;; : (-> String version: Symbol expected-sources: MaybeStringList expected-outputs: MaybeStringList Alist)
(def (poo-flow-package-build-receipt-status stamp
                                            version: (version
                                                      poo-flow-package-build-receipt-version)
                                            expected-sources: (expected-sources #f)
                                            expected-outputs: (expected-outputs #f))
  (cond
   ((not (file-exists? stamp))
    (poo-flow-package-build-receipt-make-status 'stale
                                                'missing-stamp
                                                stamp
                                                #f))
   (else
    (let* ((raw-receipt
            (poo-flow-package-build-receipt-read/raw stamp version: version))
           (receipt
            (and raw-receipt
                 (cons (poo-flow-package-build-receipt-ref raw-receipt
                                                           'sources
                                                           [])
                       (poo-flow-package-build-receipt-ref raw-receipt
                                                           'outputs
                                                           []))))
           (metadata
            (poo-flow-package-build-receipt-debug-metadata raw-receipt)))
      (cond
       ((not receipt)
        (poo-flow-package-build-receipt-make-status 'stale
                                                    'invalid-stamp
                                                    stamp
                                                    #f))
       ((poo-flow-package-build-receipt-current?
         stamp
         receipt
         expected-sources: expected-sources
         expected-outputs: expected-outputs)
        (poo-flow-package-build-receipt-make-status 'current
                                                    #f
                                                    stamp
                                                    receipt
                                                    metadata: metadata))
       (else
        (poo-flow-package-build-receipt-make-status
         'stale
         (if (or (and expected-sources
                      (not (equal? (car receipt) expected-sources)))
                 (and expected-outputs
                      (not (equal? (cdr receipt) expected-outputs))))
           'receipt-shape-mismatch
           'dirty-source-or-missing-output)
         stamp
         receipt
         metadata: metadata)))))))

;; : (forall (a) (-> PackageReceiptStatus Symbol a a))
;; | type PackageReceiptStatus = Alist
;; | type a = PackageReceiptValue
(def (poo-flow-package-build-receipt-status-ref status key default)
  (poo-flow-package-build-receipt-ref status key default))

;; : (-> Alist String)
(def (poo-flow-package-build-receipt-status-line status)
  (string-append
   "[poo-flow-package-build-receipt] status="
   (symbol->string
    (poo-flow-package-build-receipt-status-ref status 'status 'unknown))
   " sources="
   (number->string
    (poo-flow-package-build-receipt-status-ref status 'sources 0))
   " outputs="
   (number->string
    (poo-flow-package-build-receipt-status-ref status 'outputs 0))))
