//! Integration tests: run the built binary against a fake `pmat` shell script
//! that prints canned `--help` trees, so nothing depends on the real binary.

use std::path::PathBuf;
use std::process::{Command, Output};

fn fake() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/fake-pmat.sh")
}

fn run(pmat: &str, extra_env: &[(&str, &str)]) -> Output {
    let mut c = Command::new(env!("CARGO_BIN_EXE_gen-appendix-b"));
    c.env("PMAT", pmat).env("APPENDIX_B_DATE", "2000-01-02");
    for (k, v) in extra_env {
        c.env(k, v);
    }
    c.output().expect("spawn generator")
}

#[test]
fn output_matches_golden_file_byte_for_byte() {
    let out = run(fake().to_str().unwrap(), &[]);
    assert!(out.status.success(), "stderr: {}", String::from_utf8_lossy(&out.stderr));
    let golden = std::fs::read_to_string(
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("tests/fixtures/expected.md"),
    )
    .unwrap();
    assert_eq!(String::from_utf8(out.stdout).unwrap(), golden);
}

#[test]
fn counts_commands_and_subcommands() {
    let out = run(fake().to_str().unwrap(), &[]);
    let s = String::from_utf8(out.stdout).unwrap();
    assert!(s.contains("`pmat 9.9.9` exposes **6 top-level commands** and **5 subcommands**."), "{s}");
}

#[test]
fn usage_line_names_the_rust_tool() {
    let out = run(fake().to_str().unwrap(), &[]);
    let s = String::from_utf8(out.stdout).unwrap();
    assert!(s.contains("tools/gen-appendix-b/Cargo.toml"));
    assert!(!s.contains(".py"));
}

#[test]
fn unresolvable_path_fails_the_run() {
    let out = run(fake().to_str().unwrap(), &[("FAKE_PMAT_BREAK", "analyze satd")]);
    assert!(!out.status.success());
    let err = String::from_utf8_lossy(&out.stderr);
    assert!(err.contains("FAIL:") && err.contains("analyze satd --help") && err.contains("exited 2"), "{err}");
    assert!(out.stdout.is_empty());
}

#[test]
fn missing_binary_fails_with_hint() {
    let out = run("/nonexistent/pmat-xyz", &[]);
    assert!(!out.status.success());
    let err = String::from_utf8_lossy(&out.stderr);
    assert!(err.contains("is not on PATH. Set PMAT=/path/to/pmat."), "{err}");
}
