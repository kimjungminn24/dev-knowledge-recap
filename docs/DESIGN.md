# dev-knowledge-recap 설계 문서

> AI와 함께 개발한 PR에서 **리뷰어·팀원도 알아두면 좋은 개발 지식**만 골라
> PR 댓글 또는 `docs/` 지식 베이스로 남기는 Claude Code Skill

---

## 1. 문제 정의

| 기존 방식 | 한계 |
|---|---|
| AI와의 Q&A 기록 | 질문한 사람 관점의 로그. 리뷰어에게는 맥락이 없음 |
| AI 코드 리뷰 (CodeRabbit, PR-Agent, Greptile) | "무엇이 바뀌었나 / 무엇이 잘못됐나"에 집중 |
| PR 설명(description) | 변경 요약 위주. "왜 이 기술을 썼는지"는 빠지기 쉬움 |

**목표:** PR을 "코드 변경 기록"에서 **"개발 지식이 쌓이는 공간"**으로 확장한다.

### 핵심 원칙

1. **Grounded** — 모든 개념은 이 PR의 diff에서 실제로 사용된 근거(파일·라인)가 있어야 한다.
2. **Selective** — 많이 쓰는 게 아니라 덜 쓰는 것이 품질이다. 기본 최대 5개.
3. **Reviewer-first** — 질문한 사람이 아니라 *PR을 읽는 사람*이 독자다.
4. **Accumulative** — Docs에 저장된 지식은 중복 없이 누적·갱신된다.

### Non-goals

- 코드 리뷰(버그 지적, 스타일 피드백)를 하지 않는다.
- PR 변경 사항 요약을 하지 않는다 (PR description의 역할).
- 일반적인 프로그래밍 튜토리얼을 쓰지 않는다.

---

## 2. 사용 흐름

```
개발자 ── AI와 작업 ("Promise.all 왜 써?", "캐싱 왜 안 돼?")
   │
   ▼
/dev-knowledge-recap --target both --lang ko --depth summary
   │
   ├─▶ 1. Collect   : diff + 커밋 + 세션 대화 수집
   ├─▶ 2. Extract   : 후보 개념 추출
   ├─▶ 3. Filter    : 선별 기준 + 점수화 → 상위 N개
   ├─▶ 4. Dedupe    : docs/dev-knowledge/ 기존 지식과 대조
   ├─▶ 5. Render    : 언어·깊이에 맞게 작성
   └─▶ 6. Publish   : PR 댓글 작성/갱신, docs 파일 생성/갱신
```

---

## 3. 옵션

```
/dev-knowledge-recap [--target pr|docs|both] [--lang ko|en]
                     [--depth detailed|summary|concepts]
                     [--pr <번호>] [--base <브랜치>] [--max <N>] [--dry-run]
```

| 옵션 | 값 | 기본값 | 설명 |
|---|---|---|---|
| `--target` | `pr` / `docs` / `both` | 실행 시 선택 | 저장 위치 |
| `--lang` | `ko` / `en` | `ko` | 출력 언어 |
| `--depth` | `detailed` / `summary` / `concepts` | `summary` | 설명 깊이 |
| `--pr` | 번호 | 현재 브랜치의 열린 PR | 대상 PR |
| `--base` | 브랜치 | 기본 브랜치 | diff 기준 |
| `--max` | 1–10 | `5` | 최대 개념 수 |
| `--dry-run` | — | off | 게시하지 않고 결과만 출력 |

### 저장 위치 선택

`--target`을 안 주고 설정 파일에도 없으면, 실행할 때 어디에 남길지 먼저 물어본다.

```
어디에 기록할까요?
  1) PR 댓글   - 리뷰어와 공유
  2) Docs (md) - docs/dev-knowledge/ 에 저장
  3) 둘 다
```

매번 묻는 게 귀찮으면 `.dev-knowledge-recap.yml`에 `target`을 적어두면 된다.
(예: 개인 프로젝트는 `both`, 팀 프로젝트는 `docs`)

### 역할 구분

| Target | 역할 | 독자 |
|---|---|---|
| **PR Comment** | 공유용 — 리뷰 중 개념 확인 | 현재 리뷰어 |
| **Docs** | 기록용 — 검색·온보딩 자료 | 미래의 팀원 |
| **Both** | 둘 다. PR 댓글에서 docs 문서로 링크 | 모두 |

### 깊이(depth)별 출력

| depth | 개념당 분량 | 포함 항목 |
|---|---|---|
| `concepts` | 1줄 | 제목 + 키워드 |
| `summary` | 2–3문장 | 제목, 이 PR에서 쓴 이유, 핵심 설명 |
| `detailed` | 1–2문단 | 위 + 주의점(pitfall), 대안, 참고 링크, 코드 근거 |

### 프로젝트 설정 파일 (선택)

루트의 `.dev-knowledge-recap.yml`이 있으면 기본값으로 사용한다. CLI 인자가 우선.

```yaml
target: both
lang: ko
depth: summary
max: 5
docs_dir: docs/dev-knowledge
exclude_paths:
  - "**/*.lock"
  - "**/generated/**"
categories:          # 팀이 관심 있는 카테고리만 (생략 시 전체)
  - async
  - caching
  - security
```

---

## 4. 파이프라인 상세

### 4.1 Collect — 입력 수집

| 소스 | 수집 방법 | 용도 |
|---|---|---|
| Diff | `git diff <base>...HEAD` | **근거의 1차 소스** (필수) |
| 커밋 메시지 | `git log <base>..HEAD` | 의도 파악 |
| 세션 대화 | 현재 Claude Code 대화 맥락 | "개발자가 궁금해한 것" 신호 |
| PR 메타 | GitHub (제목, 본문) | 맥락 보강 |
| 기존 지식 | `docs/dev-knowledge/README.md` 인덱스 | 중복 제거 |

- `exclude_paths`, lock 파일, 생성 코드, 바이너리는 제외.
- 세션 대화가 없어도(예: 다른 세션에서 실행) diff만으로 동작해야 한다.

### 4.2 Extract — 후보 개념 추출

diff에서 다음 신호를 찾아 후보 목록을 만든다.

- 새로 추가된 import / 의존성 (`package.json`, `build.gradle` 등)
- 새로 등장한 API·문법 (`Promise.all`, `useMemo`, `@Transactional`, `AbortController` …)
- 구조적 변화 (레이어 추가, 패턴 도입, 인터페이스 분리)
- 설정 변경 (캐시 TTL, 타임아웃, CORS, 보안 헤더)
- 세션에서 개발자가 "왜?"라고 물었던 주제

후보 카드 스키마:

```yaml
slug: promise-all              # kebab-case, docs 파일명
title: Promise.all을 사용하는 이유
category: async                # 아래 카테고리 중 하나
evidence:                      # 필수. 없으면 폐기
  - src/api/user.ts:42
why_here: 사용자·권한 조회를 병렬로 처리하기 위해
signals: [new_api, asked_in_session]
```

### 4.3 Filter — 선별 기준

**포함 (Include)**

| 카테고리 | 예시 |
|---|---|
| `library-api` | 새 라이브러리/API 사용법 |
| `architecture` | 설계 패턴, 레이어 결정 |
| `async` | 병렬/순차 처리, 동시성, 취소 |
| `caching` | 캐시 전략, 무효화, 일관성 |
| `state` | 상태 관리, 불변성 |
| `security` | 인증·인가, 입력 검증, 시크릿 처리 |
| `performance` | 복잡도, N+1, 메모이제이션 |
| `types` | 타입 안정성, 제네릭, 스키마 검증 |
| `background` | 변경을 이해하는 데 필요한 배경지식 |

**제외 (Exclude)**

- 변수명 변경, 포맷팅, 오타 수정
- 단순 CRUD·보일러플레이트
- 언어 기초 문법 (`for`, `if`, `const` …)
- diff에 근거가 없는 개념
- 이미 docs에 있고 이번 PR에서 새로운 맥락이 없는 개념 (PR 댓글에서는 링크만)

**점수화** — 후보마다 합산 후 상위 `--max`개 선택

| 신호 | 점수 |
|---|---|
| 세션에서 개발자가 질문함 | +3 |
| 레포에 처음 등장 (기존 코드에 없음) | +2 |
| security / performance 카테고리 | +2 |
| 여러 파일에 걸쳐 사용 | +1 |
| 잘못 쓰면 버그로 이어지는 개념 (pitfall 존재) | +1 |
| 기존 docs에 이미 존재 | −2 |

점수가 낮아 하나도 안 남으면 **아무것도 게시하지 않고** "이번 PR에는 정리할 개념이 없어요"로 종료한다. (억지로 채우지 않는다.)

### 4.4 Dedupe — 중복 관리

- `docs/dev-knowledge/README.md` 인덱스(slug ↔ 제목 ↔ 별칭)로 매칭.
- slug 일치 또는 별칭 일치 시 기존 문서로 간주.
- 기존 문서가 있을 때:
  - 새 파일을 만들지 않는다.
  - `## 관련 PR` 섹션에 이번 PR 링크 + 한 줄 맥락을 추가한다.
  - 이번 PR에서 새로운 관점(pitfall 등)이 있으면 `## 프로젝트 사례`에 추가.

### 4.5 Render — 작성 규칙

- 독자는 리뷰어. "당신이 질문한…" 같은 1인칭 대화체 금지.
- 개념마다 **"이 PR에서는"** 문장으로 코드와 연결.
- 근거 파일은 PR의 해당 파일 링크로.
- 세션 대화 원문을 그대로 붙이지 않는다 (사적 맥락·시크릿 유출 방지).
- 토큰, 키, 내부 호스트명 등은 출력에서 제거.

### 4.6 Publish — 게시

**PR Comment**
- 댓글 본문 첫 줄에 마커 `<!-- dev-knowledge-recap -->`.
- 같은 PR에 마커가 있는 댓글이 있으면 **새로 달지 않고 수정**(재실행 시 중복 방지).
- 우선순위: GitHub MCP → `gh` CLI → 실패 시 본문을 출력하고 수동 게시 안내.

**Docs**
- 경로: `{docs_dir}/{slug}.md`, 인덱스 `{docs_dir}/README.md` 갱신.
- 파일 변경은 작업 트리에만 반영하고, 커밋 여부는 사용자에게 확인한다.
- `both`일 때 PR 댓글의 각 개념에 docs 문서 링크를 붙인다.

---

## 5. 출력 포맷

### 5.1 PR 댓글

```markdown
<!-- dev-knowledge-recap -->
## 📚 이번 변경에서 알아두면 좋은 개발 지식

### 1. Promise.all을 사용하는 이유 `async`
여러 비동기 작업을 병렬로 실행해 전체 대기 시간을 줄여요.
이 PR에서는 사용자 정보와 권한을 동시에 조회합니다. → `src/api/user.ts`
> ⚠️ 하나라도 실패하면 전체가 reject돼요. 부분 실패를 허용하려면 `Promise.allSettled`.

### 2. 캐싱과 데이터 일관성 `caching`
...

---
<sub>이 PR에서 실제로 사용된 개념만 선별했어요 · AI-generated by dev-knowledge-recap</sub>
```

### 5.2 Docs 파일 구조

```
docs/
└── dev-knowledge/
    ├── README.md          # 인덱스 (카테고리별 목록)
    ├── promise-all.md
    ├── caching.md
    └── type-safety.md
```

개별 문서:

```markdown
---
slug: promise-all
title: Promise.all을 사용하는 이유
category: async
aliases: [병렬 비동기, parallel promises]
created: 2026-11-06
updated: 2026-11-06
---

# Promise.all을 사용하는 이유

## 개념
## 언제 쓰나
## 주의점
## 프로젝트 사례
## 관련 PR
- #128 — 사용자·권한 병렬 조회 (`src/api/user.ts`)
```

---

## 6. 레포 구조

```
dev-knowledge-recap/
├── README.md
├── docs/
│   └── DESIGN.md                         # 이 문서
├── skills/
│   └── dev-knowledge-recap/
│       ├── SKILL.md                      # Skill 본체 (실행 절차)
│       └── templates/
│           ├── pr-comment.md
│           ├── knowledge-doc.md
│           └── index.md
└── examples/                             # (예정) 샘플 diff → 출력
```

설치: `skills/dev-knowledge-recap/`를 사용자 프로젝트의 `.claude/skills/` (또는 `~/.claude/skills/`)에 복사.

---

## 7. 엣지 케이스

| 상황 | 동작 |
|---|---|
| 열린 PR이 없음 | `target=pr`이면 docs로 대체할지 묻거나 `--dry-run` 출력 |
| 세션 대화 없음 | diff만으로 추출 (질문 신호 점수 없이) |
| diff가 매우 큼 (> 2,000줄) | 파일별 요약 후 상위 변경 파일 위주로 추출 |
| 정리할 개념 없음 | 게시하지 않음 |
| GitHub 권한 없음 | 댓글 본문 출력 + 수동 게시 안내 |
| 기존 docs 파일 형식이 다름 | 덮어쓰지 않고 `관련 PR` 섹션만 append |

---

## 8. 로드맵

| 단계 | 내용 |
|---|---|
| **v0.1 (MVP)** | SKILL.md, PR 댓글/Docs/Both, ko/en, 3단계 depth, 마커 기반 갱신 |
| v0.2 | `.dev-knowledge-recap.yml`, 점수화 튜닝, examples 추가 |
| v0.3 | GitHub Action 모드 (PR 오픈 시 diff만으로 자동 실행) |
| v0.4 | 팀 지식 대시보드: 카테고리별 통계, "이번 달 새로 등장한 개념" |
