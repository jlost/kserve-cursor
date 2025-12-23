# Branch Compare

Analyze divergence between KServe forks to find merge issues, missing syncs, or botched cherry-picks.

## Instructions

Compare two branches to understand their divergence and identify problems.

1. **Fetch branch information** using GitHub MCP:
   - Get recent commits from both branches
   - Identify merge commits (code syncs)
   - Note the last common ancestor

2. **Analyze divergence patterns**:
   - Commits only in branch A (ahead)
   - Commits only in branch B (behind)
   - Merge commits and their sources

3. **Detect potential issues**:

   **Botched Merge Signs**:
   - Merge commit exists but files differ unexpectedly
   - Conflict resolution that removed important changes
   - Partial cherry-pick (some commits from a PR, not all)

   **Missing Sync Signs**:
   - Large number of commits ahead in source
   - Critical fixes in source not in target
   - Release tag in source not reflected in target

   **Cherry-Pick Issues**:
   - Commit message matches but SHA differs (expected)
   - Similar changes with different implementations
   - Reverted commits that shouldn't be reverted

4. **Generate divergence report**:
   - Summary statistics (commits ahead/behind)
   - Key differences by file/directory
   - Recommended actions

## Common Comparisons

### ODH vs Upstream
```
upstream/master vs odh/master
```
Shows ODH-specific changes and pending upstream syncs.

### ODH Release vs ODH Master
```
odh/master vs odh/release-v0.15
```
Shows what's been added to master since the release branch cut.

### Downstream vs ODH
```
odh/master vs downstream/main
```
Shows downstream-specific changes and missing syncs.

## User Input

Branch A: {{branch_a}} (e.g., "upstream/master", "kserve/kserve master")
Branch B: {{branch_b}} (e.g., "odh/master", "opendatahub-io/kserve master")

Focus area (optional): {{focus_path}} (e.g., "pkg/controller/", "config/")

## Git Commands for Reference

```bash
# Compare branches (run locally)
git fetch --all
git log branch_a..branch_b --oneline  # commits in B not in A
git log branch_b..branch_a --oneline  # commits in A not in B

# Find merge base
git merge-base branch_a branch_b

# Diff summary
git diff branch_a..branch_b --stat

# Diff specific path
git diff branch_a..branch_b -- path/to/dir/
```

## Example Output

```
Branch Comparison: upstream/master vs odh/master

Last sync: 2024-12-15 (commit abc1234 "Merge kserve v0.15.0")

Upstream ahead by: 47 commits
ODH ahead by: 12 commits (ODH-specific)

Key Differences:
- pkg/controller/: 15 files differ
  - Most are pending upstream changes
  - 2 files have ODH-specific modifications

- config/: 8 files differ
  - ODH overlay configurations (expected)

- .github/: Completely different (ODH uses OpenShift CI)

Potential Issues:
- WARNING: pkg/apis/serving/v1beta1/types.go has diverged
  - Upstream added new field in commit def5678
  - ODH has different implementation from earlier PR
  - Recommend: Review and reconcile before next sync

Recommendations:
1. Schedule upstream sync to pull in 47 new commits
2. Review types.go divergence before syncing
3. 3 commits have cherrypick-approved label, pending cherry-pick
```

