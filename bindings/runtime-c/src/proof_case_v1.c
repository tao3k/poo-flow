#include <poo_flow/proof_case_v1.h>

#include <string.h>

static const uint8_t k_schema_fingerprint[32] =
    POO_FLOW_PROOF_CASE_SCHEMA_FINGERPRINT_BYTES;

static uint32_t read_u32_le(const uint8_t *bytes) {
  return ((uint32_t)bytes[0]) | ((uint32_t)bytes[1] << 8u) |
         ((uint32_t)bytes[2] << 16u) | ((uint32_t)bytes[3] << 24u);
}

static uint64_t read_u64_le(const uint8_t *bytes) {
  uint64_t result = 0u;
  size_t index = 0u;
  for (; index < 8u; ++index) {
    result |= ((uint64_t)bytes[index]) << (index * 8u);
  }
  return result;
}

static poo_flow_proof_status validate_vector(const uint8_t *vector,
                                             size_t vector_size) {
  uint32_t case_kind;
  uint32_t obligation_count;
  uint32_t mediation;
  uint32_t durability;
  uint64_t required_mask;
  uint64_t present_mask;
  size_t index;

  if (vector == NULL) {
    return POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT;
  }
  if (vector_size != POO_FLOW_PROOF_CASE_VECTOR_SIZE) {
    return POO_FLOW_PROOF_STATUS_MALFORMED_EVIDENCE;
  }
  if (read_u32_le(vector + POO_FLOW_PROOF_FIELD_ABI_VERSION_OFFSET) !=
      POO_FLOW_PROOF_CASE_VECTOR_VERSION) {
    return POO_FLOW_PROOF_STATUS_SCHEMA_MISMATCH;
  }
  if (memcmp(vector + POO_FLOW_PROOF_FIELD_SCHEMA_FINGERPRINT_OFFSET,
             k_schema_fingerprint, sizeof(k_schema_fingerprint)) != 0) {
    return POO_FLOW_PROOF_STATUS_SCHEMA_MISMATCH;
  }

  required_mask = read_u64_le(
      vector + POO_FLOW_PROOF_FIELD_REQUIRED_OBLIGATION_MASK_OFFSET);
  present_mask = read_u64_le(
      vector + POO_FLOW_PROOF_FIELD_PRESENT_OBLIGATION_MASK_OFFSET);
  if (((required_mask | present_mask) &
       ~POO_FLOW_PROOF_REQUIRED_OBLIGATION_MASK) != 0u) {
    return POO_FLOW_PROOF_STATUS_UNSUPPORTED_OBLIGATION;
  }
  if ((present_mask & ~required_mask) != 0u) {
    return POO_FLOW_PROOF_STATUS_MALFORMED_EVIDENCE;
  }

  case_kind = read_u32_le(vector + POO_FLOW_PROOF_FIELD_CASE_KIND_OFFSET);
  obligation_count =
      read_u32_le(vector + POO_FLOW_PROOF_FIELD_OBLIGATION_COUNT_OFFSET);
  mediation =
      read_u32_le(vector + POO_FLOW_PROOF_FIELD_MEDIATION_OUTCOME_OFFSET);
  durability =
      read_u32_le(vector + POO_FLOW_PROOF_FIELD_DURABILITY_PROFILE_OFFSET);
  if (case_kind != POO_FLOW_PROOF_CASE_KIND_AUTHORIZED_EFFECT_TOKEN ||
      obligation_count > 8u ||
      mediation < POO_FLOW_PROOF_MEDIATION_ALLOW ||
      mediation > POO_FLOW_PROOF_MEDIATION_INVALID_TOKEN ||
      durability < POO_FLOW_PROOF_DURABILITY_STRICT ||
      durability > POO_FLOW_PROOF_DURABILITY_DIAGNOSTIC) {
    return POO_FLOW_PROOF_STATUS_MALFORMED_EVIDENCE;
  }
  for (index = 0u; index < 12u; ++index) {
    if (vector[POO_FLOW_PROOF_FIELD_RESERVED_OFFSET + index] != 0u) {
      return POO_FLOW_PROOF_STATUS_MALFORMED_EVIDENCE;
    }
  }
  return POO_FLOW_PROOF_STATUS_OK;
}

static poo_flow_proof_status validate_handle(
    const poo_flow_proof_case_handle *handle) {
  if (handle == NULL) {
    return POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT;
  }
  if (handle->data == NULL || handle->generation == 0u) {
    return POO_FLOW_PROOF_STATUS_STALE_HANDLE;
  }
  return validate_vector(handle->data, handle->size);
}

poo_flow_proof_status poo_flow_proof_case_init(
    const void *vector, size_t vector_size,
    poo_flow_proof_case_handle *out_handle) {
  poo_flow_proof_status status;
  if (out_handle == NULL) {
    return POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT;
  }
  out_handle->data = NULL;
  out_handle->size = 0u;
  out_handle->generation = 0u;
  status = validate_vector((const uint8_t *)vector, vector_size);
  if (status != POO_FLOW_PROOF_STATUS_OK) {
    return status;
  }
  out_handle->data = (const uint8_t *)vector;
  out_handle->size = vector_size;
  out_handle->generation = 1u;
  return POO_FLOW_PROOF_STATUS_OK;
}

poo_flow_proof_status poo_flow_proof_case_release(
    poo_flow_proof_case_handle *handle) {
  if (handle == NULL) {
    return POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT;
  }
  if (handle->data == NULL || handle->generation == 0u) {
    return POO_FLOW_PROOF_STATUS_STALE_HANDLE;
  }
  handle->data = NULL;
  handle->size = 0u;
  handle->generation = 0u;
  return POO_FLOW_PROOF_STATUS_OK;
}

poo_flow_proof_status poo_flow_proof_case_measure(
    const poo_flow_proof_case_handle *handle,
    poo_flow_proof_case_layout *out_layout) {
  poo_flow_proof_status status;
  if (out_layout == NULL) {
    return POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT;
  }
  status = validate_handle(handle);
  if (status != POO_FLOW_PROOF_STATUS_OK) {
    return status;
  }
  out_layout->required_size = POO_FLOW_PROOF_CASE_VECTOR_SIZE;
  out_layout->alignment = POO_FLOW_PROOF_CASE_VECTOR_ALIGNMENT;
  out_layout->abi_version = POO_FLOW_PROOF_CASE_VECTOR_VERSION;
  memcpy(out_layout->schema_fingerprint, k_schema_fingerprint,
         sizeof(k_schema_fingerprint));
  return POO_FLOW_PROOF_STATUS_OK;
}

poo_flow_proof_status poo_flow_proof_case_write(
    const poo_flow_proof_case_handle *handle, void *buffer, size_t capacity,
    size_t *written) {
  poo_flow_proof_status status;
  if (written == NULL) {
    return POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT;
  }
  *written = 0u;
  status = validate_handle(handle);
  if (status != POO_FLOW_PROOF_STATUS_OK) {
    return status;
  }
  *written = POO_FLOW_PROOF_CASE_VECTOR_SIZE;
  if (capacity < POO_FLOW_PROOF_CASE_VECTOR_SIZE) {
    return POO_FLOW_PROOF_STATUS_BUFFER_TOO_SMALL;
  }
  if (buffer == NULL) {
    return POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT;
  }
  memcpy(buffer, handle->data, POO_FLOW_PROOF_CASE_VECTOR_SIZE);
  return POO_FLOW_PROOF_STATUS_OK;
}

const char *poo_flow_proof_status_name(poo_flow_proof_status status) {
  switch (status) {
  case POO_FLOW_PROOF_STATUS_OK:
    return "ok";
  case POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT:
    return "invalid-argument";
  case POO_FLOW_PROOF_STATUS_BUFFER_TOO_SMALL:
    return "buffer-too-small";
  case POO_FLOW_PROOF_STATUS_STALE_HANDLE:
    return "stale-handle";
  case POO_FLOW_PROOF_STATUS_SCHEMA_MISMATCH:
    return "schema-mismatch";
  case POO_FLOW_PROOF_STATUS_MALFORMED_EVIDENCE:
    return "malformed-evidence";
  case POO_FLOW_PROOF_STATUS_UNSUPPORTED_OBLIGATION:
    return "unsupported-obligation";
  default:
    return "unknown-status";
  }
}
