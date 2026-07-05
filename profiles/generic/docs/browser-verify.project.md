# Browser verification (project supplement)

Loaded by the `jira-browser-verify` skill and [browser-verify.instructions.md](../github/instructions/browser-verify.instructions.md).

Install paths: `.cursor/docs/browser-verify.project.md` (Cursor) or `.github/docs/browser-verify.project.md` (VS Code). Copy from `ai-dotfiles/profiles/generic/docs/` or your profile `cursor/docs/` overlay.

## Operator gate

Ask and stop if these are missing:

- region or market
- brand
- task id
- surface when ambiguous
- environment when not the local default

Do not infer region or brand from a branch name.

## Dev runtime

- Start command: operator-provided (e.g. `npm run dev`)
- Typical URL: operator-provided local URL
- Mocks: confirm with the operator if flows behave unexpectedly

## Test persona

- Schema example: `.mlem/test-personas/generic-app.example.json`
- Local copy: `.mlem/test-personas/generic-app.json`
- Never invent PII and never commit real persona files

## Route map

Document key routes in your project docs. Transient routes should be verified by observed URL changes, not fixed sleeps.

## Escalation

Ask the operator when login or registration is blocked, OTP is required, the expected route is unreachable after two attempts, or backend errors prevent a meaningful check.
