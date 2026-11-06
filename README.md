# dev-knowledge-recap

A Claude Code skill that writes up the CS and engineering concepts behind a PR's code: the principle, trade-offs and alternatives. Output goes to a PR comment, Markdown files under `docs/`, or both.

It doesn't review the code or summarize the change. If a PR adds `Promise.all`, you get a note on concurrency vs. parallelism and the event loop, not a description of what `Promise.all` does.

Built for the case where AI wrote most of the code and you want to understand what's underneath it.

## Usage

```
/dev-knowledge-recap
/dev-knowledge-recap --target docs --depth detailed
```

| Option | Values | Default |
|---|---|---|
| `--target` | `pr`, `docs`, `both` | asks |
| `--lang` | any language code | language of the PR, else `en` |
| `--depth` | `concepts`, `summary`, `detailed` | `summary` |
| `--max` | 1–10 | 3 |
| `--dry-run` | | off |

Defaults can be set in `.dev-knowledge-recap.yml` at the repo root.

Docs go to `docs/dev-knowledge/<topic>.md`. When a topic shows up again in a later PR, the existing file gets the PR added to it instead of a new file being created.

## Example

From a real deploy PR (systemd, health checks, rollback). Collapsed by default:

<img src="docs/images/collapsed.png" width="600">

Expanded:

<img src="docs/images/expanded.png" width="600">

Templates: [`templates/pr-comment.md`](skills/dev-knowledge-recap/templates/pr-comment.md) and [`templates/knowledge-doc.md`](skills/dev-knowledge-recap/templates/knowledge-doc.md).

## Install

Copy `skills/dev-knowledge-recap/` into your project's `.claude/skills/` (or `~/.claude/skills/`).

## Design

[docs/DESIGN.md](docs/DESIGN.md)
