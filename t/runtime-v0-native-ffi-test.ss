#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :std/encoding/json
                 JSONReadOptions
                 current-json-read-options
                 string->json)
        (only-in :poo-flow/src/ffi/runtime-v0-native
                 native-abi-version
                 native-descriptor-payload
                 native-validate-payload
                 native-c-round-trip))

(export runtime-v0-native-ffi-test)

(def (runtime-test-json-object text)
  (parameterize ((current-json-read-options
                  (JSONReadOptions object-as-hash: #t)))
    (string->json text)))

(def valid-source-query
  #<<JSON
{"source-language":"scheme","source-content-id":"sha256:source","source-version":"1","parser-id":"gerbil-parser","parser-version":"1","query-id":"q1","query-version":"1","selected-node-identities":["node-1"],"representation":"ast-data","provenance-root":"sha256:provenance","result-digest":"sha256:result"}
JSON
  )

(def runtime-v0-native-ffi-test
  (test-suite "Runtime v0 Scheme-native C ABI"
    (test-case "descriptor is versioned and bounded"
      (check (native-abi-version) => 1)
      (let (descriptor (runtime-test-json-object (native-descriptor-payload)))
        (check (hash-get descriptor "schema")
               => "poo-flow.scheme-native-descriptor.v1")
        (check (hash-get descriptor "runtimeAbiMajor") => 0)
        (check (hash-get descriptor "runtimeAbiMinor") => 3)
        (check (hash-get descriptor "maximumInputBytes") => (* 16 1024 1024))
        (check (length (hash-get descriptor "contracts")) => 3)))
    (test-case "valid POO contract crosses as a validation receipt"
      (let (receipt
            (runtime-test-json-object
             (native-validate-payload "source-query-receipt"
                                      valid-source-query)))
        (check (hash-get receipt "valid") => #t)
        (check (length (hash-get receipt "failures")) => 0)))
    (test-case "semantic failure remains typed rather than exceptional"
      (let* ((invalid
              (string-append
               "{\"source-language\":\"scheme\",\"source-content-id\":\"sha256:source\","
               "\"source-version\":\"1\",\"parser-id\":\"gerbil-parser\","
               "\"parser-version\":\"1\",\"query-id\":\"q1\",\"query-version\":\"1\","
               "\"selected-node-identities\":[\"node-1\"],\"representation\":\"unknown\","
               "\"provenance-root\":\"sha256:provenance\",\"result-digest\":\"sha256:result\"}"))
             (receipt
              (runtime-test-json-object
               (native-validate-payload "source-query-receipt" invalid))))
        (check (hash-get receipt "valid") => #f)
        (check (car (hash-get receipt "failures"))
               => "unsupported-source-representation")))
    (test-case "unknown contract fails closed"
      (check-exception
       (native-validate-payload "unknown" "{}") true))
    (test-case "C consumer observes the exported ABI and releases its result"
      (check (native-c-round-trip) => 0))))
