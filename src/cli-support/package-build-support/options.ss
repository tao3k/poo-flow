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
                 filter))

(export #t)

;; : (-> Boolean BuildOptionRow [BuildOptionRow])
(def (poo-flow-entry-option enabled? option-row)
  (if enabled? option-row []))

;; : (-> Boolean Boolean Boolean Boolean Boolean Boolean Boolean BuildOptions)
(def (poo-flow-entry-options release optimized debug cli tests force verbose)
  (append
   (poo-flow-entry-option release [build-release: #t])
   (poo-flow-entry-option optimized [build-optimized: #t])
   (poo-flow-entry-option debug [debug: #t])
   (poo-flow-entry-option cli [build-cli: #t])
   (poo-flow-entry-option tests [build-tests: #t])
   (poo-flow-entry-option force [force: #t])
   (poo-flow-entry-option verbose [verbose: 9])))

;; : (-> BuildOptions Boolean)
(def (poo-flow-release-build-options? options)
  (match options
    ([build-release: value . _] value)
    ([_ _ . rest] (poo-flow-release-build-options? rest))
    ([] #t)))

;; : (-> BuildOptions Boolean)
(def (poo-flow-optimized-build-options? options)
  (match options
    ([build-optimized: value . _] value)
    ([_ _ . rest] (poo-flow-optimized-build-options? rest))
    ([] #f)))

;; : (-> BuildOptions Boolean)
(def (poo-flow-debug-build-options? options)
  (match options
    ([debug: value . _] value)
    ([_ _ . rest] (poo-flow-debug-build-options? rest))
    ([] #f)))

;; : (-> BuildOptions Boolean)
(def (poo-flow-verbose-build-options? options)
  (match options
    ([verbose: value . _] value)
    ([_ _ . rest] (poo-flow-verbose-build-options? rest))
    ([] #f)))

;; : (-> BuildOptions Boolean)
(def (poo-flow-build-debug-tracking-options? options)
  (or (poo-flow-debug-build-options? options)
      (poo-flow-verbose-build-options? options)))

;; : (-> String Boolean)
(def (poo-flow-profiled-stage-label? label)
  (or (string=? label "runtime")
      (string=? label "tests")))

;; : [String]
(def +poo-flow-debug-heavy-facade-targets+
  '("src/module-system/init-syntax.ss"))

;; : (-> BuildSpec MaybeString)
(def (poo-flow-gxc-spec-target spec)
  (match spec
    ([gxc: file . _] file)
    (_ #f)))

;; : (-> BuildSpec Boolean)
(def (poo-flow-debug-heavy-facade-spec? spec)
  (let (target (poo-flow-gxc-spec-target spec))
    (and target
         (member target +poo-flow-debug-heavy-facade-targets+)
         #t)))

;; : (-> BuildOptions BuildOptions)
(def (poo-flow-build-options/drop-debug options)
  (match options
    ([debug: _ . rest]
     (poo-flow-build-options/drop-debug rest))
    ([key value . rest]
     (cons key
           (cons value
                 (poo-flow-build-options/drop-debug rest))))
    ([] [])))

;; : (-> BuildSpec BuildOptions BuildOptions)
(def (poo-flow-profiled-spec-options spec options)
  (if (and (poo-flow-debug-build-options? options)
           (poo-flow-debug-heavy-facade-spec? spec))
    (begin
      (display "|note kind=build-debug-skip target=")
      (write (poo-flow-gxc-spec-target spec))
      (display " reason=\"heavy facade macro module stays below watchdog without debug-source tracking\"")
      (newline)
      (force-output)
      (poo-flow-build-options/drop-debug options))
    options))

;; : (-> String [BuildSpec] BuildOptions Boolean)
(def (poo-flow-profiled-stage-options? label stage options)
  (and (not (null? stage))
       (poo-flow-build-debug-tracking-options? options)
       (poo-flow-profiled-stage-label? label)))

;; : (-> BuildOptions Boolean)
(def (poo-flow-cli-build-options? options)
  (match options
    ([build-cli: value . _] value)
    ([_ _ . rest] (poo-flow-cli-build-options? rest))
    ([] #f)))

;; : (-> BuildOptions Boolean)
(def (poo-flow-tests-build-options? options)
  (match options
    ([build-tests: value . _] value)
    ([_ _ . rest] (poo-flow-tests-build-options? rest))
    ([] #t)))

;; : (-> BuildOptions Boolean)
(def (poo-flow-force-build-options? options)
  (match options
    ([force: value . _] value)
    ([_ _ . rest] (poo-flow-force-build-options? rest))
    ([] #f)))

;; : (-> BuildOptions Boolean)
(def (poo-flow-native-build-options? options)
  (or (poo-flow-release-build-options? options)
      (poo-flow-optimized-build-options? options)
      (poo-flow-debug-build-options? options)))
