;;; -*- Gerbil -*-
;;; Boundary: POO owns dependency identity; Bzlmod is a deterministic projection.

(import (only-in :std/srfi/13 string-contains)
        (only-in :std/test
                 test-suite
                 test-case
                 check-equal?)
        :clan/poo/object
        :poo-flow/src/contract/dependency-source-identity)

(export dependency-source-identity-test)

(def dependency-source-identity-test
  (test-suite "poo-flow dependency source identity"
    (test-case "owns logical package, URI, revision, and content digest"
      (let (dependencies
            (.ref +poo-flow-dependency-source-contract+ 'dependencies))
        (check-equal?
         (.ref +poo-flow-dependency-source-contract+ 'kind)
         'poo-flow.dependency-source-contract.1)
        (check-equal? (map (lambda (dependency)
                             (.ref dependency 'logical-package))
                           dependencies)
                      '("gerbil-poo" "gerbil-utils" "gslph"))
        (check-equal? (map (lambda (dependency)
                             (.ref dependency 'revision))
                           dependencies)
                      '("1c3225637525400341a09e958296962c10184ead"
                        "f45a4ef3bfecd2af39e114ed736ce9082cbb8244"
                        "8eb8604e1907c294c60d8c6a7084c0ab50a80557"))))

    (test-case "projects hermetic archives without local Gerbil paths"
      (let (projection
            (poo-flow-dependency-source-contract->module-fragment
             +poo-flow-dependency-source-contract+))
        (check-equal? (not (not (string-contains
                                 projection
                                 "gerbil_dependency_sources.source_package")))
                      #t)
        (check-equal? (not (not (string-contains
                                 projection
                                 "sha256 = \"9425b2baff5ee87c046d43dac0b11ed6b174f4e4c12c01c747c066383517964e\"")))
                      #t)
        (check-equal? (string-contains projection ".gerbil/pkg") #f)
        (check-equal? (string-contains projection "GERBIL_LOADPATH") #f)
        (check-equal? (string-contains projection "GERBIL_PATH") #f)))))
