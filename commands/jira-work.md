# JIRA Work

Create a git worktree and start working on a JIRA issue.

## Instructions

Given a JIRA key (e.g., RHOAIENG-1234), set up a development environment:

### Phase 1: Research (uses `/jira-research`)

Run the research workflow from `/jira-research`:
- Fetch JIRA details and extract context
- Deep search for existing work across all forks
- Document findings in JIRA (create or update comment)
- Get recommendation on whether to proceed

**If research recommends "needs more information"**, stop and help the user gather that information before proceeding.

**If research recommends "duplicate"**, confirm with user before proceeding.

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

Once target is confirmed, generate commands for the user:

```bash
# From main repo
cd ~/projects/kserve
git fetch --all

# Create worktree
git worktree add ../kserve-JIRA_KEY -b JIRA_KEY/description REMOTE/BRANCH

# Setup worktree (symlinks .vscode/.cursor)
.vscode/scripts/setup-worktree.sh ../kserve-JIRA_KEY --prompt "/jira JIRA_KEY"

# Open in Cursor
cursor ../kserve-JIRA_KEY
```

Where:
- `JIRA_KEY` = the JIRA issue key (e.g., RHOAIENG-1234)
- `description` = short kebab-case description from JIRA summary (e.g., `fix-nil-transformer`)
- `REMOTE/BRANCH` = the determined base (e.g., `odh/release-v0.15`)

### Phase 4: Summary

After presenting the commands, provide:
- JIRA summary and key details
- Target fork/branch with reasoning
- Related PRs that may be useful reference
- What the new agent will see (the `/jira` prompt runs on open)

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
3. Determine or confirm target fork/branch
4. Generate worktree commands
5. User runs commands to create worktree
6. New Cursor window opens with `/jira` context

## Notes

- The `/jira` prompt runs in the new Cursor window to give the new agent full context
- If research was already done, use `skip_research:true` to jump to worktree creation
- This command composes: `/jira-research` -> `/jira-work` -> `/jira` (in new window)

## Related Commands

- `/jira-research` - Research only, no worktree creation
- `/jira` - Quick context fetch (runs automatically in new worktree)
- `/pr-target` - Determine PR target for existing changes
- `/spinoff-pr` - Spin off unrelated changes to a separate PR



