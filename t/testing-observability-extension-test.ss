;;; -*- Gerbil -*-

(import :std/test
        (only-in :std/srfi/13 string-contains)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 testing-interface-call-with-operation
                 testing-interface-run-test-batch!)
        (only-in :poo-flow/src/module-system/observability/testing-extension
                 poo-flow-native-observability-enabled?
                 poo-flow-testing-heartbeat-interval-seconds
                 poo-flow-testing-observability-extension))

(export testing-observability-extension-test)

(def testing-observability-extension-test
  (test-suite "POO Flow native testing observability extension"
    (test-case "GERBIL_BUILD_VERBOSE emits admission before the operation"
      (let ((previous (getenv "GERBIL_BUILD_VERBOSE" #f))
            (port (open-output-string))
            (admission-visible-inside? #f))
        (dynamic-wind
          (lambda () (setenv "GERBIL_BUILD_VERBOSE" "9"))
          (lambda ()
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
                   => #t))
          (lambda ()
            (setenv "GERBIL_BUILD_VERBOSE" (or previous ""))))))
    (test-case "long operations emit bounded POO heartbeat and elapsed receipts"
      (let ((previous (getenv "GERBIL_BUILD_VERBOSE" #f))
            (port (open-output-string)))
        (dynamic-wind
          (lambda () (setenv "GERBIL_BUILD_VERBOSE" "1"))
          (lambda ()
            (parameterize
                ((current-error-port port)
                 (poo-flow-testing-heartbeat-interval-seconds 0.01))
              (testing-interface-call-with-operation
               (poo-flow-testing-observability-extension
                +asp-testing-interface+)
               'native-test-batch
               (lambda () (thread-sleep! 0.03))))
            (let (output (get-output-string port))
              (check (and (string-contains output "operation-heartbeat") #t)
                     => #t)
              (check (and (string-contains output "elapsed-nanoseconds") #t)
                     => #t)))
          (lambda ()
            (setenv "GERBIL_BUILD_VERBOSE" (or previous ""))))))
    (test-case "enablement follows std/make numeric environment semantics"
      (let (previous (getenv "GERBIL_BUILD_VERBOSE" #f))
        (dynamic-wind
          void
          (lambda ()
            (setenv "GERBIL_BUILD_VERBOSE" "1")
            (check (poo-flow-native-observability-enabled?) => #t)
            (setenv "GERBIL_BUILD_VERBOSE" "0")
            (check (poo-flow-native-observability-enabled?) => #f)
            (setenv "GERBIL_BUILD_VERBOSE" "not-a-level")
            (check (poo-flow-native-observability-enabled?) => #f))
          (lambda ()
            (setenv "GERBIL_BUILD_VERBOSE" (or previous ""))))))
    (test-case "the native batch emits POO receipts and upstream elapsed timing"
      (let ((previous (getenv "GERBIL_BUILD_VERBOSE" #f))
            (port (open-output-string)))
        (dynamic-wind
          (lambda () (setenv "GERBIL_BUILD_VERBOSE" "9"))
          (lambda ()
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
                     => #t)))
          (lambda ()
            (setenv "GERBIL_BUILD_VERBOSE" (or previous ""))))))
    (test-case "failed native batches retain POO and ASP elapsed terminals"
      (let ((previous (getenv "GERBIL_BUILD_VERBOSE" #f))
            (port (open-output-string))
            (raised? #f))
        (dynamic-wind
          (lambda () (setenv "GERBIL_BUILD_VERBOSE" "1"))
          (lambda ()
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
                     => #t)))
          (lambda ()
            (setenv "GERBIL_BUILD_VERBOSE" (or previous ""))))))))
