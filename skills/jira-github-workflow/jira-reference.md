# JIRA Reference

## JIRA Markup (Not Markdown)

JIRA does NOT support Markdown. Use JIRA wiki markup:

| Element | Markdown | JIRA Markup |
|---------|----------|-------------|
| Bold | `**text**` | `*text*` |
| Italic | `_text_` | `_text_` |
| Code inline | `` `code` `` | `{{code}}` |
| Code block | ` ```lang ``` ` | `{code:lang}...{code}` |
| Link | `[text](url)` | `[text\|url]` |
| Bullet list | `- item` | `* item` |
| Numbered list | `1. item` | `# item` (see note) |
| Heading | `## Heading` | `h2. Heading` |

**Numbered list bug:** When using `# item` via MCP, `#` may convert to `h1.` (heading). Workarounds:
- Use bullet lists (`* item`) instead
- Fix manually in JIRA UI after creation
- Use explicit numbering: `1. item`, `2. item`

## Fetching JIRA Context

When fetching a JIRA issue:

1. Use `fields: "*all"` and `expand: "changelog"` for complete info
2. Check changelog for **RemoteIssueLink** entries (GitHub PR/issue links)
3. Check comments for PR links (especially upstream PRs)
4. Follow ALL linked PRs, issues, and related JIRAs
5. Check parent issues and sub-tasks

## Fetching Comments

Comments are controlled by the `comment_limit` parameter (default: 10, max: 100):

```
jira_get_issue(
  issue_key="RHOAIENG-1234",
  fields="summary,status,description",
  comment_limit=20
)
```

Key points:
- `comment_limit` controls how many comments are included (set to 0 to exclude)
- Default is 10 comments - set higher if you need more context
- Comments appear in the response under the `comment` field

**Default fields** (when `fields` is omitted):
`reporter,labels,priority,assignee,issuetype,updated,summary,description,created,status`

## Custom Field Reference

| Field | Custom Field ID | Field Type | Value Format |
|-------|-----------------|------------|--------------|
| Priority | `priority` | Standard | `{"name": "Normal"}` |
| Team | `customfield_12313240` | Teams plugin | `"4156"` (string ID) |
| Activity Type | `customfield_12320040` | Select | `{"value": "General Engineering"}` |
| Sprint | `customfield_12310940` | Greenhopper | `81370` (integer ID) |
| Git Pull Request | `customfield_12310220` | Multi-URL | `["https://..."]` |

**Priority:** Always set to `"Normal"` (do not leave as "Undefined")

**Team IDs:**
- `"4156"` = "RHOAI Model Server and Serving Metrics" (default)
- `"4155"` = "RHOAI Model Serving Runtimes"

**Activity Type values:** `"General Engineering"`, `"Usability"`, `"Regression"`

## Issue Type Selection

**Default to Task** for most work items:

| Type | When to Use |
|------|-------------|
| **Task** | Default. CI fixes, workflow improvements, refactoring, technical debt, test improvements |
| **Bug** | Defects, broken functionality that needs fixing |
| **Story** | User-facing features with acceptance criteria |
| **Epic** | Large initiatives containing multiple tasks/stories |

## Creating Issues

The `additional_fields` parameter often fails during creation. Use a two-step approach:

**Step 1: Create with minimal fields**

```
jira_create_issue(
  project_key="RHOAIENG",
  summary="Issue title",
  issue_type="Task",
  components="Model Serving",
  description="Description in JIRA markup"
)
```

**Step 2: Update fields individually**

Some fields fail when updated together. Update them one at a time:

```
# Priority
jira_update_issue(issue_key="RHOAIENG-1234", fields={"priority": {"name": "Normal"}})

# Parent (Epic link)
jira_update_issue(issue_key="RHOAIENG-1234", fields={"parent": {"key": "RHOAIENG-5678"}})

# Team
jira_update_issue(issue_key="RHOAIENG-1234", fields={"customfield_12313240": "4156"})

# Sprint (integer, not string)
jira_update_issue(issue_key="RHOAIENG-1234", fields={"customfield_12310940": 81370})
```

## Known API Quirks

| Field | Issue | Workaround |
|-------|-------|------------|
| Activity Type | Update via API often fails silently | Set manually in JIRA UI |
| Parent/Epic | Update reports success but may not link | Verify after update; set manually if needed |
| Multiple fields | Batch updates fail unpredictably | Update fields one at a time |

## Sprint (Always Add to Current)

**Board ID:** `23162` (Kserve Squad board)

New issues should always be added to the current sprint. The sprint ID changes each cycle, so look it up first:

```
jira_search(
  jql="project = RHOAIENG AND component = \"Model Serving\" AND Sprint IS NOT EMPTY",
  fields="customfield_12310940",
  limit=1
)
```

Look for `state=ACTIVE` in the response to get the sprint ID (e.g., `81370`).

Then include it when creating/updating the issue:

```
jira_update_issue(
  issue_key="RHOAIENG-1234",
  fields={"customfield_12310940": 81370}
)
```

Note: Sprint ID is an integer, not a string.
