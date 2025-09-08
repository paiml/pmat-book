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
	@chmod +x tests/ch01/*.sh
	@for test in tests/ch01/*.sh; do \
		echo "Running $$test..."; \
		$$test > test-results/ch01/$$(basename $$test .sh).log 2>&1 || exit 1; \
	done
	@echo "✅ Chapter 1 tests passed"

test-ch02:
	@echo "🧪 Testing Chapter 2 examples..."
	@mkdir -p test-results/ch02
	@chmod +x tests/ch02/*.sh 2>/dev/null || echo "No tests for chapter 2 yet"
	@echo "⚠️  Chapter 2 tests not implemented"

test-ch03:
	@echo "🧪 Testing Chapter 3 examples..."
	@mkdir -p test-results/ch03
	@chmod +x tests/ch03/*.sh 2>/dev/null || echo "No tests for chapter 3 yet"
	@echo "⚠️  Chapter 3 tests not implemented"

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

test-all-chapters: test-ch01 test-ch02 test-ch03 test-ch04 test-ch05 test-ch06 test-ch07 test-ch08

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
	@pmat analyze . --format json > pmat-reports/analysis.json
	@pmat analyze tdg . --format json > pmat-reports/tdg.json
	@pmat similarity . --format json > pmat-reports/similarity.json
	@echo "📊 PMAT reports generated in pmat-reports/"

# Check quality gates with PMAT
quality-gate:
	@echo "🚪 Checking quality gates..."
	@if [ ! -f pmat-reports/tdg.json ]; then make dogfood-pmat; fi
	@GRADE=$$(jq -r '.grade' pmat-reports/tdg.json); \
	echo "Code Quality Grade: $$GRADE"; \
	if [[ "$$GRADE" < "B" ]]; then \
		echo "❌ Quality gate failed: Grade $$GRADE is below B"; \
		exit 1; \
	fi; \
	echo "✅ Quality gate passed: Grade $$GRADE"

# Run all quality checks
validate: test lint lint-markdown dogfood-pmat quality-gate
	@echo "✅ All quality checks passed"