# dev-knowledge-recap — Design

## Problem

When AI writes most of the code, it's easy to ship things you don't fully understand. The PR records *what* changed, but not the knowledge needed to understand *why it works*.

Existing tools cover nearby ground but not this:

| Tool | Focus |
|---|---|
| CodeRabbit, PR-Agent, Greptile | Code review, change summaries |
| Copilot | Explaining code on request |
| PR description | What changed and why |

**Goal:** for each PR, write up the CS / engineering concepts underneath the code as short, structured study notes.

## Scope

| In | Out |
|---|---|
| Principles below the API (concurrency, cache consistency, isolation levels, indexing…) | API how-tos |
| Trade-offs and alternatives | Summary of the change |
| Concepts the developer asked about while working with AI | Code review, bugs, style |
| | Basic syntax, renames, boilerplate |

The PR description and review already cover what changed. This tool only adds the knowledge layer, so the two don't overlap. Each note points back to the code with a single "Seen in `<file>`" line.

## Flow

```
/dev-knowledge-recap
  1. Collect   diff, commits, session questions, existing docs index
  2. Find      the principle under each meaningful construct
  3. Select    rank, cap at --max, drop if nothing worthwhile
  4. Write     notes: principle / trade-offs / alternatives
  5. Publish   PR comment and/or docs files
```

## Options

| Option | Values | Default | Notes |
|---|---|---|---|
| `--target` | `pr` / `docs` / `both` | ask | Asked at run time if not set in args or config |
| `--lang` | any language code | `auto` | `auto` follows the PR's language, falls back to English |
| `--depth` | `concepts` / `summary` / `detailed` | `summary` | Applies to the PR comment; docs are always `detailed` |
| `--max` | 1–10 | 3 | |
| `--pr`, `--base` | | current PR / default branch | |
| `--dry-run` | | off | |

Config file `.dev-knowledge-recap.yml` (args win):

```yaml
target: docs
lang: en
depth: summary
max: 3
docs_dir: docs/dev-knowledge
exclude_paths: ["**/*.lock", "**/generated/**"]
categories: [concurrency, caching, databases]
```

### Why `--lang` stays

Primary audience is English-speaking, but teams write PRs in their own language. `auto` handles most cases with no flag; `--lang` is there to override. Section headings are translated; code identifiers and established terms are not.

## Selection

1. Find the concept *below* the API. `Promise.all` -> concurrency vs. parallelism. `invalidateQueries` -> cache consistency. `@Transactional` -> isolation levels.
2. Drop anything without code in the diff to point to.
3. Rank:
   1. asked about in the session
   2. first appearance in the repo
   3. foundational CS (interview-level)
   4. used across several files
4. Already documented -> link, don't rewrite.
5. Keep the top `--max`. Nothing worthwhile -> post nothing.

No numeric scoring. It's a priority order the model follows, not something code computes.

## Output format

Notes, not prose. Each concept:

| Section | Format | `concepts` | `summary` | `detailed` |
|---|---|---|---|---|
| Concept | 1–2 bullets | ✓ | ✓ | ✓ |
| Principle | 2–3 bullets | | ✓ | ✓ |
| Trade-offs | pros / cons table, 1–2 rows | | ✓ | ✓ |
| Alternatives | up to 2 bullets, `name`: when | | ✓ | ✓ |
| Common pitfalls | bullets | | | ✓ |
| Further reading | links | | | ✓ |

PR comments are collapsed by default: each concept is a `<details>` block whose summary line is the title plus a one-line hook. Closed, the comment is a 3-line list; reviewers open what they care about.

Examples: [`pr-comment.md`](../skills/dev-knowledge-recap/templates/pr-comment.md), [`knowledge-doc.md`](../skills/dev-knowledge-recap/templates/knowledge-doc.md).

## Storage

**PR comment**
- Starts with `<!-- dev-knowledge-recap -->`; reruns edit the existing comment.
- GitHub MCP, then `gh`, then print the body for manual posting.

**Docs**
```
docs/dev-knowledge/
├── README.md                       index by category
├── concurrency-vs-parallelism.md
└── cache-consistency.md
```
- Files are per concept, not per PR, so they build up into a CS notebook for the project.
- Existing slug or alias -> append the PR to "Seen in this project" instead of creating a file.
- Changes stay in the working tree; the user decides whether to commit.

## Edge cases

| Case | Behavior |
|---|---|
| No open PR | `pr` target -> offer `docs` or `--dry-run` |
| No session context | Work from the diff alone |
| Very large diff | Focus on the most-changed files |
| Nothing worth writing | Post nothing |
| No GitHub access | Print the comment body |

## Roadmap

- v0.1 — skill, PR/docs/both, depth levels, language auto-detect, marker-based updates
- v0.2 — config file, `examples/` with real diffs
- v0.3 — GitHub Action (diff-only, runs on PR open)
