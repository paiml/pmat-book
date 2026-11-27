//! Generate `src/appendix-b-commands.md` from the pmat binary's own `--help` output.
//!
//! WHY THIS EXISTS
//! ---------------
//! Appendix B used to be hand-written. By 2026-08-25 it listed 31 top-level commands
//! that `pmat` has never had (`pmat architecture`, `pmat rules`, `pmat clippy`,
//! `pmat status`, ...) -- 73 of the 150 command paths it printed did not resolve. A
//! command reference that is wrong is worse than no reference at all, because a reader
//! trusts it more than prose.
//!
//! A hand-written reference drifts silently every time the CLI changes. A generated one
//! cannot: it is read out of the binary, and every path it prints is re-checked by
//! running `pmat <path> --help` and requiring exit status 0 before it is written down.
//!
//! USAGE
//! -----
//!     cargo run -q --release --manifest-path tools/gen-appendix-b/Cargo.toml > src/appendix-b-commands.md
//!
//! Set PMAT=/path/to/pmat to point it at a specific binary (default: `pmat` on PATH).
//! Set APPENDIX_B_DATE=YYYY-MM-DD to pin the embedded date (used by the tests).
//!
//! The prose sections (preamble, the map of commands that never existed, the executed
//! examples, exit codes, environment variables) are the files in `text/`. Everything
//! that names a command path is generated and verified. When a hand-written claim
//! there goes stale, fix it there -- not in the generated Markdown, which is overwritten.

use std::env;
use std::path::Path;
use std::process::{self, Command};
use std::sync::mpsc;
use std::thread;
use std::time::Duration;

const PREAMBLE: &str = include_str!("../text/preamble.md");
const FICTION: &str = include_str!("../text/fiction.md");
const EXAMPLES: &str = include_str!("../text/examples.md");
const TAIL: &str = include_str!("../text/tail.md");

// ----------------------------------------------------------------- binary probing

/// Combined stdout+stderr and exit code for `pmat <path> --help` (124 on timeout).
fn help_text(pmat: &str, path: &[&str]) -> (String, i32) {
    let (pmat, args): (String, Vec<String>) = (
        pmat.to_string(),
        path.iter()
            .map(|s| s.to_string())
            .chain(["--help".to_string()])
            .collect(),
    );
    let (tx, rx) = mpsc::channel();
    thread::spawn(move || {
        let _ = tx.send(Command::new(&pmat).args(&args).output());
    });
    match rx.recv_timeout(Duration::from_secs(60)) {
        Ok(Ok(o)) => {
            let mut s = String::from_utf8_lossy(&o.stdout).into_owned();
            s.push_str(&String::from_utf8_lossy(&o.stderr));
            (s, o.status.code().unwrap_or(-1))
        }
        Ok(Err(_)) => (String::new(), 127),
        Err(_) => (String::new(), 124),
    }
}

type Entry = (String, Vec<String>, String);

/// Index of the first non-blank line at/after `i`, if it is still indented.
fn next_entry_line(lines: &[&str], i: usize) -> Option<usize> {
    let mut j = i;
    while j < lines.len() && lines[j].trim().is_empty() {
        j += 1;
    }
    if j >= lines.len() || !lines[j].starts_with("  ") {
        return None;
    }
    Some(j)
}

/// `[alias: a, b]` / `[aliases: a, b]` at the end of `desc` -> (start, aliases).
fn trailing_aliases(desc: &str) -> Option<(usize, Vec<String>)> {
    for (start, _) in desc.match_indices("[alias") {
        let rest = &desc[start + "[alias".len()..];
        let rest = rest.strip_prefix("es").unwrap_or(rest);
        let Some(body) = rest.strip_prefix(": ") else { continue };
        let Some(close) = body.find(']') else { continue };
        if close == 0 || !body[close + 1..].trim().is_empty() {
            continue;
        }
        let aliases = body[..close].split(',').map(|a| a.trim().to_string()).collect();
        return Some((start, aliases));
    }
    None
}

/// Match `^  (\S+)\s\s+(.*)$`, returning (name, description).
fn command_line(ln: &str) -> Option<(&str, &str)> {
    let rest = ln.strip_prefix("  ")?;
    let name_end = rest.find(char::is_whitespace).unwrap_or(rest.len());
    if name_end == 0 {
        return None;
    }
    let (name, tail) = rest.split_at(name_end);
    let mut ws = tail.chars().take_while(|c| c.is_whitespace());
    if ws.next().is_none() || ws.next().is_none() {
        return None;
    }
    Some((name, tail.trim_start_matches(char::is_whitespace)))
}

fn command_entry(name: &str, desc: &str) -> Entry {
    let mut desc = desc.trim().to_string();
    let mut aliases = Vec::new();
    if let Some((start, al)) = trailing_aliases(&desc) {
        aliases = al;
        desc = desc[..start].trim().to_string();
    }
    (name.to_string(), aliases, desc)
}

/// Fold one `Commands:` line into `out`; false when the block has ended.
fn absorb(out: &mut Vec<Entry>, ln: &str) -> bool {
    let m = command_line(ln);
    if let Some((name, desc)) = m {
        out.push(command_entry(name, desc));
    } else if ln.starts_with("     ") {
        if let Some(last) = out.last_mut() {
            last.2 = format!("{} {}", last.2, ln.trim()).trim().to_string();
        }
    }
    m.is_some() || ln.starts_with("  ")
}

/// [(name, aliases, description)] from a clap `Commands:` block.
fn parse_commands(text: &str) -> Vec<Entry> {
    let lines: Vec<&str> = text.lines().collect();
    let mut out = Vec::new();
    let Some(pos) = lines.iter().position(|l| *l == "Commands:") else {
        return out;
    };
    let mut i = Some(pos + 1);
    while let Some(k) = i {
        if k >= lines.len() {
            break;
        }
        i = if lines[k].trim().is_empty() {
            next_entry_line(&lines, k)
        } else if absorb(&mut out, lines[k]) {
            Some(k + 1)
        } else {
            None
        };
    }
    out
}

/// (placeholder or None, stop) for one line of an `Arguments:` block.
fn positional_of(ln: &str) -> (Option<&str>, bool) {
    let Some(rest) = ln.strip_prefix("  ") else {
        return (None, true);
    };
    let tok_end = rest.find(char::is_whitespace).unwrap_or(rest.len());
    let tok = &rest[..tok_end];
    let first = tok.chars().next();
    let last = tok.chars().last();
    let only_token = rest[tok_end..].trim().is_empty();
    if only_token
        && tok.chars().count() >= 3
        && matches!(first, Some('[' | '<'))
        && matches!(last, Some(']' | '>'))
    {
        return (Some(tok), false);
    }
    let stop = first.is_some() && !matches!(first, Some('[' | '<'));
    (None, stop)
}

/// Positional placeholders, e.g. `[PATH]`, `<QUERY>`.
fn parse_positionals(text: &str) -> Vec<String> {
    let lines: Vec<&str> = text.lines().collect();
    let mut out = Vec::new();
    let Some(pos) = lines.iter().position(|l| *l == "Arguments:") else {
        return out;
    };
    for ln in &lines[pos + 1..] {
        if ln.trim().is_empty() {
            continue;
        }
        let (found, stop) = positional_of(ln);
        if let Some(f) = found {
            out.push(f.to_string());
        }
        if stop {
            break;
        }
    }
    out
}

/// The long flag DEFINED on this line of an Options block, if any.
fn long_flag(ln: &str) -> Option<&str> {
    let body = ln.trim_start_matches(' ');
    let indent = ln.len() - body.len();
    if !(2..=6).contains(&indent) {
        return None;
    }
    let b = body.as_bytes();
    let body = if b.len() >= 4 && b[0] == b'-' && b[1].is_ascii_alphabetic() && &body[2..4] == ", " {
        &body[4..]
    } else {
        body
    };
    let name = body.strip_prefix("--")?;
    if !name.starts_with(|c: char| c.is_ascii_lowercase()) {
        return None;
    }
    let n = name
        .find(|c: char| !(c.is_ascii_lowercase() || c.is_ascii_digit() || c == '-'))
        .unwrap_or(name.len());
    let after = &name[n..];
    let tail_ok = match after.strip_prefix(' ') {
        Some(v) if v.starts_with(['<', '[']) => {
            let inner = &v[1..];
            let k = inner
                .find(|c: char| !(c.is_ascii_uppercase() || c == '_'))
                .unwrap_or(inner.len());
            k > 0 && inner[k..].starts_with([']', '>']) && inner[k + 1..].trim().is_empty()
        }
        _ => false,
    };
    if after.trim().is_empty() || tail_ok {
        Some(&body[..2 + n])
    } else {
        None
    }
}

/// Long flags DEFINED in the Options block -- not ones merely named in prose.
fn parse_long_flags(text: &str) -> Vec<String> {
    let mut flags: Vec<String> = text.lines().filter_map(long_flag).map(String::from).collect();
    flags.sort();
    flags.dedup();
    flags
}

struct Node {
    name: String,
    aliases: Vec<String>,
    desc: String,
    args: Vec<String>,
    flags: Vec<String>,
    subs: Vec<Node>,
}

fn fail(msg: String) -> ! {
    eprintln!("{msg}");
    process::exit(1);
}

/// `pmat <path> --help` text; exit the whole run if it does not resolve.
fn probe(pmat: &str, path: &[&str]) -> String {
    let (text, rc) = help_text(pmat, path);
    if rc != 0 {
        fail(format!("FAIL: `{pmat} {} --help` exited {rc}", path.join(" ")));
    }
    text
}

fn node(e: &Entry, text: &str) -> Node {
    Node {
        name: e.0.clone(),
        aliases: e.1.clone(),
        desc: e.2.clone(),
        args: parse_positionals(text),
        flags: parse_long_flags(text),
        subs: Vec::new(),
    }
}

fn command_node(pmat: &str, e: &Entry) -> Node {
    let text = probe(pmat, &[&e.0]);
    let subs = parse_commands(&text)
        .iter()
        .filter(|s| s.0 != "help")
        .map(|s| node(s, &probe(pmat, &[&e.0, &s.0])))
        .collect();
    let mut n = node(e, &text);
    n.subs = subs;
    n
}

fn build_tree(pmat: &str) -> (String, Vec<Node>) {
    let top = probe(pmat, &[]);
    let v = Command::new(pmat)
        .arg("--version")
        .output()
        .unwrap_or_else(|e| fail(format!("FAIL: `{pmat} --version`: {e}")));
    let stdout = String::from_utf8_lossy(&v.stdout).into_owned();
    let version = stdout
        .lines()
        .next()
        .unwrap_or_else(|| fail(format!("FAIL: `{pmat} --version` printed nothing")))
        .trim()
        .to_string();
    let tree = parse_commands(&top)
        .iter()
        .filter(|c| c.0 != "help")
        .map(|c| command_node(pmat, c))
        .collect();
    (version, tree)
}

// ----------------------------------------------------------------------- rendering

fn is_word(c: char) -> bool {
    c.is_alphanumeric() || c == '_'
}

/// Backtick a bare word `pmat` (not already quoted, not part of a longer word).
fn backtick_pmat(s: &str) -> String {
    let chars: Vec<char> = s.chars().collect();
    let pat = ['p', 'm', 'a', 't'];
    let mut out = String::new();
    let mut i = 0;
    while i < chars.len() {
        let hit = chars[i..].starts_with(&pat)
            && (i == 0 || !(chars[i - 1] == '`' || is_word(chars[i - 1])))
            && chars.get(i + 4).map_or(true, |&c| !(c == '`' || is_word(c)));
        if hit {
            out.push_str("`pmat`");
            i += 4;
        } else {
            out.push(chars[i]);
            i += 1;
        }
    }
    out
}

/// One table cell: whitespace-collapsed, pipe-escaped, `pmat` quoted, truncated.
fn cell(s: &str, limit: usize) -> String {
    let joined = s.split_whitespace().collect::<Vec<_>>().join(" ").replace('|', "\\|");
    // `scripts/verify-documented-commands.sh` reads `pmat <word>` as a command path
    // wherever the word is preceded by whitespace; backticking keeps prose out of it.
    let s = backtick_pmat(&joined);
    let chars: Vec<char> = s.chars().collect();
    if chars.len() > limit {
        let head: String = chars[..limit].iter().collect();
        let cut = head.rsplit_once(' ').map_or(head.as_str(), |(a, _)| a);
        return format!("{cut} …");
    }
    s
}

fn is_path_name(a: &str) -> bool {
    matches!(
        a.trim_matches(['[', ']', '<', '>']),
        "PATH" | "FILE" | "PROJECT_PATH"
    )
}

fn path_arg(n: &Node) -> String {
    if let Some(a) = n.args.iter().find(|a| is_path_name(a)) {
        return format!("`{a}` (positional)");
    }
    for f in ["--path", "--project-path"] {
        if n.flags.iter().any(|x| x == f) {
            return format!("`{f}`");
        }
    }
    "—".to_string()
}

fn unavailable(desc: &str) -> bool {
    desc.starts_with("[NOT AVAILABLE") || desc.starts_with("[REMOVED")
}

fn anchor(name: &str) -> String {
    format!("pmat-{name}")
}

fn mark(desc: &str) -> &'static str {
    if unavailable(desc) {
        "⚠ "
    } else {
        ""
    }
}

fn code_list(items: &[String], sep: &str) -> String {
    if items.is_empty() {
        return "—".to_string();
    }
    items.iter().map(|a| format!("`{a}`")).collect::<Vec<_>>().join(sep)
}

fn fill(tpl: &str, version: &str, date: &str, n_top: usize, n_sub: usize) -> String {
    tpl.replace("{version}", version)
        .replace("{date}", date)
        .replace("{n_top}", &n_top.to_string())
        .replace("{n_sub}", &n_sub.to_string())
}

fn top_level_table(tree: &[Node]) -> Vec<String> {
    let mut o = vec![
        "## Top-level commands\n".to_string(),
        "| Command | Aliases | Subcommands | What it does |".to_string(),
        "|---------|---------|-------------|--------------|".to_string(),
    ];
    for c in tree {
        let n = if c.subs.is_empty() {
            "—".to_string()
        } else {
            format!("[{}](#{})", c.subs.len(), anchor(&c.name))
        };
        o.push(format!(
            "| `pmat {}` | {} | {} | {}{} |",
            c.name,
            code_list(&c.aliases, ", "),
            n,
            mark(&c.desc),
            cell(&c.desc, 170)
        ));
    }
    o.push(String::new());
    o
}

fn no_subcommand_table(tree: &[Node]) -> Vec<String> {
    let mut o = vec![
        "## Commands that take no subcommand\n".to_string(),
        "These run directly. The Path column is the form this command accepts a \
         target path in — using the wrong one exits 2.\n"
            .to_string(),
        "| Command | Path | Other positional arguments |".to_string(),
        "|---------|------|----------------------------|".to_string(),
    ];
    for c in tree.iter().filter(|c| c.subs.is_empty()) {
        let others: Vec<String> = c.args.iter().filter(|a| !is_path_name(a)).cloned().collect();
        o.push(format!(
            "| `pmat {}` | {} | {} |",
            c.name,
            path_arg(c),
            code_list(&others, " ")
        ));
    }
    o.push(String::new());
    o.push(
        "A `—` in the Path column means the command takes no path at all, or takes its\n\
         target some other way. Two that catch people out: `pmat extract` takes its file\n\
         as the *value* of `--list` (`pmat extract --list src/main.rs`), and `pmat generate`\n\
         takes a template category and name (`pmat generate makefile rust/cli -p project_name=demo`).\n"
            .to_string(),
    );
    o
}

fn by_parent(tree: &[Node]) -> Vec<String> {
    let mut o = vec!["## Subcommands by parent\n".to_string()];
    for c in tree.iter().filter(|c| !c.subs.is_empty()) {
        o.push(format!("<a id=\"{}\"></a>\n", anchor(&c.name)));
        let al = if c.aliases.is_empty() {
            String::new()
        } else {
            format!(" (aliases: {})", code_list(&c.aliases, " "))
        };
        o.push(format!("### `pmat {}`{al}\n", c.name));
        o.push(format!("{}\n", cell(&c.desc, 400)));
        o.push("| Subcommand | Aliases | Path | What it does |".to_string());
        o.push("|------------|---------|------|--------------|".to_string());
        for s in &c.subs {
            o.push(format!(
                "| `pmat {} {}` | {} | {} | {}{} |",
                c.name,
                s.name,
                code_list(&s.aliases, ", "),
                path_arg(s),
                mark(&s.desc),
                cell(&s.desc, 170)
            ));
        }
        o.push(String::new());
    }
    o
}

/// Civil date (UTC) as YYYY-MM-DD from days since the Unix epoch.
fn civil(days: i64) -> String {
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097);
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = yoe + era * 400 + i64::from(m <= 2);
    format!("{y:04}-{m:02}-{d:02}")
}

/// Today's local date: `APPENDIX_B_DATE` override, else `date +%F`, else UTC.
fn today() -> String {
    if let Ok(d) = env::var("APPENDIX_B_DATE") {
        return d;
    }
    if let Ok(o) = Command::new("date").arg("+%F").output() {
        let s = String::from_utf8_lossy(&o.stdout).trim().to_string();
        if o.status.success() && s.len() == 10 {
            return s;
        }
    }
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |d| d.as_secs());
    civil((secs / 86_400) as i64)
}

/// Mirror of Python's `shutil.which`.
fn on_path(pmat: &str) -> bool {
    use std::os::unix::fs::PermissionsExt;
    let ok = |p: &Path| p.is_file() && p.metadata().is_ok_and(|m| m.permissions().mode() & 0o111 != 0);
    if pmat.contains('/') {
        return ok(Path::new(pmat));
    }
    env::var_os("PATH").is_some_and(|p| env::split_paths(&p).any(|d| ok(&d.join(pmat))))
}

fn main() {
    let pmat = env::var("PMAT").unwrap_or_else(|_| "pmat".to_string());
    if !on_path(&pmat) {
        fail(format!("FAIL: '{pmat}' is not on PATH. Set PMAT=/path/to/pmat."));
    }
    let (version, tree) = build_tree(&pmat);
    let date = today();
    let n_top = tree.len();
    let n_sub: usize = tree.iter().map(|c| c.subs.len()).sum();

    let mut o = vec![fill(PREAMBLE, &version, &date, n_top, n_sub)];
    o.extend(top_level_table(&tree));
    o.extend(no_subcommand_table(&tree));
    o.extend(by_parent(&tree));
    o.push(fill(EXAMPLES, &version, &date, n_top, n_sub));
    o.push(fill(FICTION, &version, &date, n_top, n_sub));
    o.push(fill(TAIL, &version, &date, n_top, n_sub));

    print!("{}\n", o.join("\n").trim_end());
}
