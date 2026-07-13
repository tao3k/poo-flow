#ifndef POO_FLOW_PROOF_CASE_V1_H
#define POO_FLOW_PROOF_CASE_V1_H

#include <stddef.h>
#include <stdint.h>

#include <poo_flow/proof_case_vector_v1.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uint32_t poo_flow_proof_status;

enum {
  POO_FLOW_PROOF_STATUS_OK = 0u,
  POO_FLOW_PROOF_STATUS_INVALID_ARGUMENT = 1u,
  POO_FLOW_PROOF_STATUS_BUFFER_TOO_SMALL = 2u,
  POO_FLOW_PROOF_STATUS_STALE_HANDLE = 3u,
  POO_FLOW_PROOF_STATUS_SCHEMA_MISMATCH = 4u,
  POO_FLOW_PROOF_STATUS_MALFORMED_EVIDENCE = 5u,
  POO_FLOW_PROOF_STATUS_UNSUPPORTED_OBLIGATION = 6u
};

typedef struct {
  const uint8_t *data;
  size_t size;
  uint64_t generation;
} poo_flow_proof_case_handle;

typedef struct {
  size_t required_size;
  size_t alignment;
  uint32_t abi_version;
  uint8_t schema_fingerprint[32];
} poo_flow_proof_case_layout;

/* The vector is borrowed and must outlive the handle. No allocation occurs. */
poo_flow_proof_status poo_flow_proof_case_init(
    const void *vector, size_t vector_size, poo_flow_proof_case_handle *out_handle);

poo_flow_proof_status poo_flow_proof_case_release(
    poo_flow_proof_case_handle *handle);

poo_flow_proof_status poo_flow_proof_case_measure(
    const poo_flow_proof_case_handle *handle,
    poo_flow_proof_case_layout *out_layout);

/* On BUFFER_TOO_SMALL, written reports the required size and buffer is untouched. */
poo_flow_proof_status poo_flow_proof_case_write(
    const poo_flow_proof_case_handle *handle, void *buffer, size_t capacity,
    size_t *written);

const char *poo_flow_proof_status_name(poo_flow_proof_status status);

#ifdef __cplusplus
}
#endif

#endif
