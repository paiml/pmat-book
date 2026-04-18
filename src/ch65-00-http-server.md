# Chapter 65: The HTTP Server — Current State is a Stub

*`pmat serve --transport http` announces a URL, prints "Server ready", and does not bind the port. This chapter documents the v3.14.0 reality, the planned REST surface, and the tracking issue.*

`pmat serve` has appeared in `pmat --help` since the 2.x series. As of `pmat 3.14.0` the subcommand exists, it parses its flags, and it prints a welcome banner — but its most-advertised transport, `--transport http`, is a stub that does not open a socket. This chapter documents that gap honestly: what `pmat serve --help` says vs what the binary actually does, how to reproduce the defect, what the source tree shows about the planned REST surface, and which issue tracks the fix.

If you are reading this chapter looking for a running REST API, stop and read Chapter 64 instead. MCP mode over stdin is the supported server transport in 3.14.0. HTTP is planned but not shipped.

## What `pmat serve --help` Advertises

Running `pmat serve --help` in `pmat 3.14.0`:

```
Start HTTP API server with WebSocket support

Usage: pmat serve [OPTIONS]

Options:
      --mode <MODE>       Force specific mode (auto-detected by default)
                          [possible values: cli, mcp]
      --port <PORT>       Port to bind the server to [default: 8080]
      --host <HOST>       Host address to bind to [default: 127.0.0.1]
      --cors              Enable CORS for cross-origin requests
      --transport <TRANSPORT>
                          Transport protocol to use
                          Possible values:
                          - http:       HTTP transport (REST API)
                          - web-socket: WebSocket transport (real-time bidirectional)
                          - http-sse:   HTTP Server-Sent Events transport (streaming)
                          - both:       Both HTTP and WebSocket (hybrid mode)
                          - all:        All transports (HTTP, WebSocket, SSE)
                          [default: http]
```

The help text promises four transports and a default (`http`). A user reading this text would reasonably expect `pmat serve --transport http --port 9999` to bind a REST server on port 9999 with `/health` and `/api/v1` routes live.

## What It Actually Does

Verified run in `pmat 3.14.0` on 2026-04-18:

```bash
pmat serve --transport http --port 9999
```

Actual output on stderr:

```
🚀 Starting PMAT HTTP server on http://127.0.0.1:9999
✅ Server ready!
  Health check: http://127.0.0.1:9999/health
  API base: http://127.0.0.1:9999/api/v1

HTTP server functionality ready for implementation.
Press Ctrl+C to exit.
```

Exit behaviour: the process hangs on `tokio::signal::ctrl_c()` until interrupted. No port is bound during that wait. Verified with `ss -tln | grep 9999` while the server was "ready" — zero matches, socket not open. `curl http://127.0.0.1:9999/health` returns `curl: (7) Failed to connect to 127.0.0.1 port 9999: Connection refused`.

This is defect **D13** on [issue #333](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/333). The banner is marketing for functionality that does not exist yet. The final line — `"HTTP server functionality ready for implementation."` — is the honest truth hidden in the middle of a success-looking block.

## Source of the Stub

The stub lives in `server/src/cli/analysis_utilities/comprehensive_serve.rs`. The handler that the `--transport http` flag dispatches into is literally:

```rust
async fn handle_http_server(host: &str, port: u16, cors: bool) -> Result<()> {
    eprintln!("🚀 Starting PMAT HTTP server on http://{host}:{port}");
    eprintln!("✅ Server ready!");
    eprintln!("  Health check: http://{host}:{port}/health");
    eprintln!("  API base: http://{host}:{port}/api/v1");
    print_cors_status(cors);
    eprintln!("\n🔧 HTTP server functionality ready for implementation.");

    await_shutdown_signal().await
}
```

Six `eprintln!` calls and a shutdown-signal await. No `TcpListener`, no Axum router, no `tokio::spawn` of a server task. The sibling handlers tell a slightly different story: `handle_websocket_server` and `handle_http_sse_server` at least call into transport-layer modules (`start_websocket_server`, `start_http_sse_server`) — but those modules, when inspected, also fall through to `Press Ctrl+C to exit.` without binding sockets. As of 3.14.0, **every** branch of `pmat serve --transport <...>` is a stub. `--transport all` just prints more banners before going idle.

## How to Reproduce the Defect in Under a Minute

```bash
# Terminal 1
pmat serve --transport http --port 9876 &
PID=$!
sleep 2

# Terminal 2 (or same shell, new command)
ss -tln | grep 9876           # expect: (nothing)
curl -s -o /dev/null -w "http=%{http_code}\n" http://127.0.0.1:9876/health
                              # expect: http=000 (connection refused)
curl -s -o /dev/null -w "http=%{http_code}\n" http://127.0.0.1:9876/api/v1
                              # expect: http=000

kill $PID
```

On `pmat 3.14.0`:
- `ss` prints nothing (no listening socket on 9876).
- `curl` reports `http=000` — the write code for "connection refused / not established".
- The banner promised `/health` and `/api/v1`. Neither exists.

This is the evidence block captured in the dogfood report referenced by issue #333.

## What the --mode Flag Does (and Does Not Do)

The `--mode` flag on `pmat serve` takes `cli` or `mcp`. Its intent is to force the server to behave as an MCP host even when launched in a non-MCP context — useful if you wanted a long-lived MCP-over-WebSocket endpoint.

In 3.14.0, `--mode mcp` does *not* produce a working MCP server over HTTP or WebSocket. The MCP path at the WebSocket transport also falls through to the stub print-and-wait pattern (same file, `start_websocket_server`). The only working MCP transport remains **stdio**, auto-detected when JSON-RPC is piped to `pmat` with no subcommand (Chapter 64).

`pmat --mode mcp` as a *top-level* flag (not under `serve`) is separately broken — defect D12, issue #333. It exits code 2 demanding a subcommand. Do not rely on it.

## The Planned REST Surface

The source comments hint at the intended surface. From the same file:

```rust
/// Start a hybrid server (HTTP + WebSocket)
async fn start_hybrid_server(addr: String, _cors: bool) -> Result<()> {
    eprintln!("🔧 Hybrid server functionality ready for implementation on {addr}.");
    eprintln!("📍 This would support both HTTP REST API and WebSocket MCP protocol");
    ...
}

/// Start an HTTP-SSE server
async fn start_http_sse_server(addr: String, _cors: bool) -> Result<()> {
    eprintln!("🌊 HTTP-SSE server implementation ready for {addr}");
    eprintln!("📍 This would start an HTTP Server-Sent Events server for MCP protocol");
    eprintln!("📨 POST /message - Send messages to server");
    eprintln!("🔄 GET /sse - Receive events via Server-Sent Events");
    ...
}
```

Reading the banners and the `--help` text together, the planned surface appears to be:

* **`GET /health`** — liveness probe. Returns `200 OK` with server info (version, build, uptime).
* **`/api/v1/*`** — the REST prefix for the analysis API. The banner does not detail sub-routes; the existing MCP tool names (`analyze_complexity`, `analyze_satd`, `analyze_dead_code`, `quality_gate`, `scaffold_project`, etc.) are the natural candidates for `POST /api/v1/analyze/complexity`, `POST /api/v1/quality-gate`, and so on, with JSON request bodies mirroring the MCP `arguments` objects.
* **`GET /sse`** and **`POST /message`** — an HTTP-SSE transport for MCP, with `/message` carrying JSON-RPC requests and `/sse` streaming responses.
* **`ws://host:port`** — a WebSocket upgrade endpoint running the same JSON-RPC 2.0 MCP protocol as stdio mode, but over a persistent connection.
* **Hybrid** — HTTP REST on the root and WebSocket upgrade on the same port.

None of these are implemented. All of them are wired in the CLI flag surface. The implementation work is the substance of the fix for D13.

## Why This Matters

`pmat serve --transport http` appears in integration guides and in developer setup scripts because the help text is authoritative. Pointing clients at `http://host:port/api/v1/...` produces connection-refused errors and generates bug reports against downstream tools. The honest approach — what this chapter promotes — is to treat `pmat serve` as not-yet-shipped for the HTTP / WebSocket / SSE transports, and route clients to the working stdin MCP path (Chapter 64) until a release closes D13.

## What to Do Today

For each intended integration, here is the working alternative in 3.14.0:

| You want | Broken today | Works today |
|---|---|---|
| REST API from Node / Python / curl | `pmat serve --transport http` | Invoke `pmat` CLI from the client; parse stdout |
| MCP over WebSocket | `pmat serve --transport web-socket` | MCP over stdio — spawn `pmat` per-session, pipe JSON-RPC |
| MCP in Claude Code | — | `.claude/settings.json` with `command: "pmat"` (Chapter 64) |
| SSE streaming | `pmat serve --transport http-sse` | Not available; no stdio streaming equivalent |
| CI quality gate over HTTP | `pmat serve` | `pmat quality-gate` as a direct CLI call |

The pattern is clear: every "over a socket" integration is a stub; every "directly invoke the CLI or pipe to the binary" path works.

## Tracking and Fix Status

Defect D13 is one of three release-blockers on [issue #333 — Dogfood Round 2 session 2](https://github.com/paiml/paiml-mcp-agent-toolkit/issues/333). The issue captures:

* The reproducer (`pmat serve --transport http --port 9876 && curl` → `http=000`).
* The source pointer (`comprehensive_serve.rs::handle_http_server`).
* The expectation: the banner is a lie; either implement the transport or stop printing "Server ready!" when no socket is bound.

The expected fix replaces each stub `handler_*_server` body with a real `axum::Router` / `tokio::net::TcpListener::bind` pair, wires the MCP dispatch logic used by stdio mode into a WebSocket handler, and restores `curl http://.../health` to a working `200`. The scope is medium — a well-defined Axum router with the sixteen MCP tools exposed under REST endpoints — but the implementation has not landed in any 3.14.x build.

Until it does, this chapter's advice stands: **do not use `pmat serve --transport http` in production or in any test that expects a live socket.** Use MCP-over-stdin (Chapter 64) or the `pmat` CLI directly. Treat the banner as a TODO comment printed to stderr, not a running service.

## Summary

* `pmat serve --help` advertises four HTTP-family transports.
* All four are stubs in `pmat 3.14.0`. None bind a port.
* Source: `server/src/cli/analysis_utilities/comprehensive_serve.rs`.
* Tracking: issue #333, defect D13.
* Supported server transport today: MCP over stdio (Chapter 64).
* Planned REST surface: `/health`, `/api/v1/*`, `/sse`, `/message`, WebSocket upgrade — all on the flag surface, none on the wire.

When a release closes D13, this chapter will be rewritten around the real HTTP API. Until then, the honest documentation is the broken banner.

---

*Cross-references:*
- Issue #333 — D13 HTTP server stub (release blocker)
- Chapter 64 (`ch64-00-mcp-mode.md`) — MCP mode over stdin (working transport)
- Chapter 3 (`ch03-00-mcp-protocol.md`) — MCP protocol overview
- Chapter 18 (`ch18-00-api.md`) — API server historical documentation
- Source: `server/src/cli/analysis_utilities/comprehensive_serve.rs`
