;;; -*- Gerbil -*-
;;; Boundary: pure native POO observation authoring and inspection interface.
;;; Development output requires a separate explicit import of ./debug.ss.
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
        "source-authoring.ss")
(export PooFlowObservationIdentityContract PooFlowObservationProvenanceContract
        PooFlowObservationContextContract PooFlowObservationContract
        PooFlowAdmissionObservationContract PooFlowAdmissionObservationFactsContract
        PooFlowObservationSummaryContract poo-flow-admission-observation-prototype
        poo-flow-observation-identity poo-flow-observation-provenance
        poo-flow-observation-context poo-flow-observe-admission-evidence
        poo-flow-observe-contract-admission poo-flow-observation-explain
        poo-flow-observation-summary
        (import: "source-authoring.ss"))
