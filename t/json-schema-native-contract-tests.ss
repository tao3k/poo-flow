;;; -*- Gerbil -*-
;;; Boundary: executable JSON Schema native Contract regression root.

(import (only-in :std/test run-tests!)
        :poo-flow/t/json-schema-native-contract-test
        :poo-flow/t/json-schema-contract-bridge-test
        :poo-flow/t/funflow-github-ci-json-schema-contract-test)

(run-tests! json-schema-contract-bridge-test)
(run-tests! funflow-github-ci-json-schema-contract-test)
