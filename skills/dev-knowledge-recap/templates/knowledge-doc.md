---
slug: graceful-shutdown
title: Signals and graceful shutdown
category: os
aliases: [SIGTERM, SIGKILL, kill -9, exit code 143]
created: 2026-11-06
updated: 2026-11-06
---

# Signals and graceful shutdown

## Concept
- A signal is a notification the OS sends to a process
- SIGTERM: clean up and exit. SIGKILL: die immediately

## Principle
- SIGKILL can't be caught or ignored; the kernel ends the process
- SIGTERM can be handled: the JVM runs shutdown hooks, Spring closes pools and finishes work
- Exit code after a fatal signal is 128 + N (SIGTERM 15 -> 143, SIGKILL 9 -> 137)

## Trade-offs
| Pros | Cons |
|---|---|
| No half-written state | Slower stop; a hung app still needs SIGKILL |

## Alternatives
- `server.shutdown=graceful`: finish in-flight requests before exiting
- `TimeoutStopSec`: cap how long a graceful stop may take

## Common pitfalls
- Using `kill -9` by default in deploy scripts
- Treating exit code 143 as a crash in monitoring

## Further reading
- `man 7 signal`
- Spring Boot docs: Graceful Shutdown

## Seen in this project
- #209 — `deploy/pik-one-backend.service`
