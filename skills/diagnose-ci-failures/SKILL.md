---
name: diagnose-ci-failures
description: Diagnose errors in all failed Prow CI jobs for a given GitHub PR. Use when the user shares a PR URL and asks to check CI logs, investigate test failures, or understand why CI is failing.
---

# Diagnose CI Failures

Analyze all failed Prow CI jobs for a GitHub PR, extract root causes from build logs, and summarize findings.

## Workflow

### Step 1: Get Failed Jobs from the PR

Fetch the PR page with `WebFetch` and identify all failed CI checks. Each failed Prow check links to a URL like:

```
https://prow.ci.openshift.org/view/gs/test-platform-results/pr-logs/pull/<org>_<repo>/<pr_number>/<job-name>/<build-id>
```

Extract **every** failed job URL from the PR.

### Step 2: Fetch Artifacts for Each Failed Job

For each failed job, derive the GCS artifact URL from the Prow URL:

```
Base: https://gcsweb-ci.apps.ci.l2s4.p1.openshiftapps.com/gcs/test-platform-results/pr-logs/pull/<org>_<repo>/<pr>/<job-name>/<build-id>/
```

Fetch these files:

| File | Purpose |
|------|---------|
| `finished.json` | Quick pass/fail status and result metadata |
| `build-log.txt` | Full CI output (may be large -- read from the end first) |

### Step 3: Analyze Build Logs

Build logs can be very large (10K-20K+ lines). Use this strategy:

1. **Read the last ~200 lines** first -- test summaries and final errors are at the end
2. **Search for failure markers** with `Grep`:
   - `FAIL` / `FAILED` / `ERROR` (test results)
   - `short test summary` (pytest summary)
   - `=+ FAILURES =+` (pytest failures section)
   - `timed out` / `timeout` (timeout issues)
   - `no endpoints available` (webhook/service issues)
   - `MinimumReplicasUnavailable` (pod scheduling)
   - `failed liveness probe` / `failed readiness probe` (health check failures)
   - `panic` (Go panics)
   - `error occurred` (controller errors)
3. **Read around failure markers** (50-100 lines of context) to understand root cause
4. **Check for infrastructure vs code issues**:
   - Webhook unavailable -> infrastructure
   - Pod probe failures -> resource/config issue
   - Test assertion failures -> potential code issue
   - Timeout waiting for resources -> flaky/infrastructure

### Step 4: Classify Each Failure

Categorize failures to help the user decide next steps:

| Category | Indicators | Typical Action |
|----------|-----------|----------------|
| **Infrastructure** | Webhook down, node issues, lease timeout | `/retest` |
| **Flaky test** | Intermittent timeouts, probe failures, race conditions | `/retest` or check job history |
| **Code issue** | Assertion errors with clear mismatch, compilation errors, import errors | Fix the code |
| **Config issue** | Missing CRDs, wrong image refs, missing secrets | Fix configuration |

### Step 5: Summarize

Present findings in this format:

```
## CI Failure Analysis for PR #<number>

### <Job Name 1>: <CATEGORY>
**Status**: FAILURE
**Root cause**: <1-2 sentence description>
**Key error**: <quoted error message>
**Action**: `/retest` | fix needed | ...

### <Job Name 2>: <CATEGORY>
...

### Flakiness Assessment
<Whether this appears related to the PR's changes or is a pre-existing issue>
```

### Step 6 (Optional): Flakiness Analysis

If the user asks, or if failures look infrastructure-related:

1. Fetch the job history page:
   ```
   https://prow.ci.openshift.org/job-history/gs/test-platform-results/pr-logs/directory/<job-name>
   ```
2. Check pass/fail rates across recent runs from **other PRs**
3. If the job is failing across many unrelated PRs, it's a flaky/infrastructure issue unrelated to the current change

### Step 7 (Optional): Retest via MCP

If all failures are classified as **Infrastructure** or **Flaky test**, offer to post `/retest` on the PR using the GitHub MCP tool:

```
CallMcpTool:
  server: user-github
  toolName: add_issue_comment
  arguments:
    owner: <org>
    repo: <repo>
    issue_number: <pr_number>
    body: "/retest"
```

Only do this when the user asks or confirms. For selective retesting, use `/retest-required` (mandatory jobs only) or `/test <job-name>` (single job).

### Step 8: File JIRA for Identified Flaky Tests

When a specific flaky test is identified (a named test case that fails intermittently across multiple PRs), tell the user to invoke `/jira-github-workflow` to create a JIRA issue. That skill has the project key, component, team, and other defaults.

Provide the following details for the JIRA so the user can pass them along:

- **Summary:** `Flaky test: <test_name>`
- **Issue type:** Bug
- **Description content** (Jira wiki markup):

```
h2. Flaky Test Report

*Test name:* <full test name including parameterization>
*Job:* <prow job name>
*PR where observed:* <pr_url>

h3. Failure Pattern
<brief description -- e.g., timeout, probe failure, webhook unavailable>

h3. Error Log Snippet
{code}
<relevant error output, ~10-30 lines>
{code}

h3. Job History
<pass/fail rate, e.g., "2/20 passed in last 7 days across multiple PRs">
[Job history|<job-history-url>]

h3. Recommended Fix
<concrete suggestion -- e.g., increase timeout, add retry, add startup probe>
```

- **Labels:** `flaky-test`, `ci`

## Tips

- The Prow dashboard pages are JS-rendered -- always go to the GCS artifact URLs directly for log content
- `build-log.txt` is the primary source; `finished.json` gives a quick status check
- For pytest output, the `FAILURES` section has full stack traces; the `ERRORS` section has setup/teardown failures
- When multiple jobs fail with the same root cause (e.g., webhook down), note the shared cause rather than repeating
- Always state clearly whether the failure is related to the PR's changes or not
