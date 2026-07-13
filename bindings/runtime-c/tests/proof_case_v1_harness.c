#include <poo_flow/proof_case_v1.h>

#include <stdio.h>
#include <string.h>

static const uint8_t k_schema_fingerprint[32] =
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

static void make_vector(uint8_t *vector) {
  memset(vector, 0, POO_FLOW_PROOF_CASE_VECTOR_SIZE);
  write_u32_le(vector + POO_FLOW_PROOF_FIELD_ABI_VERSION_OFFSET,
               POO_FLOW_PROOF_CASE_VECTOR_VERSION);
  write_u32_le(vector + POO_FLOW_PROOF_FIELD_CASE_KIND_OFFSET,
               POO_FLOW_PROOF_CASE_KIND_AUTHORIZED_EFFECT_TOKEN);
  memcpy(vector + POO_FLOW_PROOF_FIELD_SCHEMA_FINGERPRINT_OFFSET,
         k_schema_fingerprint, sizeof(k_schema_fingerprint));
  write_u64_le(vector + POO_FLOW_PROOF_FIELD_REQUIRED_OBLIGATION_MASK_OFFSET,
               POO_FLOW_PROOF_REQUIRED_OBLIGATION_MASK);
  write_u64_le(vector + POO_FLOW_PROOF_FIELD_PRESENT_OBLIGATION_MASK_OFFSET,
               POO_FLOW_PROOF_REQUIRED_OBLIGATION_MASK);
  write_u32_le(vector + POO_FLOW_PROOF_FIELD_OBLIGATION_COUNT_OFFSET, 8u);
  write_u32_le(vector + POO_FLOW_PROOF_FIELD_MEDIATION_OUTCOME_OFFSET,
               POO_FLOW_PROOF_MEDIATION_ALLOW);
  write_u32_le(vector + POO_FLOW_PROOF_FIELD_DURABILITY_PROFILE_OFFSET,
               POO_FLOW_PROOF_DURABILITY_STRICT);
}

static int expect_status(const char *label, poo_flow_proof_status actual,
                         poo_flow_proof_status expected) {
  if (actual == expected) {
    return 0;
  }
  fprintf(stderr, "%s: expected %s, got %s\n", label,
          poo_flow_proof_status_name(expected),
          poo_flow_proof_status_name(actual));
  return 1;
}

int main(void) {
  uint8_t vector[POO_FLOW_PROOF_CASE_VECTOR_SIZE];
  uint8_t output[POO_FLOW_PROOF_CASE_VECTOR_SIZE];
  uint8_t guard[POO_FLOW_PROOF_CASE_VECTOR_SIZE];
  poo_flow_proof_case_handle handle = {0};
  poo_flow_proof_case_layout layout = {0};
  size_t written = 0u;

  make_vector(vector);
  if (expect_status("null-vector",
                    poo_flow_proof_case_init(NULL, sizeof(vector), &handle),
                    POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT) != 0 ||
      expect_status("null-output-handle",
                    poo_flow_proof_case_init(vector, sizeof(vector), NULL),
                    POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT) != 0) {
    return 1;
  }
  if (expect_status("init",
                    poo_flow_proof_case_init(vector, sizeof(vector), &handle),
                    POO_FLOW_PROOF_STATUS_OK) != 0 ||
      expect_status("measure", poo_flow_proof_case_measure(&handle, &layout),
                    POO_FLOW_PROOF_STATUS_OK) != 0) {
    return 1;
  }
  if (layout.required_size != sizeof(vector) ||
      layout.alignment != POO_FLOW_PROOF_CASE_VECTOR_ALIGNMENT ||
      layout.abi_version != POO_FLOW_PROOF_CASE_VECTOR_VERSION ||
      memcmp(layout.schema_fingerprint, k_schema_fingerprint,
             sizeof(k_schema_fingerprint)) != 0) {
    fprintf(stderr, "measure returned the wrong layout\n");
    return 1;
  }

  memset(guard, 0xa5, sizeof(guard));
  if (expect_status("small-buffer",
                    poo_flow_proof_case_write(&handle, guard,
                                              sizeof(guard) - 1u, &written),
                    POO_FLOW_PROOF_STATUS_BUFFER_TOO_SMALL) != 0 ||
      written != sizeof(vector) || guard[0] != 0xa5u) {
    fprintf(stderr, "small-buffer write was not atomic\n");
    return 1;
  }
  if (expect_status("write",
                    poo_flow_proof_case_write(&handle, output, sizeof(output),
                                              &written),
                    POO_FLOW_PROOF_STATUS_OK) != 0 ||
      written != sizeof(vector) || memcmp(output, vector, sizeof(vector)) != 0) {
    fprintf(stderr, "bulk write did not preserve the vector\n");
    return 1;
  }
  if (expect_status("release", poo_flow_proof_case_release(&handle),
                    POO_FLOW_PROOF_STATUS_OK) != 0 ||
      expect_status("stale", poo_flow_proof_case_measure(&handle, &layout),
                    POO_FLOW_PROOF_STATUS_STALE_HANDLE) != 0 ||
      expect_status("double-release", poo_flow_proof_case_release(&handle),
                    POO_FLOW_PROOF_STATUS_STALE_HANDLE) != 0) {
    return 1;
  }

  make_vector(vector);
  vector[POO_FLOW_PROOF_FIELD_SCHEMA_FINGERPRINT_OFFSET] ^= 1u;
  if (expect_status("schema-mismatch",
                    poo_flow_proof_case_init(vector, sizeof(vector), &handle),
                    POO_FLOW_PROOF_STATUS_SCHEMA_MISMATCH) != 0) {
    return 1;
  }
  make_vector(vector);
  write_u64_le(vector + POO_FLOW_PROOF_FIELD_REQUIRED_OBLIGATION_MASK_OFFSET,
               UINT64_C(0x1ff));
  if (expect_status("unsupported-obligation",
                    poo_flow_proof_case_init(vector, sizeof(vector), &handle),
                    POO_FLOW_PROOF_STATUS_UNSUPPORTED_OBLIGATION) != 0) {
    return 1;
  }
  make_vector(vector);
  write_u64_le(vector + POO_FLOW_PROOF_FIELD_PRESENT_OBLIGATION_MASK_OFFSET,
               UINT64_C(0x1ff));
  if (expect_status("unsupported-present-obligation",
                    poo_flow_proof_case_init(vector, sizeof(vector), &handle),
                    POO_FLOW_PROOF_STATUS_UNSUPPORTED_OBLIGATION) != 0) {
    return 1;
  }
  make_vector(vector);
  write_u32_le(vector + POO_FLOW_PROOF_FIELD_OBLIGATION_COUNT_OFFSET, 9u);
  if (expect_status("obligation-count",
                    poo_flow_proof_case_init(vector, sizeof(vector), &handle),
                    POO_FLOW_PROOF_STATUS_MALFORMED_EVIDENCE) != 0) {
    return 1;
  }
  make_vector(vector);
  vector[POO_FLOW_PROOF_FIELD_RESERVED_OFFSET] = 1u;
  if (expect_status("reserved-byte",
                    poo_flow_proof_case_init(vector, sizeof(vector), &handle),
                    POO_FLOW_PROOF_STATUS_MALFORMED_EVIDENCE) != 0) {
    return 1;
  }
  make_vector(vector);
  if (expect_status("truncated",
                    poo_flow_proof_case_init(vector, sizeof(vector) - 1u,
                                             &handle),
                    POO_FLOW_PROOF_STATUS_MALFORMED_EVIDENCE) != 0) {
    return 1;
  }

  puts("proof-case-v1: ok");
  return 0;
}
