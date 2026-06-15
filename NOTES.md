# Demo Notes: Call-Outs & Talking Points

> Narrative, rationale, and presenter cues. For the execution steps, see `MainDemo.md`.

## The Story (one sentence)
"We point the agent at a running app it has never seen, it discovers what the app
actually does, and it writes Playwright tests that lock that behavior in — then CI
enforces it."

This is **characterization testing**: the agent asserts *what is*, not *what should be*.
That framing is the heart of the demo.

## Why This Resonates
- **No spec required.** Modernizing apps rarely have one. The agent derives tests from the *live application*.
- **Safety net before change.** Reverse-engineered tests catch regressions the moment modernization begins.
- **Visible and concrete.** Playwright traces, video, and screenshots make "the agent understood the app" tangible to any audience.

## The Decision: Playwright via Agent vs. Dedicated Workflow

**We chose a dedicated GitHub Actions workflow to *run* Playwright — the agent only *authors* the tests.**

| Concern | Agent runs Playwright | Dedicated GH Actions workflow |
|---|---|---|
| Repeatable / deterministic | No | Yes |
| Gates PRs & deploys | No | Yes (`pull_request` + branch protection) |
| Browser binaries / infra | Fragile | Clean runner (`npx playwright install --with-deps`) |
| Artifacts (traces, video) | Hard | Native (`actions/upload-artifact`) |
| Flake handling / retries | Manual | Built-in (`retries`, sharding) |

**Separation of duties:**
- **Unit tests** → run on every build in the existing deploy pipeline (fast, always-on gate).
- **Playwright UI tests** → separate workflow on `pull_request` + `workflow_dispatch` (manual). Heavier; keep out of the inner loop but still enforceable.

## Presenter Cues (what to say at each beat)
- *Discover:* "Notice — we gave it no documentation. It's learning the app by using it, like a new engineer would."
- *Generate:* "It's not guessing the *ideal* behavior. It's capturing *today's* behavior so nothing breaks when we modernize."
- *Enforce:* "Here's the regression. The test the agent wrote catches it automatically."

## Consistency Rules (so the demo never wobbles)
1. **Pin everything.** Fixed Playwright + Node versions, seeded data, fixed app port.
2. **Stable locators only.** `getByRole`/`getByText`, never auto-generated CSS/XPath — the #1 cause of flaky demos.
3. **Deterministic app state.** Reset/seed the DB before each run.
4. **Rehearse exact prompts.** Same wording each time; keep a prompt cheat-sheet.
5. **Pre-bake a fallback branch.** `demo-known-good` with tests already committed.
6. **Headed for humans, headless for CI.** Run `--headed` live so the audience watches the browser drive itself.

## Key Takeaway
The agent reverse-engineers a working app into a **living regression suite** — discovered
from behavior, written in Playwright, enforced in CI. Modernization can now move fast
*without* fear of breaking what works.
