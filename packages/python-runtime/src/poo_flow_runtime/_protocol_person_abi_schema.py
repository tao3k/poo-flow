"""Frozen identities for the POO Flow Runtime Language ABI promotion lane."""

REQUEST_SCHEMA = "poo-flow.runtime-language.promotion-request.1"
RECEIPT_SCHEMA = "poo-flow.runtime-language.promotion-receipt.1"
IDEMPOTENCY_KEY_SCHEMA = (
    "poo-flow.runtime-language.promotion-idempotency-key.1"
)
SOURCE_QUERY_RECEIPT_SCHEMA = (
    "poo-flow.runtime-language.source-query-receipt.1"
)
RUNTIME_ADMISSION_RECEIPT_SCHEMA = (
    "poo-flow.runtime-language.admission-receipt.1"
)
CONTRACT_ARTIFACT_PROJECTION_RECEIPT_SCHEMA = (
    "poo-flow.contract.artifact-projection-receipt.1"
)
ABI_MAJOR = 0
ABI_MINOR = 3

REQUIRED_CAPABILITIES = (
    "PROMOTION_MATERIALIZE",
    "INJECTION_RECEIPT",
    "ROLLBACK",
    "EXACTLY_ONCE",
    "LANGUAGE_QUALIFICATION",
)

REQUIRED_CHECKED_GATES = (
    "intent-kind",
    "world-kind",
    "decision-facts-kind",
    "cedar-permit",
    "lean-verified",
    "bundle-epoch",
    "authority-epoch",
    "proof-epoch",
    "evaluator-epoch",
    "evaluator-applicable",
    "evidence-complete",
    "exactly-once-materialization",
    "injection-receipt",
)

OUTCOMES = (
    "accepted",
    "materialized",
    "injected",
    "replayed-active",
    "rejected-stale-epoch",
    "rejected-capability",
    "rolled-back",
    "failed",
)

REQUIRED_VECTOR_FIELDS = (
    "schema",
    "abi-major",
    "abi-minor",
    "required-capabilities",
    "idempotency-key-schema",
    "promotion-id",
    "materialization-id",
    "candidate-digest",
    "subject-id",
    "commitment-id",
    "source-role",
    "target-role",
    "scope",
    "bundle-epoch",
    "authority-epoch",
    "proof-epoch",
    "evaluator-epoch",
    "evidence-root",
    "injection-target",
    "rollback-target",
    "validation-receipt-schema",
    "approval-code",
    "checked-gates",
)
