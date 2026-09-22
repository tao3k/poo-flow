;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later


(import :std/test
        (only-in :clan/poo/object .o .ref)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 testing-interface-call-with-operation
                 testing-interface-run-test-batch!)
        (only-in :poo-flow/src/module-system/observability/testing-extension
                 +poo-flow-testing-import-footprint-profile+
                 poo-flow-native-observability-enabled?
                 make-poo-flow-testing-observability-profile
                 poo-flow-testing-observability-profile-source-load-paths
                 poo-flow-testing-observability-extension))

(export testing-observability-extension-test)

(def testing-observability-extension-test
  (test-suite "POO Flow native testing observability extension"
    (test-case "source roots are owned by the POO testing profile"
      (let (profile
            (make-poo-flow-testing-observability-profile
             'testing/source-root 1/100))
        (check-equal?
         (poo-flow-testing-observability-profile-source-load-paths profile)
         '("."))))

    (test-case "registry footprint policy is declared only through POO slots"
      (check (.ref +poo-flow-testing-import-footprint-profile+
                   'heavyOwners)
             => '())
      (check (.ref +poo-flow-testing-import-footprint-profile+
                   'largeClosureModuleCount)
             ? (lambda (value) (and (integer? value) (> value 0))))
      (check (< (.ref +poo-flow-testing-import-footprint-profile+
                      'maxSharedClosureModules)
                (.ref +poo-flow-testing-import-footprint-profile+
                      'largeClosureModuleCount))
             => #t)
      (check (.ref +poo-flow-testing-import-footprint-profile+
                   'action)
             => 'reject))

    (test-case "the default POO profile emits admission before the operation"
      (let ((port (open-output-string))
            (admission-visible-inside? #f))
        (parameterize ((current-error-port port))
          (check
           (testing-interface-call-with-operation
            (poo-flow-testing-observability-extension
             +asp-testing-interface+)
            'native-test-batch
            (lambda ()
              (set! admission-visible-inside?
                    (and (string-contains
                          (get-output-string port)
                          "call-admitted")
                         #t))
              'completed))
           => 'completed))
        (check (poo-flow-native-observability-enabled?) => #t)
        (check admission-visible-inside? => #t)
        (check (and (string-contains
                     (get-output-string port)
                     "call-returned")
                    #t)
               => #t)))
    (test-case "long operations emit bounded POO heartbeat and elapsed receipts"
      (let (port (open-output-string))
        (parameterize
            ((current-error-port port))
          (testing-interface-call-with-operation
           (poo-flow-testing-observability-extension
            +asp-testing-interface+
            (make-poo-flow-testing-observability-profile
             'testing/fast-heartbeat 0.01))
           'native-test-batch
           (lambda () (thread-sleep! 0.03))))
        (let (output (get-output-string port))
          (check (and (string-contains output "operation-heartbeat") #t)
                 => #t)
          (check (and (string-contains output "elapsed-nanoseconds") #t)
                 => #t))))
    (test-case "enablement is a composable POO profile slot"
      (let ((enabled-inside? #t)
            (profile
             (.o (:: @ (make-poo-flow-testing-observability-profile
                         'testing/quiet 1))
                 (enabled? #f))))
        (check
         (testing-interface-call-with-operation
          (poo-flow-testing-observability-extension
           +asp-testing-interface+ profile)
          'native-test-batch
          (lambda ()
            (set! enabled-inside?
                  (poo-flow-native-observability-enabled?))
            'completed))
         => 'completed)
        (check enabled-inside? => #f)))
    (test-case "the native batch emits POO receipts and upstream elapsed timing"
      (let (port (open-output-string))
        (parameterize ((current-output-port port)
                       (current-error-port port))
          (check
           (testing-interface-run-test-batch!
            (poo-flow-testing-observability-extension
             +asp-testing-interface+)
            '("t/scenarios/testing-observability/native-batch-test.ss"))
           => (void)))
        (let (output (get-output-string port))
          (check (and (string-contains output "call-admitted") #t) => #t)
          (check (and (string-contains output "call-returned") #t) => #t)
          (check (and (string-contains output "phase=batch-start") #t) => #t)
          (check (and (string-contains output
                                       "phase=batch-complete elapsedNs=")
                      #t)
                 => #t))))
    (test-case "failed native batches retain POO and ASP elapsed terminals"
      (let ((port (open-output-string))
            (raised? #f))
        (parameterize ((current-output-port port)
                       (current-error-port port))
          (with-catch
           (lambda (_failure) (set! raised? #t))
           (lambda ()
             (testing-interface-run-test-batch!
              (poo-flow-testing-observability-extension
               +asp-testing-interface+)
              '("t/scenarios/testing-observability/missing-test.ss")))))
        (let (output (get-output-string port))
          (check raised? => #t)
          (check (and (string-contains output "call-raised") #t) => #t)
          (check (and (string-contains output "elapsed-nanoseconds") #t)
                 => #t)
          (check (and (string-contains output
                                       "phase=batch-failed elapsedNs=")
                      #t)
                 => #t))))))
