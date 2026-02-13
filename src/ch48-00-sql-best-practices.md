# Chapter 48: SQL Best Practices (CB-700 to CB-705)

The CB-700 series detects SQL-specific defect patterns that apply to **any** project containing SQL files or embedded SQL statements. These checks target the most common sources of data loss, performance degradation, and security vulnerabilities in SQL: unbounded SELECT projections, missing WHERE clauses on destructive operations, implicit Cartesian joins, ambiguous column references, injection vectors, and N+1 query patterns.

## Overview

```bash
# Run all compliance checks including CB-700 series
pmat comply check

# Example output:
# ⚠ CB-700: SQL Best Practices (CB-700 to CB-705): [Advisory] 0 errors, 4 warnings, 2 info:
# CB-700: SELECT * usage obscures column dependencies (migrations/002_users.sql:12)
# CB-701: DELETE without WHERE clause — data-loss risk (scripts/cleanup.sql:8)
# CB-702: Implicit join (Cartesian product) — use explicit JOIN syntax (queries/report.sql:23)
# CB-704: SQL injection risk — string concatenation in query (src/db.py:45)
```

The CB-700 series is **advisory** — it reports with `Warn` status but does not block CI or commits. Violations are categorized into three severity tiers:

| Severity | Meaning | Example |
|----------|---------|---------|
| Error | Likely defect in production | DELETE/UPDATE without WHERE clause |
| Warning | Code smell, should fix | SELECT *, implicit joins, unqualified columns |
| Info | Suggestion, low priority | N+1 query patterns, minor injection risk |

## Defect Taxonomy

### Data Safety (CB-700, CB-701)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-700 | SELECT * Usage | Warning | `SELECT *` in SQL files — obscures column dependencies and breaks schema evolution |
| CB-701 | Missing WHERE Clause | Error | `UPDATE` or `DELETE` without a `WHERE` clause — data-loss risk |

### Query Structure (CB-702, CB-703)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-702 | Implicit Join (Cartesian Product) | Warning | Comma-separated `FROM` clauses (`FROM a, b`) without explicit `JOIN` syntax |
| CB-703 | Unqualified Column Reference | Warning | Column references without table alias in multi-table queries |

### Security & Performance (CB-704, CB-705)

| ID | Check | Severity | What it detects |
|----|-------|----------|-----------------|
| CB-704 | SQL Injection Risk | Warning | String concatenation in SQL statements suggesting injection vulnerability |
| CB-705 | N+1 Query Pattern | Info | SQL execution inside loops (`for`/`while`/`foreach`/`.map`), causing O(n) round trips |

## Detection Algorithms

### CB-700: SELECT * Usage

Detects `SELECT *` in SQL files. Using `SELECT *` obscures which columns a query depends on, breaks consumers when the schema changes, and transfers unnecessary data:

```sql
-- ❌ SELECT * obscures column dependencies (CB-700 Warning):
SELECT * FROM users;
SELECT * FROM orders WHERE status = 'pending';

-- ✅ Explicit column list:
SELECT id, name, email FROM users;
SELECT order_id, amount, status FROM orders WHERE status = 'pending';
```

The detector matches `SELECT *` (case-insensitive) followed by `FROM`, excluding `SELECT COUNT(*)` and `SELECT EXISTS(*)` which are legitimate aggregate patterns.

### CB-701: Missing WHERE Clause

Detects `UPDATE` or `DELETE` statements without a `WHERE` clause. An unqualified `UPDATE` or `DELETE` applies to every row in the table, which is almost always a mistake:

```sql
-- ❌ DELETE without WHERE — deletes ALL rows (CB-701 Error):
DELETE FROM users;
DELETE FROM audit_log;

-- ❌ UPDATE without WHERE — overwrites ALL rows (CB-701 Error):
UPDATE accounts SET balance = 0;
UPDATE sessions SET expired = true;

-- ✅ Targeted operations:
DELETE FROM users WHERE deactivated_at < '2024-01-01';
DELETE FROM audit_log WHERE created_at < NOW() - INTERVAL '90 days';
UPDATE accounts SET balance = 0 WHERE flagged = true;
UPDATE sessions SET expired = true WHERE last_active < NOW() - INTERVAL '24 hours';
```

The detector parses `UPDATE ... SET` and `DELETE FROM` statements and checks for the presence of a `WHERE` keyword before the statement terminator (`;`) or end of input. `TRUNCATE` is not flagged because it is an intentional bulk operation.

### CB-702: Implicit Join (Cartesian Product)

Detects comma-separated tables in `FROM` clauses without explicit `JOIN` syntax. Implicit joins produce Cartesian products when the `WHERE` clause is missing or incomplete, and they obscure the join relationship:

```sql
-- ❌ Implicit join — Cartesian product risk (CB-702 Warning):
SELECT u.name, o.total
FROM users u, orders o
WHERE u.id = o.user_id;

SELECT p.name, c.name
FROM products p, categories c, product_categories pc
WHERE p.id = pc.product_id AND c.id = pc.category_id;

-- ✅ Explicit JOIN syntax:
SELECT u.name, o.total
FROM users u
JOIN orders o ON u.id = o.user_id;

SELECT p.name, c.name
FROM products p
JOIN product_categories pc ON p.id = pc.product_id
JOIN categories c ON c.id = pc.category_id;
```

The detector identifies `FROM` clauses containing comma-separated table references (pattern: `FROM <identifier> [alias], <identifier>`) that do not also contain an explicit `JOIN` keyword.

### CB-703: Unqualified Column Reference

Detects column references without table alias qualifiers in queries that involve multiple tables. Unqualified columns are ambiguous when two tables share a column name and cause runtime errors on schema changes:

```sql
-- ❌ Unqualified columns in multi-table query (CB-703 Warning):
SELECT name, total, created_at
FROM users
JOIN orders ON users.id = orders.user_id;

-- ✅ All columns qualified with table alias:
SELECT u.name, o.total, o.created_at
FROM users u
JOIN orders o ON u.id = o.user_id;
```

The detector identifies queries with `JOIN` or comma-separated `FROM` (multi-table context) and then checks the `SELECT` column list for bare identifiers that lack a `<table>.` prefix.

### CB-704: SQL Injection Risk

Detects string concatenation used to build SQL statements in application code. Concatenating user input into SQL strings is the primary vector for SQL injection attacks:

```python
# ❌ String concatenation in SQL — injection risk (CB-704 Warning):
query = "SELECT * FROM users WHERE name = '" + user_input + "'"
cursor.execute("DELETE FROM sessions WHERE id = " + session_id)

# ❌ f-string / format string interpolation:
query = f"SELECT * FROM users WHERE email = '{email}'"
cursor.execute("UPDATE accounts SET balance = %s WHERE id = %s" % (amount, uid))
```

```python
# ✅ Parameterized queries:
cursor.execute("SELECT * FROM users WHERE name = %s", (user_input,))
cursor.execute("DELETE FROM sessions WHERE id = ?", (session_id,))
cursor.execute("SELECT * FROM users WHERE email = :email", {"email": email})
```

```java
// ❌ String concatenation in Java (CB-704 Warning):
String sql = "SELECT * FROM users WHERE id = " + userId;
stmt.executeQuery("DELETE FROM logs WHERE date < '" + cutoff + "'");

// ✅ Prepared statements:
PreparedStatement ps = conn.prepareStatement("SELECT * FROM users WHERE id = ?");
ps.setInt(1, userId);
```

The detector scans application code files (`.py`, `.java`, `.rb`, `.php`, `.js`, `.ts`, `.go`, `.rs`) for patterns where SQL keywords (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) appear inside string concatenation expressions (`+`, `..`, `||`, f-strings, format strings).

### CB-705: N+1 Query Pattern

Detects SQL query execution inside loop bodies. Executing a query per iteration causes O(n) database round trips instead of a single batch query:

```python
# ❌ N+1 pattern — one query per iteration (CB-705 Info):
users = db.execute("SELECT id FROM users WHERE active = true")
for user in users:
    orders = db.execute(f"SELECT * FROM orders WHERE user_id = {user.id}")
    process(orders)

# ✅ Batch query:
results = db.execute("""
    SELECT u.id, o.*
    FROM users u
    JOIN orders o ON u.id = o.user_id
    WHERE u.active = true
""")
for user_id, orders in group_by(results, key=lambda r: r.id):
    process(orders)
```

```javascript
// ❌ N+1 pattern in JavaScript (CB-705 Info):
const users = await db.query("SELECT id FROM users");
for (const user of users) {
    const orders = await db.query(`SELECT * FROM orders WHERE user_id = ${user.id}`);
    handle(orders);
}

// ✅ Single query with JOIN:
const results = await db.query(`
    SELECT u.id AS user_id, o.*
    FROM users u
    JOIN orders o ON u.id = o.user_id
`);
```

The detector identifies loop constructs (`for`, `while`, `foreach`, `.map`, `.forEach`, `.each`) whose body contains a function call with a SQL string argument. Both raw SQL strings and ORM-style query builder calls are detected.

## Test Code Exclusion

All CB-700 checks exclude test code using two mechanisms:

1. **Test file exclusion**: Files under `test/`, `tests/`, `spec/` directories, or matching `*_test.*`, `test_*.*` patterns
2. **Migration awareness**: CB-700 (SELECT *) applies to migration files, but CB-701 (missing WHERE) treats `DELETE FROM <table>;` in migration or seed files as intentional truncation and reduces severity to Info

## Remediation Priority

When `pmat comply check` reports CB-700 violations, fix them in this priority order:

1. **CB-701 Errors** (missing WHERE) — highest data-loss risk
2. **CB-704** — SQL injection enables unauthorized data access and destruction
3. **CB-702** — implicit joins silently produce Cartesian products
4. **CB-703** — unqualified columns cause ambiguous query failures on schema change
5. **CB-700** — SELECT * breaks consumers and transfers excess data
6. **CB-705** — N+1 queries degrade performance under load

## CI/CD Integration

```yaml
# .github/workflows/sql-best-practices.yml
name: SQL Best Practices
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install PMAT
        run: cargo install pmat
      - name: Check SQL Best Practices
        run: |
          OUTPUT=$(pmat comply check 2>&1)
          echo "$OUTPUT"
          # Fail on Error-severity violations
          if echo "$OUTPUT" | grep -q "CB-700.*errors: [1-9]"; then
            echo "::error::CB-700 series has Error-severity violations"
            exit 1
          fi
```

## Testing

```bash
# Run CB-700 compliance tests
cargo test --lib -- sql_best_practices

# Run a specific check test
cargo test --lib -- cb700_select_star
cargo test --lib -- cb701_missing_where
cargo test --lib -- cb702_implicit_join
cargo test --lib -- cb703_unqualified_column
cargo test --lib -- cb704_sql_injection
cargo test --lib -- cb705_n_plus_one
```

## Academic Foundations

The CB-700 checks are grounded in empirical research on SQL defect patterns:

| Paper | Finding | Applied To |
|-------|---------|-----------|
| Brass & Goldberg (2006). "Semantic Errors in SQL Queries: A Quite Complete List" | Cartesian products from implicit joins are the most common semantic error | CB-702 |
| Halfond et al. (2006). "A Classification of SQL Injection Attacks and Countermeasures" | String concatenation is the primary injection vector | CB-704 |
| Chen et al. (2014). "Detecting and Fixing the N+1 Query Problem in Database-Backed Web Applications" | N+1 queries cause 25-90% of performance issues in ORM-based applications | CB-705 |
| Qiu et al. (2021). "Detecting SQL Anti-Patterns in Data-Intensive Systems" | SELECT * and missing WHERE account for 34% of SQL anti-patterns in production | CB-700, CB-701 |

## Specification Reference

Full detection logic: `src/cli/handlers/comply_cb_detect/sql_best_practices.rs`
Aggregate check: `src/cli/handlers/comply_handlers/check_handlers.rs` (`check_sql_best_practices`)
