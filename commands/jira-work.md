# JIRA Work

Start working on a JIRA issue in the current worktree. This is the entry point for a new Cursor session created by `setup-worktree.sh`.

## Prerequisites

This command assumes:
- You're in a git worktree created by `setup-worktree.sh`
- The worktree has a branch tracking the appropriate base (can be corrected if wrong)
- You know which repo this work targets (see `workspace.mdc` for detection)

## Instructions

Given a JIRA key (e.g., RHOAIENG-1234), execute the full development workflow:

### Phase 1: Research

Read and follow the research workflow in `.cursor/commands/jira-research.md`:

1. **Fetch JIRA details** using JIRA MCP:
   - Get issue with `fields: *all` and `expand: changelog`
   - Fetch comments separately (not included in `*all`)
   - Extract key terms: error messages, function names, component names

2. **Deep search GitHub** across all forks using GitHub MCP:
   - Search by JIRA key in PRs, issues, commits
   - Search by keywords/error messages from JIRA
   - Check all forks:
     - kserve: `kserve/kserve`, `opendatahub-io/kserve`, `red-hat-data-services/kserve`
     - omc: `opendatahub-io/odh-model-controller`, `red-hat-data-services/odh-model-controller`

3. **Search Slack** for relevant discussions (if appropriate)

4. **Compile findings** and determine recommendation

**Based on research recommendation:**
- **"needs more information"**: Stop and help gather missing details before proceeding
- **"duplicate"**: Confirm with user before proceeding
- **"cherry-pick needed"**: Adjust workflow to cherry-pick instead of new implementation
- **"ready to proceed"**: Continue to Phase 2

### Phase 2: Validate Target Branch

Check if the current worktree branch is based on the correct upstream.
Run from within the repo directory (e.g., `kserve/` or worktree root):

```bash
git rev-parse --abbrev-ref HEAD
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no upstream"
```

Apply branch targeting rules from fork-structure rules (`fork-structure.mdc` for kserve, `omc-fork-structure.mdc` for omc):

**kserve:**

| Scenario | Target Fork | Base Branch |
|----------|-------------|-------------|
| General KServe bug/feature | upstream | `master` |
| OpenShift-specific change | odh | `release-v0.17` |
| ODH release fix | odh | `release-v0.17` |
| Downstream-only change (rare) | downstream | `main` |

**odh-model-controller:**

| Scenario | Target Fork | Base Branch |
|----------|-------------|-------------|
| ODH feature (latest) | odh | `master` |
| ODH feature (older) | odh | `stable-X.x` |
| Downstream-only change (latest) | downstream | `main` |
| Downstream-only change (older) | downstream | `rhoai-X.Y` |

**If current base doesn't match recommendation:**
- Present the mismatch to user
- Offer to rebase: `git fetch <remote> && git rebase <remote>/<branch>`
- Or continue with current base if user confirms

### Phase 3: Environment Setup

Read and follow the dev-environments skill: `.cursor/skills/dev-environments/SKILL.md`

**Determine environment needed:**

| Target Fork | Environment | Setup |
|-------------|-------------|-------|
| upstream | Kind cluster | Kind setup flow |
| odh | CRC (OpenShift) | CRC setup flow |
| downstream | CRC (OpenShift) | CRC setup flow |

**Check current environment state:**
1. Is Kind running? (`kind get clusters`)
2. Is CRC running? (`crc status`)
3. Is the right environment for the target already running?

**If environment switch needed:**
- Stop the current environment first (Kind and CRC cannot coexist)
- Set up the correct environment using MCP tools

**Environment setup:**

For Kind (upstream):
```bash
hack/setup/dev/manage.kind-with-registry.sh   # create/refresh Kind cluster
test/scripts/gh-actions/setup-deps.sh          # install kserve + network deps
make deploy-dev                                # deploy kserve with dev images
```

For CRC (ODH/downstream):
```bash
crc start                                              # start CRC
test/scripts/openshift-ci/deploy.odh.sh                # install ODH operator
test/scripts/openshift-ci/setup-e2e-tests.sh           # E2E parity setup
test/scripts/openshift-ci/setup-ci-namespace.sh        # create/recreate E2E namespace
```

**After environment is ready:**
- Start devspace for local code deployment: `devspace dev`

### Phase 4: Test Discovery and Reproduction (TDD)

Follow the TDD workflow from `tdd-workflow.mdc`.

**Find existing tests** (paths relative to workspace root):

**kserve:**
- E2E tests: `kserve/test/e2e/` - Python pytest with markers
- Controller tests: `kserve/pkg/controller/**/*_test.go`
- Webhook tests: `kserve/pkg/webhook/**/*_test.go`
- API tests: `kserve/pkg/apis/**/*_test.go`

**odh-model-controller:**
- E2E tests: `odh-model-controller/test/e2e/`
- Controller tests: `odh-model-controller/controllers/*_test.go`
- Webhook tests: `odh-model-controller/webhooks/*_test.go`

Search strategies:
- Feature/component name in test file names
- Error messages or conditions from JIRA
- Related InferenceService configurations in test fixtures

**If no existing test covers the issue:**
- Plan to create a new test that demonstrates the bug/validates the feature

**Run test to reproduce (expect RED):**

For unit tests:
```bash
# Focused by test name (Ginkgo or standard)
make test TEST_PKGS="./pkg/controller/v1beta1/inferenceservice/..."

# Or directly with go test
KUBEBUILDER_ASSETS="$(make setup-envtest 2>&1 | tail -1)" \
  go test -v -run "TestName" ./pkg/path/to/package/...
```

For E2E tests:
```bash
test/scripts/gh-actions/run-e2e-tests.sh          # upstream (Kind)
test/scripts/openshift-ci/run-e2e-tests.sh        # ODH/downstream (CRC)
```

**Confirm the test fails** with the expected error before proceeding to implementation.

### Phase 5: Implementation

Implement the fix with minimal changes needed to pass the test.

**Guidelines:**
- Focus on the root cause identified in research
- Keep changes scoped to the issue
- Follow existing code patterns

### Phase 6: Verification

**Run test again (expect GREEN):**
- Same test command as Phase 4
- Confirm the fix resolves the issue

**Run related tests for regression check:**
- Unit tests in the same package
- E2E tests with related markers

### Phase 7: PR Creation

Follow the jira-github-workflow skill: `.cursor/skills/jira-github-workflow/SKILL.md`

**Before creating PR:**
- Ensure commits are signed: `git commit -s -S`
- Follow conventional commit format
- Check for linter errors: run `make lint` or equivalent

**Create PR:**
- Always create as **draft** first
- Include JIRA key in title for ODH/downstream PRs: `[RHOAIENG-1234] Fix description`
- Do NOT include JIRA key in upstream PR titles
- Use PR template from the repo's `.github/PULL_REQUEST_TEMPLATE.md`

**Link JIRA:**
- For ODH/downstream: DPTP bot auto-links from PR title
- For upstream: Manually add PR URL to JIRA's "Git Pull Request" field

## User Input

JIRA Key: {{jira_key}}

Options:
- `skip_research:true` - Skip Phase 1 if already researched
- `target:<remote>/<branch>` - Override target determination
- `skip_env:true` - Skip environment setup (already running)

## Example Usage

**Full workflow (start of new session):**
```
/jira-work RHOAIENG-1234
```

**Skip research (already done in previous session):**
```
/jira-work RHOAIENG-1234 skip_research:true
```

**Override target:**
```
/jira-work RHOAIENG-1234 target:upstream/master
```

**Skip environment (already set up):**
```
/jira-work RHOAIENG-1234 skip_env:true
```

## Typical Session Flow

1. `setup-worktree.sh --jira RHOAIENG-1234` creates worktree and opens Cursor
2. User pastes `/jira-work RHOAIENG-1234` from clipboard
3. Agent researches JIRA and validates branch target
4. Agent sets up environment (Kind or CRC as appropriate)
5. Agent finds/creates test and confirms it reproduces the issue
6. Agent implements the fix
7. Agent verifies fix with tests
8. Agent creates draft PR (after user approval)

## Related Commands

These are standalone commands for specific tasks (not called by this command):
- `/jira-research` - Research only, no implementation (use when you just want to investigate)
- `/jira` - Quick JIRA context fetch
- `/pr-target` - Determine PR target for existing changes
- `/e2e-debug` - Debug failing E2E tests
- `/cherrypick-check` - Check cherry-pick status across forks

## Notes

- This command assumes the worktree already exists (created by `setup-worktree.sh`)
- Environment setup may take several minutes for first-time setup
- Always confirm test reproduction before implementing a fix (TDD workflow)
- Get user approval before creating PRs or posting JIRA comments
