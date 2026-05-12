Roo loads `AGENTS.md` and `AGENTS.local.md` as rules. To persist platform info across runs, add a `## pr-comments-resolver` block to `AGENTS.local.md` (gitignored by default):

```
## pr-comments-resolver

- platform: <github|gitlab|bitbucket|azure>
- auth-method: <cli|mcp>
- cli-tool: <gh|glab|acli|az>        # only when auth-method = cli
- mcp-server: <ado|atlassian>        # only when auth-method = mcp
- token-env-var: $<ENV_VAR_NAME>     # only when MCP auth uses a PAT
- org-or-workspace: <name>           # bitbucket workspace or azure organization
- repository: <platform-native identifier>
- reply-resolve-permission: <a|b|c>  # a = post & resolve, b = post only, c = none
```

Entries missing `auth-method` from older runs are treated as `cli`. Entries missing `reply-resolve-permission` trigger the one-time Step 4.0 prompt.
