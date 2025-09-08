# The PMAT Book

Official documentation for [PMAT (PAIML MCP Agent Toolkit)](https://github.com/paiml/paiml-mcp-agent-toolkit) - Zero-configuration AI context generation with extreme quality enforcement.

## About

This book provides comprehensive documentation for PMAT, covering:
- Installation and setup
- Core concepts and analysis capabilities
- MCP (Model Context Protocol) integration
- Technical Debt Grading (TDG) system
- Code similarity detection
- Real-world usage examples
- Advanced features and optimization

## Building the Book

### Prerequisites

- Rust and Cargo (for installing mdBook)
- Git

### Quick Start

```bash
# Install dependencies
make install-deps

# Build the book
make build

# Serve locally (opens in browser)
make serve
```

The book will be available at http://localhost:3000

### Available Commands

```bash
make help          # Show all available commands
make build         # Build the book
make serve         # Serve with auto-reload
make clean         # Remove build artifacts
make validate      # Run quality checks
make test          # Test code examples (when implemented)
```

## Book Structure

```
src/
├── SUMMARY.md                # Table of contents
├── title-page.md            # Title page
├── foreword.md              # Foreword
├── introduction.md          # Introduction
├── ch01-*.md               # Installation and setup
├── ch02-*.md               # Core concepts
├── ch03-*.md               # MCP integration
├── ch04-*.md               # Advanced features
├── ch05-*.md               # CLI mastery
├── ch06-*.md               # Real-world examples
├── ch07-*.md               # Architecture patterns
├── ch08-*.md               # Performance and scale
├── appendix-*.md           # Reference materials
└── conclusion.md           # Conclusion
```

## Contributing

Contributions are welcome! Please ensure:
1. All code examples are tested and working
2. Chapter status blocks are updated
3. Run `make validate` before submitting

## Status

The book is currently in active development. Chapters marked as "✅ Working" are production-ready.

## Resources

- [PMAT GitHub Repository](https://github.com/paiml/paiml-mcp-agent-toolkit)
- [Pragmatic AI Labs](https://paiml.com)
- [MCP Documentation](https://modelcontextprotocol.io)

## License

MIT License - See LICENSE file for details
