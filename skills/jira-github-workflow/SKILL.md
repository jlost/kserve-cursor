---
name: jira-github-workflow
description: JIRA and GitHub integration for RHOAI Model Serving. Use when creating PRs, linking JIRAs, fetching issue context, or working with the kserve fork hierarchy (upstream/ODH/downstream).
---
# JIRA-GitHub Workflow

## JIRA Defaults

When creating or updating JIRA issues for this repository:

- **Project:** RHOAIENG
- **Issue Type:** Task (default) - see jira-reference.md for when to use other types
- **Component:** Model Serving
- **Team:** RHOAI Model Server and Serving Metrics (ID: `"4156"`)
- **Priority:** Normal (always set - do not leave as "Undefined")
- **Sprint:** Current active sprint (look up dynamically - see jira-reference.md)
- **Activity Type:** Choose based on context:
  - `"General Engineering"` - routine dev, tests, CI fixes, CVEs, builds
  - `"Usability"` - UX issues, docs, user-facing improvements
  - `"Regression"` - previously working functionality now broken

## JIRA Summary Conventions

When creating JIRA issues, prefix the summary based on target fork:

| Target Fork | Summary Prefix | Example |
|-------------|----------------|---------|
| Upstream (kserve/kserve) | `upstream: ` | `upstream: Fix validation for pathTemplate` |
| ODH/Downstream only | (none) | `Fix OpenShift-specific routing` |

Use the `upstream: ` prefix when:
- The primary PR will be to `kserve/kserve`
- The fix/feature is upstream-first, even if later cherry-picked to ODH/downstream

## PR Creation Policy

1. **Always get user approval** before creating any PR - present title, description, target repo/branch
2. **Always create as draft** - use `draft: true`
3. **Use the PR template** - base on `.github/PULL_REQUEST_TEMPLATE.md`, delete irrelevant sections
4. **PR title must be <=60 characters** - keep titles concise; use the description for details

## JIRA Linking by Repository

DPTP Bot only monitors ODH repos, not upstream. Link PRs accordingly:

### Upstream PRs (kserve/kserve)

**Do NOT put JIRA keys in PR title/body.** This is the established Red Hat contributor convention.

After creating the PR, add it to the JIRA's "Git Pull Request" field:

```
jira_update_issue(
  issue_key="RHOAIENG-1234",
  fields={},
  additional_fields={"customfield_12310220": ["https://github.com/kserve/kserve/pull/4910"]}
)
```

Notes:
- Value must be an **array of URLs**, even for a single PR
- To add to existing PRs, fetch current values first and include all URLs
- Do NOT use `jira_create_remote_issue_link`

### ODH/Downstream PRs (opendatahub-io/kserve, red-hat-data-services/kserve)

**Include JIRA key in PR title** for automatic DPTP Bot linking:
- Format: `[RHOAIENG-1234] Fix validation bug`

## Cross-Fork Coordination

GitHub PR numbers are repository-specific. "#942" could be any fork:
- `kserve/kserve#942`
- `opendatahub-io/kserve#942`
- `red-hat-data-services/kserve#942`

Check JIRA changelog's RemoteIssueLink for full URLs that disambiguate.

## Additional Resources

- For JIRA markup syntax and custom fields, see [jira-reference.md](jira-reference.md)
- For PR template and description conventions, see [github-reference.md](github-reference.md)
