---
name: recap
description: Writes up the CS concepts behind the current PR's code as short study notes, posted as a PR comment or saved under docs/. Use for /recap or when asked for the CS concepts behind a PR.
argument-hint: "[--target pr|docs|both] [--lang auto|en|ko] [--depth concepts|summary|detailed] [--max N] [--dry-run]"
allowed-tools: Bash(git diff *) Bash(git log *) Bash(git rev-parse *) Bash(git merge-base *)
---

# recap

Write up the CS and engineering knowledge underneath this PR's code.

Do not review the code, summarize the change, or explain API usage. Go one level below the API.
`Promise.all` leads to concurrency vs. parallelism. `invalidateQueries` leads to cache consistency.
`@Transactional` leads to isolation levels.

## Arguments

Read `$ARGUMENTS`. Missing values come from `.dev-knowledge-recap.yml` in the repo root, then the defaults below.

| arg | values | default |
|---|---|---|
| `--target` | `pr`, `docs`, `both` | ask |
| `--lang` | `auto` or a language code | `auto` |
| `--depth` | `concepts`, `summary`, `detailed` | `summary` |
| `--max` | 1 to 5 | 2 |
| `--pr` | number or PR URL | open PR of this branch |
| `--base` | branch | the PR's base, else the default branch |
| `--dry-run` | | off |
| `--auto` | | off. Set by the hook and the GitHub Action |

Config only: `docs_dir` (default `docs/dev-knowledge`), `exclude_paths`, `categories`,
`auto` (default `true`; `false` turns off the hook that runs this after a PR is created).

If no target is set, ask first with three choices: PR comment, docs files, both.

### Automatic runs (`--auto`)

The plugin's hook adds `--auto` right after Claude opens a PR, and the GitHub Action passes it on every push.
- Keep it quiet: no preamble, and a one-line report at the end.
- If no target is set, ask once. Then offer to save the answer as `target` in `.dev-knowledge-recap.yml`
  so later runs do not ask.
- If there is no terminal user to ask (CI), use `pr`.
- If nothing is worth writing, say so in one line and stop.

`auto` language means the language of the PR title and body. With no PR, use English.

## Step 1. Quick checks (main context)

1. Resolve `base` and `head` (`git rev-parse HEAD`).
2. If posting to a PR and its existing comment starts with `<!-- dev-knowledge-recap sha=<head> -->`, stop and say it is already up to date.
3. Run `git diff --stat -w <base>...HEAD`, dropping the default excludes and `exclude_paths`.
   If nothing is left, stop and say there is nothing to write up.
4. Write down up to 5 questions the developer asked in this session, one short line each.
   The subagent in step 2 cannot see this conversation, so this list is the only way it learns them.

Default excludes: lock files, images, fonts, 3D and media assets, `*.import`, generated or vendored code,
minified files, snapshots, tests, Markdown docs, CHANGELOG.

## Step 2. Analyze in a subagent

Start one subagent with the Agent tool (general-purpose, model `sonnet`). Pass it base, head, the options,
the stat output, the question list, `docs_dir`, and the instructions in steps 2a to 2d.
It returns the comment body and the content of each docs file. The diff never enters the main context.
If the Agent tool is not available, do 2a to 2d yourself.

### 2a. Read only what matters
- From the stat and `git log --format=%s <base>..HEAD`, pick at most 5 files likely to hold a concept:
  new dependencies, new APIs, config, infra, concurrency, storage, security.
- Read each with `git diff -U1 -w <base>...HEAD -- <file>`. Stop at 200 lines per file.
- For dedupe, read only `{docs_dir}/README.md`. Never open individual docs files here.

### 2b. Pick concepts
Rank by: asked in the session, first time in the repo, foundational CS, used in several files.
Drop anything with no code to point to. Already in the index means link it, do not rewrite it.
Keep the top `--max`. If nothing is worth it, return nothing. Never pad.

### 2c. Sections
Every section is a bullet list, except trade-offs, which is a table with one or two rows.

| Section | Content | concepts | summary | detailed |
|---|---|---|---|---|
| Concept | 1 or 2 bullets: what it is | yes | yes | yes |
| Principle | 2 or 3 bullets: how it works and how this code uses it | | yes | yes |
| Trade-offs | pros and cons table | | yes | yes |
| Alternatives | up to 2 bullets, `name`: when to use it | | yes | yes |
| Common pitfalls | bullets | | | yes |
| Further reading | official docs or well-known references | | | yes |

`--depth` applies to the PR comment and to docs files alike.

### 2d. Writing style
This matters more than anything else in the output. It must read like a person wrote it.

- Never use middle dots (·), em or en dashes, or arrows (→, ->). Use a comma, a colon, or a new sentence.
- Write full short sentences, one idea per bullet. Explain a term the first time it appears.
- Korean: plain declarative sentences ending in "~다". No noun-form endings like "~됨", "~음", "~필요".
  No "~해요". Keep established terms in English (SIGTERM, write-through).
- English: plain sentences. No marketing tone, no filler.
- No conversational lines, no "you asked", no session transcripts. Remove secrets and internal hostnames.

Bad: `kill -9`(SIGKILL)는 가로챌 수 없음 → 요청 유실, DB 연결 정리 안 됨
Good: `kill -9`는 SIGKILL을 보낸다. 프로세스가 이 신호를 막을 수 없어서 처리 중이던 요청이 끊긴다.

Bad: Fails fast → one rejection rejects all
Good: If one promise rejects, the whole call rejects right away.

## Step 3. Publish (main context)

- `--dry-run`: print only.
- PR: use `templates/pr-comment.md`. The first line is `<!-- dev-knowledge-recap sha=<head> -->`.
  If a comment with this marker exists, edit it. Prefer GitHub MCP tools, then `gh`.
  If both fail, print the body and say how to post it.
- Docs: use `templates/knowledge-doc.md`. A new slug gets a new file. An existing slug only gets the PR added
  under "Seen in this project". Add one line per new concept to `{docs_dir}/README.md` (`templates/index.md`).
  Ask before committing.
- Both: docs first, then link each concept in the comment to its file.
- Read a template only for the target you are writing.

End with a short report: concepts written, files touched, comment link.
