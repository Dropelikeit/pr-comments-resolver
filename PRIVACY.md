# Privacy Policy

_Last updated: 2026-04-21_

This document describes how the **pr-comments-resolver** Claude Code plugin handles data.

## Overview

pr-comments-resolver is a client-side Claude Code skill plugin. It runs entirely within your local Claude Code session and does not operate any servers, telemetry endpoints, or hosted services of its own.

## Data the Plugin Accesses

When you invoke the `/resolve-comments` skill, Claude Code may access the following on your behalf:

- **Git repository metadata** — the remote URL of the current repository (via `git remote get-url origin`) to detect the hosting platform.
- **Pull request / merge request data** — review comments, threads, diffs, and related metadata fetched through the `gh` (GitHub CLI) or `glab` (GitLab CLI) tools installed on your machine.
- **Local source files** — files in the current working directory that need to be read or modified to address review feedback.
- **Claude Code project memory** — a small configuration value (`pr-comments-resolver-platform`) stored locally to remember the detected platform between sessions.

## Data the Plugin Does Not Collect

The plugin itself:

- Does **not** collect, transmit, or store any personal data.
- Does **not** contain analytics, tracking, or phone-home functionality.
- Does **not** send data to the plugin author or any third party.

## Third-Party Services

The skill orchestrates the following third-party tools, each governed by their own privacy policies:

- **Anthropic Claude** — processes the conversation and code. See Anthropic's [Privacy Policy](https://www.anthropic.com/legal/privacy).
- **GitHub CLI (`gh`)** — communicates with GitHub on your behalf. See GitHub's [Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement).
- **GitLab CLI (`glab`)** — communicates with GitLab on your behalf. See GitLab's [Privacy Statement](https://about.gitlab.com/privacy/).

Authentication credentials for these tools are managed by the tools themselves and never handled directly by this plugin.

## Data You Send to Claude

To address review comments, Claude needs to read the contents of review threads and the relevant source files. This content is transmitted to Anthropic's API as part of the normal Claude Code operation. Review what is sent if your repository contains sensitive material.

## Your Control

You can at any time:

- Uninstall the plugin to stop all access by this skill.
- Revoke `gh` / `glab` authentication via those tools.
- Delete the locally stored platform memory entry.

## Contact

Questions about this plugin's privacy practices can be directed to the maintainer via the repository's [issue tracker](https://github.com/Dropelikeit/pr-comments-resolver/issues).
