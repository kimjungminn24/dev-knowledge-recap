---
name: dev-knowledge-recap
description: Extract development knowledge that reviewers and teammates should know from the current branch's changes (diff + AI session context) and publish it as a PR comment and/or docs/dev-knowledge Markdown files. Use when the user runs /dev-knowledge-recap or asks to summarize the dev concepts used in a PR.
---

# dev-knowledge-recap

Goal: leave the **development concepts actually used in this PR** for the people who read the PR.
This is NOT a code review and NOT a change summary.

## Arguments

Parse `$ARGUMENTS`. Missing values fall back to `.dev-knowledge-recap.yml` in the repo root, then to defaults.

| arg | values | default |
|---|---|---|
| `--target` | `pr` \| `docs` \| `both` | `pr` |
| `--lang` | `ko` \| `en` | `ko` |
| `--depth` | `detailed` \| `summary` \| `concepts` | `summary` |
| `--pr` | number | open PR of current branch |
| `--base` | branch | repo default branch |
| `--max` | 1–10 | 5 |
| `--dry-run` | flag | off |

Config-only keys: `docs_dir` (default `docs/dev-knowledge`), `exclude_paths`, `categories`.

## Procedure

### 1. Collect
- `git diff <base>...HEAD` (skip lock files, generated code, binaries, `exclude_paths`).
- `git log <base>..HEAD --format='%s%n%b'`.
- Questions the developer asked in this session ("why…", "what is…"), if any.
- PR title/body if a PR exists.
- `{docs_dir}/README.md` index, if it exists.

### 2. Extract candidates
Look for: new imports/dependencies, newly introduced APIs or syntax, structural/pattern changes,
config changes (cache, timeout, security), and topics the developer asked about.
For each candidate record: `slug`, `title`, `category`, `evidence` (file:line in the diff), `why_here`.
**Drop any candidate without evidence in the diff.**

Categories: `library-api`, `architecture`, `async`, `caching`, `state`, `security`, `performance`, `types`, `background`.

### 3. Filter and score
Exclude: renames, formatting, typo fixes, boilerplate CRUD, basic language syntax.

Score: asked in session +3 · first appearance in repo +2 · security/performance +2 ·
used across multiple files +1 · has a real pitfall +1 · already in docs −2.

Keep the top `--max`. If nothing meaningful remains, publish nothing and tell the user so. Never pad.

### 4. Dedupe against docs
Match by slug or `aliases` in existing docs. If found: do not create a new file; append to
`## 관련 PR` / `## Related PRs` and, if there's a new project-specific angle, to `## 프로젝트 사례` / `## In this project`.
In the PR comment, link to the existing doc.

### 5. Render
- Reader is the reviewer. No "you asked…" phrasing. Do not paste session transcripts.
- Each concept must include a "이 PR에서는 / In this PR" sentence pointing to the evidence file.
- Depth: `concepts` = one line; `summary` = 2–3 sentences; `detailed` = + pitfalls, alternatives, references.
- Strip secrets, tokens, internal hostnames.
- Use `templates/pr-comment.md`, `templates/knowledge-doc.md`, `templates/index.md`.

### 6. Publish
- `--dry-run`: print output only.
- **PR**: body starts with `<!-- dev-knowledge-recap -->`. If a comment with that marker already exists on the PR,
  update it instead of creating a new one. Prefer GitHub MCP tools, then `gh`. On failure, print the body and explain how to post it.
- **Docs**: write `{docs_dir}/{slug}.md` and update `{docs_dir}/README.md`. Ask the user before committing.
- **Both**: do docs first, then link each concept in the PR comment to its doc.

Finish with a short report: concepts published, files touched, comment URL.
