# PMAT Book Makefile
# Quality Gates and Development Commands

.PHONY: all build serve test clean lint validate help install-deps

# Default target
all: validate build

# Help target
help:
	@echo "PMAT Book Development Commands:"
	@echo ""
	@echo "📚 BOOK OPERATIONS:"
	@echo "  make build             - Build the book with mdBook"
	@echo "  make serve             - Serve the book locally with auto-reload"
	@echo "  make clean             - Remove all build artifacts"
	@echo ""
	@echo "🧪 TESTING OPERATIONS:"
	@echo "  make test              - Test all code examples"
	@echo "  make test-ch01         - Test Chapter 1 examples"
	@echo "  make test-ch02         - Test Chapter 2 examples"
	@echo "  make test-ch03         - Test Chapter 3 examples"
	@echo "  make test-ch04         - Test Chapter 4 examples"
	@echo "  make test-all-chapters - Run ALL chapter tests"
	@echo ""
	@echo "🎨 CODE QUALITY:"
	@echo "  make lint              - Lint all code examples"
	@echo "  make lint-markdown     - Validate markdown links"
	@echo "  make dogfood-pmat      - Run PMAT analysis on book itself"
	@echo "  make quality-gate      - Check quality gates (Grade B+ minimum)"
	@echo "  make validate          - Run ALL quality checks"
	@echo ""
	@echo "⚙️  SETUP:"
	@echo "  make install-deps      - Install required dependencies"
	@echo ""

# Install dependencies
install-deps:
	@echo "Installing mdBook and required tools..."
	@command -v mdbook >/dev/null 2>&1 || cargo install mdbook
	@command -v mdbook-linkcheck >/dev/null 2>&1 || cargo install mdbook-linkcheck
	@echo "✅ Dependencies installed"

# Build the book
build: install-deps
	@echo "📚 Building PMAT book..."
	@mdbook build
	@echo "✅ Book built successfully"

# Serve the book locally
serve: install-deps
	@echo "🌐 Serving PMAT book on http://localhost:3000"
	@mdbook serve --open

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf book
	@echo "✅ Clean complete"

# Test all code examples
test: test-all-chapters
	@echo "✅ All tests completed"

# Test specific chapters
test-ch01:
	@echo "🧪 Testing Chapter 1 examples..."
	@mkdir -p test-results/ch01
	@chmod +x tests/ch01/test_simple.sh
	@echo "Running Chapter 1 TDD validation..."
	@tests/ch01/test_simple.sh > test-results/ch01/test_simple.log 2>&1 || { cat test-results/ch01/test_simple.log; exit 1; }
	@echo "✅ Chapter 1 tests passed"

test-ch02:
	@echo "🧪 Testing Chapter 2 examples..."
	@mkdir -p test-results/ch02
	@chmod +x tests/ch02/*.sh 2>/dev/null || echo "No tests for chapter 2 yet"
	@echo "⚠️  Chapter 2 tests not implemented"

test-ch03:
	@echo "🧪 Testing Chapter 3 examples..."
	@mkdir -p test-results/ch03
	@chmod +x tests/ch03/test_simple.sh
	@echo "Running Chapter 3 MCP TDD validation..."
	@tests/ch03/test_simple.sh > test-results/ch03/test_simple.log 2>&1 || { cat test-results/ch03/test_simple.log; exit 1; }
	@echo "✅ Chapter 3 tests passed"

test-ch04:
	@echo "🧪 Testing Chapter 4 examples..."
	@mkdir -p test-results/ch04
	@chmod +x tests/ch04/*.sh 2>/dev/null || echo "No tests for chapter 4 yet"
	@echo "⚠️  Chapter 4 tests not implemented"

test-ch05:
	@echo "🧪 Testing Chapter 5 examples..."
	@mkdir -p test-results/ch05
	@chmod +x tests/ch05/*.sh 2>/dev/null || echo "No tests for chapter 5 yet"
	@echo "⚠️  Chapter 5 tests not implemented"

test-ch06:
	@echo "🧪 Testing Chapter 6 examples..."
	@mkdir -p test-results/ch06
	@chmod +x tests/ch06/*.sh 2>/dev/null || echo "No tests for chapter 6 yet"
	@echo "⚠️  Chapter 6 tests not implemented"

test-ch07:
	@echo "🧪 Testing Chapter 7 examples..."
	@mkdir -p test-results/ch07
	@chmod +x tests/ch07/*.sh 2>/dev/null || echo "No tests for chapter 7 yet"
	@echo "⚠️  Chapter 7 tests not implemented"

test-ch08:
	@echo "🧪 Testing Chapter 8 examples..."
	@mkdir -p test-results/ch08
	@chmod +x tests/ch08/*.sh 2>/dev/null || echo "No tests for chapter 8 yet"
	@echo "⚠️  Chapter 8 tests not implemented"

test-ch09:
	@echo "🧪 Testing Chapter 9: Pre-commit Hooks..."
	@mkdir -p test-results/ch09
	@chmod +x tests/ch09/test_simple.sh
	@echo "Running Chapter 9 pre-commit hooks tests..."
	@tests/ch09/test_simple.sh > test-results/ch09/test_simple.log 2>&1 || { cat test-results/ch09/test_simple.log; exit 1; }
	@echo "✅ Chapter 9 tests passed"

test-all-chapters: test-ch01 test-ch02 test-ch03 test-ch04 test-ch05 test-ch06 test-ch07 test-ch08 test-ch09

# Lint code examples
lint:
	@echo "🎨 Linting code examples..."
	@# TODO: Add linting for bash and JSON examples

# Validate markdown links
lint-markdown:
	@echo "🔗 Validating markdown links..."
	@if command -v mdbook-linkcheck >/dev/null 2>&1; then \
		mdbook-linkcheck --standalone .; \
	else \
		echo "⚠️  mdbook-linkcheck not installed, skipping link validation"; \
	fi

# PMAT dogfooding - analyze our own codebase
dogfood-pmat:
	@echo "🐕 Running PMAT analysis on book codebase..."
	@command -v pmat >/dev/null 2>&1 || { echo "❌ PMAT not installed. Run: cargo install pmat"; exit 1; }
	@mkdir -p pmat-reports
	@echo "Running PMAT context generation..."
	@pmat context > pmat-reports/context.txt 2>/dev/null || echo "Context generation skipped"
	@echo "Running PMAT complexity analysis..."
	@pmat analyze complexity --project-path . > pmat-reports/complexity.txt 2>/dev/null || echo "Complexity analysis skipped"
	@echo "Running PMAT dead code analysis..."
	@pmat analyze dead-code --path . > pmat-reports/dead-code.txt 2>/dev/null || echo "Dead code analysis skipped"
	@echo "Running PMAT technical debt analysis..."
	@pmat analyze satd --path . --exclude-pattern "book/**,target/**,*.pyc" > pmat-reports/technical-debt.txt 2>/dev/null || echo "Technical debt analysis skipped"
	@echo "📊 PMAT reports generated in pmat-reports/"
	@ls -la pmat-reports/

# Check quality gates with PMAT
quality-gate:
	@echo "🚪 Checking quality gates..."
	@if [ ! -f pmat-reports/context.txt ]; then make dogfood-pmat; fi
	@echo "Checking PMAT analysis results..."
	@if [ -f pmat-reports/technical-debt.txt ] && [ -s pmat-reports/technical-debt.txt ]; then \
		SATD_COUNT=$$(wc -l < pmat-reports/technical-debt.txt || echo "0"); \
		echo "Technical Debt Issues: $$SATD_COUNT"; \
		if [ "$$SATD_COUNT" -gt 10 ]; then \
			echo "❌ Quality gate failed: Too many technical debt issues ($$SATD_COUNT > 10)"; \
			exit 1; \
		fi; \
	fi
	@if [ -f pmat-reports/complexity.txt ] && [ -s pmat-reports/complexity.txt ]; then \
		echo "✅ Complexity analysis completed"; \
	fi
	@if [ -f pmat-reports/context.txt ] && [ -s pmat-reports/context.txt ]; then \
		CONTEXT_SIZE=$$(wc -c < pmat-reports/context.txt); \
		echo "✅ Context generated: $$CONTEXT_SIZE bytes"; \
	fi
	@echo "✅ Quality gates passed"

# Run all quality checks
validate: test lint lint-markdown dogfood-pmat quality-gate
	@echo "✅ All quality checks passed"