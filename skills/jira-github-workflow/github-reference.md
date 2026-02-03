# GitHub Reference

## PR Template

Base PR descriptions on `.github/PULL_REQUEST_TEMPLATE.md`. Delete irrelevant sections to reduce noise; keep only applicable checkboxes.

## PR Description Conventions

### Cherry-picks

Include source reference in description:
- "Cherry-pick of kserve/kserve#1234"
- "Backport of opendatahub-io/kserve#567"

### Cross-fork coordination

Note if PR needs cherry-picking to other forks.

## Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/) for upstream:

```
<type>: <description>

<optional body>

Signed-off-by: Your Name <email@example.com>
```

### Type Prefixes

| Prefix | Usage |
|--------|-------|
| `feat:` | New features |
| `fix:` | Bug fixes |
| `chore:` | Maintenance, dependency updates |
| `ci:` | CI/CD changes |
| `docs:` | Documentation |

### Examples

```
feat: Add pathTemplate configuration for inference service routing

Signed-off-by: Your Name <email@example.com>
```

```
fix: clear stale router and scheduler conditions on config changes

Signed-off-by: Your Name <email@example.com>
```

### CVE References

For security fixes, reference CVE directly:
```
CVE-2024-43598: Update lightgbm version to 4.6.0
```
