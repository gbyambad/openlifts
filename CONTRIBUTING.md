# Contributing to OpenLifts

Contributions are welcome — bug fixes, features, exercises/programs, docs.

## Ground rules

- Read [`AGENTS.md`](AGENTS.md) first — it defines the house architecture,
  patterns, and commands. New code follows those conventions.
- Keep the app green: `dart format .`, `flutter analyze` (zero issues), and
  `flutter test` must pass. The git hooks (`.githooks/`) run these for you.
- One logical change per PR; conventional-commit messages (`feat:`, `fix:`, …).

## Workflow

1. Fork and branch from `main`.
2. Make your change with a test.
3. Run format → analyze → test locally.
4. Open a PR describing the change and why.

## Licensing of contributions

OpenLifts is licensed under the **GNU GPLv3** (see [`LICENSE`](LICENSE)). By
contributing, you agree your contributions are licensed under the same GPLv3.

Please **sign off** your commits (Developer Certificate of Origin) with:

```bash
git commit -s
```

This adds a `Signed-off-by` line certifying you have the right to submit the
work under the project's license.

> Note: OpenLifts uses the DCO (lightweight sign-off), not a full CLA. If the
> project later needs a CLA (e.g. to retain relicensing flexibility), this
> section will be updated.

## Name & branding

The GPLv3 covers the **code**, not the **"OpenLifts" name or logo**. Forks and
derivatives must rebrand — don't ship a fork as OpenLifts.
