# Optional usage feed

The Usage surface reads `$XDG_STATE_HOME/notchD/usage.json` (or `~/.local/state/notchD/usage.json` when XDG_STATE_HOME is unset). No adapter is included. An external writer should update it atomically and must supply only data it is authorized to use; never put credentials in this file.

```json
{
  "updatedAt": "2026-11-20T12:00:00Z",
  "providers": {
    "codex": { "remaining": 20, "used": 80, "limit": 100, "unit": "requests", "resetAt": "2026-11-21T00:00:00Z" },
    "claude": { "updatedAt": "2026-11-20T12:00:00Z", "error": "Provider unavailable" },
    "opencode": { "used": 42, "unit": "requests" }
  }
}
```

All provider entries and numeric fields are optional; values must be nonnegative numbers. `updatedAt` is an ISO 8601 timestamp, either per provider or at the top level. `resetAt` is an optional ISO 8601 timestamp. Missing timestamps are unavailable; data older than one hour or over five minutes in the future is stale. An `error` string reports a provider error. The surface shows supplied values only and does not derive subscription limits from token counts.
