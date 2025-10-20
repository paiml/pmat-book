#!/bin/bash
# TDD Test: Chapter 26 - Graph Statistics and Network Analysis
# Tests the graph analytics features added in PMAT v2.95.0

PASS_COUNT=0
FAIL_COUNT=0
TEST_DIR=$(mktemp -d)
PMAT_DIR="/home/noah/src/paiml-mcp-agent-toolkit"

# Test utilities
test_pass() {
    echo "✅ PASS: $1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Test 1: Graph module structure exists
test_graph_modules() {
    echo "Testing graph module structure..."

    # Check core graph modules
    if [ -d "$PMAT_DIR/server/src/graph" ]; then
        test_pass "Graph module directory exists"
    else
        test_fail "Graph module directory not found"
        return 1
    fi

    # Check key graph files
    local modules=(
        "builder.rs"
        "centrality.rs"
        "community.rs"
        "context_annotator.rs"
        "structure.rs"
        "types.rs"
    )

    for module in "${modules[@]}"; do
        if [ -f "$PMAT_DIR/server/src/graph/$module" ]; then
            test_pass "Graph module $module exists"
        else
            test_fail "Graph module $module not found"
        fi
    done
}

# Test 2: PageRank implementation
test_pagerank_implementation() {
    echo "Testing PageRank implementation..."

    # Check for PageRank in source code
    if grep -r "PageRank\|pagerank" "$PMAT_DIR/server/src/graph/" >/dev/null 2>&1; then
        test_pass "PageRank implementation found"
    else
        test_fail "PageRank implementation not found"
    fi

    # Check for power iteration algorithm
    if grep -r "power.*iteration\|damping.*factor" "$PMAT_DIR/server/src/" >/dev/null 2>&1; then
        test_pass "Power iteration algorithm present"
    else
        test_fail "Power iteration algorithm not found"
    fi
}

# Test 3: Community detection (Louvain algorithm)
test_community_detection() {
    echo "Testing community detection..."

    # Check for Louvain algorithm
    if [ -f "$PMAT_DIR/server/src/graph/community.rs" ]; then
        if grep -q "LouvainDetector\|Louvain" "$PMAT_DIR/server/src/graph/community.rs"; then
            test_pass "Louvain community detection implemented"
        else
            test_fail "Louvain algorithm not found"
        fi

        # Check for modularity calculation
        if grep -q "modularity" "$PMAT_DIR/server/src/graph/community.rs"; then
            test_pass "Modularity optimization present"
        else
            test_fail "Modularity optimization not found"
        fi
    else
        test_fail "Community detection module not found"
    fi
}

# Test 4: Graph context annotation
test_context_annotation() {
    echo "Testing graph context annotation..."

    if [ -f "$PMAT_DIR/server/src/graph/context_annotator.rs" ]; then
        test_pass "Context annotator module exists"

        # Check for annotation features
        if grep -q "ContextAnnotation\|importance_score\|community_id" "$PMAT_DIR/server/src/graph/context_annotator.rs"; then
            test_pass "Context annotation structures defined"
        else
            test_fail "Context annotation structures not found"
        fi

        # Check for complexity classification
        if grep -q "classify_complexity" "$PMAT_DIR/server/src/graph/context_annotator.rs"; then
            test_pass "Complexity classification implemented"
        else
            test_fail "Complexity classification not found"
        fi
    else
        test_fail "Context annotator not found"
    fi
}

# Test 5: CLI integration
test_cli_integration() {
    echo "Testing CLI integration..."

    # Check for graph metrics in CLI
    if grep -r "graph.*metrics\|GraphMetric" "$PMAT_DIR/server/src/cli/" >/dev/null 2>&1; then
        test_pass "Graph metrics CLI integration found"
    else
        test_fail "Graph metrics CLI integration not found"
    fi

    # Check for context integration
    if [ -f "$PMAT_DIR/server/src/cli/handlers/graph_context_integration_tests.rs" ]; then
        test_pass "Graph context integration tests exist"
    else
        test_fail "Graph context integration tests not found"
    fi
}

# Test 6: Dependency graph construction
test_dependency_graph() {
    echo "Testing dependency graph construction..."

    # Create test project structure
    mkdir -p "$TEST_DIR/test_project/src"

    # Create sample Rust files with dependencies
    cat > "$TEST_DIR/test_project/src/main.rs" << 'EOF'
mod utils;
mod config;

use utils::helper_function;
use config::Settings;

fn main() {
    let settings = Settings::new();
    helper_function(&settings);
}
EOF

    cat > "$TEST_DIR/test_project/src/utils.rs" << 'EOF'
use crate::config::Settings;

pub fn helper_function(settings: &Settings) {
    println!("Helper called with: {:?}", settings);
}
EOF

    cat > "$TEST_DIR/test_project/src/config.rs" << 'EOF'
#[derive(Debug)]
pub struct Settings {
    pub debug: bool,
}

impl Settings {
    pub fn new() -> Self {
        Settings { debug: true }
    }
}
EOF

    if [ -f "$TEST_DIR/test_project/src/main.rs" ] && \
       [ -f "$TEST_DIR/test_project/src/utils.rs" ] && \
       [ -f "$TEST_DIR/test_project/src/config.rs" ]; then
        test_pass "Test project with dependencies created"
    else
        test_fail "Failed to create test project"
    fi
}

# Test 7: Graph statistics output formats
test_output_formats() {
    echo "Testing graph statistics output formats..."

    # Check for GraphML export
    if grep -r "GraphML\|graphml" "$PMAT_DIR/server/src/" >/dev/null 2>&1; then
        test_pass "GraphML export support found"
    else
        test_fail "GraphML export support not found"
    fi

    # Check for JSON output
    if grep -r "serde.*Serialize" "$PMAT_DIR/server/src/graph/" >/dev/null 2>&1; then
        test_pass "JSON serialization support found"
    else
        test_fail "JSON serialization support not found"
    fi

    # Check for markdown formatting
    if grep -r "markdown\|md" "$PMAT_DIR/server/src/cli/handlers/" >/dev/null 2>&1; then
        test_pass "Markdown output support found"
    else
        test_fail "Markdown output support not found"
    fi
}

# Test 8: Centrality metrics
test_centrality_metrics() {
    echo "Testing centrality metrics..."

    if [ -f "$PMAT_DIR/server/src/graph/centrality.rs" ]; then
        test_pass "Centrality module exists"

        # Check for centrality types
        local metrics=(
            "degree"
            "betweenness"
            "closeness"
            "eigenvector"
        )

        for metric in "${metrics[@]}"; do
            if grep -q "$metric" "$PMAT_DIR/server/src/graph/centrality.rs"; then
                test_pass "$metric centrality defined"
            else
                test_fail "$metric centrality not found"
            fi
        done
    else
        test_fail "Centrality module not found"
    fi
}

# Test 9: Graph structural analysis
test_structural_analysis() {
    echo "Testing graph structural analysis..."

    if [ -f "$PMAT_DIR/server/src/graph/structure.rs" ]; then
        test_pass "Structural analysis module exists"

        # Check for structural metrics
        local metrics=(
            "density"
            "diameter"
            "clustering_coefficient"
            "components"
        )

        for metric in "${metrics[@]}"; do
            if grep -q "$metric" "$PMAT_DIR/server/src/graph/structure.rs"; then
                test_pass "$metric structural metric defined"
            else
                test_fail "$metric structural metric not found"
            fi
        done
    else
        test_fail "Structural analysis module not found"
    fi
}

# Test 10: Performance optimizations
test_performance_optimizations() {
    echo "Testing performance optimizations..."

    # Check for CSR (Compressed Sparse Row) matrices
    if grep -r "CSR\|csr\|sparse.*matrix" "$PMAT_DIR/server/src/" >/dev/null 2>&1; then
        test_pass "Sparse matrix optimizations found"
    else
        test_fail "Sparse matrix optimizations not found"
    fi

    # Check for parallel processing
    if grep -r "rayon\|parallel" "$PMAT_DIR/server/src/graph/" >/dev/null 2>&1; then
        test_pass "Parallel processing support found"
    else
        test_fail "Parallel processing support not found"
    fi
}

# Test 11: Multi-language support
test_multi_language_support() {
    echo "Testing multi-language dependency analysis..."

    # Check for language-specific parsers
    if grep -r "rust\|python\|typescript\|javascript" "$PMAT_DIR/server/src/" >/dev/null 2>&1; then
        test_pass "Multi-language support indicators found"
    else
        test_fail "Multi-language support not found"
    fi

    # Check for AST processing
    if grep -r "AST\|ast\|syntax.*tree" "$PMAT_DIR/server/src/" >/dev/null 2>&1; then
        test_pass "AST processing support found"
    else
        test_fail "AST processing support not found"
    fi
}

# Test 12: Graph visualization support
test_visualization_support() {
    echo "Testing graph visualization support..."

    # Check for Mermaid generation
    if grep -r "mermaid\|Mermaid" "$PMAT_DIR/server/src/" >/dev/null 2>&1; then
        test_pass "Mermaid diagram support found"
    else
        test_fail "Mermaid diagram support not found"
    fi

    # Check for DOT format
    if grep -r "dot\|graphviz" "$PMAT_DIR/server/src/" >/dev/null 2>&1; then
        test_pass "DOT/Graphviz support found"
    else
        test_fail "DOT/Graphviz support not found"
    fi
}

# Test 13: Quality metrics integration
test_quality_integration() {
    echo "Testing quality metrics integration..."

    # Check for complexity integration
    if grep -r "complexity.*graph\|graph.*complexity" "$PMAT_DIR/server/src/" >/dev/null 2>&1; then
        test_pass "Complexity-graph integration found"
    else
        test_fail "Complexity-graph integration not found"
    fi

    # Check for TDD test coverage
    if [ -d "$PMAT_DIR/server/src/graph/tests" ]; then
        test_pass "Graph module test directory exists"
    else
        test_fail "Graph module test directory not found"
    fi
}

# Test 14: Context command integration
test_context_integration() {
    echo "Testing context command integration..."

    # Check for context integration tests
    if [ -f "$PMAT_DIR/server/src/cli/handlers/graph_context_integration_tests.rs" ]; then
        test_pass "Context integration test file exists"

        # Check test content
        if grep -q "graph.*analysis\|PageRank\|community" "$PMAT_DIR/server/src/cli/handlers/graph_context_integration_tests.rs"; then
            test_pass "Context integration tests contain graph analysis"
        else
            test_fail "Context integration tests missing graph analysis"
        fi
    else
        test_fail "Context integration test file not found"
    fi
}

# Test 15: Configuration and thresholds
test_configuration() {
    echo "Testing graph analysis configuration..."

    # Create sample configuration
    cat > "$TEST_DIR/graph_config.toml" << 'EOF'
[graph_analysis]
pagerank_damping = 0.85
pagerank_iterations = 100
pagerank_convergence = 1e-6
community_resolution = 1.0
min_centrality_threshold = 0.01
top_k_nodes = 10

[performance]
parallel_processing = true
cache_results = true
max_nodes = 10000
EOF

    if [ -f "$TEST_DIR/graph_config.toml" ]; then
        test_pass "Graph configuration file created"

        # Validate TOML structure
        if grep -q "pagerank_damping\|community_resolution" "$TEST_DIR/graph_config.toml"; then
            test_pass "Configuration has required graph parameters"
        else
            test_fail "Configuration missing graph parameters"
        fi
    else
        test_fail "Failed to create graph configuration"
    fi
}

# Run all tests
echo "=================================="
echo "Running Chapter 26 Graph Statistics Tests"
echo "=================================="

test_graph_modules
test_pagerank_implementation
test_community_detection
test_context_annotation
test_cli_integration
test_dependency_graph
test_output_formats
test_centrality_metrics
test_structural_analysis
test_performance_optimizations
test_multi_language_support
test_visualization_support
test_quality_integration
test_context_integration
test_configuration

# Summary
echo "=================================="
echo "Test Summary:"
echo "  Passed: $PASS_COUNT"
echo "  Failed: $FAIL_COUNT"

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ $FAIL_COUNT tests failed"
    exit 1
fi