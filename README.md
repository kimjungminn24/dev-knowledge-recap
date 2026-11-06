# dev-knowledge-recap

AI랑 같이 작업한 PR에서, 리뷰하는 사람도 알아두면 좋을 개발 지식을 뽑아서 PR 댓글이나 `docs/`에 남겨주는 Claude Code 스킬입니다.

코드 리뷰나 변경 요약이 아니라, 이 PR에서 실제로 쓰인 개념(예: 왜 `Promise.all`을 썼는지, 캐시 무효화를 어떻게 처리했는지)만 정리합니다.

## 사용법

```
/dev-knowledge-recap --target both --lang ko --depth summary
```

- `--target`: `pr`(PR 댓글), `docs`(문서 저장), `both`. 생략하면 실행할 때 어디에 남길지 물어봅니다.
- `--lang`: `ko`, `en`
- `--depth`: `detailed`, `summary`, `concepts`

PR 댓글은 리뷰할 때 같이 보는 용도고, `docs/dev-knowledge/`에 쌓이는 문서는 나중에 찾아보거나 온보딩할 때 쓰는 용도입니다. 같은 개념이 다른 PR에서 또 나오면 새 파일을 만들지 않고 기존 문서에 PR 링크만 추가합니다.

## 설치

`skills/dev-knowledge-recap/` 폴더를 프로젝트의 `.claude/skills/`에 복사하면 됩니다.

## 설계

[docs/DESIGN.md](docs/DESIGN.md)
