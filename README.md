# dev-knowledge-recap

A Claude Code skill that writes up the CS concepts behind a PR's code: what the concept is, how it works,
its trade-offs, and alternatives. The notes go to a PR comment, to Markdown files under `docs/`, or both.

It does not review code or summarize the change. If a PR swaps `kill -9` for a systemd restart,
you get a note on signals and graceful shutdown, not a list of what changed.

I built it for the case where AI wrote most of the code and I still want to understand what is underneath.

## Usage

```
/dev-knowledge-recap
/dev-knowledge-recap --target docs --depth detailed
```

| Option | Values | Default |
|---|---|---|
| `--target` | `pr`, `docs`, `both` | asks |
| `--lang` | `auto` or a language code | language of the PR, else English |
| `--depth` | `concepts`, `summary`, `detailed` | `summary` |
| `--max` | 1 to 5 | 2 |
| `--dry-run` | | off |

Defaults can live in `.dev-knowledge-recap.yml` at the repo root.

Docs go to `docs/dev-knowledge/<topic>.md`. When a topic shows up again in a later PR,
the existing file gets the PR added to it instead of a new file.

## Example

From a deploy PR that moved the backend to systemd and added a health check with rollback.
Each concept is collapsed by default.

<img src="docs/images/collapsed.png" width="600">

<img src="docs/images/expanded.png" width="600">

## Install

Copy `skills/dev-knowledge-recap/` into `.claude/skills/` in your project, or into `~/.claude/skills/`.

## Design

[docs/DESIGN.md](docs/DESIGN.md)
