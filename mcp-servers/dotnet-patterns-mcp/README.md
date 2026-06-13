# dotnet-patterns MCP Server

Local Model Context Protocol server that surfaces the patterns and practices in
[`/dotnet-patterns`](../../dotnet-patterns/) to any MCP-capable agent (VS Code,
Claude Desktop, MCP Inspector, custom clients).

Treat the patterns repo as a read-only knowledge source; the server exposes it
through tools, resources, and (eventually) prompts.

## Capabilities

### Tools

| Tool                  | Purpose                                                                          |
|-----------------------|----------------------------------------------------------------------------------|
| `list_patterns`       | List every pattern category with its title, checklist availability, example count. |
| `get_pattern`         | Return the full README.md markdown for a category.                               |
| `get_checklist`       | Parsed validation checklist (sections + items + done state).                     |
| `get_examples`        | List example files (optionally with contents).                                   |
| `get_example_file`    | Full text of a single example file.                                              |
| `search_patterns`     | Case-insensitive substring search across READMEs / checklists / examples.        |
| `get_adoption_matrix` | Parsed service-vs-pattern adoption table from the root README.                   |
| `recommend_patterns`  | Heuristic match of pattern categories to a code snippet (sync-over-async, embedded credentials, service locator, oversized constructors). |

### Resources

URI templates the host can attach directly to a conversation:

| URI                                       | Returns                          |
|-------------------------------------------|----------------------------------|
| `pattern://{category}/readme`             | README.md (markdown)             |
| `pattern://{category}/checklist`          | CHECKLIST.md (markdown)          |
| `pattern://{category}/examples/{fileName}`| Single example file              |

## Configuration

The server reads the patterns directory from (in priority order):

1. `PATTERNS_PATH` environment variable
2. First CLI argument
3. A `dotnet-patterns/` folder discovered by walking up from the working directory

Setting `PATTERNS_PATH` is the recommended approach — it decouples the server
binary from the patterns repo location.

## Run locally

```bash
dotnet build
PATTERNS_PATH=/abs/path/to/dotnet-patterns dotnet run --no-build
```

The server speaks STDIO, so launching it directly will block waiting for
JSON-RPC frames on stdin. Use a client (VS Code, MCP Inspector, the smoke test
below) rather than running it interactively.

### Smoke test

```bash
PATTERNS_PATH=/abs/path/to/dotnet-patterns python3 - <<'PY'
import json, subprocess
p = subprocess.Popen(["dotnet","run","--no-build","--project","."],
                     stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
def rpc(req):
    p.stdin.write(json.dumps(req)+"\n"); p.stdin.flush()
    return json.loads(p.stdout.readline())
print(rpc({"jsonrpc":"2.0","id":1,"method":"initialize",
          "params":{"protocolVersion":"2025-11-25","capabilities":{},
                    "clientInfo":{"name":"t","version":"0"}}}))
p.stdin.write(json.dumps({"jsonrpc":"2.0","method":"notifications/initialized"})+"\n")
p.stdin.flush()
print(rpc({"jsonrpc":"2.0","id":2,"method":"tools/list"}))
p.terminate()
PY
```

## Wire into VS Code

A workspace-scoped config is provided at
[`.vscode/mcp.json`](../../.vscode/mcp.json). VS Code's Copilot Chat picks it up
automatically — no per-user setup required.

## Wire into Claude Desktop

Add to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "dotnet-patterns": {
      "command": "dotnet",
      "args": ["run", "--no-build", "-c", "Release",
               "--project", "/abs/path/to/mcp-servers/dotnet-patterns-mcp"],
      "env": {
        "PATTERNS_PATH": "/abs/path/to/dotnet-patterns"
      }
    }
  }
}
```

## Design notes

- **STDIO only.** Local-first; no auth surface, no network exposure. Streamable HTTP transport can be added later by switching to `ModelContextProtocol.AspNetCore` and `WithHttpTransport()`.
- **Read-only.** The server never writes to the patterns repo. All filesystem access is constrained to `RootPath` with explicit traversal guards.
- **No caching yet.** Files are re-read on each call. Patterns repo is small enough that this is fine; add a `FileSystemWatcher` + memory cache when it grows.
- **Search is naive substring.** Upgrade path: tokenized ranking, then embeddings (local model or Azure AI Foundry) if quality becomes the bottleneck.
- **Recommendations are heuristic.** Regex-based detection of common smells. Good enough for "point me at the right pattern"; not a replacement for real static analysis.

## Security

- Category names are validated to reject `..`, `/`, `\`. All resolved paths must remain under `PATTERNS_PATH`.
- The server inherits the launching user's filesystem permissions — STDIO runs as a child process.
- No secrets are read or stored. The patterns repo itself contains no credentials (per the [managed-identity](../../dotnet-patterns/managed-identity/) checklist).

## Open work

- [ ] Add MCP **prompts** for `apply-pattern`, `validate-against-pattern`, `recommend-patterns-for-file`.
- [ ] File-system watcher with in-memory cache invalidation.
- [ ] Unit tests for `PatternRepository` (path traversal, missing categories, malformed checklists).
- [ ] Optional embeddings-backed search behind a feature flag.
- [ ] Streamable HTTP transport variant for shared/team deployment.
