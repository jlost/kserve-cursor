# PR Target

Determine the correct target fork and base branch for a proposed change.

## Instructions

Analyze the proposed change and recommend where to submit the PR.

1. **Understand the change type**:
   - Is this a bug fix, feature, or refactor?
   - Is it specific to OpenShift/ODH/RHODS or general KServe?
   - Does it depend on ODH-specific code paths?

2. **Check for existing code**:
   - Search the codebase for related files/functions
   - Determine if the affected code exists in upstream or is ODH-specific

3. **Apply targeting rules**:

   | Change Type | Target | Base Branch |
   |-------------|--------|-------------|
   | General KServe bug/feature | kserve/kserve | `master` |
   | OpenShift-specific fix | opendatahub-io/kserve | `master` |
   | ODH integration code | opendatahub-io/kserve | `master` |
   | Release-critical fix | opendatahub-io/kserve | `release-vX.Y` |
   | RHODS-only configuration | red-hat-data-services/kserve | `main` |
   | CI/build system (ODH) | opendatahub-io/kserve | `master` |

4. **Consider cherry-pick needs**:
   - If fixing in upstream, will it need cherry-pick to ODH?
   - If fixing in ODH master, does it need backport to release branch?
   - If fixing in ODH, does it need cherry-pick to downstream?

5. **Generate recommendation**:
   - Primary target fork and branch
   - Secondary cherry-pick targets (if applicable)
   - Branch naming suggestion
   - PR title format suggestion

## User Input

Describe the change: {{change_description}}

Affected files (if known): {{affected_files}}

## Decision Tree

```
Is the change OpenShift/ODH specific?
├── YES -> opendatahub-io/kserve
│   ├── Is it release-critical? -> release-vX.Y branch
│   └── Otherwise -> master branch
└── NO (general KServe)
    └── kserve/kserve master
        └── Plan cherry-pick to ODH after merge
```

## Example Output

```
Recommendation for: "Fix nil pointer when transformer config is empty"

Target: kserve/kserve
Base Branch: master
Reason: This is a general bug fix in core KServe code, not ODH-specific.

Suggested workflow:
1. Create branch: upstream/fix-nil-transformer-config
2. Submit PR to kserve/kserve master
3. After merge, cherry-pick to opendatahub-io/kserve master
4. If release-critical, also cherry-pick to odh/release-v0.15

PR Title: "Fix nil pointer panic when transformer config is missing"
```

