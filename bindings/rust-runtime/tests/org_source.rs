// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

#![cfg(feature = "orgize-source")]

use std::{
    fs,
    path::PathBuf,
    time::{SystemTime, UNIX_EPOCH},
};

use orgize::ParseConfig;
use poo_flow_rust_runtime::org_source::{
    OrgSourceBridgeError, WorktreeOrgSelection, WorktreeOrgSourceKey,
};

struct Fixture(PathBuf);

impl Fixture {
    fn new() -> Self {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system time")
            .as_nanos();
        let path =
            std::env::temp_dir().join(format!("poo-org-source-{}-{nonce}", std::process::id()));
        fs::create_dir(&path).expect("fixture root");
        Self(path)
    }

    fn key(&self, cut: &str) -> WorktreeOrgSourceKey {
        WorktreeOrgSourceKey::new("project", "worktree-a", cut, "notes.org")
            .expect("bounded source key")
    }
}

impl Drop for Fixture {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

#[test]
fn host_source_handle_rechecks_file_bytes_config_cut_and_query() {
    let fixture = Fixture::new();
    fs::write(fixture.0.join("notes.org"), "* TODO Remember\n").expect("source file");
    let key = fixture.key("cut-a");
    let config = ParseConfig::default();
    let selection =
        WorktreeOrgSelection::select_file(&fixture.0, key.clone(), &config, "tasks.open", 0)
            .expect("Orgize parser-owned selection");
    let current = selection
        .recheck_file(&fixture.0, &key, &config, "tasks.open")
        .expect("current source recheck");
    assert_eq!(current.key(), &key);
    assert_eq!(current.query_id(), "tasks.open");
    assert_eq!(current.matches().len(), 1);
    assert!(current.source_digest().starts_with("sha256:"));

    assert!(matches!(
        selection.recheck_file(&fixture.0, &fixture.key("cut-b"), &config, "tasks.open"),
        Err(OrgSourceBridgeError::StaleIdentity)
    ));
    assert!(matches!(
        selection.recheck_file(&fixture.0, &key, &config, "tasks.done"),
        Err(OrgSourceBridgeError::QueryNotAllowed)
    ));
    let changed_config = ParseConfig {
        todo_keywords: (vec!["WAIT".into()], vec!["DONE".into()]),
        ..config.clone()
    };
    assert!(matches!(
        selection.recheck_file(&fixture.0, &key, &changed_config, "tasks.open"),
        Err(OrgSourceBridgeError::StaleObservation)
    ));
    fs::write(fixture.0.join("notes.org"), "* DONE Remember\n").expect("changed source");
    assert!(matches!(
        selection.recheck_file(&fixture.0, &key, &config, "tasks.open"),
        Err(OrgSourceBridgeError::StaleObservation)
    ));
    println!("ORGIZE-SOURCE-HOST-OK: current source and stale cut, query, config, bytes");
}

#[test]
fn host_source_handle_rejects_path_escape_and_root_swap() {
    let fixture = Fixture::new();
    fs::write(fixture.0.join("notes.org"), "* TODO Remember\n").expect("source file");
    assert!(matches!(
        WorktreeOrgSourceKey::new("project", "worktree-a", "cut-a", "../notes.org"),
        Err(OrgSourceBridgeError::InvalidPath)
    ));
    let key = fixture.key("cut-a");
    let config = ParseConfig::default();
    let selection =
        WorktreeOrgSelection::select_file(&fixture.0, key.clone(), &config, "tasks.open", 0)
            .expect("initial file");
    let other_root = fixture.0.join("other");
    fs::create_dir(&other_root).expect("other root");
    fs::write(other_root.join("notes.org"), "* TODO Remember\n").expect("same bytes at other root");
    assert!(matches!(
        selection.recheck_file(&other_root, &key, &config, "tasks.open"),
        Err(OrgSourceBridgeError::StaleFile)
    ));

    #[cfg(unix)]
    {
        use std::os::unix::fs::symlink;
        let outside = fixture.0.with_extension("org");
        fs::write(&outside, "* TODO Outside\n").expect("outside file");
        symlink(&outside, fixture.0.join("outside.org")).expect("escape symlink");
        let outside_key =
            WorktreeOrgSourceKey::new("project", "worktree-a", "cut-a", "outside.org")
                .expect("relative path");
        assert!(matches!(
            WorktreeOrgSelection::select_file(&fixture.0, outside_key, &config, "tasks.open", 0,),
            Err(OrgSourceBridgeError::EscapesWorktree)
        ));
        fs::remove_file(outside).expect("cleanup outside file");
    }
    println!("ORGIZE-SOURCE-HOST-OK: path escape and root swap rejected");
}

#[test]
fn host_source_handle_bounds_bytes_and_requires_utf8() {
    let fixture = Fixture::new();
    let key = fixture.key("cut-a");
    let config = ParseConfig::default();
    fs::write(fixture.0.join("notes.org"), [0xff]).expect("non-UTF-8 source");
    assert!(matches!(
        WorktreeOrgSelection::select_file(&fixture.0, key.clone(), &config, "tasks.open", 0),
        Err(OrgSourceBridgeError::InvalidUtf8)
    ));
    fs::write(fixture.0.join("notes.org"), vec![b'x'; 8 * 1024 * 1024 + 1])
        .expect("oversized source");
    assert!(matches!(
        WorktreeOrgSelection::select_file(&fixture.0, key, &config, "tasks.open", 0),
        Err(OrgSourceBridgeError::SourceTooLarge)
    ));
    println!("ORGIZE-SOURCE-HOST-OK: invalid UTF-8 and oversized source rejected");
}
