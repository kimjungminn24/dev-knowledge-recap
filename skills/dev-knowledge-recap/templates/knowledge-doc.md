---
slug: concurrency-vs-parallelism
title: Concurrency vs. Parallelism
category: concurrency
aliases: [event loop, Promise.all]
created: 2026-11-06
updated: 2026-11-06
---

# Concurrency vs. Parallelism

## Principle
- Concurrency: tasks overlap in time by interleaving. Parallelism: tasks run simultaneously on separate cores.
- JS has a single call stack. I/O is delegated to the runtime (libuv / browser); completed work is queued and the event loop runs callbacks when the stack is empty.
- So concurrent I/O cuts wall-clock time, but CPU-bound JS still runs one piece at a time.

## Trade-offs
| Pros | Cons |
|---|---|
| Lower latency for independent I/O | `Promise.all` is fail-fast |
| No shared-memory races between JS code | Long sync work blocks everything |

## Alternatives
| Option | Use when |
|---|---|
| Sequential `await` | Steps depend on each other |
| `Promise.allSettled` | Partial failure is acceptable |
| Concurrency limit (`p-limit`) | Large fan-out |
| Worker threads / Web Workers | CPU-bound work |

## Common pitfalls
- `await` inside a `for` loop serializes requests that could overlap.
- Unbounded `Promise.all` over thousands of items can exhaust sockets or hit rate limits.

## Further reading
- MDN: Event loop
- Rob Pike, "Concurrency is not Parallelism"

## Seen in this project
- #128 — `src/api/user.ts`
