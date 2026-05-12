After successful detection and CLI verification (and, for bitbucket/azure, auth-method selection), save a project memory:

~~~markdown
---
name: pr-comments-resolver-platform
description: Detected hosting platform, auth method, and identifier for this repository
type: project
---

Platform: <github|gitlab|bitbucket|azure>
Auth method: <cli|mcp>
CLI tool: <gh|glab|acli|az>           # only when Auth method = cli
MCP server id: <ado|atlassian>        # only when Auth method = mcp
Token env var: $<ENV_VAR_NAME>        # only when MCP auth uses a PAT (e.g. azure mcp); omit for OAuth (atlassian) and all cli paths
Org / Workspace: <name>               # bitbucket workspace or azure organization; omit for github/gitlab
Repository: <platform-native identifier>
Reply/Resolve permission: <a|b|c>     # a = post & resolve, b = post only, c = none
~~~

> Back-compat: memories saved by older versions of this skill may lack `Auth method`. When that field is missing, treat it as `cli`.
>
> Back-compat: memories without `Reply/Resolve permission` trigger the one-time Step 4.0 prompt.
