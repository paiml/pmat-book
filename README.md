---
schema_version: "1.0"
kind: spec
entrypoints: [book.toml, Makefile]
contract_count: 1
---
# The PMAT Book

<!-- CONTRACT_COUNT_START -->1<!-- CONTRACT_COUNT_END -->

[![Deploy Book](https://github.com/paiml/pmat-book/actions/workflows/pages.yml/badge.svg)](https://github.com/paiml/pmat-book/actions/workflows/pages.yml)
[![Test Examples](https://github.com/paiml/pmat-book/actions/workflows/test.yml/badge.svg)](https://github.com/paiml/pmat-book/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Official comprehensive documentation for PMAT**

📚 **[Read the Book Online](https://paiml.github.io/pmat-book/)** | [PMAT Repository](https://github.com/paiml/paiml-mcp-agent-toolkit)

## About

This book provides comprehensive documentation for PMAT: installation and setup, core concepts
and analysis capabilities, MCP (Model Context Protocol) integration, Technical Debt Grading
(TDG), code similarity detection, and real-world usage examples. See `src/SUMMARY.md` for the
full chapter list.

## Building

```text
git clone https://github.com/paiml/pmat-book.git
cd pmat-book
bash scripts/install-hooks.sh   # prevents 404s from unpushed commits
make install-deps
make serve                      # local preview at http://localhost:3000
```

The two commands above that CI itself runs, verbatim, on the merge path:

```bash
mdbook build
```

```bash
make build
```

(`.github/workflows/pages.yml` builds and deploys the book on every push to `main`;
`.github/workflows/test.yml` builds it again, plus the flag/command-verification suite, on every
push and pull request to `main`.) Everything else above is illustration.

## Contributing

Contributions are welcome. All code examples must be tested and working; run `make validate`
before submitting.

## pv-readme Contract

This file is graded by `contracts/readme-root.yaml` (a `readme:Readme` SHACL shape) via
`pv-readme --check`, falsified by `tests/readme-shape-falsifier.sh` (paiml/pmat-book#80).

## License

MIT License - See LICENSE file for details
