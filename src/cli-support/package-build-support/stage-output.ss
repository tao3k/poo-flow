;;; -*- Gerbil -*-
;;; Package build support module split out of ../package-build.ss.

(import (only-in :gerbil/gambit
                 current-directory
                 current-jiffy
                 current-second
                 delete-file
                 delete-file-or-directory
                 directory-files
                 file-exists?
                 file-info
                 file-info-type
                 getenv
                 jiffies-per-second
                 path-expand
                 string=?
                 string-append
                 make-thread
                 thread-sleep!
                 thread-start!
                 ##os-file-times-set!
                 ##cpu-count)
        (only-in :gerbil/compiler/base
                 __available-cores)
        (only-in :gerbil/compiler
                 compile-module)
        (only-in :std/misc/process
                 run-process)
        (only-in :std/srfi/13
                 string-index
                 string-prefix?
                 string-skip
                 string-suffix?)
        (only-in :std/sugar
                 filter)
        (only-in "./specs.ss"
                 +poo-flow-build-macro-dependency-source-files+
                 +poo-flow-native-object-output-directory-cache+
                 +poo-flow-native-object-sibling-miss-limit+
                 poo-flow-package-append-missing
                 poo-flow-package-flat-map
                 poo-flow-string-member?
                 poo-flow-string-suffix?)
        (only-in "./env.ss"
                 poo-flow-delete-file-if-exists!
                 poo-flow-package-source-path
                 poo-flow-package-srcdir)
        (only-in "./options.ss"
                 poo-flow-cli-build-options?
                 poo-flow-debug-build-options?
                 poo-flow-native-build-options?
                 poo-flow-optimized-build-options?
                 poo-flow-release-build-options?))

(export #t)

;; : (forall (a) (-> (-> a Boolean) [a] Boolean))
(def (poo-flow-all? pred xs)
  (match xs
    ([] #t)
    ([x . rest]
     (and (pred x) (poo-flow-all? pred rest)))))

;; : (-> String)
(def (poo-flow-package-libdir)
  (path-expand "lib" (getenv "GERBIL_PATH")))

;; : (-> String)
(def (poo-flow-package-libdir-prefix)
  (path-expand "poo-flow" (poo-flow-package-libdir)))

;; : (-> BuildOptions [String] String)
(def (poo-flow-stage-cache-stamp-path options . maybe-label)
  (path-expand
   (string-append
    (cond
     ((poo-flow-cli-build-options? options) ".compile-cli")
     (else ".compile-package"))
    (cond
     ((poo-flow-release-build-options? options) "-release")
     ((poo-flow-optimized-build-options? options) "-optimized")
     ((poo-flow-debug-build-options? options) "-debug")
     (else ""))
    (if (null? maybe-label)
      ""
      (string-append "-" (car maybe-label)))
    ".stamp")
   (poo-flow-package-libdir-prefix)))

;; : (-> BuildOptions [String] String)
(def (poo-flow-stage-legacy-cache-stamp-path options . maybe-label)
  (path-expand
   (string-append
    (cond
     ((poo-flow-cli-build-options? options) ".compile-cli")
     (else ".compile-package"))
    (if (null? maybe-label)
      ""
      (string-append "-" (car maybe-label)))
    ".stamp")
   (poo-flow-package-libdir-prefix)))

;; : (-> String String)
(def (poo-flow-diagnostic-gxc-file file)
  (let (source (path-expand file (poo-flow-package-srcdir)))
    (if (file-exists? source)
      file
      (let (source.ss (string-append file ".ss"))
        (if (file-exists? (path-expand source.ss (poo-flow-package-srcdir)))
          source.ss
          file)))))

;; : (-> String String)
(def (poo-flow-gxc-source-file file)
  (cond
   ((file-exists? file) file)
   ((file-exists? (string-append file ".ss"))
    (string-append file ".ss"))
   (else file)))

;; : (-> String String String)
(def (poo-flow-diagnostic-suffixed-file file suffix)
  (let (source (path-expand file (poo-flow-package-srcdir)))
    (if (file-exists? source)
      file
      (let (source.suffixed (string-append file suffix))
        (if (file-exists? (path-expand source.suffixed
                                       (poo-flow-package-srcdir)))
          source.suffixed
          file)))))

;; : (-> String String)
(def (poo-flow-diagnostic-gsc-file file)
  (poo-flow-diagnostic-suffixed-file file ".scm"))

;; : (-> String String)
(def (poo-flow-diagnostic-ssi-file file)
  (poo-flow-diagnostic-suffixed-file file ".ssi"))

;; : (-> BuildSpec MaybeString)
(def (poo-flow-diagnostic-source-path spec)
  (match spec
    ([gxc: file . _]
     (path-expand
      (poo-flow-diagnostic-gxc-file file)
      (poo-flow-package-srcdir)))
    ([gsc: file . _]
     (path-expand
      (poo-flow-diagnostic-gsc-file file)
      (poo-flow-package-srcdir)))
    ([ssi: file . _]
     (path-expand
      (poo-flow-diagnostic-ssi-file file)
      (poo-flow-package-srcdir)))
    (_ #f)))

;; : (-> [String] [String] [String])
(def (poo-flow-stage-default-source-files/rev files sources-rev)
  (if (null? files)
    sources-rev
    (poo-flow-stage-default-source-files/rev
     (cdr files)
     (cons (path-expand (car files) (poo-flow-package-srcdir))
           sources-rev))))

;; : (-> [String])
(def (poo-flow-stage-default-source-files)
  (reverse
   (poo-flow-stage-default-source-files/rev
    '("build.ss" "gerbil.pkg")
    [])))

;; poo-flow-build-dependency-row-applies?
;;   : (-> [String] [String] Boolean)
;;   | doc m%
;;       Return true when any dependent source from a macro dependency row is in
;;       the current stage source set.
;;     %
(def (poo-flow-build-dependency-row-applies? stage-sources dependents)
  (match dependents
    ([] #f)
    ([dependent . rest]
     (or (poo-flow-string-member?
          (poo-flow-package-source-path dependent)
          stage-sources)
         (poo-flow-build-dependency-row-applies? stage-sources rest)))))

;; poo-flow-build-macro-dependency-sources/rev
;;   : (-> [[String]] [String] [String] [String])
;;   | doc m%
;;       Collect macro provider sources that must invalidate a stage when one of
;;       their dependent modules is compiled.
;;     %
(def (poo-flow-build-macro-dependency-sources/rev rows stage-sources sources-rev)
  (match rows
    ([] sources-rev)
    ([[provider . dependents] . rest]
     (poo-flow-build-macro-dependency-sources/rev
      rest
      stage-sources
      (if (poo-flow-build-dependency-row-applies? stage-sources dependents)
        (cons (poo-flow-package-source-path provider) sources-rev)
        sources-rev)))))

;; poo-flow-build-macro-dependency-sources
;;   : (-> [String] [String])
;;   | doc m%
;;       Resolve extra source files that participate in the cache key because
;;       they provide compile-time macros consumed by the stage.
;;     %
(def (poo-flow-build-macro-dependency-sources stage-sources)
  (reverse
   (poo-flow-build-macro-dependency-sources/rev
    +poo-flow-build-macro-dependency-source-files+
    stage-sources
    [])))

;; : (-> [String] [String])
(def (poo-flow-stage-source-files-finish sources-rev)
  (let (stage-sources
        (foldl cons (poo-flow-stage-default-source-files) sources-rev))
    (poo-flow-package-append-missing
     stage-sources
     (poo-flow-build-macro-dependency-sources stage-sources))))

;; poo-flow-stage-source-files
;; : (-> [BuildSpec] [String])
;; | doc m%
;;   Resolve the source files that determine a build stage cache key.
;;   # Examples
;;   ```scheme
;;   (poo-flow-stage-source-files stage)
;;   ;; => source file paths plus default package sources
;;   ```
(def (poo-flow-stage-source-files stage)
  (let lp ((rest stage) (sources []))
    (match rest
      ([] (poo-flow-stage-source-files-finish sources))
      ([spec . rest]
       (let (source (poo-flow-diagnostic-source-path spec))
         (if source
           (lp rest (cons source sources))
           (lp rest sources)))))))

;; : (-> BuildSpec Boolean)
(def (poo-flow-diagnostic-gxc-spec? spec)
  (match spec
    ([gxc: . _] #t)
    (_ #f)))

;; : (-> String [String])
(def (poo-flow-diagnostic-gxc-outputs file)
  [(path-expand (string-append (poo-flow-diagnostic-gxc-file file) "i")
                (poo-flow-package-libdir-prefix))])

;; : (-> String [String])
(def (poo-flow-diagnostic-gsc-outputs file)
  [(path-expand (string-append file ".o1")
                (poo-flow-package-libdir-prefix))])

;; : (-> String [String])
(def (poo-flow-diagnostic-ssi-outputs file)
  [(path-expand (string-append file ".ssi")
                (poo-flow-package-libdir-prefix))])

;; poo-flow-string-prefix?
;; : (-> String String Boolean)
;; | doc m%
;;   Check whether VALUE starts with PREFIX without allocating substrings.
;;   # Examples
;;   ```scheme
;;   (poo-flow-string-prefix? "build" "build.o1")
;;   ;; => #t
;;   ```
(def (poo-flow-string-prefix? prefix value)
  (string-prefix? prefix value))

;; : (-> String String)
(def (poo-flow-native-object-prefix output)
  (let (file (path-strip-directory output))
    (let (length (string-length file))
      (if (and (> length 4)
               (char=? (string-ref file (- length 4)) #\.)
               (char=? (string-ref file (- length 3)) #\s)
               (char=? (string-ref file (- length 2)) #\s)
               (char=? (string-ref file (- length 1)) #\i))
        (string-append (substring file 0 (- length 4)) ".o")
        file))))

;; poo-flow-string-all-digits-from?
;; : (-> String Integer Boolean)
;; | doc m%
;;   Check that VALUE contains only digits from START to the end.
;;   # Examples
;;   ```scheme
;;   (poo-flow-string-all-digits-from? "file.o12" 6)
;;   ;; => #t
;;   ```
(def (poo-flow-string-all-digits-from? value start)
  (let (length (string-length value))
    (and (< start length)
         (= (or (string-skip value char-numeric? start length)
                length)
            length))))

;; : (-> String String Boolean)
(def (poo-flow-native-object-file-name? prefix file)
  (and (poo-flow-string-prefix? prefix file)
       (poo-flow-string-all-digits-from?
        file
        (string-length prefix))))

;; poo-flow-native-object-phase0-prefix
;;   : (-> String MaybeString)
;;   | doc m%
;;       Gambit emits phase0 native objects using a `~0.oN` sibling prefix.
;;       Track that prefix with the ordinary `.oN` objects so direct compiles do
;;       not accumulate stale native files across repeated runs.
;;     %
(def (poo-flow-native-object-phase0-prefix prefix)
  (let ((suffix ".o")
        (length (string-length prefix)))
    (and (poo-flow-string-suffix? suffix prefix)
         (string-append (substring prefix 0 (- length (string-length suffix)))
                        "~0"
                        suffix))))

;; : (-> String String Boolean)
(def (poo-flow-native-object-sibling-file-name? prefix file)
  (or (poo-flow-native-object-file-name? prefix file)
      (let (phase0-prefix (poo-flow-native-object-phase0-prefix prefix))
        (and phase0-prefix
             (poo-flow-native-object-file-name? phase0-prefix file)))))

;; : (-> String String Boolean)
(def (poo-flow-native-object-debug-sibling-file-name? prefix file)
  (let* ((suffix ".dSYM")
         (length (string-length file))
         (suffix-length (string-length suffix)))
    (and (> length suffix-length)
         (poo-flow-string-suffix? suffix file)
         (poo-flow-native-object-sibling-file-name?
          prefix
          (substring file 0 (- length suffix-length))))))

;; : (-> String String Boolean)
(def (poo-flow-native-object-output-sibling-file-name? prefix file)
  (or (poo-flow-native-object-sibling-file-name? prefix file)
      (poo-flow-native-object-debug-sibling-file-name? prefix file)))

;; : (-> String Boolean)
(def (poo-flow-native-debug-sibling-directory-file-name? file)
  (poo-flow-string-suffix? ".dSYM" file))

;; : (-> String String Integer String)
(def (poo-flow-native-object-sibling-path directory prefix index)
  (path-expand (string-append prefix (number->string index))
               directory))

;; : (-> String [String])
(def (poo-flow-native-object-probed-output-files object-path)
  (let (debug-path (string-append object-path ".dSYM"))
    (append (if (file-exists? object-path) [object-path] [])
            (if (file-exists? debug-path) [debug-path] []))))

;; : (-> String String Integer Integer [String])
;; IO boundary: bounded native sibling discovery probes concrete filesystem paths.
(def (poo-flow-native-object-numbered-output-files/recur directory
                                                         prefix
                                                         index
                                                         misses)
  (if (>= misses +poo-flow-native-object-sibling-miss-limit+)
    []
    (let (outputs
          (poo-flow-native-object-probed-output-files
           (poo-flow-native-object-sibling-path directory prefix index)))
      (append outputs
              (poo-flow-native-object-numbered-output-files/recur
               directory
               prefix
               (+ index 1)
               (if (null? outputs)
                 (+ misses 1)
                 0))))))

;; : (-> String String [String])
(def (poo-flow-native-object-numbered-output-files directory prefix)
  (poo-flow-native-object-numbered-output-files/recur directory prefix 1 0))

;; : (-> String String [String])
(def (poo-flow-native-object-prefix-output-files directory prefix)
  (let ((phase0-prefix (poo-flow-native-object-phase0-prefix prefix))
        (outputs
         (poo-flow-native-object-numbered-output-files directory prefix)))
    (if phase0-prefix
      (append outputs
              (poo-flow-native-object-numbered-output-files directory
                                                            phase0-prefix))
      outputs)))

;; poo-flow-native-object-directory-files
;;   : (-> String [String])
;;   | doc m%
;;       Return cached directory entries for native object sibling discovery.
;;       Tests and runtime stages contain many outputs in the same directory, so
;;       one directory listing per build process is the intended hot path.
;;     %
(def (poo-flow-native-object-directory-files directory)
  (let (cached (hash-get +poo-flow-native-object-output-directory-cache+
                         directory))
    (if cached
      cached
      (let (files (directory-files directory))
        (hash-put! +poo-flow-native-object-output-directory-cache+
                   directory
                   files)
        files))))

;; : (-> MaybeString Void)
(def (poo-flow-delete-native-debug-sibling-directories! directory)
  (when (and directory (file-exists? directory))
    (for-each
     (lambda (file)
       (when (poo-flow-native-debug-sibling-directory-file-name? file)
         (poo-flow-delete-file-if-exists! (path-expand file directory))))
     (poo-flow-native-object-directory-files directory))))

;; poo-flow-native-object-output-files
;; : (-> String [String])
;; | doc m%
;;   Find native object siblings generated for one compiler output.
;;   # Examples
;;   ```scheme
;;   (poo-flow-native-object-output-files output)
;;   ;; => native object output paths
;;   ```
(def (poo-flow-native-object-output-files output)
  (let* ((directory (path-directory output))
         (prefix (poo-flow-native-object-prefix output)))
    (if (and directory (file-exists? directory))
      (poo-flow-native-object-prefix-output-files directory prefix)
      [])))

;; : (-> BuildSpec BuildOptions [String])
(def (poo-flow-diagnostic-output-files spec options)
  (let (outputs (poo-flow-diagnostic-outputs spec))
    (if (poo-flow-native-build-options? options)
      (append outputs
              (poo-flow-package-flat-map
               poo-flow-native-object-output-files
               outputs))
      outputs)))

;; : (-> [BuildSpec] BuildOptions [String])
(def (poo-flow-stage-output-files stage options)
  (poo-flow-package-flat-map
   (lambda (spec)
     (poo-flow-diagnostic-output-files spec options))
   stage))

;; : (-> BuildSpec [String])
(def (poo-flow-diagnostic-outputs spec)
  (match spec
    ([gxc: file . _] (poo-flow-diagnostic-gxc-outputs file))
    ([gsc: file . _] (poo-flow-diagnostic-gsc-outputs file))
    ([ssi: file . _] (poo-flow-diagnostic-ssi-outputs file))
    (_ [])))
