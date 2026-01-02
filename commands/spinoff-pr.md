# Spinoff PR

Spin off unrelated changes into a separate PR without disturbing current work.

## Instructions

Use this workflow when you notice changes that should be submitted separately from your current task - either because they're unrelated, they could benefit others sooner, or they should target a different fork/branch.

### Phase 1: Identify Changes to Spin Off

Determine what needs to be extracted:

**Scenario A - Existing changes in repo:**
- Specific commits to extract
- Modified files to extract
- Hunks/patches to extract

**Scenario B - Changes not yet made:**
- Description of work to do
- Files that will be affected

### Phase 2: Determine Target Fork/Branch

If target isn't contextually clear, analyze using `/pr-target` logic:

| Change Type | Target Fork | Base Branch | Remote |
|-------------|-------------|-------------|--------|
| General KServe bug/feature | kserve/kserve | `master` | `upstream` |
| OpenShift/ODH-specific | opendatahub-io/kserve | `master` | `odh` |
| Release-critical fix | opendatahub-io/kserve | `release-vX.Y` | `odh` |
| RHODS-only | red-hat-data-services/kserve | `main` | `downstream` |

**Present recommendation and wait for confirmation.**

### Phase 3: Create Clean Branch

**From the main repo** (not the current worktree), create a fresh branch:

```bash
# Go to main repo (keeps current worktree untouched)
cd ~/projects/kserve

# Fetch latest
git fetch REMOTE

# Create new worktree from target's latest main/master
git worktree add ../kserve-spinoff-DESCRIPTION -b spinoff/DESCRIPTION REMOTE/BRANCH

# Setup worktree
.vscode/scripts/setup-worktree.sh ../kserve-spinoff-DESCRIPTION

# Open in new Cursor window
cursor ../kserve-spinoff-DESCRIPTION
```

Where:
- `REMOTE` = target remote (upstream, odh, or downstream)
- `BRANCH` = target base branch (master, main, or release-vX.Y)
- `DESCRIPTION` = short kebab-case description of the spinoff

### Phase 4: Apply Changes

**For Scenario A (existing changes):**

Option 1 - Cherry-pick commits:
```bash
# In the new worktree
cd ../kserve-spinoff-DESCRIPTION
git cherry-pick COMMIT_SHA1 COMMIT_SHA2 ...
```

Option 2 - Apply patches from files:
```bash
# From original worktree, create patch
cd ~/projects/kserve-ORIGINAL-TASK
git diff HEAD -- path/to/file1 path/to/file2 > /tmp/spinoff.patch

# In new worktree, apply patch
cd ../kserve-spinoff-DESCRIPTION
git apply /tmp/spinoff.patch
git add -A
git commit -s -S -m "type: description"
```

Option 3 - Interactive staging (for partial changes):
```bash
# Create patch of specific hunks
git diff HEAD -- path/to/file | git apply --cached
# Or use git add -p for interactive staging
```

**For Scenario B (new work):**
- Work directly in the new worktree
- Changes don't exist yet, so nothing to extract

### Phase 5: Cleanup Original (Scenario A only)

After successfully spinning off changes, **ask the user** whether to remove them from the original worktree.

**Important:** Some spun-off changes may still be useful for local development (e.g., install script fixes, worktree support, tooling improvements). Don't automatically discard changes - ask first.

If the user wants to remove the changes:

```bash
# In original worktree
cd ~/projects/kserve-ORIGINAL-TASK

# Option 1: Revert specific commits
git revert COMMIT_SHA --no-commit
git commit -s -S -m "chore: extract DESCRIPTION to separate PR"

# Option 2: Reset and re-stage without the spun-off files
git reset HEAD~N  # N = number of commits containing spinoff changes
# Re-stage only the changes you want to keep
git add -p
git commit -s -S -m "original commit message"

# Option 3: Discard unstaged changes
git checkout -- path/to/files
```

**Note:** This step is optional. Sometimes it's fine to have overlap temporarily until the spinoff PR merges, or to keep the changes for local development convenience.

### Phase 6: Push and Prepare PR

```bash
cd ../kserve-spinoff-DESCRIPTION

# Push to personal fork
git push -u origin spinoff/DESCRIPTION
```

**Present PR details for review before creating:**
- Title (following conventional commits)
- Target repository and branch
- Description (using PR template)
- Related context

**Wait for user approval before creating PR.**

## User Input

Changes to spin off: {{changes}}
- For existing changes: commit SHAs, file paths, or "last N commits"
- For new work: description of what needs to be done

Target (optional): {{target}}
- e.g., "upstream/master", "odh/release-v0.15"
- If omitted, will determine using pr-target logic

## Examples

### Example 1: Extract a commit to upstream

```
/spinoff-pr changes:"commit abc123 - typo fix in docs" target:upstream/master
```

Result:
1. Creates `~/projects/kserve-spinoff-fix-docs-typo`
2. Cherry-picks abc123 onto fresh upstream/master base
3. Pushes and prepares PR to kserve/kserve

### Example 2: Extract file changes

```
/spinoff-pr changes:"changes to hack/setup/*.sh scripts"
```

Result:
1. Analyzes the scripts to determine target (likely odh/master)
2. Creates worktree, applies patches
3. Prepares PR

### Example 3: Start unrelated work

```
/spinoff-pr changes:"need to update CI workflow for new Go version" target:odh/master
```

Result:
1. Creates fresh worktree from odh/master
2. Opens in Cursor for you to make the changes
3. Current worktree remains untouched

## Key Principles

1. **Never modify current worktree** - Always create new worktree from main repo
2. **Always base on latest** - Fetch and branch from remote HEAD, not local
3. **Clean commits** - Use `-s -S` for signed commits with DCO
4. **Draft PRs** - Always create as draft until ready
5. **User approval** - Present PR details before creating

## Related Commands

- `/pr-target` - Determine correct target fork/branch
- `/jira-work` - Full JIRA-based workflow with research
- `/jira` - Quick context fetch for existing worktree


