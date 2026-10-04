// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Freeze receipts to the actual immutable dependency graph.
use std::fs;

fn main() {
    println!("cargo:rerun-if-changed=Cargo.toml");
    println!("cargo:rerun-if-changed=Cargo.lock");
    let manifest: toml::Value =
        toml::from_str(&fs::read_to_string("Cargo.toml").expect("qualification manifest"))
            .expect("valid manifest");
    assert!(
        manifest.get("patch").is_none(),
        "qualification rejects local dependency substitutions"
    );
    let lock: toml::Value =
        toml::from_str(&fs::read_to_string("Cargo.lock").expect("qualification lock"))
            .expect("valid lock");
    for (name, key) in [
        ("meta-relational-reasoning", "POO_QUALIFIED_MRR_PIN"),
        ("mrr-data-core", "POO_QUALIFIED_DATA_PIN"),
        (
            "gerbil-scheme-native-build",
            "POO_QUALIFIED_NATIVE_BUILD_PIN",
        ),
    ] {
        let rows: Vec<_> = lock["package"]
            .as_array()
            .expect("lock packages")
            .iter()
            .filter(|row| row["name"].as_str() == Some(name))
            .collect();
        assert_eq!(rows.len(), 1, "one immutable owner for {name}");
        let source = rows[0]["source"].as_str().expect("Git dependency source");
        let (url, pin) = source.rsplit_once('#').expect("resolved Git revision");
        assert!(
            pin.len() == 40 && pin.bytes().all(|b| b.is_ascii_hexdigit()),
            "full Git revision"
        );
        assert!(
            url.starts_with("git+https://github.com/tao3k/")
                && url.ends_with(&format!("?rev={pin}")),
            "immutable source revision"
        );
        if let Some(dependency) = manifest["dependencies"].get(name) {
            assert_eq!(
                dependency["rev"].as_str(),
                Some(pin),
                "manifest and lock must agree"
            );
        }
        println!("cargo:rustc-env={key}={pin}");
    }
}
