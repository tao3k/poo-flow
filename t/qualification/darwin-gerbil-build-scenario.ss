;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Qualification owner: measure one POO Flow build through the unique
;;; build.ss entry and emit a machine-readable Darwin Gerbil receipt.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/benchmark-api
                 benchmark-elapsed-ms)
        (only-in :std/misc/process
                 run-process/batch)
        (only-in :std/misc/walist
                 walist)
        (only-in :std/text/json
                 json-object->string))

(export main)

;; : (-> String String String Void)
(def (darwin-gerbil-build-scenario-run phase toolchain receipt-path)
  (let* ((elapsed-ms
          (benchmark-elapsed-ms
           (lambda ()
             (run-process/batch '("gerbil" "build")))))
         (receipt
          (json-object->string
           (walist
            (list
             (cons "schema" "poo-flow.darwin-gerbil-build-scenario.v1")
             (cons "phase" phase)
             (cons "toolchain" toolchain)
             (cons "entrypoint" "build.ss")
             (cons "measurementOwner" "asp-gerbil-scheme/benchmark-api")
             (cons "executor" "gerbil build")
             (cons "elapsedMs" (exact->inexact elapsed-ms))
             (cons "status" 0))))))
    (call-with-output-file
     receipt-path
     (lambda (port)
       (display receipt port)
       (newline port)))
    (displayln "[poo-flow-darwin-gerbil] " receipt)))

;; : (-> [String] Void)
(def (main . args)
  (unless (= (length args) 3)
    (displayln
     "usage: gxi t/qualification/darwin-gerbil-build-scenario.ss PHASE TOOLCHAIN RECEIPT")
    (exit 64))
  (darwin-gerbil-build-scenario-run
   (car args)
   (cadr args)
   (caddr args)))
