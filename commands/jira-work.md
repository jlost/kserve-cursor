# JIRA Work

Start working on a JIRA issue in the current worktree. This is the entry point for a new Cursor session created by `setup-worktree.sh`.

## Prerequisites

This command assumes:
- You're in a git worktree created by `setup-worktree.sh`
- The worktree has a branch tracking the appropriate base (can be corrected if wrong)

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
   - Check all three forks: `kserve/kserve`, `opendatahub-io/kserve`, `red-hat-data-services/kserve`

3. **Search Slack** for relevant discussions (if appropriate)

4. **Compile findings** and determine recommendation

**Based on research recommendation:**
- **"needs more information"**: Stop and help gather missing details before proceeding
- **"duplicate"**: Confirm with user before proceeding
- **"cherry-pick needed"**: Adjust workflow to cherry-pick instead of new implementation
- **"ready to proceed"**: Continue to Phase 2

### Phase 2: Validate Target Branch

Check if the current worktree branch is based on the correct upstream:

```bash
# Get current branch and its upstream
git rev-parse --abbrev-ref HEAD
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no upstream"

# Check which remote/branch this was based on
git log --oneline -1 $(git merge-base HEAD odh/release-0.15 2>/dev/null || echo HEAD)
git log --oneline -1 $(git merge-base HEAD upstream/master 2>/dev/null || echo HEAD)
```

Apply branch targeting rules from `fork-structure.mdc`:

| Scenario | Target Fork | Base Branch |
|----------|-------------|-------------|
| General KServe bug/feature | upstream | `master` |
| OpenShift-specific change | odh | `release-0.15` |
| ODH release fix | odh | `release-0.15` |
| Downstream-only change (rare) | downstream | `main` |

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

**Environment MCP tools:**

For Kind (upstream):
```
mcp_ignition-mcp_task_kind_refresh
mcp_ignition-mcp_task_install_kserve_dependencies
mcp_ignition-mcp_task_install_network_dependencies
mcp_ignition-mcp_task_clean_deploy_kserve
mcp_ignition-mcp_task_patch_deployment_mode
```

For CRC (ODH/downstream):
```
mcp_ignition-mcp_task_crc_refresh
mcp_ignition-mcp_task_pull_secret
mcp_ignition-mcp_task_setup_e2e  # for E2E parity
mcp_ignition-mcp_task_recreate_e2e_ns
```

**After environment is ready:**
- Start devspace for local code deployment: `mcp_ignition-mcp_launch_devspace`

### Phase 4: Test Discovery and Reproduction (TDD)

Follow the TDD workflow from `tdd-workflow.mdc`:

**Find existing tests:**
- E2E tests: `test/e2e/` - Python pytest with markers
- Controller tests: `pkg/controller/**/*_test.go`
- Webhook tests: `pkg/webhook/**/*_test.go`
- API tests: `pkg/apis/**/*_test.go`

Search strategies:
- Feature/component name in test file names
- Error messages or conditions from JIRA
- Related InferenceService configurations in test fixtures

**If no existing test covers the issue:**
- Plan to create a new test that demonstrates the bug/validates the feature

**Run test to reproduce (expect RED):**

For unit tests (Ginkgo):
```
mcp_ignition-mcp_launch_unit_test_ginkgo_focus
```

For unit tests (non-Ginkgo):
```
mcp_ignition-mcp_launch_unit_test_name
```

For E2E tests:
```
mcp_ignition-mcp_launch_e2e_test_kind  # upstream
mcp_ignition-mcp_launch_e2e_test_odh_rhoai  # ODH/downstream
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
- Use PR template from `.github/PULL_REQUEST_TEMPLATE.md`

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
