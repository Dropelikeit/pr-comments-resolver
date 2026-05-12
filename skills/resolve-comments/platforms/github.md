# Platform Module: GitHub

This module is loaded by the orchestrator when the detected platform is `github`. Read it once when dispatched and follow the steps in order.

## Auth verification

Run:
```bash
gh auth status
```

If the CLI is not installed: "Install the GitHub CLI: https://cli.github.com/ — then run `gh auth login`". Then stop.
If installed but not authenticated: "Run `gh auth login`". Then stop.

## Repository identifier

```bash
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```
Format: `<owner>/<repo>`.

## PR number (if not provided by user)

```bash
gh pr view --json number,title --jq '"\(.number) \(.title)"'
```

## Fetch unresolved review threads

Load all review threads via the GraphQL API. The `isResolved` status is only available through GraphQL.

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      title
      url
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          path
          line
          startLine
          comments(first: 50) {
            nodes {
              author { login }
              body
              createdAt
              url
            }
          }
        }
      }
    }
  }
}' -F owner=OWNER -F repo=REPO -F pr=PR_NUMBER
```

Replace `OWNER`, `REPO`, and `PR_NUMBER` with the values from the orchestrator.

Filter: keep only threads where `isResolved` is `false`. Use `isOutdated` to mark `(outdated)` in the display.

## Post reply and resolve thread

To post a reply to a review thread, use `gh api` against the GraphQL `addPullRequestReviewThreadReply` mutation, then call `resolveReviewThread`. Exact mutation calls are looked up at execution time against the installed `gh` version.
