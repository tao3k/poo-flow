// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Exact-byte Orgize candidates for a POO Flow Memory policy decision.
//!
//! The caller owns Git/source-cut authentication. This adapter checks that the
//! bytes and cut it received still match the caller's current declaration; it
//! does not grant Memory access or publish a head.

use std::collections::HashSet;

use orgize::{
    org_aot::{org_event_parser_digest, org_graph_spec, parse_org_aot},
    org_element_query::{OrgElementFieldMatch, OrgElementQueryError, OrgElementRelation},
};
use sha2::{Digest, Sha256};

const ORGIZE_REVISION: &str = "16d2a8c3ac168d73b890262b29b756d4b4ec3361";
const ORG_MEMORY_LOAD_SCHEMA: &str = "poo-flow.modules.memory-core.org-load.v1";
const MAX_ORG_BYTES: usize = 1_048_576;
const MAX_CANDIDATES: usize = 4096;

/// A host-captured source snapshot. `current_cut_digest` must come from a
/// fresh, authorized host read, not from the Org document itself.
pub struct OrgMemorySource<'a> {
    pub project_id: &'a str,
    pub worktree_id: &'a str,
    pub source_path: &'a str,
    pub captured_cut_digest: &'a str,
    pub current_cut_digest: &'a str,
    pub expected_bytes_sha256: &'a str,
    pub bytes: &'a [u8],
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct OrgMemoryCandidate {
    pub record_id: usize,
    pub parent_id: Option<usize>,
    pub kind: &'static str,
    pub start_byte: usize,
    pub end_byte: usize,
    pub span_sha256: String,
}

/// Structural candidates only. Semantic admission and scope policy are later
/// owner decisions, so a nonempty candidate set is not publication authority.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct OrgMemoryLoadReceipt {
    pub schema: &'static str,
    pub project_id: String,
    pub worktree_id: String,
    pub source_path: String,
    pub source_cut_digest: String,
    pub bytes_sha256: String,
    pub orgize_revision: &'static str,
    pub parser_digest: &'static str,
    pub graph_digest: &'static str,
    pub query_id: String,
    pub query_rule_sha256: String,
    pub scope_record_id: usize,
    pub candidates: Vec<OrgMemoryCandidate>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub enum OrgMemoryLoadError {
    InvalidSourceIdentity,
    SourceTooLarge,
    StaleSourceCut,
    ByteDigestMismatch,
    InvalidUtf8,
    Parse(String),
    Query(OrgElementQueryError),
    CandidateLimit,
    DuplicateCandidate,
    InvalidSpan,
}

fn sha256(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}

fn hash_string(hash: &mut Sha256, value: &str) {
    hash.update((value.len() as u64).to_le_bytes());
    hash.update(value.as_bytes());
}

fn query_rule_sha256(id: &str) -> Result<String, OrgMemoryLoadError> {
    let pack = orgize::org_element_query::org_element_query_pack();
    let mut rules = pack.rules.iter().filter(|rule| rule.id == id);
    let rule = rules.next().ok_or(OrgMemoryLoadError::Query(
        OrgElementQueryError::UnknownQuery,
    ))?;
    if rules.next().is_some() {
        return Err(OrgMemoryLoadError::Query(OrgElementQueryError::InvalidRule));
    }
    let mut hash = Sha256::new();
    hash_string(&mut hash, pack.graph_digest);
    hash_string(&mut hash, rule.id);
    hash_string(&mut hash, rule.node_kind);
    hash.update([match rule.relation {
        OrgElementRelation::Any => 0,
        OrgElementRelation::At => 1,
        OrgElementRelation::ChildOf => 2,
        OrgElementRelation::DescendantOf => 3,
    }]);
    hash.update([u8::from(rule.target_scope)]);
    hash.update((rule.groups.len() as u64).to_le_bytes());
    for group in rule.groups {
        hash.update((group.len() as u64).to_le_bytes());
        for property in *group {
            hash_string(&mut hash, property.name);
            hash_string(&mut hash, property.value);
            hash.update([match property.matcher {
                OrgElementFieldMatch::Exact => 0,
                OrgElementFieldMatch::Contains => 1,
            }]);
        }
    }
    Ok(format!("{:x}", hash.finalize()))
}

/// Parse exact bytes with Orgize's Scheme-AOT parser and run one named query.
/// The host must recheck source authority and scope policy before using this
/// receipt in a Session turn or publishing a Memory head.
pub fn load_org_memory_candidates(
    source: &OrgMemorySource<'_>,
    query_id: &str,
    scope_record_id: usize,
) -> Result<OrgMemoryLoadReceipt, OrgMemoryLoadError> {
    if source.project_id.is_empty()
        || source.project_id.len() > 256
        || source.worktree_id.is_empty()
        || source.worktree_id.len() > 256
        || source.source_path.is_empty()
        || source.source_path.len() > 4096
        || source.captured_cut_digest.is_empty()
        || source.captured_cut_digest.len() > 256
        || source.current_cut_digest.is_empty()
        || source.current_cut_digest.len() > 256
        || source.expected_bytes_sha256.len() != 64
        || query_id.is_empty()
        || query_id.len() > 256
    {
        return Err(OrgMemoryLoadError::InvalidSourceIdentity);
    }
    if source.bytes.len() > MAX_ORG_BYTES {
        return Err(OrgMemoryLoadError::SourceTooLarge);
    }
    if source.captured_cut_digest != source.current_cut_digest {
        return Err(OrgMemoryLoadError::StaleSourceCut);
    }
    let bytes_sha256 = sha256(source.bytes);
    if bytes_sha256 != source.expected_bytes_sha256 {
        return Err(OrgMemoryLoadError::ByteDigestMismatch);
    }
    let text = std::str::from_utf8(source.bytes).map_err(|_| OrgMemoryLoadError::InvalidUtf8)?;
    let document =
        parse_org_aot(text).map_err(|error| OrgMemoryLoadError::Parse(format!("{error:?}")))?;
    let ids = document
        .query_named(query_id, scope_record_id)
        .map_err(OrgMemoryLoadError::Query)?;
    if ids.len() > MAX_CANDIDATES {
        return Err(OrgMemoryLoadError::CandidateLimit);
    }
    let query_rule_sha256 = query_rule_sha256(query_id)?;
    let mut candidates = Vec::with_capacity(ids.len());
    let mut seen = HashSet::with_capacity(ids.len());
    for id in ids {
        if !seen.insert(id) {
            return Err(OrgMemoryLoadError::DuplicateCandidate);
        }
        let record = document
            .records()
            .get(id)
            .ok_or(OrgMemoryLoadError::InvalidSpan)?;
        let start_byte = usize::from(record.range.start());
        let end_byte = usize::from(record.range.end());
        if start_byte >= end_byte {
            return Err(OrgMemoryLoadError::InvalidSpan);
        }
        let span = source
            .bytes
            .get(start_byte..end_byte)
            .ok_or(OrgMemoryLoadError::InvalidSpan)?;
        candidates.push(OrgMemoryCandidate {
            record_id: id,
            parent_id: record.parent_id,
            kind: record.kind,
            start_byte,
            end_byte,
            span_sha256: sha256(span),
        });
    }
    Ok(OrgMemoryLoadReceipt {
        schema: ORG_MEMORY_LOAD_SCHEMA,
        project_id: source.project_id.to_owned(),
        worktree_id: source.worktree_id.to_owned(),
        source_path: source.source_path.to_owned(),
        source_cut_digest: source.captured_cut_digest.to_owned(),
        bytes_sha256,
        orgize_revision: ORGIZE_REVISION,
        parser_digest: org_event_parser_digest(),
        graph_digest: org_graph_spec().projection_digest,
        query_id: query_id.to_owned(),
        query_rule_sha256,
        scope_record_id,
        candidates,
    })
}
