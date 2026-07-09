;;; -*- Gerbil -*-
;;; Boundary: shared CLI process, loadpath, string, and RSS helpers.
;;; Invariant: this owner has no command dispatch.

(import :gerbil/gambit
        (only-in :std/misc/process run-process)
        (only-in :std/sugar foldl)
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
        poo-flow-cli-gerbil-env-vars-argv
        poo-flow-cli-gerbil-env-argv
        poo-flow-cli-string-contains?
        poo-flow-cli-max-rss-bytes
        poo-flow-cli-megabytes->bytes)

;;; Intent: keep focused child commands anchored at the package source root.
;;; Boundary: this path is prepended before compiled artifacts.
;; : (-> String)
(def (poo-flow-cli-local-source-loadpath)
  ".")

;;; Intent: name the package-local compiled artifact directory used by gxpkg.
;;; Boundary: callers do not expand to the user-level ~/.gerbil cache.
;; : (-> String)
(def (poo-flow-cli-package-compiled-loadpath)
  ".gerbil/lib")

;;; Intent: write user-facing CLI diagnostics to stderr with a newline.
;;; Boundary: formatting stays plain text so tests can match exact repair lines.
;; : (-> String Void)
(def (poo-flow-cli-error message)
  (display message (current-error-port))
  (newline (current-error-port)))

;;; Intent: normalize process statuses into portable shell exit codes.
;;; Boundary: subprocess launchers store raw statuses; callers receive 0..255.
;; : (-> Integer Integer)
(def (poo-flow-cli-exit-code status)
  (cond
   ((< status 0) 1)
   ((> status 255) (quotient status 256))
   (else status)))

;;; Intent: drop the launcher and command tokens before script dispatch.
;;; Boundary: the script receives only user arguments after `poo-flow run file`.
;; : (-> [String] [String])
(def (poo-flow-cli-script-args command-line-args)
  (if (and (pair? command-line-args)
           (pair? (cdr command-line-args)))
    (cddr command-line-args)
    '()))

;;; Intent: expose command argv after the executable token for CLI dispatch.
;;; Boundary: empty argv stays empty rather than raising during help handling.
;; : (-> [String] [String])
(def (poo-flow-cli-executable-args command-line-args)
  (if (pair? command-line-args)
    (cdr command-line-args)
    '()))

;;; Intent: join the project source and compiled artifact loadpath segments.
;;; Boundary: this base path excludes user caches and external overrides.
;; : (-> String)
(def (poo-flow-cli-local-loadpath)
  (string-append (poo-flow-cli-local-source-loadpath)
                 ":"
                 (poo-flow-cli-package-compiled-loadpath)))

;;; Intent: discover the optional user compiled package cache for fallback loads.
;;; Boundary: returns #f when HOME is unavailable so callers can skip it.
;; : (-> (U #f String))
(def (poo-flow-cli-user-package-compiled-loadpath)
  (let (home (getenv "HOME" #f))
    (and home (path-expand ".gerbil/lib" home))))

;;; Intent: add an existing loadpath segment while ignoring absent optional caches.
;;; Boundary: preserves caller order by consing only validated path strings.
;; : (-> (U #f String) (List String) (List String))
(def (poo-flow-cli-cons-existing-loadpath path paths)
  (if (and path (not (string=? path "")) (file-exists? path))
    (cons path paths)
    paths))

;;; Intent: render a colon-separated GERBIL_LOADPATH from validated segments.
;;; Boundary: the empty list becomes the empty string for env compatibility.
;; : (-> (List String) String)
(def (poo-flow-cli-join-loadpath paths)
  (match paths
    ([] "")
    ([path] path)
    ([path . rest]
     (foldl (lambda (next-path joined)
              (string-append joined ":" next-path))
            path
            rest))))

;;; Intent: build the default loadpath order from source, package artifacts, user cache.
;;; Boundary: callers may append external loadpath entries after this default.
;; : (-> String)
(def (poo-flow-cli-default-loadpath)
  (poo-flow-cli-join-loadpath
   (reverse
    (poo-flow-cli-cons-existing-loadpath
     (poo-flow-cli-user-package-compiled-loadpath)
     (poo-flow-cli-cons-existing-loadpath
      (poo-flow-cli-package-compiled-loadpath)
      [(poo-flow-cli-local-source-loadpath)])))))

;;; Intent: build the child Gerbil loadpath with project artifacts first.
;;; Boundary: user GERBIL_LOADPATH is appended, never allowed to shadow local code.
;; : (-> String)
(def (poo-flow-cli-gerbil-loadpath)
  (let ((current (getenv "GERBIL_LOADPATH" #f))
        (local-loadpath (poo-flow-cli-default-loadpath)))
    (if (and current (not (string=? current "")))
      (string-append local-loadpath ":" current)
      local-loadpath)))

;;; Intent: construct the argv used by `poo-flow run` for Scheme scripts.
;;; Boundary: script execution goes through gxpkg env gxi in this package.
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

;;; Intent: spawn child commands that should stream directly to the terminal.
;;; Boundary: status is captured, but stdout/stderr ownership stays with child.
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

;;; Intent: run a child command when the caller must inspect combined output.
;;; Boundary: returns a pair of normalized exit code and captured text.
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

;;; Intent: attach environment bindings before a package-local Gerbil command.
;;; Boundary: used by tests and perf commands that need a scoped child env.
;; : (-> [String] String [String] [String])
(def (poo-flow-cli-gerbil-env-vars-argv env-bindings executable args)
  (append
   (list "env"
         (string-append "GERBIL_LOADPATH="
                        (poo-flow-cli-gerbil-loadpath)))
   env-bindings
   (list executable)
   args))

;;; Intent: create a package-local Gerbil command without extra env bindings.
;;; Boundary: preserves the same loadpath construction as env-bearing commands.
;; : (-> String [String] [String])
(def (poo-flow-cli-gerbil-env-argv executable args)
  (poo-flow-cli-gerbil-env-vars-argv [] executable args))

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

;;; Boundary: cli leading number is the policy-visible edge for CLI behavior,
;;; keeping validation, lookup, or projection responsibilities centralized for
;;; callers.
;; : (-> String (U #f Integer))
(def (poo-flow-cli-leading-number text)
  (let* ((length (string-length text))
         (start (poo-flow-cli-skip-whitespace text 0 length))
         (end (poo-flow-cli-skip-digits text start length)))
    (if (> end start)
      (string->number (substring text start end))
      #f)))

;;; Intent: locate a delimiter before numeric field parsing.
;;; Boundary: returns #f when the delimiter is absent.
;; : (-> String Char Fixnum Fixnum (U #f Fixnum))
(def (poo-flow-cli-find-char text ch start length)
  (string-index text ch start length))

;;; Intent: parse GNU /usr/bin/time fields such as `Maximum ...: 123`.
;;; Boundary: returns #f unless digits follow the requested delimiter.
;; : (-> String Char (U #f Integer))
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

;;; Intent: normalize platform-specific maximum RSS output to bytes.
;;; Boundary: Darwin already reports bytes; GNU reports kilobytes after colon.
;; : (-> String (U #f Integer))
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
;; : (-> [String] (U #f Integer))
(def (poo-flow-cli-first-rss-bytes lines)
  (cond
   ((null? lines) #f)
   (else
    (let (bytes (poo-flow-cli-rss-line-bytes (car lines)))
      (if bytes
        bytes
        (poo-flow-cli-first-rss-bytes (cdr lines)))))))

;;; Intent: extract the first RSS value emitted by /usr/bin/time.
;;; Boundary: supports Darwin bytes and GNU/Linux kilobytes output formats.
;; : (-> String (U #f Integer))
(def (poo-flow-cli-max-rss-bytes output)
  (poo-flow-cli-first-rss-bytes (string-split output #\newline)))

;; : (-> Integer Integer)
(def (poo-flow-cli-megabytes->bytes megabytes)
  (* megabytes 1024 1024))
