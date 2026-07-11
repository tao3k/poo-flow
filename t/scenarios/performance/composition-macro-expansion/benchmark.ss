;;; -*- Gerbil -*-
;;; Boundary: compiler-process benchmark for the production composition macro.

(import :std/misc/process
        :std/srfi/13
        (only-in :clan/poo/object .o .ref))

(export run-composition-macro-expansion-case
        run-composition-macro-expansion-benchmark
        composition-macro-expansion-benchmark->alist)

(def +composition-expansion-1000-source+
  "t/scenarios/performance/composition-macro-expansion/case-1000.ss")

(def +composition-expansion-5000-source+
  "t/scenarios/performance/composition-macro-expansion/case-5000.ss")

(def +composition-expansion-1000-output-directory+
  ".cache/composition-macro-expansion-1000")

(def +composition-expansion-5000-first-output-directory+
  ".cache/composition-macro-expansion-5000-first")

(def +composition-expansion-5000-second-output-directory+
  ".cache/composition-macro-expansion-5000-second")

(def +composition-expansion-1000-max-rss-bytes+ (* 256 1024 1024))
(def +composition-expansion-5000-max-rss-bytes+ (* 384 1024 1024))
(def +composition-expansion-max-elapsed-ms+ 20000.0)
(def +composition-expansion-max-rss-drift-bytes+ (* 32 1024 1024))

;; : (-> String [String])
(def (composition-benchmark-output-lines output)
  (string-split output #\newline))

;; : (-> [String] Flonum)
(def (composition-benchmark-real-seconds lines)
  (let loop ((rest lines))
    (if (null? rest)
      (error "composition benchmark output has no real-time metric")
      (let (tokens (string-tokenize (car rest)))
        (if (and (= (length tokens) 2)
                 (string=? (car tokens) "real"))
          (or (string->number (cadr tokens))
              (error "invalid composition benchmark real-time metric"
                     (car rest)))
          (loop (cdr rest)))))))

;; : (-> [String] Integer)
(def (composition-benchmark-max-rss-bytes lines)
  (let loop ((rest lines))
    (if (null? rest)
      (error "composition benchmark output has no maximum RSS metric")
      (let (tokens (string-tokenize (car rest)))
        (if (and (= (length tokens) 5)
                 (string=? (cadr tokens) "maximum")
                 (string=? (caddr tokens) "resident"))
          (or (string->number (car tokens))
              (error "invalid composition benchmark maximum RSS metric"
                     (car rest)))
          (loop (cdr rest)))))))

;; : (-> Fixnum String Integer Flonum Integer PooBenchmarkReceipt)
(def (run-composition-macro-expansion-case
      profile-count
      source
      output-directory
      max-rss
      max-elapsed-ms)
  (unless (file-exists? output-directory)
    (create-directory output-directory))
  (let* ((output
          (run-process
           (list "/usr/bin/time"
                 "-lp"
                 "env"
                 "-u"
                 "SDKROOT"
                 "gxc"
                 "-S"
                 "-d"
                 output-directory
                 source)
           stderr-redirection: #t))
         (lines (composition-benchmark-output-lines output))
         (elapsed-ms (* 1000.0
                        (composition-benchmark-real-seconds lines)))
         (max-rss-bytes
          (composition-benchmark-max-rss-bytes lines)))
    (let ((source-value source)
          (profile-count-value profile-count)
          (elapsed-ms-value elapsed-ms)
          (max-rss-bytes-value max-rss-bytes)
          (max-elapsed-ms-value max-elapsed-ms)
          (max-rss-value max-rss)
          (pass-value
           (and (<= elapsed-ms max-elapsed-ms)
                (<= max-rss-bytes max-rss))))
      (.o (kind 'poo-flow.composition.macro-expansion.benchmark)
          (source source-value)
          (profile-count profile-count-value)
          (generated-profile-expression-count profile-count-value)
          (generated-compose-reference-count profile-count-value)
          (compiler-mode 'gerbil-expansion-and-scheme-generation)
          (gsc-executed #f)
          (elapsed-ms elapsed-ms-value)
          (max-rss-bytes max-rss-bytes-value)
          (max-elapsed-ms max-elapsed-ms-value)
          (max-rss-budget-bytes max-rss-value)
          (pass pass-value)))))

;; : (-> PooBenchmarkSuiteReceipt)
(def (run-composition-macro-expansion-benchmark)
  (let* ((case-1000
          (run-composition-macro-expansion-case
           1000
           +composition-expansion-1000-source+
           +composition-expansion-1000-output-directory+
           +composition-expansion-1000-max-rss-bytes+
           +composition-expansion-max-elapsed-ms+))
         (case-5000-first
          (run-composition-macro-expansion-case
           5000
           +composition-expansion-5000-source+
           +composition-expansion-5000-first-output-directory+
           +composition-expansion-5000-max-rss-bytes+
           +composition-expansion-max-elapsed-ms+))
         (case-5000-second
          (run-composition-macro-expansion-case
           5000
           +composition-expansion-5000-source+
           +composition-expansion-5000-second-output-directory+
           +composition-expansion-5000-max-rss-bytes+
           +composition-expansion-max-elapsed-ms+))
         (rss-drift
          (abs
           (- (.ref case-5000-second 'max-rss-bytes)
              (.ref case-5000-first 'max-rss-bytes))))
         (stable-rss
          (<= rss-drift
              +composition-expansion-max-rss-drift-bytes+)))
    (let ((case-1000-value case-1000)
          (case-5000-first-value case-5000-first)
          (case-5000-second-value case-5000-second)
          (rss-drift-value rss-drift)
          (stable-rss-value stable-rss)
          (pass-value
           (and (.ref case-1000 'pass)
                (.ref case-5000-first 'pass)
                (.ref case-5000-second 'pass)
                stable-rss)))
      (.o (kind 'poo-flow.composition.macro-expansion.benchmark-suite)
          (case-1000 case-1000-value)
          (case-5000-first case-5000-first-value)
          (case-5000-second case-5000-second-value)
          (rss-drift-bytes rss-drift-value)
          (max-rss-drift-bytes
           +composition-expansion-max-rss-drift-bytes+)
          (stable-rss stable-rss-value)
          (pass pass-value)))))

;; : (-> PooBenchmarkReceipt Alist)
(def (composition-macro-expansion-case->alist receipt)
  (list
   (cons 'profile-count (.ref receipt 'profile-count))
   (cons 'generated-profile-expression-count
         (.ref receipt 'generated-profile-expression-count))
   (cons 'generated-compose-reference-count
         (.ref receipt 'generated-compose-reference-count))
   (cons 'gsc-executed (.ref receipt 'gsc-executed))
   (cons 'elapsed-ms (.ref receipt 'elapsed-ms))
   (cons 'max-rss-bytes (.ref receipt 'max-rss-bytes))
   (cons 'pass (.ref receipt 'pass))))

;;; Project the POO receipt only at the subprocess test/report boundary.
;; : (-> PooBenchmarkSuiteReceipt Alist)
(def (composition-macro-expansion-benchmark->alist receipt)
  (list
   (cons 'case-1000
         (composition-macro-expansion-case->alist
          (.ref receipt 'case-1000)))
   (cons 'case-5000-first
         (composition-macro-expansion-case->alist
          (.ref receipt 'case-5000-first)))
   (cons 'case-5000-second
         (composition-macro-expansion-case->alist
          (.ref receipt 'case-5000-second)))
   (cons 'rss-drift-bytes (.ref receipt 'rss-drift-bytes))
   (cons 'stable-rss (.ref receipt 'stable-rss))
   (cons 'pass (.ref receipt 'pass))))
