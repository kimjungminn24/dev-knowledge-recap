---
name: dev-knowledge-recap
description: Pick out the CS and software engineering concepts underlying the current branch's changes (diff + AI session context) and write them up as structured study notes - principle, trade-offs, alternatives - as a PR comment and/or Markdown files under docs/. Use when the user runs /dev-knowledge-recap or asks for the dev knowledge behind a PR.
---

# dev-knowledge-recap

Write up the **CS / engineering knowledge underneath this PR's code**.

This is NOT:
- a code review
- a summary of what changed (that's the PR description's job)
- API usage docs ("call `Promise.all` with an array…")

Go one level below the API: `Promise.all` -> concurrency vs. parallelism, event loop.
`invalidateQueries` -> cache consistency strategies. `@Transactional` -> isolation levels.

## Arguments

Parse `$ARGUMENTS`. Missing values fall back to `.dev-knowledge-recap.yml` in the repo root, then to defaults.

| arg | values | default |
|---|---|---|
| `--target` | `pr` \| `docs` \| `both` | ask |
| `--lang` | any language code (`en`, `ko`, `ja`, …) | `auto` |
| `--depth` | `concepts` \| `summary` \| `detailed` | `summary` |
| `--pr` | number | open PR of current branch |
| `--base` | branch | repo default branch |
| `--max` | 1–10 | 3 |
| `--dry-run` | flag | off |

Config-only keys: `docs_dir` (default `docs/dev-knowledge`), `exclude_paths`, `categories`.

**Target.** If neither the args nor the config set it, ask before doing anything else
(use AskUserQuestion if available): `pr` (PR comment), `docs` (Markdown files under `docs_dir`), `both`.

**Language.** `auto` = the language of the PR title/body; if there is no PR or it's unclear, English.
Translate section headings too. Keep code identifiers and established terms (e.g. "write-through") as-is.

## Procedure

### 1. Collect
- `git diff <base>...HEAD`, skipping lock files, generated code, binaries and `exclude_paths`.
- `git log <base>..HEAD`.
- Questions the developer asked in this session ("why…", "what is…"), if any.
- `{docs_dir}/README.md` index, if it exists.

### 2. Find the underlying concepts
For each meaningful construct in the diff, ask "what CS / engineering principle makes this work or matter?"
Record `slug`, `title`, `category`, `seen_in` (file paths from the diff).
Drop anything with no code in the diff to point to.

Categories: `concurrency`, `caching`, `data-structures`, `algorithms`, `databases`, `networking`,
`os`, `security`, `type-systems`, `design-patterns`, `architecture`, `testing`.

### 3. Select
Skip: API how-tos, renames/formatting, boilerplate, basic syntax, and anything describing the change itself.

Rank by:
1. the developer asked about it in this session
2. first time the concept appears in the repo
3. foundational CS (the kind of thing asked in interviews)
4. used across several files

Already in docs -> don't rewrite it; in the PR comment, link to the existing doc.
Keep the top `--max`. If nothing worthwhile is left, publish nothing and say so. Never pad.

### 4. Write
Notes, not prose. No conversational tone, no "you asked…", no session transcripts.
Use `templates/pr-comment.md` and `templates/knowledge-doc.md`.

| depth | per concept |
|---|---|
| `concepts` | name + one-line definition |
| `summary` | Principle (2–4 bullets), Trade-offs (pros/cons), Alternatives (table) |
| `detailed` | summary + Common pitfalls + Further reading (official docs / well-known references only) |

Docs files are always written at `detailed` depth; `--depth` applies to the PR comment.
Strip secrets, tokens and internal hostnames.

### 5. Publish
- `--dry-run`: print only.
- **pr**: the body starts with `<!-- dev-knowledge-recap -->`. If a comment with that marker already
  exists on the PR, edit it instead of posting a new one. Prefer GitHub MCP tools, then `gh`.
  If both fail, print the body and say how to post it.
- **docs**: create `{docs_dir}/{slug}.md`, or for an existing slug append the PR to "Seen in this project".
  Update `{docs_dir}/README.md`. Ask before committing.
- **both**: docs first, then link each concept in the comment to its doc.

End with a short report: concepts written, files touched, comment URL.
