;;; -*- Gerbil -*-
;;; Boundary: sandbox backend object-family macro contracts.
;;; Invariant: generated backend objects stay POO-native and runtime-free.

(import (only-in :std/test
                 check-eq?
                 check-equal?
                 run-tests!
                 test-case
                 test-suite)
        :poo-flow/src/module-system/object-core
        :poo-flow/src/modules/sandbox-core/objects
        :poo-flow/src/modules/sandbox-core/profile-support/policy
        :poo-flow/src/modules/nono-sandbox/objects
        :poo-flow/src/modules/cubeSandbox/objects
        :poo-flow/src/modules/docker-sandbox/objects)

;; : (-> Symbol Alist MaybeValue)
(def (alist-ref/default key entries default)
  (let (entry (and (list? entries) (assoc key entries)))
    (if entry (cdr entry) default)))

;; : (-> PooModuleObject Symbol PooModuleFieldContract)
(def (required-field object field)
  (let (contract (poo-flow-module-object-field object field))
    (check-equal? (poo-flow-module-field-contract? contract) #t)
    contract))

;; : (-> PooModuleObject Symbol Value)
(def (field-default object field)
  (poo-flow-module-field-contract-default
   (required-field object field)))

;; : (-> PooModuleObject Symbol Symbol)
(def (field-value-kind object field)
  (poo-flow-module-field-contract-value-kind
   (required-field object field)))

;; : (-> PooModuleObject Symbol Alist)
(def (field-metadata object field)
  (poo-flow-module-field-contract-metadata
   (required-field object field)))

(def (check-backend-registry registry key capability)
  (check-equal? (poo-flow-sandbox-backend-capability-registry? registry) #t)
  (check-equal? (poo-flow-sandbox-backend-capability-registry-entries registry)
                (list (cons key capability)))
  (check-eq? (poo-flow-sandbox-backend-capability-registry-ref registry key)
             capability)
  (check-eq? (poo-flow-sandbox-backend-capability/backend-kind capability)
             key))

(run-tests!
 (test-suite "sandbox backend object family macro contracts"
   (test-case "generates backend object identities and metadata"
     (check-equal? (poo-flow-module-object? poo-flow-nono-sandbox-object) #t)
     (check-equal? (poo-flow-module-object? poo-flow-cubeSandbox-object) #t)
     (check-equal? (poo-flow-module-object? poo-flow-docker-sandbox-object) #t)
     (check-eq? (poo-flow-module-object-identity
                 poo-flow-nono-sandbox-object)
                'objects.nono-sandbox.sandbox)
     (check-eq? (poo-flow-module-object-identity
                 poo-flow-cubeSandbox-object)
                'objects.cubeSandbox.sandbox)
     (check-eq? (poo-flow-module-object-identity
                 poo-flow-docker-sandbox-object)
                'objects.docker-sandbox.sandbox)
     (check-eq? (alist-ref/default
                 'domain
                 (poo-flow-module-object-metadata
                  poo-flow-docker-sandbox-object)
                 #f)
                'sandbox)
     (check-eq? (alist-ref/default
                 'namespace
                 (poo-flow-module-object-metadata
                  poo-flow-docker-sandbox-object)
                 #f)
                'objects.docker-sandbox))
   (test-case "generates backend field contracts"
     (check-eq? (field-value-kind poo-flow-nono-sandbox-object 'backend)
                'Symbol)
     (check-eq? (field-default poo-flow-nono-sandbox-object 'backend)
                'nono)
     (check-eq? (field-value-kind poo-flow-docker-sandbox-object 'image)
                'String)
     (check-equal? (field-default poo-flow-docker-sandbox-object 'image)
                   "ubuntu:latest")
     (check-eq? (alist-ref/default
                 'scope
                 (field-metadata poo-flow-cubeSandbox-object 'profile)
                 #f)
                'cubeSandbox)
     (check-equal? (poo-flow-module-object-field
                    poo-flow-docker-sandbox-object
                    'backend-ref)
                   #f))
   (test-case "generates profile object inheritance and resolved fields"
     (check-equal? (poo-flow-module-object?
                    poo-flow-nono-sandbox-profile-object)
                   #t)
     (check-equal? (poo-flow-module-object?
                    poo-flow-cubeSandbox-profile-object)
                   #t)
     (check-equal? (poo-flow-module-object?
                    poo-flow-docker-sandbox-profile-object)
                   #t)
     (check-eq? (poo-flow-module-object-identity
                 poo-flow-docker-sandbox-profile-object)
                'objects.docker-sandbox.profile)
     (check-equal? (poo-flow-module-object-inherits
                    poo-flow-docker-sandbox-profile-object)
                   (list poo-flow-sandbox-core-profile-object
                         poo-flow-docker-sandbox-object))
     (check-eq? (field-default
                 poo-flow-docker-sandbox-profile-object
                 'backend-kind)
                'docker)
     (check-eq? (field-default
                 poo-flow-docker-sandbox-profile-object
                 'backend)
                'docker)
     (check-equal? (field-default
                    poo-flow-docker-sandbox-profile-object
                    'image)
                   "ubuntu:latest")
     (check-eq? (field-value-kind
                 poo-flow-nono-sandbox-profile-object
                 'metadata)
                'List)
     (check-equal? (field-default
                    poo-flow-cubeSandbox-profile-object
                    'resource-policy)
                   '((filesystem
                      (scope . snapshot)
                      (snapshot . clone)))))
   (test-case "generates backend capability registries"
     (check-backend-registry
      poo-flow-nono-sandbox-backend-capability-registry
      'nono
      poo-flow-nono-sandbox-backend-capability)
     (check-backend-registry
      poo-flow-cubeSandbox-backend-capability-registry
      'cube
      poo-flow-cubeSandbox-backend-capability)
     (check-backend-registry
      poo-flow-docker-sandbox-backend-capability-registry
      'docker
      poo-flow-docker-sandbox-backend-capability))))
