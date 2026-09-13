//! Restricted deterministic CBOR: only unsigned integers, bytes, and arrays.
//! JSON is an input projection, never the signed representation.

use serde::de::{self, MapAccess, SeqAccess, Visitor};
use serde::{Deserialize, Deserializer};
use serde_json::Value;
use sha2::{Digest, Sha256};
use std::fmt;

use crate::{Error, Result};

pub const MAX_PROJECTION_BYTES: usize = 1024 * 1024;

struct UniqueValue(Value);

impl<'de> Deserialize<'de> for UniqueValue {
    fn deserialize<D: Deserializer<'de>>(d: D) -> std::result::Result<Self, D::Error> {
        struct UniqueVisitor;
        impl<'de> Visitor<'de> for UniqueVisitor {
            type Value = UniqueValue;
            fn expecting(&self, f: &mut fmt::Formatter) -> fmt::Result {
                f.write_str("integer-only JSON with unique object keys")
            }
            fn visit_unit<E: de::Error>(self) -> std::result::Result<Self::Value, E> {
                Ok(UniqueValue(Value::Null))
            }
            fn visit_bool<E: de::Error>(self, v: bool) -> std::result::Result<Self::Value, E> {
                Ok(UniqueValue(v.into()))
            }
            fn visit_i64<E: de::Error>(self, v: i64) -> std::result::Result<Self::Value, E> {
                Ok(UniqueValue(v.into()))
            }
            fn visit_u64<E: de::Error>(self, v: u64) -> std::result::Result<Self::Value, E> {
                Ok(UniqueValue(v.into()))
            }
            fn visit_str<E: de::Error>(self, v: &str) -> std::result::Result<Self::Value, E> {
                Ok(UniqueValue(v.into()))
            }
            fn visit_string<E: de::Error>(self, v: String) -> std::result::Result<Self::Value, E> {
                Ok(UniqueValue(v.into()))
            }
            fn visit_seq<A: SeqAccess<'de>>(
                self,
                mut seq: A,
            ) -> std::result::Result<Self::Value, A::Error> {
                let mut values = Vec::new();
                while let Some(UniqueValue(value)) = seq.next_element()? {
                    values.push(value);
                }
                Ok(UniqueValue(Value::Array(values)))
            }
            fn visit_map<A: MapAccess<'de>>(
                self,
                mut map: A,
            ) -> std::result::Result<Self::Value, A::Error> {
                let mut values = serde_json::Map::new();
                while let Some(key) = map.next_key::<String>()? {
                    if values.contains_key(&key) {
                        return Err(de::Error::custom("duplicate semantic key"));
                    }
                    values.insert(key, map.next_value::<UniqueValue>()?.0);
                }
                Ok(UniqueValue(Value::Object(values)))
            }
        }
        d.deserialize_any(UniqueVisitor)
    }
}

pub fn parse<T: serde::de::DeserializeOwned>(bytes: &[u8]) -> Result<T> {
    if bytes.len() > MAX_PROJECTION_BYTES {
        return Err(Error::new("projection-too-large", "maximum is 1 MiB"));
    }
    let value: UniqueValue = serde_json::from_slice(bytes)
        .map_err(|e| Error::new("projection-invalid", e.to_string()))?;
    serde_json::from_value(value.0).map_err(|e| Error::new("projection-invalid", e.to_string()))
}

fn head(out: &mut Vec<u8>, major: u8, n: u64) {
    let prefix = major << 5;
    match n {
        0..=23 => out.push(prefix | n as u8),
        24..=0xff => out.extend([prefix | 24, n as u8]),
        0x100..=0xffff => {
            out.push(prefix | 25);
            out.extend((n as u16).to_be_bytes());
        }
        0x1_0000..=0xffff_ffff => {
            out.push(prefix | 26);
            out.extend((n as u32).to_be_bytes());
        }
        _ => {
            out.push(prefix | 27);
            out.extend(n.to_be_bytes());
        }
    }
}

fn bytes(out: &mut Vec<u8>, value: &[u8]) {
    head(out, 2, value.len() as u64);
    out.extend(value);
}

fn encode(out: &mut Vec<u8>, value: &Value) -> Result<()> {
    match value {
        Value::Null => {
            head(out, 4, 1);
            head(out, 0, 0);
        }
        Value::Bool(value) => {
            head(out, 4, 2);
            head(out, 0, 1);
            head(out, 0, u64::from(*value));
        }
        Value::Number(value) => {
            head(out, 4, 3);
            head(out, 0, 2);
            if let Some(n) = value.as_u64() {
                head(out, 0, 0);
                head(out, 0, n);
            } else if let Some(n) = value.as_i64() {
                head(out, 0, 1);
                head(out, 0, n.unsigned_abs());
            } else {
                return Err(Error::new(
                    "noncanonical-number",
                    "floating point is not admitted",
                ));
            }
        }
        Value::String(value) => {
            head(out, 4, 2);
            head(out, 0, 3);
            bytes(out, value.as_bytes());
        }
        Value::Array(values) => {
            head(out, 4, 2);
            head(out, 0, 4);
            head(out, 4, values.len() as u64);
            for value in values {
                encode(out, value)?;
            }
        }
        Value::Object(values) => {
            head(out, 4, 2);
            head(out, 0, 5);
            head(out, 4, values.len() as u64);
            let mut sorted: Vec<_> = values.iter().collect();
            sorted.sort_by(|(a, _), (b, _)| a.as_bytes().cmp(b.as_bytes()));
            for (key, value) in sorted {
                head(out, 4, 2);
                bytes(out, key.as_bytes());
                encode(out, value)?;
            }
        }
    }
    Ok(())
}

pub fn material(domain: &str, value: &impl serde::Serialize) -> Result<Vec<u8>> {
    let value =
        serde_json::to_value(value).map_err(|e| Error::new("projection-invalid", e.to_string()))?;
    let mut out = Vec::new();
    head(&mut out, 4, 3);
    bytes(&mut out, domain.as_bytes());
    head(&mut out, 0, 1);
    encode(&mut out, &value)?;
    Ok(out)
}

pub fn digest(domain: &str, value: &impl serde::Serialize) -> Result<String> {
    Ok(raw_digest(&material(domain, value)?))
}

pub fn raw_digest(bytes: &[u8]) -> String {
    format!("sha256:{}", hex::encode(Sha256::digest(bytes)))
}

pub fn check_digest(value: &str) -> Result<()> {
    let encoded = value.strip_prefix("sha256:").unwrap_or("");
    if encoded.len() != 64
        || !encoded
            .bytes()
            .all(|c| c.is_ascii_digit() || (b'a'..=b'f').contains(&c))
    {
        return Err(Error::new(
            "digest-invalid",
            "expected canonical lowercase SHA-256 identity",
        ));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn sha256_known_vectors_and_streaming_are_stable() {
        assert_eq!(
            raw_digest(b""),
            "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        );
        assert_eq!(
            raw_digest(b"abc"),
            "sha256:ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        );
        let bytes = vec![b'a'; 1_000_000];
        assert_eq!(
            raw_digest(&bytes),
            "sha256:cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0"
        );
        let mut streaming = Sha256::new();
        for chunk in bytes.chunks(65536) {
            streaming.update(chunk);
        }
        assert_eq!(
            format!("sha256:{}", hex::encode(streaming.finalize())),
            raw_digest(&bytes)
        );
    }

    #[test]
    fn canonical_order_and_domains_are_explicit() {
        assert_eq!(
            digest("x", &json!({"b": 1, "a": false})).unwrap(),
            digest("x", &json!({"a": false, "b": 1})).unwrap()
        );
        assert_ne!(
            digest("x", &json!({"a": false})).unwrap(),
            digest("y", &json!({"a": false})).unwrap()
        );
        assert_ne!(
            digest("x", &json!(false)).unwrap(),
            digest("x", &json!(null)).unwrap()
        );
        assert_ne!(
            digest("x", &json!(-1)).unwrap(),
            digest("x", &json!(1)).unwrap()
        );
    }

    #[test]
    fn duplicate_keys_floats_and_trailing_data_fail_closed() {
        for data in [
            br#"{"a":1,"a":2}"#.as_slice(),
            br#"{"nested":{"a":1,"a":2}}"#,
            b"1.0",
            b"{} {}",
        ] {
            assert!(parse::<Value>(data).is_err());
        }
    }
}
