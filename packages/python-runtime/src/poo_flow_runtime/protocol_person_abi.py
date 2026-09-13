"""Public validation facade for the POO Flow Runtime Language ABI.

The POO Contract is the sole canonical semantic owner.  Python, Marlin, and
future runtimes consume this projection surface as implementations; this module
does not execute effects.
"""

from ._protocol_person_abi_receipt import (
    PromotionRuntimeReceipt,
    receipts_exactly_once,
)
from ._protocol_person_abi_schema import (
    ABI_MAJOR,
    ABI_MINOR,
    CONTRACT_ARTIFACT_PROJECTION_RECEIPT_SCHEMA,
    IDEMPOTENCY_KEY_SCHEMA,
    OUTCOMES,
    RECEIPT_SCHEMA,
    REQUEST_SCHEMA,
    REQUIRED_CAPABILITIES,
    REQUIRED_CHECKED_GATES,
    RUNTIME_ADMISSION_RECEIPT_SCHEMA,
    SOURCE_QUERY_RECEIPT_SCHEMA,
)
from ._protocol_person_abi_vector import (
    PromotionRequest,
    ProtocolPersonAbiError,
)
from ._runtime_language_receipts import (
    ContractArtifactProjectionReceipt,
    RuntimeLanguageAdmissionReceipt,
    SourceQueryReceipt,
)

__all__ = [
    "ABI_MAJOR",
    "ABI_MINOR",
    "CONTRACT_ARTIFACT_PROJECTION_RECEIPT_SCHEMA",
    "ContractArtifactProjectionReceipt",
    "IDEMPOTENCY_KEY_SCHEMA",
    "OUTCOMES",
    "PromotionRequest",
    "PromotionRuntimeReceipt",
    "ProtocolPersonAbiError",
    "RECEIPT_SCHEMA",
    "REQUEST_SCHEMA",
    "REQUIRED_CAPABILITIES",
    "REQUIRED_CHECKED_GATES",
    "RUNTIME_ADMISSION_RECEIPT_SCHEMA",
    "RuntimeLanguageAdmissionReceipt",
    "SOURCE_QUERY_RECEIPT_SCHEMA",
    "SourceQueryReceipt",
    "receipts_exactly_once",
]
