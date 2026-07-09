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
                 +poo-flow-native-object-output-directory-cache+))

(export #t)

;; poo-flow-delete-file-if-exists!
;; : (-> String Void)
;; | doc m%
;;   Remove an existing generated file before writing a replacement.
;;   # Examples
;;   ```scheme
;;   (poo-flow-delete-file-if-exists! "bin/poo-flow")
;;   ;; => removes the file when present
;;   ```
(def (poo-flow-delete-file-if-exists! path)
  (when (file-exists? path)
    (delete-file-or-directory path #t)))

;; : (forall (a) (-> String (-> a) a))
;; IO boundary: dynamic-wind restores the caller directory after THUNK.
(def (poo-flow-with-directory directory thunk)
  (let (previous (current-directory))
    (dynamic-wind
      (lambda () (current-directory directory))
      thunk
      (lambda () (current-directory previous)))))

;; : (-> String)
(def (poo-flow-package-srcdir)
  (path-expand "."))

;; poo-flow-package-source-path
;;   : (-> String String)
;;   | doc m%
;;       Resolve a package source path through the same root used by build
;;       diagnostics and cache receipts.
;;     %
(def (poo-flow-package-source-path source)
  (path-expand source (poo-flow-package-srcdir)))

;; poo-flow-native-object-output-directory-cache-clear!
;;   : (-> Void)
;;   | doc m%
;;       Clear the per-build directory listing cache after a compiler run may
;;       have created or removed native object outputs.
;;     %
(def (poo-flow-native-object-output-directory-cache-clear!)
  (set! +poo-flow-native-object-output-directory-cache+ (make-hash-table)))

;; : (-> Void)
(def (poo-flow-package-require-gxpkg-env!)
  (unless (getenv "GERBIL_PATH" #f)
    (error "poo-flow package builds require gxpkg env; run gxpkg env gxi build.ss compile")))

;; : (-> String MaybeInteger)
(def (poo-flow-package-cores-from-env name)
  (let (value (getenv name #f))
    (and value
         (let (cores (string->number value))
           (and (integer? cores)
                (> cores 0)
                cores)))))

;; : (-> Integer)
(def (poo-flow-package-worker-count)
  (or (poo-flow-package-cores-from-env "GERBIL_BUILD_CORES")
      (max 1 (##cpu-count))))

;; : (-> Integer)
;; Runtime boundary: mirrors the selected worker count into Gerbil's compiler core parameter.
(def (poo-flow-package-parallelize)
  (let (worker-count (poo-flow-package-worker-count))
    (set! __available-cores worker-count)
    worker-count))

;; : (-> BuildOptions BuildOptions)
(def (poo-flow-make-options options)
  (match options
    ([build-cli: _ . rest]
     (poo-flow-make-options rest))
    ([build-tests: _ . rest]
     (poo-flow-make-options rest))
    ([force: _ . rest]
     (poo-flow-make-options rest))
    ([key value . rest]
     (cons key
           (cons value
                 (poo-flow-make-options rest))))
    ([] [])))

;; : (-> BuildOptions BuildOptions)
(def (poo-flow-package-options options)
  (let (parallelize (poo-flow-package-parallelize))
    (if parallelize
      (append (poo-flow-make-options options) [parallelize: parallelize])
      (poo-flow-make-options options))))

;; : (-> Void)
(def (poo-flow-load-make!)
  (eval '(import (only-in :std/make make make-clean))))

;; : (-> [BuildSpec] BuildOptions MakeResult)
(def (poo-flow-apply-make stage . options)
  (poo-flow-load-make!)
  (apply (eval 'make) stage options))

;; : (-> [BuildSpec] BuildOptions MakeResult)
(def (poo-flow-apply-make-clean stage . options)
  (poo-flow-load-make!)
  (apply (eval 'make-clean) stage options))

;; : (-> [BuildSpec] BuildOptions BuildOptions)
(def (poo-flow-package-stage-options stage options)
  (if (> (length stage) 1)
    (poo-flow-package-options options)
    (poo-flow-make-options options)))

;; : (-> String String [BuildSpec] Void)
(def (poo-flow-package-message action label stage)
  (display "... poo-flow ")
  (display action)
  (display " ")
  (display label)
  (display " targets=")
  (display (length stage))
  (let (parallelize (and (> (length stage) 1)
                         (poo-flow-package-worker-count)))
    (when parallelize
      (display " parallelize=")
      (display parallelize)))
  (newline)
  (force-output))
