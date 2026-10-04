// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
//! Inert Scheme datum ABI projection. No evaluator or extensible reader.
use std::collections::BTreeMap;
use std::ops::{Index, IndexMut};
#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Null,
    Bool(bool),
    Integer(i128),
    Float(f64),
    String(String),
    Array(Vec<Value>),
    Object(BTreeMap<String, Value>),
}
impl Value {
    pub fn as_str(&self) -> Option<&str> {
        if let Self::String(v) = self {
            Some(v)
        } else {
            None
        }
    }
    pub fn as_array(&self) -> Option<&Vec<Self>> {
        if let Self::Array(v) = self {
            Some(v)
        } else {
            None
        }
    }
    pub fn as_object(&self) -> Option<&BTreeMap<String, Self>> {
        if let Self::Object(v) = self {
            Some(v)
        } else {
            None
        }
    }
    pub fn as_object_mut(&mut self) -> Option<&mut BTreeMap<String, Self>> {
        if let Self::Object(v) = self {
            Some(v)
        } else {
            None
        }
    }
}
impl Index<&str> for Value {
    type Output = Self;
    fn index(&self, k: &str) -> &Self {
        self.as_object()
            .and_then(|v| v.get(k))
            .unwrap_or(&Self::Null)
    }
}
impl IndexMut<&str> for Value {
    fn index_mut(&mut self, k: &str) -> &mut Self {
        self.as_object_mut()
            .expect("object")
            .entry(k.into())
            .or_insert(Self::Null)
    }
}
impl From<&Value> for Value {
    fn from(v: &Value) -> Self {
        v.clone()
    }
}
impl From<String> for Value {
    fn from(v: String) -> Self {
        Self::String(v)
    }
}
impl From<&String> for Value {
    fn from(v: &String) -> Self {
        Self::String(v.clone())
    }
}
impl From<&str> for Value {
    fn from(v: &str) -> Self {
        Self::String(v.into())
    }
}
impl From<bool> for Value {
    fn from(v: bool) -> Self {
        Self::Bool(v)
    }
}
impl From<Vec<Value>> for Value {
    fn from(v: Vec<Value>) -> Self {
        Self::Array(v)
    }
}
macro_rules! integers {($($t:ty),*)=>{$(impl From<$t> for Value {fn from(v:$t)->Self{Self::Integer(v as i128)}} impl From<&$t> for Value {fn from(v:&$t)->Self{Self::Integer(*v as i128)}})*}}
integers!(i32, i64, u32, u64, usize);
macro_rules! compare {($($t:ty),*)=>{$(impl PartialEq<$t> for Value {fn eq(&self,v:&$t)->bool {self==&Value::from(v.clone())}})*}}
compare!(&str, String, bool, i32);
impl std::fmt::Display for Value {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match to_vec(self) {
            Ok(v) => write!(f, "{}", String::from_utf8_lossy(&v)),
            Err(_) => Err(std::fmt::Error),
        }
    }
}
#[derive(Debug)]
pub struct WireError;
impl std::fmt::Display for WireError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("invalid or unbounded Scheme datum")
    }
}
impl std::error::Error for WireError {}
pub fn to_vec(v: &Value) -> Result<Vec<u8>, WireError> {
    fn emit(v: &Value, out: &mut String, depth: usize) -> Result<(), WireError> {
        if depth > 64 || out.len() > 16_777_216 {
            return Err(WireError);
        }
        match v {
            Value::Null => out.push_str("null"),
            Value::Bool(v) => out.push_str(if *v { "#t" } else { "#f" }),
            Value::Integer(v) => out.push_str(&v.to_string()),
            Value::Float(v) => {
                if !v.is_finite() {
                    return Err(WireError);
                }
                out.push_str(&format!("{v:?}"));
            }
            Value::String(v) => {
                out.push('"');
                for c in v.chars() {
                    match c {
                        '"' => out.push_str("\\\""),
                        '\\' => out.push_str("\\\\"),
                        '\n' => out.push_str("\\n"),
                        '\r' => out.push_str("\\r"),
                        '\t' => out.push_str("\\t"),
                        c if c < ' ' => return Err(WireError),
                        c => out.push(c),
                    }
                }
                out.push('"');
            }
            Value::Array(v) => {
                out.push_str("(list");
                for item in v {
                    out.push(' ');
                    emit(item, out, depth + 1)?;
                }
                out.push(')');
            }
            Value::Object(v) => {
                out.push_str("(object");
                for (key, value) in v {
                    out.push_str(" (");
                    emit(&Value::String(key.clone()), out, depth + 1)?;
                    out.push(' ');
                    emit(value, out, depth + 1)?;
                    out.push(')');
                }
                out.push(')');
            }
        }
        if out.len() > 16_777_216 {
            Err(WireError)
        } else {
            Ok(())
        }
    }
    let mut out = String::new();
    emit(v, &mut out, 0)?;
    Ok(out.into_bytes())
}
fn decimal_atom(a: &str) -> bool {
    if a.is_empty() || a.len() > 64 {
        return false;
    }
    let b = a.as_bytes();
    let mut i = usize::from(b[0] == b'-');
    if i >= b.len() || !b[i].is_ascii_digit() {
        return false;
    }
    if b[i] == b'0' {
        i += 1;
    } else {
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
    }
    if i < b.len() && b[i] == b'.' {
        i += 1;
        let start = i;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        if i == start {
            return false;
        }
    }
    if i < b.len() && matches!(b[i], b'e' | b'E') {
        i += 1;
        if i < b.len() && matches!(b[i], b'+' | b'-') {
            i += 1;
        }
        let start = i;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        if i == start {
            return false;
        }
    }
    i == b.len()
}
pub fn from_slice(bytes: &[u8]) -> Result<Value, WireError> {
    if bytes.len() > 16_777_216 || std::str::from_utf8(bytes).is_err() {
        return Err(WireError);
    }
    struct Reader<'a> {
        b: &'a [u8],
        i: usize,
        nodes: usize,
    }
    impl Reader<'_> {
        fn space(&mut self) {
            while self.i < self.b.len() && b" \t\r\n".contains(&self.b[self.i]) {
                self.i += 1;
            }
        }
        fn take(&mut self, b: u8) -> Result<(), WireError> {
            self.space();
            if self.b.get(self.i) != Some(&b) {
                return Err(WireError);
            }
            self.i += 1;
            Ok(())
        }
        fn atom(&mut self) -> Result<&str, WireError> {
            let start = self.i;
            while self.i < self.b.len() && !b" ()\n\r\t".contains(&self.b[self.i]) {
                self.i += 1;
            }
            std::str::from_utf8(&self.b[start..self.i]).map_err(|_| WireError)
        }
        fn value(&mut self, d: usize) -> Result<Value, WireError> {
            self.nodes += 1;
            if d > 64 || self.nodes > 262144 {
                return Err(WireError);
            }
            self.space();
            match self.b.get(self.i).ok_or(WireError)? {
                b'"' => {
                    self.i += 1;
                    let mut s = Vec::new();
                    loop {
                        let c = *self.b.get(self.i).ok_or(WireError)?;
                        self.i += 1;
                        match c {
                            b'"' => {
                                return Ok(Value::String(
                                    String::from_utf8(s).map_err(|_| WireError)?,
                                ));
                            }
                            b'\\' => {
                                let c = *self.b.get(self.i).ok_or(WireError)?;
                                self.i += 1;
                                s.push(match c {
                                    b'n' => b'\n',
                                    b'r' => b'\r',
                                    b't' => b'\t',
                                    b'"' => b'"',
                                    b'\\' => b'\\',
                                    _ => return Err(WireError),
                                });
                            }
                            0..=31 => return Err(WireError),
                            _ => s.push(c),
                        }
                    }
                }
                b'(' => {
                    self.i += 1;
                    let object = match self.atom()? {
                        "object" => true,
                        "list" => false,
                        _ => return Err(WireError),
                    };
                    let mut map = BTreeMap::new();
                    let mut items = Vec::new();
                    loop {
                        self.space();
                        if self.b.get(self.i) == Some(&b')') {
                            self.i += 1;
                            break;
                        }
                        if object {
                            self.take(b'(')?;
                            let Value::String(key) = self.value(d + 1)? else {
                                return Err(WireError);
                            };
                            let value = self.value(d + 1)?;
                            self.take(b')')?;
                            if map.insert(key, value).is_some() {
                                return Err(WireError);
                            }
                        } else {
                            items.push(self.value(d + 1)?);
                        }
                    }
                    Ok(if object {
                        Value::Object(map)
                    } else {
                        Value::Array(items)
                    })
                }
                _ => {
                    let a = self.atom()?;
                    match a {
                        "#t" => Ok(Value::Bool(true)),
                        "#f" => Ok(Value::Bool(false)),
                        "null" => Ok(Value::Null),
                        _ => {
                            if !decimal_atom(a) {
                                return Err(WireError);
                            }
                            if a.contains(['.', 'e', 'E']) {
                                let v = a.parse::<f64>().map_err(|_| WireError)?;
                                if !v.is_finite() {
                                    return Err(WireError);
                                }
                                Ok(Value::Float(v))
                            } else {
                                Ok(Value::Integer(a.parse().map_err(|_| WireError)?))
                            }
                        }
                    }
                }
            }
        }
    }
    let mut r = Reader {
        b: bytes,
        i: 0,
        nodes: 0,
    };
    let value = r.value(0)?;
    r.space();
    if r.i != bytes.len() {
        return Err(WireError);
    }
    Ok(value)
}
#[macro_export]
macro_rules! datum {
 (@object $map:ident;) => {};
 (@object $map:ident; $key:literal : {$($v:tt)*} $(, $($rest:tt)*)?) => {{$map.insert($key.into(),$crate::datum!({$($v)*}));$crate::datum!(@object $map; $($($rest)*)?);}};
 (@object $map:ident; $key:literal : [$($v:tt)*] $(, $($rest:tt)*)?) => {{$map.insert($key.into(),$crate::datum!([$($v)*]));$crate::datum!(@object $map; $($($rest)*)?);}};
 (@object $map:ident; $key:literal : $v:expr $(, $($rest:tt)*)?) => {{$map.insert($key.into(),$crate::wire::Value::from($v));$crate::datum!(@object $map; $($($rest)*)?);}};
 ({}) => {$crate::wire::Value::Object(::std::collections::BTreeMap::new())};
 ({$($v:tt)*}) => {{let mut fields=::std::collections::BTreeMap::new();$crate::datum!(@object fields;$($v)*);$crate::wire::Value::Object(fields)}};
 ([$($v:tt),* $(,)?]) => {$crate::wire::Value::Array(vec![$($crate::datum!($v)),*])};
 ($v:expr) => {$crate::wire::Value::from($v)};
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn inert_bounded_roundtrip() {
        let v = crate::datum!({"empty":[],"unicode":"时态\n\"\\","flag":false,"integer":-3});
        assert_eq!(from_slice(&to_vec(&v).unwrap()).unwrap(), v);
        for bytes in [
            b"{}".as_slice(),
            b"#.(exit)",
            b"(object (\"a\" 1) (\"a\" 2))",
            b"(list) (list)",
            b"#0=(list #0#)",
            b"(list +inf.0)",
        ] {
            assert!(from_slice(bytes).is_err());
        }
    }
}
