# PR Target

Determine the correct target repo, fork, and base branch for a proposed change.

## Instructions

Analyze the proposed change and recommend where to submit the PR.

1. **Determine the target repo**:
   - Use `workspace.mdc` and `repo-scope.mdc` to determine if this is kserve or odh-model-controller
   - OpenShift Routes, AuthConfig, ServiceMesh, NetworkPolicy -> odh-model-controller
   - Core model serving, predictors, transformers, autoscaling -> kserve

2. **Understand the change type**:
   - Is this a bug fix, feature, or refactor?
   - Is it specific to OpenShift/ODH/RHODS or general KServe?
   - Does it depend on ODH-specific code paths?

3. **Check for existing code**:
   - Search the codebase for related files/functions
   - Determine if the affected code exists in upstream or is ODH-specific

4. **Apply targeting rules**:

   **kserve:**

   | Change Type | Target | Base Branch |
   |-------------|--------|-------------|
   | General KServe bug/feature | kserve/kserve | `master` |
   | OpenShift-specific fix | opendatahub-io/kserve | `release-v0.17` |
   | ODH integration code | opendatahub-io/kserve | `release-v0.17` |
   | Release-critical fix | opendatahub-io/kserve | `release-vX.Y` |
   | RHODS-only configuration | red-hat-data-services/kserve | `main` |
   | CI/build system (ODH) | opendatahub-io/kserve | `release-v0.17` |

   **odh-model-controller:**

   | Change Type | Target | Base Branch |
   |-------------|--------|-------------|
   | ODH feature (latest) | opendatahub-io/odh-model-controller | `master` |
   | ODH feature (older) | opendatahub-io/odh-model-controller | `stable-X.x` |
   | Downstream-only change | red-hat-data-services/odh-model-controller | `main` |

5. **Consider cherry-pick needs**:
   - If fixing in upstream, will it need cherry-pick to ODH?
   - If fixing in ODH master, does it need backport to release branch?
   - If fixing in ODH, does it need cherry-pick to downstream?

6. **Generate recommendation**:
   - Target repo, fork, and branch
   - Secondary cherry-pick targets (if applicable)
   - Branch naming suggestion
   - PR title format suggestion

## User Input

Describe the change: {{change_description}}

Affected files (if known): {{affected_files}}

## Decision Tree

```
Which repo does this belong to?
├── kserve
│   └── Is the change OpenShift/ODH specific?
│       ├── YES -> opendatahub-io/kserve
│       │   ├── Is it release-critical? -> release-vX.Y branch
│       │   └── Otherwise -> release-v0.17 branch
│       └── NO (general KServe)
│           └── kserve/kserve master
│               └── Plan cherry-pick to ODH after merge
└── odh-model-controller
    └── opendatahub-io/odh-model-controller master
        └── Plan cherry-pick to downstream after merge
```

## Example Output

```
Recommendation for: "Fix nil pointer when transformer config is empty"

Target repo: kserve
Target fork: kserve/kserve
Base Branch: master
Reason: This is a general bug fix in core KServe code, not ODH-specific.

Suggested workflow:
1. Create worktree: cd kserve && git worktree add ../kserve-spinoff-fix-nil-transformer
2. Submit PR to kserve/kserve master
3. After merge, cherry-pick to opendatahub-io/kserve release-v0.17
4. If release-critical, also cherry-pick to odh/release-v0.15

PR Title: "Fix nil pointer panic when transformer config is missing"
```

## Related Commands

- `/jira-work` - Full JIRA-based workflow with research
- `/spinoff-pr` - Spin off unrelated changes to a separate PR
