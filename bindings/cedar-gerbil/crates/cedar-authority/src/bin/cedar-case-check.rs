// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
//
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

//! Data-driven qualification of exported Cedar files against the strict Runtime Host.

use cedar_policy::PolicySet;
use poo_flow_cedar_authority::authority::Authority;
use poo_flow_cedar_authority::canonical;
use poo_flow_cedar_authority::projection::{Bootstrap, PolicySource, Proposal};
use poo_flow_cedar_authority::runtime::{Deployment, HOST_READY_SCHEMA, RuntimeReady};
use poo_flow_cedar_authority::wire::{CEDAR_VERSION, LEAN_REVISION};
use serde::Deserialize;
use std::collections::BTreeSet;
use std::io::{BufRead, BufReader};
use std::path::{Path, PathBuf};
use std::process::{Child, Command, Stdio};
use std::str::FromStr;
use std::sync::mpsc;
use std::time::Duration;

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Case {
    name: String,
    proposal: Proposal,
    expected_status: String,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Manifest {
    bootstrap: Bootstrap,
    cases: Vec<Case>,
}

struct Host {
    child: Child,
    _directory: tempfile::TempDir,
    deployment: Deployment,
}

impl Drop for Host {
    fn drop(&mut self) {
        let _ = self.child.kill();
        let _ = self.child.wait();
    }
}

fn read_policy_file(path: &Path) -> Result<Vec<PolicySource>, String> {
    let bytes = std::fs::read(path).map_err(|error| format!("{}: {error}", path.display()))?;
    let source = std::str::from_utf8(&bytes).map_err(|error| error.to_string())?;
    let policies =
        PolicySet::from_str(source).map_err(|error| format!("{}: {error}", path.display()))?;
    if policies.templates().next().is_some() {
        return Err(format!(
            "{}: policy templates require explicit linking",
            path.display()
        ));
    }
    let prefix = canonical::raw_digest(&bytes);
    let prefix = &prefix[7..];
    let mut parsed = policies
        .policies()
        .map(|policy| {
            let body = policy.to_cedar().ok_or_else(|| {
                format!(
                    "{}: linked policy cannot render as Cedar text",
                    path.display()
                )
            })?;
            Ok((policy.id().to_string(), body))
        })
        .collect::<Result<Vec<_>, String>>()?;
    if parsed.is_empty() {
        return Err(format!("{}: no static policies", path.display()));
    }
    parsed.sort_by(|left, right| left.0.cmp(&right.0));
    Ok(parsed
        .into_iter()
        .enumerate()
        .map(|(index, (_, source))| PolicySource {
            identity: format!("artifact-{prefix}-{index}"),
            source,
        })
        .collect())
}

fn start_host(path: &Path) -> Result<Host, String> {
    let artifact = canonical::raw_digest(&std::fs::read(path).map_err(|error| error.to_string())?);
    let rust = canonical::raw_digest(CEDAR_VERSION.as_bytes());
    let lean = canonical::raw_digest(LEAN_REVISION.as_bytes());
    let directory = tempfile::tempdir().map_err(|error| error.to_string())?;
    let endpoint = directory.path().join("runtime.sock");
    let mut child = Command::new(path)
        .args([
            "serve-unix",
            endpoint.to_str().ok_or("non-UTF8 socket path")?,
            &artifact,
            &rust,
            &lean,
            "10000",
        ])
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
        .map_err(|error| error.to_string())?;
    let stdout = child.stdout.take().ok_or("missing Host readiness pipe")?;
    let (sender, receiver) = mpsc::sync_channel(1);
    std::thread::spawn(move || {
        let mut line = String::new();
        let result = BufReader::new(stdout).read_line(&mut line).map(|_| line);
        let _ = sender.send(result);
    });
    let ready = receiver
        .recv_timeout(Duration::from_secs(10))
        .map_err(|error| format!("Host readiness timeout: {error}"))?
        .map_err(|error| error.to_string())?;
    let ready: RuntimeReady = serde_json::from_str(&ready).map_err(|error| error.to_string())?;
    if ready.schema_id != HOST_READY_SCHEMA || Path::new(&ready.endpoint) != endpoint {
        return Err("Host readiness identity mismatch".into());
    }
    Ok(Host {
        child,
        _directory: directory,
        deployment: Deployment {
            runtime_endpoint: endpoint,
            runtime_artifact_digest: artifact,
            rust_component_digest: rust,
            lean_component_digest: lean,
            timeout_ms: 10000,
            grant_lifetime_ms: 30000,
        },
    })
}

fn run() -> Result<(), String> {
    let mut args = std::env::args_os().skip(1);
    let first = args
        .next()
        .ok_or("usage: cedar-case-check MANIFEST HOST POLICY.cedar [POLICY.cedar ...]")?;
    if first == std::ffi::OsStr::new("inspect") {
        let files = args.map(PathBuf::from).collect::<Vec<_>>();
        if files.is_empty() {
            return Err("usage: cedar-case-check inspect POLICY.cedar [POLICY.cedar ...]".into());
        }
        for file in files {
            println!(
                "{}: {} static policies",
                file.display(),
                read_policy_file(&file)?.len()
            );
        }
        return Ok(());
    }
    let manifest_path = PathBuf::from(first);
    let host_path = PathBuf::from(args.next().ok_or("missing AOT Runtime Host path")?);
    let files = args.map(PathBuf::from).collect::<Vec<_>>();
    if files.is_empty() {
        return Err("at least one exported .cedar file is required".into());
    }
    let mut manifest: Manifest =
        serde_json::from_slice(&std::fs::read(&manifest_path).map_err(|error| error.to_string())?)
            .map_err(|error| error.to_string())?;
    if !manifest.bootstrap.policies.is_empty() || manifest.cases.is_empty() {
        return Err("manifest requires empty bootstrap.policies and nonempty cases".into());
    }
    let mut names = BTreeSet::new();
    for case in &manifest.cases {
        if case.name.is_empty() || !names.insert(&case.name) {
            return Err(format!("duplicate or empty case name: {}", case.name));
        }
        if case.expected_status != "authorized" && case.expected_status != "denied" {
            return Err(format!(
                "{}: expected_status must be authorized or denied",
                case.name
            ));
        }
    }
    for file in &files {
        manifest.bootstrap.policies.extend(read_policy_file(file)?);
    }
    let host = start_host(&host_path)?;
    let mut authority = Authority::new(manifest.bootstrap, host.deployment.clone(), [77; 32])
        .map_err(|error| error.to_string())?;
    for case in manifest.cases {
        let result = authority
            .issue(case.proposal)
            .map_err(|error| format!("{}: {error}", case.name))?;
        if result.status != case.expected_status
            || !result
                .receipt
                .payload
                .rust
                .payload
                .outcome
                .agrees_with(&result.receipt.payload.lean.payload.outcome)
        {
            return Err(format!(
                "{}: expected {}, got {}",
                case.name, case.expected_status, result.status
            ));
        }
        println!("{}: {} (Cedar Rust + Lean)", case.name, result.status);
    }
    Ok(())
}

fn main() {
    if let Err(error) = run() {
        eprintln!("cedar-case-check: {error}");
        std::process::exit(1);
    }
}
