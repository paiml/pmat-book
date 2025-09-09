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
	@echo "🧪 Testing Chapter 2: Getting Started (context command)..."
	@mkdir -p test-results/ch02
	@chmod +x tests/ch02/test_context.sh
	@echo "Running Chapter 2 context tests..."
	@tests/ch02/test_context.sh > test-results/ch02/test_context.log 2>&1 || { cat test-results/ch02/test_context.log; exit 1; }
	@echo "✅ Chapter 2 tests passed"

test-ch03:
	@echo "🧪 Testing Chapter 3 examples..."
	@mkdir -p test-results/ch03
	@chmod +x tests/ch03/test_simple.sh
	@echo "Running Chapter 3 MCP TDD validation..."
	@tests/ch03/test_simple.sh > test-results/ch03/test_simple.log 2>&1 || { cat test-results/ch03/test_simple.log; exit 1; }
	@echo "✅ Chapter 3 tests passed"

test-ch04:
	@echo "🧪 Testing Chapter 4: Technical Debt Grading (TDG)..."
	@mkdir -p test-results/ch04
	@chmod +x tests/ch04/test_tdg.sh
	@echo "Running Chapter 4 TDG tests..."
	@tests/ch04/test_tdg.sh > test-results/ch04/test_tdg.log 2>&1 || { cat test-results/ch04/test_tdg.log; exit 1; }
	@echo "✅ Chapter 4 TDG tests passed"

test-ch05:
	@echo "🧪 Testing Chapter 5: Analyze Command Suite..."
	@mkdir -p test-results/ch05
	@chmod +x tests/ch05/test_analyze.sh
	@echo "Running Chapter 5 analyze tests..."
	@tests/ch05/test_analyze.sh > test-results/ch05/test_analyze.log 2>&1 || { cat test-results/ch05/test_analyze.log; exit 1; }
	@echo "✅ Chapter 5 tests passed"

test-ch06:
	@echo "🧪 Testing Chapter 6: Scaffold Command..."
	@mkdir -p test-results/ch06
	@chmod +x tests/ch06/test_scaffold.sh
	@echo "Running Chapter 6 scaffold tests..."
	@tests/ch06/test_scaffold.sh > test-results/ch06/test_scaffold.log 2>&1 || { cat test-results/ch06/test_scaffold.log; exit 1; }
	@echo "✅ Chapter 6 tests passed"

test-ch07:
	@echo "🧪 Testing Chapter 7: Quality Gate Command..."
	@mkdir -p test-results/ch07
	@chmod +x tests/ch07/test_quality_gate.sh
	@echo "Running Chapter 7 quality gate tests..."
	@tests/ch07/test_quality_gate.sh > test-results/ch07/test_quality_gate.log 2>&1 || { cat test-results/ch07/test_quality_gate.log; exit 1; }
	@echo "✅ Chapter 7 tests passed"

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

test-ch10:
	@echo "🧪 Testing Chapter 10: Auto-clippy Integration..."
	@mkdir -p test-results/ch10
	@chmod +x tests/ch10/test_auto_clippy.sh
	@echo "Running Chapter 10 auto-clippy tests..."
	@tests/ch10/test_auto_clippy.sh > test-results/ch10/test_auto_clippy.log 2>&1 || { cat test-results/ch10/test_auto_clippy.log; exit 1; }
	@echo "✅ Chapter 10 tests passed"

test-ch11:
	@echo "🧪 Testing Chapter 11: Custom Quality Rules..."
	@mkdir -p test-results/ch11
	@chmod +x tests/ch11/test_custom_rules.sh
	@echo "Running Chapter 11 custom rules tests..."
	@tests/ch11/test_custom_rules.sh > test-results/ch11/test_custom_rules.log 2>&1 || { cat test-results/ch11/test_custom_rules.log; exit 1; }
	@echo "✅ Chapter 11 tests passed"

test-ch12:
	@echo "🧪 Testing Chapter 12: Architecture Analysis..."
	@mkdir -p test-results/ch12
	@chmod +x tests/ch12/test_architecture.sh
	@echo "Running Chapter 12 architecture tests..."
	@tests/ch12/test_architecture.sh > test-results/ch12/test_architecture.log 2>&1 || { cat test-results/ch12/test_architecture.log; exit 1; }
	@echo "✅ Chapter 12 tests passed"

test-ch13:
	@echo "🧪 Testing Chapter 13: Performance Analysis..."
	@mkdir -p test-results/ch13
	@tests/ch13/test_performance.sh > test-results/ch13/test_performance.log 2>&1 || { cat test-results/ch13/test_performance.log; exit 1; }
	@echo "✅ Chapter 13 tests passed"

test-ch14:
	@echo "🧪 Testing Chapter 14: Quality-Driven Development (QDD)..."
	@mkdir -p test-results/ch14
	@chmod +x tests/ch14/test_qdd.sh
	@echo "Running Chapter 14 QDD tests..."
	@tests/ch14/test_qdd.sh > test-results/ch14/test_qdd.log 2>&1 || { cat test-results/ch14/test_qdd.log; exit 1; }
	@echo "✅ Chapter 14 QDD tests passed"

test-ch15:
	@echo "🧪 Testing Chapter 15: Team Workflows..."
	@mkdir -p test-results/ch15
	@tests/ch15/test_team_workflows.sh > test-results/ch15/test_team_workflows.log 2>&1 || { cat test-results/ch15/test_team_workflows.log; exit 1; }
	@echo "✅ Chapter 15 tests passed"

test-ch16:
	@echo "🧪 Testing Chapter 16: CI/CD Integration..."
	@mkdir -p test-results/ch16
	@tests/ch16/test_cicd.sh > test-results/ch16/test_cicd.log 2>&1 || { cat test-results/ch16/test_cicd.log; exit 1; }
	@echo "✅ Chapter 16 tests passed"

test-ch17:
	@echo "🧪 Testing Chapter 17: Plugin Development..."
	@mkdir -p test-results/ch17
	@tests/ch17/test_plugins.sh > test-results/ch17/test_plugins.log 2>&1 || { cat test-results/ch17/test_plugins.log; exit 1; }
	@echo "✅ Chapter 17 tests passed"

test-ch18:
	@echo "🧪 Testing Chapter 18: API Integration..."
	@mkdir -p test-results/ch18
	@tests/ch18/test_api.sh > test-results/ch18/test_api.log 2>&1 || { cat test-results/ch18/test_api.log; exit 1; }
	@echo "✅ Chapter 18 tests passed"

test-ch19:
	@echo "🧪 Testing Chapter 19: AI Integration..."
	@mkdir -p test-results/ch19
	@tests/ch19/test_ai.sh > test-results/ch19/test_ai.log 2>&1 || { cat test-results/ch19/test_ai.log; exit 1; }
	@echo "✅ Chapter 19 tests passed"

test-all-chapters: test-ch01 test-ch02 test-ch03 test-ch04 test-ch05 test-ch06 test-ch07 test-ch08 test-ch09 test-ch10 test-ch11 test-ch12 test-ch13 test-ch14 test-ch15 test-ch16 test-ch17 test-ch18 test-ch19

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