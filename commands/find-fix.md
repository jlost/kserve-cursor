# Find Fix

Search all KServe forks for existing fixes to a JIRA issue or bug description.

## Instructions

Before implementing a fix, check if it already exists in any fork to avoid duplicate work.

1. **Search by JIRA key** (if provided):
   - Search JIRA for issue details and linked PRs
   - Search GitHub PRs in all forks mentioning the JIRA key
   - Search commit messages for the JIRA key

2. **Search by keywords/description**:
   - Extract key terms from the bug description
   - Search GitHub code for related changes
   - Search PR titles and descriptions
   - Search commit messages

3. **Search each fork systematically**:

   ```
   Forks to search (in order):
   1. kserve/kserve (upstream) - original fix likely here
   2. opendatahub-io/kserve (ODH) - may have cherry-picked or custom fix
   3. red-hat-data-services/kserve (downstream) - may have hotfix
   ```

4. **Check Slack for discussions**:
   - Search for mentions of the issue
   - Look for workarounds discussed by team

5. **Analyze findings**:
   - Is there a merged fix in any fork?
   - Is there an open PR addressing this?
   - Is there a partial fix or workaround?
   - Which forks have the fix, which don't?

6. **Generate action plan**:
   - If fix exists: recommend cherry-pick workflow
   - If partial fix: recommend enhancement approach
   - If no fix: confirm original work needed

## User Input

JIRA Key (optional): {{jira_key}}

Bug description: {{description}}

Keywords: {{keywords}} (e.g., "nil pointer transformer", "memory leak predictor")

## Search Strategy

### For JIRA Key (e.g., RHOAIENG-1234)

```
GitHub search queries:
- repo:kserve/kserve RHOAIENG-1234
- repo:opendatahub-io/kserve RHOAIENG-1234
- repo:red-hat-data-services/kserve RHOAIENG-1234
```

### For Keywords

```
GitHub code search:
- "nil pointer" language:go repo:kserve/kserve
- "transformer config" path:pkg/controller repo:opendatahub-io/kserve
```

### For Error Messages

```
Search for unique error strings:
- "failed to reconcile" in controller code
- Specific panic messages
- Log error patterns
```

## Example Output

```
Search: RHOAIENG-5678 "predictor memory leak"

Results:

UPSTREAM (kserve/kserve):
  ✓ PR #4521 "Fix memory leak in predictor container" - MERGED
    - Merged: 2024-12-10
    - Commit: abc1234
    - Author: developer@example.com

ODH (opendatahub-io/kserve):
  ✓ PR #612 "Cherry-pick: Fix memory leak" - MERGED
    - Merged: 2024-12-12
    - Cherry-pick of upstream #4521
    - In: master branch
  
  ✗ NOT in release-v0.15 branch
    - Needs cherry-pick for next release

DOWNSTREAM (red-hat-data-services/kserve):
  ✗ No fix found
    - Needs cherry-pick from ODH

SLACK:
  - Discussion in #kserve-dev on 2024-12-08
  - Workaround mentioned: increase memory limits

RECOMMENDATION:
1. Fix exists in upstream and ODH master
2. Cherry-pick needed:
   - ODH master -> ODH release-v0.15
   - ODH -> downstream main
3. Use commit abc1234 for cherry-pick

Cherry-pick commands:
  git fetch odh
  git checkout -b cp-fix-memory-leak odh/release-v0.15
  git cherry-pick abc1234
  git push -u origin cp-fix-memory-leak
```

## No Fix Found Output

```
Search: "InferenceService stuck in Unknown state"

Results:

UPSTREAM: No matching PRs or commits
ODH: No matching PRs or commits  
DOWNSTREAM: No matching PRs or commits
SLACK: No relevant discussions

CONCLUSION: No existing fix found.

Suggested next steps:
1. Create new JIRA if not exists
2. Investigate the issue
3. Target: kserve/kserve master (if general issue)
   or opendatahub-io/kserve master (if ODH-specific)
4. Plan cherry-picks after fix is merged
```

