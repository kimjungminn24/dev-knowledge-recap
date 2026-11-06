<!-- dev-knowledge-recap -->
### 📚 Dev knowledge in this PR

`os` `deployment` · 3 concepts

<details>
<summary><b>Signals and graceful shutdown</b> — SIGTERM vs. SIGKILL</summary>
<br>

**Concept**
- A signal is a notification the OS sends to a process
- SIGTERM: clean up and exit. SIGKILL: die immediately

**Principle**
- SIGKILL (`kill -9`) can't be caught → in-flight requests dropped, DB connections left open
- `systemctl restart` sends SIGTERM first → JVM shutdown hooks run
- Killed by signal N → exit code 128 + N. SIGTERM (15) → 143, hence `SuccessExitStatus=143`

**Trade-offs**
| Pros | Cons |
|---|---|
| No half-written state | Slower stop; a hung app still needs SIGKILL |

**Alternatives**
- `server.shutdown=graceful` — finish in-flight requests before exiting
- `TimeoutStopSec` — cap how long a graceful stop may take

<sub>📄 `deploy/pik-one-backend.service` · `.github/workflows/deploy.yml`</sub>
</details>

<details>
<summary><b>Process supervision</b> — keeping a process running</summary>
<br>

...
</details>

<details>
<summary><b>Health checks and rollback</b> — verify after deploy, revert on failure</summary>
<br>

...
</details>

<sub>dev-knowledge-recap · concepts from this PR's diff</sub>
