;;; -*- Gerbil -*-

(import :std/test
        (only-in :clan/poo/object .ref .slot?)
        (only-in :poo-flow/src/module-system/base
                 poo-flow-user-module-selection-key
                 poo-flow-user-module-selection-flag-entry)
        :poo-flow/user-interface/custom/my-module/config)

(export user-interface-custom-sandbox-durable-test)

(def (test-ref row key)
  (let (entry (assoc key row))
    (if entry (cdr entry) #f)))

(def (sandbox-config module-selection-bundle)
  (let* ((selection (car module-selection-bundle))
         (entry
          (poo-flow-user-module-selection-flag-entry selection ':config)))
    (and entry
         (pair? (cdr entry))
         (car (cdr entry)))))

(def user-interface-custom-sandbox-durable-test
  (test-suite "poo-flow custom user-interface sandbox-durable case"
    (test-case "projects durable sandbox config without runtime work"
      (let* ((selection (car poo-flow-custom-my-module-sandbox-durable-case))
             (config (sandbox-config
                      poo-flow-custom-my-module-sandbox-durable-case))
             (metadata (.ref config 'metadata)))
        (check-equal? (poo-flow-user-module-selection-key selection)
                      '(sandbox . nono-sandbox))
        (check-equal? (.slot? config 'name) #t)
        (check-equal? (.slot? config 'metadata) #t)
        (check-equal? (.ref config 'name) 'agent/durable-build)
        (check-equal? (test-ref metadata 'backend) 'nono-sandbox)
        (check-equal? (test-ref metadata 'intent) 'durable-sandbox-build)
        (check-equal? (test-ref metadata 'scope) 'custom-module)
        (check-equal? (test-ref metadata 'durable-policy) 'durable/default)
        (check-equal? (test-ref metadata 'runtime-executed) #f)))))
