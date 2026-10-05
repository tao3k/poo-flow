// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Host-side source binding for Orgize's Scheme-AOT named Element queries.
//!
//! This module never accepts a caller-built Element graph or query result.
//! The host still owns WorkTree identity, the meaning of its source cut,
//! current grants, Session policy, and publication. A file read is one
//! observation, not an atomic filesystem snapshot or an effect permit.

use std::{
    fs,
    io::Read,
    path::{Component, Path, PathBuf},
};

use orgize::{
    ParseConfig,
    org_aot::{OrgAotError, parse_org_aot_with_config},
    org_element_query::{
        OrgElementQueryError, OrgElementQueryMatch, OrgElementQueryRecheckError,
        OrgElementQuerySourceObservation,
    },
};

const MAX_SOURCE_BYTES: usize = 8 * 1024 * 1024;

/// Host-declared scope and relative source path. Its cut is a premise, not a Git proof.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorktreeOrgSourceKey {
    project_id: String,
    worktree_id: String,
    source_cut_digest: String,
    relative_path: PathBuf,
}

impl WorktreeOrgSourceKey {
    /// Construct a bounded source key with a path confined to one WorkTree root.
    ///
    /// # Errors
    ///
    /// Rejects empty or unbounded identities and non-normal path components.
    pub fn new(
        project_id: impl Into<String>,
        worktree_id: impl Into<String>,
        source_cut_digest: impl Into<String>,
        relative_path: impl Into<PathBuf>,
    ) -> Result<Self, OrgSourceBridgeError> {
        let key = Self {
            project_id: project_id.into(),
            worktree_id: worktree_id.into(),
            source_cut_digest: source_cut_digest.into(),
            relative_path: relative_path.into(),
        };
        if ![&key.project_id, &key.worktree_id, &key.source_cut_digest]
            .into_iter()
            .all(|value| !value.is_empty() && value.len() <= 128 && !value.contains('\0'))
        {
            return Err(OrgSourceBridgeError::InvalidIdentity);
        }
        if key.relative_path.as_os_str().is_empty()
            || !key
                .relative_path
                .components()
                .all(|component| matches!(component, Component::Normal(_)))
        {
            return Err(OrgSourceBridgeError::InvalidPath);
        }
        Ok(key)
    }

    #[must_use]
    pub fn project_id(&self) -> &str {
        &self.project_id
    }

    #[must_use]
    pub fn worktree_id(&self) -> &str {
        &self.worktree_id
    }

    #[must_use]
    pub fn source_cut_digest(&self) -> &str {
        &self.source_cut_digest
    }

    #[must_use]
    pub fn relative_path(&self) -> &Path {
        &self.relative_path
    }
}

/// Parser-owned query observation tied to one host-declared WorkTree file.
#[derive(Debug)]
pub struct WorktreeOrgSelection {
    key: WorktreeOrgSourceKey,
    canonical_root: PathBuf,
    canonical_file: PathBuf,
    observation: OrgElementQuerySourceObservation,
}

/// Ephemeral current-file recheck. Recheck again before a later publication.
#[derive(Debug)]
pub struct CurrentWorktreeOrgSelection<'a> {
    selection: &'a WorktreeOrgSelection,
}

impl CurrentWorktreeOrgSelection<'_> {
    #[must_use]
    pub fn key(&self) -> &WorktreeOrgSourceKey {
        &self.selection.key
    }

    #[must_use]
    pub fn query_id(&self) -> &str {
        self.selection.observation.rule().id
    }

    #[must_use]
    pub fn source_digest(&self) -> &str {
        self.selection.observation.source_digest()
    }

    #[must_use]
    pub fn matches(&self) -> &[OrgElementQueryMatch] {
        self.selection.observation.matches()
    }
}

/// A rejected file, source, parser, or named query boundary.
#[derive(Debug)]
pub enum OrgSourceBridgeError {
    InvalidIdentity,
    InvalidPath,
    EscapesWorktree,
    NotRegularFile,
    SourceTooLarge,
    InvalidUtf8,
    StaleIdentity,
    StaleFile,
    QueryNotAllowed,
    StaleObservation,
    Io(std::io::Error),
    Parse(OrgAotError),
    Query(OrgElementQueryError),
    Recheck(OrgElementQueryRecheckError),
}

struct SourceRead {
    canonical_root: PathBuf,
    canonical_file: PathBuf,
    source: String,
}

fn read_worktree_source(
    worktree_root: &Path,
    key: &WorktreeOrgSourceKey,
) -> Result<SourceRead, OrgSourceBridgeError> {
    let canonical_root = fs::canonicalize(worktree_root).map_err(OrgSourceBridgeError::Io)?;
    if !canonical_root.is_dir() {
        return Err(OrgSourceBridgeError::InvalidPath);
    }
    let canonical_file = fs::canonicalize(canonical_root.join(&key.relative_path))
        .map_err(OrgSourceBridgeError::Io)?;
    if !canonical_file.starts_with(&canonical_root) {
        return Err(OrgSourceBridgeError::EscapesWorktree);
    }
    let file = fs::File::open(&canonical_file).map_err(OrgSourceBridgeError::Io)?;
    let metadata = file.metadata().map_err(OrgSourceBridgeError::Io)?;
    if !metadata.is_file() {
        return Err(OrgSourceBridgeError::NotRegularFile);
    }
    if metadata.len() > MAX_SOURCE_BYTES as u64 {
        return Err(OrgSourceBridgeError::SourceTooLarge);
    }
    // Bound the actual read as well: the file can grow after its metadata check.
    let mut bytes = Vec::new();
    file.take(MAX_SOURCE_BYTES as u64 + 1)
        .read_to_end(&mut bytes)
        .map_err(OrgSourceBridgeError::Io)?;
    if bytes.len() > MAX_SOURCE_BYTES {
        return Err(OrgSourceBridgeError::SourceTooLarge);
    }
    let source = String::from_utf8(bytes).map_err(|_| OrgSourceBridgeError::InvalidUtf8)?;
    Ok(SourceRead {
        canonical_root,
        canonical_file,
        source,
    })
}

impl WorktreeOrgSelection {
    /// Read a WorkTree file and run Orgize's maintained Scheme-AOT named query.
    ///
    /// The caller must supply an authentic WorkTree root, identity, and cut.
    /// This function only binds the selected graph records to the bytes read.
    ///
    /// # Errors
    ///
    /// Rejects path escape, non-UTF-8 or oversized input, parse failure,
    /// invalid scope, and unadmitted named query.
    pub fn select_file(
        worktree_root: &Path,
        key: WorktreeOrgSourceKey,
        config: &ParseConfig,
        query_id: &str,
        scope_id: usize,
    ) -> Result<Self, OrgSourceBridgeError> {
        let read = read_worktree_source(worktree_root, &key)?;
        let document =
            parse_org_aot_with_config(&read.source, config).map_err(OrgSourceBridgeError::Parse)?;
        let observation = document
            .query_named_source_observation(query_id, scope_id)
            .map_err(OrgSourceBridgeError::Query)?;
        Ok(Self {
            key,
            canonical_root: read.canonical_root,
            canonical_file: read.canonical_file,
            observation,
        })
    }

    /// Reopen the current file, reparse, and rerun the current named rule.
    ///
    /// This is a read-side source check only. The host must recheck the
    /// WorkTree cut and access grant, and use an expected-head CAS before
    /// publishing any Session or Memory effect.
    ///
    /// # Errors
    ///
    /// Rejects a changed host identity, root or resolved file, disallowed
    /// query, changed bytes/configuration/rule/results, or parser failure.
    pub fn recheck_file(
        &self,
        worktree_root: &Path,
        current_key: &WorktreeOrgSourceKey,
        current_config: &ParseConfig,
        allowed_query_id: &str,
    ) -> Result<CurrentWorktreeOrgSelection<'_>, OrgSourceBridgeError> {
        if current_key != &self.key {
            return Err(OrgSourceBridgeError::StaleIdentity);
        }
        if allowed_query_id != self.observation.rule().id {
            return Err(OrgSourceBridgeError::QueryNotAllowed);
        }
        let read = read_worktree_source(worktree_root, current_key)?;
        if read.canonical_root != self.canonical_root || read.canonical_file != self.canonical_file
        {
            return Err(OrgSourceBridgeError::StaleFile);
        }
        let current = self
            .observation
            .recheck_current_source(&read.source, current_config)
            .map_err(OrgSourceBridgeError::Recheck)?;
        if !current {
            return Err(OrgSourceBridgeError::StaleObservation);
        }
        Ok(CurrentWorktreeOrgSelection { selection: self })
    }
}
