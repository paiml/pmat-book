# Chapter 50: Markdown Best Practices (CB-900 to CB-904)

The CB-900 series detects Markdown defect patterns that apply to **any** project containing Markdown documentation. These checks enforce documentation quality, accessibility compliance, and consistent formatting. Poorly structured Markdown degrades the developer experience: broken links erode trust in documentation, missing alt text excludes screen reader users, and inconsistent heading hierarchies confuse both readers and automated tooling (table-of-contents generators, search indexers, accessibility auditors).

## Overview

```bash
# Run all compliance checks including CB-900 series
pmat comply check

# Example output:
# ⚠ CB-900: Markdown Best Practices (CB-900 to CB-904): [Advisory] 0 errors, 7 warnings, 3 info:
# CB-900: Heading hierarchy violation — jumped from h1 to h3, missing h2 (README.md:15)
# CB-901: Broken link — file `docs/setup.md` does not exist (CONTRIBUTING.md:42)
# CB-902: Missing alt text on image — accessibility violation (docs/architecture.md:8)
# CB-903: Trailing whitespace (docs/api.md:23)
# CB-904: Long line (134 chars, limit 120) (CHANGELOG.md:67)
```

The CB-900 series is **advisory** — it reports with `Warn` status but does not block CI or commits. Violations are categorized into three severity tiers:

| Severity | Meaning | Example |
|----------|---------|---------|
| Error | Broken documentation | Broken link to nonexistent file |
| Warning | Structural or accessibility defect | Skipped heading level, missing alt text |
| Info | Formatting hygiene | Trailing whitespace, long lines |

## Defect Taxonomy

### Structure (CB-900, CB-904)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-900 | Heading Hierarchy Violation | Warning | Skipped heading levels (e.g., `#` followed by `###` without `##`) |
| CB-904 | Long Line | Info | Lines exceeding 120 characters (excluding code blocks, tables, URLs) |

### Links & Media (CB-901, CB-902)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-901 | Broken Link | Error | `[text](path)` where the referenced file does not exist on disk |
| CB-902 | Missing Alt Text | Warning | `![](url)` images without alt text — accessibility violation |

### Formatting (CB-903)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-903 | Trailing Whitespace | Info | Lines ending with trailing spaces or tabs |

## Detection Algorithms

### CB-900: Heading Hierarchy Violation

Detects skipped heading levels in the document structure. Markdown heading levels should increment by one — jumping from `#` (h1) directly to `###` (h3) breaks the semantic outline and confuses screen readers, table-of-contents generators, and search indexers:

```markdown
<!-- ❌ Skipped heading level (CB-900 Warning): -->
# Project Overview

### Installation
<!-- Jumped from h1 to h3, missing h2 -->

#### Prerequisites
<!-- This is fine — h3 to h4 is sequential -->

# API Reference

#### Endpoints
<!-- Jumped from h1 to h4, missing h2 and h3 -->

<!-- ✅ Correct heading hierarchy: -->
# Project Overview

## Getting Started

### Installation

### Prerequisites

# API Reference

## Endpoints
```

The detector tracks the most recently seen heading level. When a new heading is encountered, it checks that the level difference from the previous heading is at most +1. Decreasing levels (e.g., `###` back to `#`) are always permitted — they represent closing a section.

### CB-901: Broken Link

Detects `[text](path)` link references where the target file does not exist on disk. External URLs (starting with `http://` or `https://`) and anchor links (starting with `#`) are excluded from this check:

```markdown
<!-- ❌ Broken links (CB-901 Error): -->
See the [setup guide](docs/setup.md) for details.
Read the [API docs](api/reference.md) before contributing.

<!-- Both files do not exist on disk -->

<!-- ✅ Valid links: -->
See the [setup guide](docs/getting-started.md) for details.
Read the [API docs](docs/api-reference.md) before contributing.

<!-- External URLs are not checked by CB-901: -->
Visit [Rust documentation](https://doc.rust-lang.org/) for more.

<!-- Anchor links are not checked by CB-901: -->
See [Installation](#installation) below.
```

The detector resolves relative paths from the directory containing the Markdown file. A link `[text](docs/setup.md)` in `README.md` at the project root checks for existence of `docs/setup.md` relative to the project root.

### CB-902: Missing Alt Text

Detects images with empty alt text, which is an accessibility violation. Screen readers rely on alt text to describe images to visually impaired users. The Web Content Accessibility Guidelines (WCAG 2.1, Success Criterion 1.1.1) require non-text content to have a text alternative:

```markdown
<!-- ❌ Missing alt text (CB-902 Warning): -->
![](assets/architecture.png)
![](https://example.com/logo.svg)
![  ](diagrams/flow.png)

<!-- ✅ Descriptive alt text: -->
![System architecture showing three-tier design](assets/architecture.png)
![Company logo](https://example.com/logo.svg)
![Data flow diagram from ingestion to output](diagrams/flow.png)
```

The detector matches the pattern `![](` and `![ ](` (empty or whitespace-only alt text). Images with any non-whitespace alt text pass the check.

### CB-903: Trailing Whitespace

Detects lines ending with trailing spaces or tabs. Trailing whitespace causes noisy diffs, inconsistent rendering, and in some Markdown parsers, unintended line breaks (two trailing spaces create a `<br>`):

```markdown
<!-- ❌ Trailing whitespace (CB-903 Info): -->
This line has trailing spaces.
This line has a trailing tab.

<!-- ✅ Clean lines: -->
This line has no trailing whitespace.
This line is also clean.
```

The detector checks every line for trailing whitespace characters (spaces and tabs). Intentional hard line breaks should use `<br>` instead of trailing spaces for explicit intent.

### CB-904: Long Line

Detects lines exceeding 120 characters. Long lines reduce readability, cause horizontal scrolling in code review tools, and make diffs harder to review. The following line types are excluded from the check:

- **Code blocks**: Lines inside fenced code blocks (`` ``` ``) are excluded — code formatting has its own conventions
- **Tables**: Lines starting with `|` are excluded — table rows often require width for column alignment
- **URLs**: Lines containing `http://` or `https://` are excluded — URLs cannot be meaningfully wrapped

```markdown
<!-- ❌ Long line (CB-904 Info): -->
This is an extremely long paragraph line that exceeds the 120-character limit and should be wrapped to improve readability in editors and diff tools.

<!-- ✅ Wrapped to 120 characters: -->
This is a paragraph line that has been wrapped to stay within
the 120-character limit for improved readability.

<!-- Excluded from CB-904 (not flagged): -->
```rust
let very_long_variable_name = some_function_with_a_long_name(parameter_one, parameter_two, parameter_three, parameter_four);
```

| Column A | Column B | Column C | Column D | Column E | Column F | Column G | Column H | Column I | Column J |
|----------|----------|----------|----------|----------|----------|----------|----------|----------|----------|

See https://very-long-domain.example.com/path/to/some/deeply/nested/resource/that/exceeds/the/line/limit
```

The detector maintains a boolean flag to track whether the current line is inside a fenced code block. Lines inside code blocks are skipped entirely. For non-code-block lines, the detector checks the character count after excluding table and URL lines.

## Testing

The CB-900 checks are validated with synthetic Markdown fixtures that exercise each detection pattern:

```rust
#[test]
fn test_cb900_heading_hierarchy() {
    let md = "# Title\n### Skipped\n";
    let findings = check_markdown_best_practices(md, Path::new("test.md"));
    assert!(findings.iter().any(|f| f.code == "CB-900"));
}

#[test]
fn test_cb900_heading_decrease_allowed() {
    let md = "# Title\n## Section\n### Sub\n# New Top\n";
    let findings = check_markdown_best_practices(md, Path::new("test.md"));
    assert!(!findings.iter().any(|f| f.code == "CB-900"));
}

#[test]
fn test_cb901_broken_link() {
    let md = "[guide](nonexistent-file.md)\n";
    let findings = check_markdown_best_practices(md, Path::new("test.md"));
    assert!(findings.iter().any(|f| f.code == "CB-901"));
}

#[test]
fn test_cb901_external_url_skipped() {
    let md = "[docs](https://example.com)\n";
    let findings = check_markdown_best_practices(md, Path::new("test.md"));
    assert!(!findings.iter().any(|f| f.code == "CB-901"));
}

#[test]
fn test_cb902_missing_alt_text() {
    let md = "![](image.png)\n";
    let findings = check_markdown_best_practices(md, Path::new("test.md"));
    assert!(findings.iter().any(|f| f.code == "CB-902"));
}

#[test]
fn test_cb902_alt_text_present() {
    let md = "![Architecture diagram](image.png)\n";
    let findings = check_markdown_best_practices(md, Path::new("test.md"));
    assert!(!findings.iter().any(|f| f.code == "CB-902"));
}

#[test]
fn test_cb903_trailing_whitespace() {
    let md = "Hello world   \n";
    let findings = check_markdown_best_practices(md, Path::new("test.md"));
    assert!(findings.iter().any(|f| f.code == "CB-903"));
}

#[test]
fn test_cb904_long_line() {
    let md = &format!("{}\n", "x".repeat(121));
    let findings = check_markdown_best_practices(md, Path::new("test.md"));
    assert!(findings.iter().any(|f| f.code == "CB-904"));
}

#[test]
fn test_cb904_code_block_excluded() {
    let md = "```\nxxxxxxxxx... (200 chars)\n```\n";
    let findings = check_markdown_best_practices(md, Path::new("test.md"));
    assert!(!findings.iter().any(|f| f.code == "CB-904"));
}

#[test]
fn test_cb904_table_excluded() {
    let md = "| col1 | col2 | col3 | col4 | col5 | col6 | col7 | col8 | col9 | col10 | col11 | col12 |\n";
    let findings = check_markdown_best_practices(md, Path::new("test.md"));
    assert!(!findings.iter().any(|f| f.code == "CB-904"));
}
```

## Remediation Priority

When `pmat comply check` reports CB-900 violations, fix them in this priority order:

1. **CB-901** (broken links) — readers clicking dead links lose trust in documentation
2. **CB-902** (missing alt text) — accessibility violation, excludes screen reader users
3. **CB-900** (heading hierarchy) — breaks document outline and navigation tooling
4. **CB-904** (long lines) — reduces readability in code review and diff tools
5. **CB-903** (trailing whitespace) — cosmetic, fix at leisure or via editor auto-trim

## CI/CD Integration

```yaml
# .github/workflows/markdown-best-practices.yml
name: Markdown Best Practices
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install PMAT
        run: cargo install pmat
      - name: Check Markdown Best Practices
        run: |
          OUTPUT=$(pmat comply check 2>&1)
          echo "$OUTPUT"
          # Fail on Error-severity violations (broken links)
          if echo "$OUTPUT" | grep -q "CB-900.*errors: [1-9]"; then
            echo "::error::CB-900 series has Error-severity violations"
            exit 1
          fi
```

## Specification Reference

Full detection logic: `src/cli/handlers/comply_cb_detect/markdown_best_practices.rs`
Aggregate check: `src/cli/handlers/comply_handlers/check_handlers.rs` (`check_markdown_best_practices`)
