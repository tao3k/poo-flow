// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
#![cfg(feature = "org-memory")]

use poo_flow_rust_runtime::org_memory::{
    OrgMemoryLoadError, OrgMemorySource, load_org_memory_candidates,
};
use sha2::{Digest, Sha256};

const ORG: &[u8] = b"#+TITLE: Team notes\n* TODO Review evidence\n* DONE Archived decision\n";

fn source<'a>(bytes: &'a [u8], expected_bytes_sha256: &'a str) -> OrgMemorySource<'a> {
    OrgMemorySource {
        project_id: "project-one",
        worktree_id: "worktree-a",
        source_path: "notes/memory.org",
        captured_cut_digest: "cut-a",
        current_cut_digest: "cut-a",
        expected_bytes_sha256,
        bytes,
    }
}

#[test]
fn named_query_candidates_bind_exact_source_and_orgize_versions() {
    let digest = format!("{:x}", Sha256::digest(ORG));
    let receipt = load_org_memory_candidates(&source(ORG, &digest), "tasks.open", 0).unwrap();
    assert_eq!(receipt.schema, "poo-flow.modules.memory-core.org-load.v1");
    assert_eq!(receipt.bytes_sha256, digest);
    assert_eq!(receipt.project_id, "project-one");
    assert_eq!(receipt.worktree_id, "worktree-a");
    assert_eq!(receipt.source_cut_digest, "cut-a");
    assert_eq!(receipt.candidates.len(), 1);
    assert!(!receipt.parser_digest.is_empty());
    assert!(!receipt.graph_digest.is_empty());
    assert_eq!(receipt.query_rule_sha256.len(), 64);
    let candidate = &receipt.candidates[0];
    assert!(
        std::str::from_utf8(&ORG[candidate.start_byte..candidate.end_byte])
            .unwrap()
            .contains("TODO Review evidence")
    );
}

#[test]
fn stale_cut_and_changed_bytes_are_refused_before_query() {
    let digest = format!("{:x}", Sha256::digest(ORG));
    let mut stale = source(ORG, &digest);
    stale.current_cut_digest = "cut-b";
    assert_eq!(
        load_org_memory_candidates(&stale, "tasks.open", 0),
        Err(OrgMemoryLoadError::StaleSourceCut)
    );
    let changed = b"* TODO Different source\n";
    assert_eq!(
        load_org_memory_candidates(&source(changed, &digest), "tasks.open", 0),
        Err(OrgMemoryLoadError::ByteDigestMismatch)
    );
}

#[test]
fn unknown_query_cannot_become_memory_authority() {
    let digest = format!("{:x}", Sha256::digest(ORG));
    assert!(matches!(
        load_org_memory_candidates(&source(ORG, &digest), "memory.all", 0),
        Err(OrgMemoryLoadError::Query(_))
    ));
}
