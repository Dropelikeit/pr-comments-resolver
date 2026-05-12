Persist platform info in `.junie/AGENTS.md` under a `## Project Memory` section:

~~~markdown
## Project Memory

- pr-comments-resolver-platform: <github|gitlab|bitbucket|azure>
- pr-comments-resolver-auth: <cli|mcp>
- pr-comments-resolver-cli: <gh|glab|acli|az>          # only when auth = cli
- pr-comments-resolver-mcp: <ado|atlassian>            # only when auth = mcp
- pr-comments-resolver-token-env: $<ENV_VAR_NAME>      # only for PAT-based MCP (azure)
- pr-comments-resolver-org: <name>                     # bitbucket workspace or azure organization
- pr-comments-resolver-repo: <owner/repo>
~~~

Entries missing `pr-comments-resolver-auth` from older runs are treated as `cli`.
