### MCP Config Writer

When a platform module needs to add an MCP server entry, follow this procedure exactly. Do not silently overwrite existing configuration.

**Target file selection.** Ask the user where to write the config:

- User scope: `~/.claude.json` (default)
- Project scope: `.mcp.json` in the repository root

Use the AskUserQuestion helper.

**Procedure:**

1. Read the target file. If it does not exist, treat the starting content as `{"mcpServers": {}}`.
2. If `mcpServers.<id>` does not exist: insert the new entry and write the file back. Inform the user where the entry was added.
3. If `mcpServers.<id>` already exists:
   1. Compute the diff between the existing entry and the entry we intend to write.
   2. If identical: no-op. Inform the user "MCP entry already present and matches; nothing to write."
   3. If different: show the diff to the user and ask via AskUserQuestion: `Overwrite` / `Keep existing` / `Abort`. Apply the chosen action.

**Secret handling.**

- Never write a token literal into the config. Use `${ENV_VAR_NAME}` placeholders in the `env` section.
- Verify the named env variable is set in the current shell environment before writing. If unset, instruct the user to add it to their shell profile (e.g. `export AZURE_DEVOPS_PAT=...` in `~/.zshrc`), then stop the skill until they confirm.

**Restart notice.**

After writing, tell the user: "MCP server configured. Restart Claude Code to load the new server. Re-run `/resolve-comments` afterwards." Stop the skill in this session.
