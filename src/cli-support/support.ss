;;; -*- Gerbil -*-
;;; Boundary: shared CLI process, loadpath, string, and RSS helpers.
;;; Invariant: this owner has no command dispatch.

(import :gerbil/gambit
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/1 filter-map)
        (only-in :std/srfi/13
                 string-contains
                 string-index
                 string-prefix?
                 string-skip
                 string-suffix?))

(export poo-flow-cli-error
        poo-flow-cli-exit-code
        poo-flow-cli-script-args
        poo-flow-cli-executable-args
        poo-flow-cli-run-file
        poo-flow-cli-run-inherited
        poo-flow-cli-run-captured
        poo-flow-cli-gerbil-env-argv
        poo-flow-cli-string-prefix?
        poo-flow-cli-string-suffix?
        poo-flow-cli-string-contains?
        poo-flow-cli-max-rss-bytes
        poo-flow-cli-megabytes->bytes)

;; : (-> Unit String)
(def (poo-flow-cli-local-source-loadpath)
  ".")

;; : (-> Unit String)
(def (poo-flow-cli-package-compiled-loadpath)
  ".gerbil/lib")

;; : (-> String Void)
(def (poo-flow-cli-error message)
  (display message (current-error-port))
  (newline (current-error-port)))

;; : (-> Integer Integer)
(def (poo-flow-cli-exit-code status)
  (cond
   ((< status 0) 1)
   ((> status 255) (quotient status 256))
   (else status)))

;; : (-> [String] [String])
(def (poo-flow-cli-script-args command-line-args)
  (if (and (pair? command-line-args)
           (pair? (cdr command-line-args)))
    (cddr command-line-args)
    '()))

;; : (-> [String] [String])
(def (poo-flow-cli-executable-args command-line-args)
  (if (pair? command-line-args)
    (cdr command-line-args)
    '()))

;; : (-> Unit String)
(def (poo-flow-cli-local-loadpath)
  (string-append (poo-flow-cli-local-source-loadpath)
                 ":"
                 (poo-flow-cli-package-compiled-loadpath)))

;; : (-> Unit String)
(def (poo-flow-cli-gerbil-loadpath)
  (let ((current (getenv "GERBIL_LOADPATH" #f))
        (local-loadpath (poo-flow-cli-local-loadpath)))
    (if (and current (not (string=? current "")))
      (string-append local-loadpath ":" current)
      local-loadpath)))

;; : (-> String [String] [String])
(def (poo-flow-cli-run-command file args)
  (append
   (list "env"
         (string-append "GERBIL_LOADPATH="
                        (poo-flow-cli-gerbil-loadpath))
         "gxpkg"
         "env"
         "gxi"
         file)
   args))

;;; Boundary: child output is passed through as the run receipt surface.
;;; Intent: scripts own funflow construction; CLI only reports process status.
;; : (-> String [String] Integer)
(def (poo-flow-cli-run-file file args)
  (let (status 0)
    (let (output
          (run-process
           (poo-flow-cli-run-command file args)
           stderr-redirection: #t
           check-status:
           (lambda (exit-status _settings)
             (set! status exit-status))))
      (display output)
      (poo-flow-cli-exit-code status))))

;; : (-> [String] Integer)
(def (poo-flow-cli-run-inherited argv)
  (let (status 0)
    (run-process argv
                 stdin-redirection: #f
                 stdout-redirection: #f
                 stderr-redirection: #f
                 check-status:
                 (lambda (exit-status _settings)
                   (set! status exit-status)))
    (poo-flow-cli-exit-code status)))

;; : (-> [String] Pair)
(def (poo-flow-cli-run-captured argv)
  (let (status 0)
    (let (output
          (run-process argv
                       stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status exit-status))))
      (cons (poo-flow-cli-exit-code status) output))))

;; : (-> String [String] [String])
(def (poo-flow-cli-gerbil-env-argv executable args)
  (append
   (list "env"
         (string-append "GERBIL_LOADPATH="
                        (poo-flow-cli-gerbil-loadpath))
         executable)
   args))

;; : (-> String String Boolean)
(def (poo-flow-cli-string-prefix? prefix text)
  (string-prefix? prefix text))

;; : (-> String String Boolean)
(def (poo-flow-cli-string-suffix? suffix text)
  (string-suffix? suffix text))

;;; Intent: expose a boolean containment predicate over the SRFI index result.
;;; Boundary: callers do not depend on the match offset.
;; : (-> String String Boolean)
(def (poo-flow-cli-string-contains? needle text)
  (if (string-contains text needle) #t #f))

;;; Intent: normalize SRFI skip failure to the caller-provided end boundary.
;;; Boundary: only ASCII process-output parsing calls this helper.
;; : (-> String Fixnum Fixnum Fixnum)
(def (poo-flow-cli-skip-whitespace text start end)
  (or (string-skip text char-whitespace? start end) end))

;;; Intent: normalize digit scanning for /usr/bin/time numeric fields.
;;; Boundary: process output uses decimal ASCII numbers.
;; : (-> String Fixnum Fixnum Fixnum)
(def (poo-flow-cli-skip-digits text start end)
  (or (string-skip text char-numeric? start end) end))

;;; Intent: find the current output line boundary without allocating state.
;;; Boundary: returns string length when no newline exists after start.
;; : (-> String Fixnum Fixnum)
(def (poo-flow-cli-find-newline text start)
  (let (length (string-length text))
    (or (string-index text #\newline start length) length)))

;; : (-> String MaybeInteger)
(def (poo-flow-cli-leading-number text)
  (let* ((length (string-length text))
         (start (poo-flow-cli-skip-whitespace text 0 length))
         (end (poo-flow-cli-skip-digits text start length)))
    (if (> end start)
      (string->number (substring text start end))
      #f)))

;;; Intent: locate a delimiter before numeric field parsing.
;;; Boundary: returns #f when the delimiter is absent.
;; : (-> String Char Fixnum Fixnum MaybeFixnum)
(def (poo-flow-cli-find-char text ch start length)
  (string-index text ch start length))

;; : (-> String Char MaybeInteger)
(def (poo-flow-cli-number-after-char text ch)
  (let* ((length (string-length text))
         (anchor (poo-flow-cli-find-char text ch 0 length)))
    (if anchor
      (let* ((start (poo-flow-cli-skip-whitespace text (+ anchor 1) length))
             (end (poo-flow-cli-skip-digits text start length)))
        (if (> end start)
          (string->number (substring text start end))
          #f))
      #f)))

;; : (-> String MaybeInteger)
(def (poo-flow-cli-rss-line-bytes line)
  (cond
   ((poo-flow-cli-string-contains? "maximum resident set size" line)
    (poo-flow-cli-leading-number line))
   ((poo-flow-cli-string-contains? "Maximum resident set size" line)
    (let (kbytes (poo-flow-cli-number-after-char line #\:))
      (if kbytes
        (* kbytes 1024)
        #f)))
   (else #f)))

;;; Intent: select the first parseable RSS value from process output lines.
;;; Boundary: line parsing remains delegated to platform-specific RSS rules.
;; : (-> [String] MaybeInteger)
(def (poo-flow-cli-first-rss-bytes lines)
  (let (matches (filter-map poo-flow-cli-rss-line-bytes lines))
    (and (pair? matches) (car matches))))

;;; Intent: extract the first RSS value emitted by /usr/bin/time.
;;; Boundary: supports Darwin bytes and GNU/Linux kilobytes output formats.
;; : (-> String MaybeInteger)
(def (poo-flow-cli-max-rss-bytes output)
  (poo-flow-cli-first-rss-bytes (string-split output #\newline)))

;; : (-> Integer Integer)
(def (poo-flow-cli-megabytes->bytes megabytes)
  (* megabytes 1024 1024))
