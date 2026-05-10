Roo loads `AGENTS.md` and `AGENTS.local.md` as rules. To persist platform info across runs, add a one-line entry to `AGENTS.local.md` (gitignored by default):

```
pr-comments-resolver-platform: <github|gitlab>
```
