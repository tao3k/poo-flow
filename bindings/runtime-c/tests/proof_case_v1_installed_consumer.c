#include <poo_flow/proof_case_v1.h>

#include <string.h>

static const uint8_t k_fingerprint[32] =
    POO_FLOW_PROOF_CASE_SCHEMA_FINGERPRINT_BYTES;

static void write_u32_le(uint8_t *bytes, uint32_t value) {
  bytes[0] = (uint8_t)value;
  bytes[1] = (uint8_t)(value >> 8u);
  bytes[2] = (uint8_t)(value >> 16u);
  bytes[3] = (uint8_t)(value >> 24u);
}

static void write_u64_le(uint8_t *bytes, uint64_t value) {
  size_t index = 0u;
  for (; index < 8u; ++index) {
    bytes[index] = (uint8_t)(value >> (index * 8u));
  }
}

int main(void) {
  uint8_t vector[POO_FLOW_PROOF_CASE_VECTOR_SIZE] = {0};
  uint8_t output[POO_FLOW_PROOF_CASE_VECTOR_SIZE] = {0};
  poo_flow_proof_case_handle handle = {0};
  size_t written = 0u;

  write_u32_le(vector + POO_FLOW_PROOF_FIELD_ABI_VERSION_OFFSET,
               POO_FLOW_PROOF_CASE_VECTOR_VERSION);
  write_u32_le(vector + POO_FLOW_PROOF_FIELD_CASE_KIND_OFFSET,
               POO_FLOW_PROOF_CASE_KIND_AUTHORIZED_EFFECT_TOKEN);
  memcpy(vector + POO_FLOW_PROOF_FIELD_SCHEMA_FINGERPRINT_OFFSET, k_fingerprint,
         sizeof(k_fingerprint));
  write_u64_le(vector + POO_FLOW_PROOF_FIELD_REQUIRED_OBLIGATION_MASK_OFFSET,
               POO_FLOW_PROOF_REQUIRED_OBLIGATION_MASK);
  write_u32_le(vector + POO_FLOW_PROOF_FIELD_MEDIATION_OUTCOME_OFFSET,
               POO_FLOW_PROOF_MEDIATION_ALLOW);
  write_u32_le(vector + POO_FLOW_PROOF_FIELD_DURABILITY_PROFILE_OFFSET,
               POO_FLOW_PROOF_DURABILITY_STRICT);

  if (poo_flow_proof_case_init(vector, sizeof(vector), &handle) !=
          POO_FLOW_PROOF_STATUS_OK ||
      poo_flow_proof_case_write(&handle, output, sizeof(output), &written) !=
          POO_FLOW_PROOF_STATUS_OK ||
      written != sizeof(vector) || memcmp(vector, output, sizeof(vector)) != 0 ||
      poo_flow_proof_case_release(&handle) != POO_FLOW_PROOF_STATUS_OK) {
    return 1;
  }
  return 0;
}
