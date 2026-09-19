# tests/ — Inspector-based verification (Quân & Huy · Tasks 12, 13, 17)

- `inspector/` — MCP Inspector `--cli` scripts, pointed at the **gateway** endpoint, never the raw backend
- `expected/` — expected `tools/list` output per team; scripts diff actual output against these

Naming: `team-<name>_tools-list.sh`, `team-<name>_call-denied.sh`. Requires Node 22.19.0+.
