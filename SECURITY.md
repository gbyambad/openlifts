# Security Policy

## Supported versions

OpenLifts is an actively developed, local-first app with no backend. Security
fixes land on the `main` branch and ship in the next release. Please make sure
you're on the latest version before reporting.

## Reporting a vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, report them privately through GitHub's built-in
[private vulnerability reporting][gh-report]:

1. Go to the **Security** tab of this repository.
2. Click **Report a vulnerability**.
3. Fill in the advisory form with as much detail as you can.

> Maintainer note: this requires **Private vulnerability reporting** to be
> enabled under *Settings → Security → Advanced Security*.

Please include, where possible:

- A description of the vulnerability and its impact
- Steps to reproduce (a minimal proof of concept is ideal)
- The affected version or commit, and platform (Android / iOS)
- Any suggested remediation

## What to expect

- We aim to acknowledge a report within **7 days**.
- We'll keep you updated as we investigate and work on a fix.
- Once a fix is released, we're happy to credit you in the advisory unless you
  prefer to remain anonymous.

Because OpenLifts stores all data locally on the device and talks to no server,
the most relevant classes of issue are around local data handling, backup/export
files, and dependencies. Reports in those areas are especially welcome.

[gh-report]: https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability
