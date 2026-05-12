Augment reads `AGENTS.md` for project guidelines. To persist platform info across runs, add a `## pr-comments-resolver` section (or place these lines in `AGENTS.local.md` if you want to keep them out of version control):

```
## pr-comments-resolver

- platform: <github|gitlab|bitbucket|azure>
- auth-method: <cli|mcp>
- cli-tool: <gh|glab|acli|az>        # only when auth-method = cli
- mcp-server: <ado|atlassian>        # only when auth-method = mcp
- token-env-var: $<ENV_VAR_NAME>     # only when MCP auth uses a PAT
- org-or-workspace: <name>           # bitbucket workspace or azure organization
- repository: <platform-native identifier>
```

Memories without `auth-method` from older runs are treated as `auth-method: cli`.
