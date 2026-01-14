# JIRA Work

Create a git worktree and start working on a JIRA issue.

## Instructions

Given a JIRA key (e.g., RHOAIENG-1234), set up a development environment:

### Phase 1: Research (uses `/jira-research`)

Run the research workflow from `/jira-research`:
- Fetch JIRA details and extract context
- Deep search for existing work across all forks
- Get recommendation on whether to proceed

**If research recommends "needs more information"**, stop and help the user gather that information before proceeding.

**If research recommends "duplicate"**, confirm with user before proceeding.

#### Reproduction Strategy

After initial research, determine how to reproduce the issue:

1. **Find or create a failing test**
   - Search `test/e2e/` for existing tests covering the affected functionality
   - Search `pkg/` for unit tests (`*_test.go`) near the affected code
   - If no test exists, plan to create one that demonstrates the bug

2. **Determine environment requirements**
   - **Unit tests**: Can run in isolation (`go test ./pkg/...`)
   - **E2E tests**: Require cluster setup - see `.vscode/workflow.md`
     - KIND/upstream: Standard Kubernetes testing
     - OpenShift/CRC: ODH/RHOAI-specific features, routes, ServiceMesh
   - Note which markers apply (e.g., `predictor`, `raw`, `kserve_on_openshift`)

3. **Plan the workflow** for the handoff prompt:
   - Step 1: Set up environment (if e2e needed)
   - Step 2: Run test to confirm it fails (reproduce the issue)
   - Step 3: Implement the fix
   - Step 4: Rerun test to verify fix

### Phase 2: Determine Target

If not provided via target override, apply branch targeting rules:

| Scenario | Target Fork | Base Branch | Remote |
|----------|-------------|-------------|--------|
| General KServe bug/feature | kserve/kserve | `master` | `upstream` |
| OpenShift-specific change | opendatahub-io/kserve | `master` | `odh` |
| Release-targeted fix (e.g., "ODH-3.2") | opendatahub-io/kserve | `release-vX.Y` | `odh` |
| RHODS-only configuration | red-hat-data-services/kserve | `main` | `downstream` |
| Cherry-pick needed | Use source fork's target | Appropriate branch | Per fork |

**Present recommendation to user** and wait for confirmation.

### Phase 3: Create Worktree

Once target is confirmed, generate commands for the user.

Important: do NOT try to pass a multi-line "handoff prompt" via a CLI arg. Instead, create a prompt file in the new worktree and point `setup-worktree.sh` at it with `--prompt-file`.

```bash
# From main repo
cd ~/projects/kserve
git fetch --all

# Create worktree
git worktree add ../kserve-JIRA_KEY -b JIRA_KEY/description REMOTE/BRANCH

# Create handoff prompt for new agent session
cat > ../kserve-JIRA_KEY/.agent-prompt <<'EOF'
Context:
- JIRA: JIRA_KEY - <paste summary here>
- Target: REMOTE/BRANCH (explain why)

Research findings:
- <bullet list of findings, linked PRs/issues, root cause hypothesis, etc>

Reproduction strategy:
- Test type: <unit test / e2e test / new test needed>
- Existing test: <path to test file, or "none - create new">
- Environment: <none (unit) / KIND / OpenShift CRC>
- E2E markers: <predictor, raw, kserve_on_openshift, etc. if applicable>
- Setup reference: .vscode/workflow.md

Workflow:
1. <Set up environment if needed - reference specific workflow.md section>
2. <Run test to reproduce: specific pytest/go test command>
3. <Implement fix: files to modify, approach>
4. <Rerun test to verify: same command as step 2>
EOF

# Setup worktree and open in Cursor (symlinks .vscode/.cursor, copies prompt to clipboard)
.vscode/scripts/setup-worktree.sh ../kserve-JIRA_KEY --open
```

Where:
- `JIRA_KEY` = the JIRA issue key (e.g., RHOAIENG-1234)
- `description` = short kebab-case description from JIRA summary (e.g., `fix-nil-transformer`)
- `REMOTE/BRANCH` = the determined base (e.g., `odh/release-v0.15`)

**Stop after generating the commands.** Do not continue implementing changes in this window - work continues in the new Cursor window.

## User Input

JIRA Key: {{jira_key}}

Target override (optional): {{target}} (e.g., "upstream/master", "odh/release-v0.15")

Skip research (optional): {{skip_research}} (use if already researched)

## Example Usage

**Full workflow:**
```
/jira-work RHOAIENG-1234
```

**With target override (skip target determination):**
```
/jira-work RHOAIENG-1234 target:odh/release-v0.15
```

**Skip research (already done):**
```
/jira-work RHOAIENG-1234 skip_research:true target:upstream/master
```

Expected flow:
1. Run `/jira-research` workflow (unless skipped)
2. Review research findings and recommendation
3. **Determine reproduction strategy** (test type, environment, existing tests)
4. Determine or confirm target fork/branch
5. Generate worktree commands with `.agent-prompt` containing full context
6. User runs commands to create worktree and open in Cursor

## Notes

- The `.agent-prompt` file contains full context for the new agent session (copied to clipboard)
- If research was already done, use `skip_research:true` to jump to worktree creation
- **Test-first workflow**: The handoff prompt should guide the new session to reproduce the issue BEFORE implementing a fix

### Test Discovery Tips

When searching for existing tests:
- E2E tests: `test/e2e/` - Python pytest tests with markers
- Controller tests: `pkg/controller/**/*_test.go`
- Webhook tests: `pkg/webhook/**/*_test.go`
- API tests: `pkg/apis/**/*_test.go`

Common test patterns to search for:
- Feature name in test file names
- Related InferenceService configurations in `test/e2e/` JSON fixtures
- Error messages or conditions mentioned in the JIRA

## Related Commands

- `/jira-research` - Research only, no worktree creation
- `/jira` - Quick context fetch (if you need to refresh JIRA details later)
- `/pr-target` - Determine PR target for existing changes
- `/spinoff-pr` - Spin off unrelated changes to a separate PR

