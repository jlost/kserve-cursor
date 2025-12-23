# Cherry-Pick Check

Find missing cherry-picks between KServe forks by comparing commits.

## Instructions

Given a source and target fork/branch, identify commits that exist in the source but are missing from the target.

1. **Identify the comparison range**:
   - Source: The fork/branch where commits originated (e.g., `upstream/master`, `odh/master`)
   - Target: The fork/branch to check for missing commits (e.g., `odh/release-v0.15`, `downstream/main`)

2. **Use GitHub MCP to compare**:
   - List recent commits on the source branch
   - Check if each commit (by title/message pattern) exists in the target
   - Look for commits with `cherrypick-approved` label that lack `cherrypicked` label

3. **Check for JIRA references**:
   - Extract JIRA keys from commit messages (RHOAIENG-XXXX pattern)
   - Cross-reference with JIRA to see fix versions

4. **Generate report**:
   - List commits missing from target
   - Group by: critical fixes, features, minor changes
   - Suggest cherry-pick order (oldest first to minimize conflicts)

## Common Scenarios

### Upstream to ODH Master
Check what upstream commits need syncing to ODH:
- Source: `kserve/kserve` master
- Target: `opendatahub-io/kserve` master

### ODH Master to ODH Release Branch
Check what ODH master commits should be backported:
- Source: `opendatahub-io/kserve` master
- Target: `opendatahub-io/kserve` release-vX.Y

### ODH to Downstream
Check what ODH commits need cherry-picking to downstream:
- Source: `opendatahub-io/kserve` master or release branch
- Target: `red-hat-data-services/kserve` main

## User Input

Source: {{source_ref}} (e.g., "upstream/master", "kserve/kserve master")
Target: {{target_ref}} (e.g., "odh/release-v0.15", "downstream/main")

## Git Commands for Reference

```bash
# Find commits in source not in target (run locally)
git log target_branch..source_branch --oneline --first-parent

# Check if specific commit exists in branch
git branch -a --contains <commit-sha>
```

## Example Output

```
Missing cherry-picks from upstream/master to odh/release-v0.15:

CRITICAL (bug fixes):
- abc1234 [RHOAIENG-5678] Fix memory leak in predictor
- def5678 Fix nil pointer in transformer

FEATURES:
- 111aaaa Add support for new model format

MINOR:
- 222bbbb Update dependency versions

Recommended: Cherry-pick in order listed (oldest first).
```

