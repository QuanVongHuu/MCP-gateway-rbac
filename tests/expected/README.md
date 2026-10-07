# tests/expected

**What:** the expected behaviour as data: the role × tool allow/deny matrix for the five test users, plus the expected `tools/list` per user.

**Contains (planned):**
- A YAML or JSON matrix, e.g. user → tools visible, user → tool → allow/deny.

**README mapping:** *Test users* table; *Common changes* (changing `rbac/` means changing this in the same PR).

**How it's used:** `tests/inspector/` and `tests/curl/` produce actual results; a script compares them with this file. Keeping the data separate means a policy change edits one file, not the test scripts.

**Users:** `analyst.user`, `engineer.user`, `multi.user`, `admin.user`, `nobody.user`.
