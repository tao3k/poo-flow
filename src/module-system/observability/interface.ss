;;; -*- Gerbil -*-
;;; Boundary: native POO observation, authoring, quality, and development
;;; performance interface. Debug effects remain opt-in function calls; loading
;;; this interface only makes their bounded contracts available by default.
(import (only-in "types.ss"
                 PooFlowObservationIdentityContract PooFlowObservationProvenanceContract
                 PooFlowObservationContextContract PooFlowObservationContract
                 PooFlowAdmissionObservationContract PooFlowAdmissionObservationFactsContract
                 PooFlowObservationSummaryContract)
        (only-in "objects.ss"
                 poo-flow-admission-observation-prototype
                 poo-flow-observation-identity poo-flow-observation-provenance
                 poo-flow-observation-context poo-flow-observe-admission-evidence
                 poo-flow-observe-contract-admission poo-flow-observation-explain
                 poo-flow-observation-summary)
        "source-authoring.ss"
        "debug.ss")
(export PooFlowObservationIdentityContract PooFlowObservationProvenanceContract
        PooFlowObservationContextContract PooFlowObservationContract
        PooFlowAdmissionObservationContract PooFlowAdmissionObservationFactsContract
        PooFlowObservationSummaryContract poo-flow-admission-observation-prototype
        poo-flow-observation-identity poo-flow-observation-provenance
        poo-flow-observation-context poo-flow-observe-admission-evidence
        poo-flow-observe-contract-admission poo-flow-observation-explain
        poo-flow-observation-summary
        (import: "source-authoring.ss")
        (import: "debug.ss"))
