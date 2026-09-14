;;; -*- Gerbil -*-
;;; Minimal native gxtest fixture for the POO Flow operation-observation lane.

(import :std/test)

(export native-batch-test)

(def native-batch-test
  (test-suite "POO Flow observed native batch fixture"
    (test-case "runs through the upstream Gerbil test executor"
      (check #t => #t))))
