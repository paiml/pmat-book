# Chapter 1: Installation and Setup

<!-- DOC_STATUS_START -->
**Chapter Status**: ✅ 100% Working (All methods tested)

| Status | Count | Description |
|--------|-------|-------------|
| ✅ Working | 7 | All installation methods verified |
| ⚠️ Not Implemented | 0 | Planned for future versions |
| ❌ Broken | 0 | Known issues, needs fixing |
| 📋 Planned | 0 | Future roadmap features |

*Last updated: 2025-09-08*  
*PMAT version: pmat 2.63.0*
<!-- DOC_STATUS_END -->

## Overview

PMAT is designed for immediate productivity. This chapter covers:
- Multiple installation methods for every platform
- Verification and troubleshooting
- Your first analysis
- Understanding the output

By the end of this chapter, you'll have PMAT running and will have analyzed your first repository.

## Quick Start

The fastest way to get started:

```bash
# Install via Cargo (recommended)
cargo install pmat

# Verify installation
pmat --version

# Analyze current directory
pmat analyze .
```

That's it! PMAT is now analyzing your code.

## What's Next

The following sections dive deeper into:
- [Installing PMAT](ch01-01-installing.md) - All installation methods
- [First Analysis (TDD)](ch01-02-first-analysis-tdd.md) - Running your first analysis
- [Understanding Output](ch01-03-output.md) - Interpreting the results