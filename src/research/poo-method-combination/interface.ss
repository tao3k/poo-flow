;;; -*- Gerbil -*-
;;; Local facade. Collector, frame and execution protocols stay internal.
(import "types.ss" "objects.ss" "func.ss")
(export CombinationGeneric CombinationMethod CombinationBundle CombinationFailure
        poo-combination-generic poo-combination-method poo-method-bundle
        poo-method-root poo-method-prototype poo-combination-call poo-combination-bind
        poo-call-next-method poo-next-method? poo-combination-failure?)
