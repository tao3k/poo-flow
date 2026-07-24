#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; JSON is an artifact projection; the POO contract remains the sole owner.

(export main)

(import :gerbil/gambit
        (only-in :std/text/json
                 json-object->string
                 write-json-sort-keys?)
        (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/contract/dependency-source-identity
                 +poo-flow-dependency-source-contract+))

(def +dependency-source-contract-projection-schema+
  "poo-flow.dependency-source-contract.projection.v1")

(def (dependency-source-entry->json-object dependency)
  (hash
   ("logicalPackage" (.ref dependency 'logical-package))
   ("repositoryName" (.ref dependency 'repository-name))
   ("canonicalUri" (.ref dependency 'canonical-uri))
   ("revision" (.ref dependency 'revision))
   ("sha256" (.ref dependency 'sha256))
   ("stripPrefix" (.ref dependency 'strip-prefix))
   ("archiveUrl" (.ref dependency 'archive-url))))

(def (dependency-source-contract->json-object contract)
  (hash
   ("schema" +dependency-source-contract-projection-schema+)
   ("contractKind" (symbol->string (.ref contract 'kind)))
   ("contractSchema" (.ref contract 'schema))
   ("contractVersion" (.ref contract 'version))
   ("dependencies"
    (map dependency-source-entry->json-object
         (.ref contract 'dependencies)))))

(def (main output)
  (parameterize ((write-json-sort-keys? #t))
    (call-with-output-file output
      (lambda (port)
        (display
         (json-object->string
          (dependency-source-contract->json-object
           +poo-flow-dependency-source-contract+))
         port)
        (newline port)))))
