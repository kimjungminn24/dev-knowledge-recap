# dev-knowledge-recap design

## Problem

When AI writes most of the code, it is easy to ship things you do not fully understand.
The PR records what changed. It does not record the knowledge you need to see why it works.

Nearby tools cover other ground.

| Tool | Focus |
|---|---|
| CodeRabbit, PR-Agent, Greptile | Code review and change summaries |
| Copilot | Explaining code on request |
| PR description | What changed and why |

Goal: for each PR, write up the CS and engineering concepts under the code as short study notes.

## Scope

| In | Out |
|---|---|
| Principles below the API: concurrency, cache consistency, isolation levels, indexing | API how-tos |
| Trade-offs and alternatives | Summary of the change |
| Concepts the developer asked about while working with AI | Code review, bugs, style |
| | Basic syntax, renames, boilerplate |

The PR description and the review already cover what changed, so this tool only adds the knowledge layer.
Each note points back to the code with a single file line.

## Flow

```
/dev-knowledge-recap
  1. Quick checks   main context: SHA check, diff stat, session questions
  2. Analyze        subagent: read selected files, pick concepts, write
  3. Publish        main context: PR comment and/or docs files
```

## Options

| Option | Values | Default | Notes |
|---|---|---|---|
| `--target` | `pr`, `docs`, `both` | ask | Asked at run time if not set |
| `--lang` | `auto` or a language code | `auto` | Follows the PR language, English if there is no PR |
| `--depth` | `concepts`, `summary`, `detailed` | `summary` | Same depth for the comment and docs |
| `--max` | 1 to 5 | 2 | |
| `--pr`, `--base` | | current PR, default branch | |
| `--dry-run` | | off | |

Config file `.dev-knowledge-recap.yml`. Arguments win over it.

```yaml
target: docs
lang: en
depth: summary
max: 2
docs_dir: docs/dev-knowledge
exclude_paths: ["**/generated/**"]
categories: [concurrency, caching, databases]
```

## Selection

1. Find the concept below the API. `Promise.all` leads to concurrency vs. parallelism.
2. Drop anything without code in the diff to point to.
3. Rank: asked in the session, first time in the repo, foundational CS, used in several files.
4. If the docs index already has it, link it instead of rewriting it.
5. Keep the top `--max`. If nothing is worth writing, post nothing.

This is a priority order the model follows. Nothing computes a score.

## Output format

Each concept has these sections. All of them are bullet lists except trade-offs.

| Section | Format | concepts | summary | detailed |
|---|---|---|---|---|
| Concept | 1 or 2 bullets | yes | yes | yes |
| Principle | 2 or 3 bullets | | yes | yes |
| Trade-offs | table, 1 or 2 rows | | yes | yes |
| Alternatives | up to 2 bullets, `name`: when | | yes | yes |
| Common pitfalls | bullets | | | yes |
| Further reading | links | | | yes |

In a PR comment each concept is a collapsed `<details>` block. The summary line is the title and a short hook,
so the closed comment reads as a short list.

## Writing style

The first drafts read like AI output, and the Korean was hard to follow. The rules:

- No middle dots, em or en dashes, or arrows. Use commas, colons, or a new sentence.
- Full short sentences, one idea per bullet. Explain a term the first time.
- Korean ends sentences with "~다". No clipped noun endings such as "~됨" or "~음", and no "~해요".
- No conversational lines and no session transcripts.

## Token budget

Measured on real PRs: `SKILL.md` is about 1.5k tokens, a small infra PR diff is about 3k,
and a large game feature diff went past 15k. Reading the diff is the main cost, so most savings come from there.

| Where | How |
|---|---|
| Skip the run | Stop if the comment marker already has the current head SHA. Stop if only docs, assets or tests changed |
| Read less diff | Start from `--stat` and commit subjects, then read at most 5 files with `-U1 -w`, 200 lines each |
| Excludes | Lock files, assets, generated code, tests and Markdown are skipped by default |
| Dedupe | Read only the docs index, never the individual docs files |
| Main context | Analysis runs in a subagent on `sonnet`, so the diff never enters the main conversation |
| Output | `--max` defaults to 2. Docs use the same depth as the comment |
| Loading | Short frontmatter description. Templates are skeletons and only the one for the target is read |

Why not `context: fork`: a forked skill does not see the current conversation, so it would lose the questions
the developer asked. The skill stays in the main context long enough to write those down, then hands off to a subagent.

## Storage

PR comment
- First line `<!-- dev-knowledge-recap sha=<head> -->`. Reruns edit this comment.
- GitHub MCP first, then `gh`, then print the body for manual posting.

Docs
```
docs/dev-knowledge/
  README.md                       index, one line per concept
  graceful-shutdown.md
  health-check-rollback.md
```
- One file per concept, not per PR, so the folder grows into a CS notebook for the project.
- An existing slug only gets the new PR added under "Seen in this project".
- Changes stay in the working tree. The user decides whether to commit.

## Edge cases

| Case | Behavior |
|---|---|
| No open PR | Offer docs or a dry run |
| No session questions | Work from the diff alone |
| Very large diff | Read only the 5 most relevant files |
| Nothing worth writing | Post nothing |
| No GitHub access | Print the comment body |

## Roadmap

- v0.1: skill, PR and docs targets, depth levels, language detection, SHA marker
- v0.2: config file, examples from real PRs
- v0.3: GitHub Action that runs on PR open from the diff alone
