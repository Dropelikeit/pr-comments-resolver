### MCP Config Writer

This adapter does not currently include automatic MCP server configuration support. If a platform module requires MCP setup (Bitbucket MCP via Atlassian Remote, or Azure DevOps MCP via `@azure-devops/mcp`), instruct the user how to configure their host manually:

- Show the user the MCP server entry the platform module wants to add (server id, command, args, and env-var-reference env block).
- Tell them to add it to their adapter's MCP configuration (e.g., Codex / Augment / Junie / Roo configuration file — exact path depends on the user's setup).
- Remind them: never paste a literal PAT into the config. Use the env-variable reference exactly as shown.
- Ask them to confirm when done, then stop and tell them to restart their agent.
