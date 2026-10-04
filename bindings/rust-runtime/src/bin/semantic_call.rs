// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! One bounded read-only request for external host adapters.
use poo_flow_rust_runtime::SemanticRuntime;
use poo_flow_rust_runtime::wire::{self, Value};
use std::io::{Read, Write};
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut input = Vec::new();
    std::io::stdin().take(1_048_577).read_to_end(&mut input)?;
    if input.len() > 1_048_576 {
        return Err("input byte bound exceeded".into());
    }
    let request: Value = wire::from_slice(&input)?;
    let object = request.as_object().ok_or("request must be an object")?;
    if object.len() != 2 || !object.contains_key("operation") || !object.contains_key("payload") {
        return Err("request requires exactly operation and payload".into());
    }
    let runtime = SemanticRuntime::open(
        std::env::var("POO_FLOW_SEMANTIC_LIBRARY")?,
        &std::env::var("POO_FLOW_SEMANTIC_SHA256")?,
        64,
    )?;
    let result = runtime.call(
        request["operation"].as_str().ok_or("invalid operation")?,
        &request["payload"],
    )?;
    runtime.close()?;
    std::io::stdout().write_all(&wire::to_vec(&result)?)?;
    std::io::stdout().write_all(b"\n")?;
    Ok(())
}
