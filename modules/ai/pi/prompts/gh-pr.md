---
description: Create GitHub pull request
argument-hint: "Additional instructions"
---

Create a pull request with a --body that describes the motivation and implementation of this feature branch. Text should sound natural and professional, with a casual tone. No mention of internal discussions or decision; all context should be comprehensible to someone unfamiliar with thread discussion.

Follow this structure:

```
## Motivation
<A simple argument for why this pull request is an improvement, preferably based on a related issue or specification if one exists>

## Overview
<A summary of the most important changes>

## Remarks
<Include only if there is additional important information. This section can usually be omitted.>

## References
<Include only if there are relevant Linear issues to reference (e.g. `Closes OPT-XXX` or `Related to OPT-YYY`) or PRs to link to>

```

Remarks and References are optional. Construct a descriptive PR --title following Conventional Commits style.

If the PR changes UI, the body must include screenshots of the changed UI (before/after where useful). `gh` cannot upload image attachments. Either ask the user to drag the images into the PR description in the web UI after creation, or commit them to the branch (e.g. `docs/screenshots/`) and embed with `![alt](https://github.com/<owner>/<repo>/blob/<branch>/<path>?raw=true)`. Prefer the first; do not commit screenshots without the user's consent.

$1
