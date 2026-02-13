# Chapter 52: MLOps Model Quality (CB-1000 to CB-1008)

The CB-1000 series detects quality and metadata defects in ML model binary files. These checks perform **header-only analysis** — they never load tensor data, making them safe to run on multi-gigabyte model files in CI pipelines. The checks are motivated by real production bugs: corrupt GGUF headers with impossible tensor counts (BUG-GGUF-001), sharded SafeTensors deployments missing their index file (BUG-212), and APR files shipped without CRC integrity checksums. The series is grounded in Sculley et al. (2015) on ML technical debt and the empirical observation that model binary metadata is the most common source of silent deployment failures.

## Overview

The CB-1000 series integrates with two PMAT entry points: compliance checking via `pmat comply check` and model inventory via `pmat analyze models`.

```bash
# Run all compliance checks including CB-1000 series
pmat comply check

# Example output:
# ⚠ CB-1000: MLOps Model Quality (CB-1000 to CB-1008): [Advisory] 0 errors, 2 warnings, 1 info:
# CB-1000: Model directory has 2 model file(s) but no model card (README.md): llama-7b.gguf, llama-7b-q4.gguf (models:0)
# CB-1004: GGUF file missing `general.architecture` metadata key (BUG-EXPORT-004) (models/export.gguf:0)
# CB-1007: Model file is 13.2 GB — consider quantization or sharding (models/llama-70b-f16.gguf:0)

# Model inventory table
pmat analyze models --path ./models

# JSON output for CI pipelines
pmat analyze models --path ./models --format json

# Inventory with inline compliance checks
pmat analyze models --path ./models --check
```

The CB-1000 series is **advisory** — it reports with `Warn` status but does not block CI or commits. Violations are categorized into three severity tiers:

| Severity | Meaning | Example |
|----------|---------|---------|
| Error | Likely corrupt or broken deployment | >100K tensors (corrupt header), sharded without index |
| Warning | Missing metadata, potential issue | No model card, no tokenizer, missing architecture key |
| Info | Suggestion, low priority | File >10 GB, consider quantization |

## Supported Model Formats

PMAT recognizes three model binary formats by file extension:

| Format | Extension | Ecosystem | Header Structure |
|--------|-----------|-----------|-----------------|
| GGUF | `.gguf` | llama.cpp, LLaMA, Mistral, Phi | Magic `0x46554747` (LE), version u32, tensor count u64, metadata KV pairs |
| SafeTensors | `.safetensors` | HuggingFace Transformers, Diffusers | Header length u64, JSON header with tensor dtype/shape/offsets |
| APR | `.apr` | aprender (batuta stack) | Magic `APR2`, metadata length u32, JSON metadata, CRC32 footer |

The header parser extracts minimal metadata without loading tensor data:

```rust
pub struct ModelMetadata {
    pub format: ModelFormat,       // Gguf, Apr, or SafeTensors
    pub file_size_bytes: u64,
    pub tensor_count: Option<u64>, // From header parse
    pub architecture: Option<String>,
    pub has_crc: bool,             // APR CRC32 footer
}
```

## Defect Taxonomy

### Metadata & Documentation (CB-1000, CB-1002)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-1000 | Missing Model Card | Warning | Model directory has `.gguf`/`.safetensors`/`.apr` files but no `README.md` or `model_card.md` |
| CB-1002 | Missing Tokenizer | Warning | GGUF model directory without `tokenizer.json`, `tokenizer.model`, or `vocab.json` |

### Format Validation (CB-1001, CB-1004, CB-1008)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-1001 | Oversized Tensor Count | Error | GGUF/APR/SafeTensors header reports >100,000 tensors — likely corrupt (BUG-GGUF-001) |
| CB-1004 | Missing Architecture | Warning | GGUF file lacks `general.architecture` metadata key (BUG-EXPORT-004) |
| CB-1008 | APR Missing CRC | Warning | APR file without CRC32 footer checksum for integrity verification |

### Size & Structure (CB-1005, CB-1006, CB-1007)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-1005 | Quantization Mismatch | Warning | Filename claims quantization (e.g., `f32`) but file size is inconsistent |
| CB-1006 | Sharded Without Index | Error | Multiple `*-of-*.safetensors` shard files without `model.safetensors.index.json` (BUG-212) |
| CB-1007 | Excessive File Size | Info | Individual model file >10 GB — consider quantization or sharding |

## `pmat analyze models` Command

The `pmat analyze models` command provides a model file inventory with optional compliance checking:

```bash
pmat analyze models --path ./my-project
```

Example table output:

```
Model Inventory (4 files, 18.7 GB total)
────────────────────────────────────────────────────────────────────────
File                                     Format          Size
────────────────────────────────────────────────────────────────────────
models/llama-7b-q4_0.gguf               GGUF          3.8 GB
models/llama-7b-f16.gguf                 GGUF         13.2 GB
weights/model.safetensors                SafeTensors    1.5 GB
weights/embeddings.apr                   APR          210.4 MB
────────────────────────────────────────────────────────────────────────
```

JSON output for CI integration:

```bash
pmat analyze models --path ./my-project --format json
```

```json
{
  "model_count": 4,
  "total_size_bytes": 20078886912,
  "total_size_human": "18.7 GB",
  "models": [
    {
      "file": "models/llama-7b-q4_0.gguf",
      "format": "GGUF",
      "size_bytes": 4080218112,
      "size_human": "3.8 GB"
    },
    {
      "file": "weights/model.safetensors",
      "format": "SafeTensors",
      "size_bytes": 1610612736,
      "size_human": "1.5 GB"
    }
  ]
}
```

With `--check`, compliance violations are appended after the inventory:

```bash
pmat analyze models --path ./my-project --check
```

```
Model Inventory (2 files, 5.3 GB total)
────────────────────────────────────────────────────────────────────────
File                                     Format          Size
────────────────────────────────────────────────────────────────────────
models/export.gguf                       GGUF          3.8 GB
models/weights.safetensors               SafeTensors    1.5 GB
────────────────────────────────────────────────────────────────────────

⚠️ CB-1000: Model directory has 2 model file(s) but no model card (README.md): export.gguf, weights.safetensors (models)
⚠️ CB-1004: GGUF file missing `general.architecture` metadata key (BUG-EXPORT-004) (models/export.gguf)
```

The command aliases `model` and `mlops` are also accepted:

```bash
pmat analyze model --path ./models          # Singular alias
pmat analyze mlops --path ./models --check  # MLOps alias
```

## Detection Algorithms

### CB-1000: Missing Model Card

Groups model files by parent directory and checks for the presence of documentation:

```
models/
  llama-7b.gguf          # Model file present
  llama-7b-q4.gguf       # Model file present
                          # ❌ No README.md, readme.md, model_card.md, or MODEL_CARD.md
```

The check accepts any of four filenames as a valid model card: `README.md`, `readme.md`, `model_card.md`, `MODEL_CARD.md`. A single model card covers all model files in the same directory.

```
models/
  llama-7b.gguf          # ✅ Covered by README.md
  llama-7b-q4.gguf       # ✅ Covered by README.md
  README.md              # Model card present
```

### CB-1001: Oversized Tensor Count

Parses the tensor count from each format's header and flags values exceeding 100,000 as likely corrupt:

```
GGUF header layout:
  Offset 0:  u32 LE — magic (0x46554747)
  Offset 4:  u32 LE — version
  Offset 8:  u64 LE — tensor_count  ← checked against 100,000 limit
  Offset 16: u64 LE — metadata_kv_count
```

For SafeTensors, tensor count is derived by counting `"dtype"` fields in the JSON header (minus 1 if `__metadata__` is present). For APR, tensor count is estimated by counting `"name"` fields in the JSON metadata block.

A tensor count of 200,000 in a GGUF file almost certainly indicates a corrupt or byte-swapped header, not an actual model with 200K tensors. This check catches BUG-GGUF-001 class defects.

### CB-1002: Missing Tokenizer

For directories containing GGUF files (which are typically language models), checks for the presence of a companion tokenizer file:

```
# ❌ CB-1002 Warning — GGUF without tokenizer:
models/
  llama-7b.gguf

# ✅ Passes — tokenizer present:
models/
  llama-7b.gguf
  tokenizer.json          # or tokenizer.model, or vocab.json
```

This check only applies to directories containing `.gguf` files, since GGUF is the primary format for language models that require tokenizer files. SafeTensors and APR directories are not checked.

### CB-1004: Missing Architecture (GGUF)

Performs a byte-level scan of the entire GGUF file for the string `general.architecture`. GGUF metadata keys are stored as length-prefixed strings in the binary, so a simple `windows()` scan reliably detects the key:

```rust
let needle = b"general.architecture";
let has_arch = content
    .windows(needle.len())
    .any(|w| w == needle);
```

GGUF files exported by conformant tools (llama.cpp, aprender) always include `general.architecture` with a value like `"llama"`, `"mistral"`, `"phi"`, or `"gpt2"`. Its absence indicates a broken export pipeline (BUG-EXPORT-004). Files smaller than 100 bytes are skipped as obviously incomplete.

### CB-1005: Quantization Mismatch

Cross-references the quantization type claimed in the filename against file size heuristics. The detector recognizes 24 quantization identifiers:

```
q2_k, q3_k, q3_k_s, q3_k_m, q3_k_l, q4_0, q4_1, q4_k, q4_k_s, q4_k_m,
q5_0, q5_1, q5_k, q5_k_s, q5_k_m, q6_k, q6_k_l, q8_0, q8_1,
f16, f32, bf16, iq4_xs, iq4_nl
```

Currently, the mismatch detection focuses on the most extreme case: a filename claiming `f32` quantization (full precision, 4 bytes per parameter) but having a suspiciously small file size (<100 KB). An F32 model with any meaningful number of parameters produces a file measured in megabytes at minimum.

```
# ❌ CB-1005 Warning:
model-f32.gguf   (size: 48 KB)  # F32 claim but tiny file — likely mislabeled

# ✅ Passes:
model-f32.gguf   (size: 14.2 GB)  # F32 with reasonable size
model-q4_0.gguf  (size: 3.8 GB)   # Q4_0 — no size assertion for quantized
```

### CB-1006: Sharded SafeTensors Without Index

Detects the HuggingFace sharded SafeTensors pattern (`model-NNNNN-of-NNNNN.safetensors`) and verifies the companion index file exists:

```
# ❌ CB-1006 Error — sharded without index:
model/
  model-00001-of-00003.safetensors
  model-00002-of-00003.safetensors
  model-00003-of-00003.safetensors
  # Missing: model.safetensors.index.json

# ✅ Passes — index present:
model/
  model-00001-of-00003.safetensors
  model-00002-of-00003.safetensors
  model-00003-of-00003.safetensors
  model.safetensors.index.json
```

This is severity Error because a missing index makes it impossible for loading libraries to correctly map tensor names to shard files. This was the root cause of BUG-212 in production.

### CB-1007: Excessive File Size

Flags individual model files exceeding 10 GB (the `LARGE_MODEL_THRESHOLD` constant) with an advisory to consider quantization or sharding:

```
# ℹ️ CB-1007 Info:
# Model file is 13.2 GB — consider quantization or sharding
models/llama-7b-f16.gguf  (13.2 GB)

# No flag (under threshold):
models/llama-7b-q4_0.gguf (3.8 GB)
```

This check applies to all three formats (GGUF, SafeTensors, APR) and is purely informational. Large models are not inherently broken, but they increase deployment costs and transfer times.

### CB-1008: APR Missing CRC

Parses the APR header and checks for a CRC32 footer checksum. APR files store a 4-byte CRC at the end of the file for integrity verification during loading:

```
APR file layout:
  Offset 0:      "APR2" magic (4 bytes)
  Offset 4:      metadata_len (u32 LE)
  Offset 8:      JSON metadata (metadata_len bytes)
  ...
  Offset EOF-4:  CRC32 footer (4 bytes)  ← checked by CB-1008
```

The detector reads the last 4 bytes of the file to determine if a CRC footer is present. Files without a CRC footer cannot be integrity-verified on load.

## File Walking

All CB-1000 checks share a common directory walker (`walkdir_model_files`) that recursively scans for files with extensions `.gguf`, `.apr`, and `.safetensors`. The walker skips common non-project directories to avoid scanning dependency caches:

| Skipped Directory | Reason |
|-------------------|--------|
| `.git` | Version control internals |
| `node_modules` | JavaScript dependencies |
| `target` | Rust build artifacts |
| `.pmat` | PMAT cache directory |
| `vendor` | Vendored dependencies |
| `build`, `dist` | Build output directories |
| `__pycache__`, `.venv` | Python artifacts |

## Testing

Tests use `tempfile::TempDir` to create synthetic model files with controlled headers:

```rust
#[test]
fn test_cb1000_detects_missing_model_card() {
    let temp = tempfile::tempdir().unwrap();
    let models_dir = temp.path().join("models");
    fs::create_dir_all(&models_dir).unwrap();

    // Write a minimal valid GGUF header
    let mut gguf_header = vec![0x47u8, 0x47, 0x55, 0x46]; // GGUF magic
    gguf_header.extend_from_slice(&3u32.to_le_bytes());     // version 3
    gguf_header.extend_from_slice(&10u64.to_le_bytes());    // tensor_count
    gguf_header.extend_from_slice(&5u64.to_le_bytes());     // metadata_count
    gguf_header.resize(64, 0);
    fs::write(models_dir.join("model.gguf"), &gguf_header).unwrap();

    let violations = detect_cb1000_missing_model_card(temp.path());
    assert_eq!(violations.len(), 1);
    assert_eq!(violations[0].pattern_id, "CB-1000");
}

#[test]
fn test_cb1001_detects_oversized_tensor_count() {
    let temp = tempfile::tempdir().unwrap();
    let mut header = vec![0x47u8, 0x47, 0x55, 0x46, 3, 0, 0, 0]; // GGUF magic + version
    header.extend_from_slice(&200_000u64.to_le_bytes()); // oversized tensor_count
    header.resize(64, 0);
    fs::write(temp.path().join("bad.gguf"), &header).unwrap();

    let violations = detect_cb1001_oversized_tensor_count(temp.path());
    assert_eq!(violations.len(), 1);
    assert_eq!(violations[0].pattern_id, "CB-1001");
}

#[test]
fn test_cb1006_detects_sharded_without_index() {
    let temp = tempfile::tempdir().unwrap();
    // Create sharded SafeTensors files (minimal valid headers)
    let header = 8u64.to_le_bytes();
    let json = b"{\"a\":{}}";
    let mut content = Vec::new();
    content.extend_from_slice(&header);
    content.extend_from_slice(json);

    fs::write(temp.path().join("model-00001-of-00002.safetensors"), &content).unwrap();
    fs::write(temp.path().join("model-00002-of-00002.safetensors"), &content).unwrap();

    let violations = detect_cb1006_sharded_without_index(temp.path());
    assert_eq!(violations.len(), 1);
    assert_eq!(violations[0].pattern_id, "CB-1006");
}
```

Test coverage includes both positive detection (violation present) and negative cases (no violation when metadata is correct).

## CI/CD Integration

```yaml
# .github/workflows/model-quality.yml
name: MLOps Model Quality
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true  # Model files are typically in Git LFS
      - name: Install PMAT
        run: cargo install pmat
      - name: Model Inventory
        run: pmat analyze models --format json
      - name: Model Quality Checks
        run: |
          OUTPUT=$(pmat comply check 2>&1)
          echo "$OUTPUT"
          # Fail on Error-severity violations (CB-1001, CB-1006)
          if echo "$OUTPUT" | grep -q "CB-1000.*errors: [1-9]"; then
            echo "::error::CB-1000 series has Error-severity violations"
            exit 1
          fi
```

## Remediation Priority

When `pmat comply check` reports CB-1000 violations, fix them in this priority order:

1. **CB-1001 Errors** (>100K tensors) — corrupt header, model will fail to load
2. **CB-1006 Errors** (sharded without index) — model loading will fail at runtime
3. **CB-1004** — missing architecture prevents runtime format negotiation
4. **CB-1005** — quantization mismatch indicates mislabeled export
5. **CB-1000** — missing model card hinders reproducibility and auditability
6. **CB-1002** — missing tokenizer prevents text generation pipelines
7. **CB-1008** — missing CRC prevents integrity verification on load
8. **CB-1007** — informational, consider quantization for deployment efficiency

## Academic Foundations

| Paper | Finding | Applied To |
|-------|---------|-----------|
| Sculley et al. (2015). "Hidden Technical Debt in Machine Learning Systems" | ML systems accumulate configuration, data, and serving debt beyond code debt | CB-1000, CB-1002, CB-1006 |
| Amershi et al. (2019). "Software Engineering for Machine Learning" | Model metadata and versioning are top engineering challenges | CB-1000, CB-1004 |
| GGUF Specification (llama.cpp, 2023) | GGUF v3 header format with typed metadata KV pairs | CB-1001, CB-1004, CB-1005 |
| HuggingFace SafeTensors Format (2023) | JSON header with tensor dtype, shape, data offsets | CB-1001, CB-1006 |

## Specification Reference

Full detection logic: `src/cli/handlers/comply_cb_detect/model_quality.rs`
Model inventory handler: `src/cli/handlers/analysis_handlers.rs` (`route_model_analysis`)
Aggregate check: `src/cli/handlers/comply_handlers/check_handlers.rs` (`check_model_quality`)
