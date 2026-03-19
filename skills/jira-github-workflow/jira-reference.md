# JIRA Reference

## Description Format

The Rovo MCP supports `contentFormat: "markdown"` -- always use this when creating or editing
issues. Write descriptions in standard Markdown and the API converts them automatically.

**Always pass these parameters:**
- `contentFormat: "markdown"` (for input -- descriptions, comments)
- `responseContentFormat: "markdown"` (for output -- readable responses)

## Rovo MCP Defaults

All Jira MCP tool calls require `cloudId`. Use `"https://issues.redhat.com"` for Red Hat JIRA.

Use `responseContentFormat: "markdown"` to get readable content instead of ADF JSON.

## Fetching JIRA Context

When fetching a JIRA issue:

1. Call `getJiraIssue` with `expand: "changelog"` for complete info
2. Check changelog for **RemoteIssueLink** entries (GitHub PR/issue links)
3. Call again with `fields: ["comment"]` to fetch comments separately
4. Follow ALL linked PRs, issues, and related JIRAs
5. Check parent issues and sub-tasks

```
getJiraIssue(
  cloudId="https://issues.redhat.com",
  issueIdOrKey="RHOAIENG-1234",
  expand="changelog",
  responseContentFormat="markdown"
)
```

To fetch specific fields only:

```
getJiraIssue(
  cloudId="https://issues.redhat.com",
  issueIdOrKey="RHOAIENG-1234",
  fields=["summary", "status", "description", "comment"],
  responseContentFormat="markdown"
)
```

## Custom Field Reference

| Field | Custom Field ID | Value Format |
|-------|-----------------|--------------|
| Priority | `priority` | `{"name": "Normal"}` |
| Sprint | `customfield_10020` | `17570` (integer ID, changes each sprint) |
| Team | `customfield_10001` | `"ec74d716-af36-4b3c-950f-f79213d08f71-2896"` (string, UUID-based) |
| Git Pull Request | `customfield_12310220` | `["https://..."]` |
| Activity Type | Unknown | Not found in field metadata; set manually in JIRA UI |

**Priority:** Always set to `"Normal"` (do not leave as "Undefined")

**Team IDs:**
- `"ec74d716-af36-4b3c-950f-f79213d08f71-2896"` = "RHOAI Model Server and Serving Metrics" (default)

To discover other team IDs, search for an issue with the desired team set and read `customfield_10001`.

**Activity Type values** (set manually in JIRA UI):
`"General Engineering"`, `"Usability"`, `"Regression"`

## Issue Type Selection

**Default to Task** for most work items:

| Type | When to Use |
|------|-------------|
| **Task** | Default. CI fixes, workflow improvements, refactoring, technical debt, test improvements |
| **Bug** | Defects, broken functionality that needs fixing |
| **Story** | User-facing features with acceptance criteria |
| **Epic** | Large initiatives containing multiple tasks/stories |

## Creating Issues

Use a two-step approach for reliability:

**Step 1: Create with minimal fields**

```
createJiraIssue(
  cloudId="https://issues.redhat.com",
  projectKey="RHOAIENG",
  summary="Issue title",
  issueTypeName="Task",
  description="Description text",
  additional_fields={"components": [{"name": "Model Serving"}]},
  contentFormat="markdown",
  responseContentFormat="markdown"
)
```

**Step 2: Update fields individually**

Some fields fail when updated together. Update them one at a time:

```
# Priority
editJiraIssue(cloudId="https://issues.redhat.com", issueIdOrKey="RHOAIENG-1234", fields={"priority": {"name": "Normal"}})

# Team (string, UUID-based ID)
editJiraIssue(cloudId="https://issues.redhat.com", issueIdOrKey="RHOAIENG-1234", fields={"customfield_10001": "ec74d716-af36-4b3c-950f-f79213d08f71-2896"})

# Sprint (integer, not string)
editJiraIssue(cloudId="https://issues.redhat.com", issueIdOrKey="RHOAIENG-1234", fields={"customfield_10020": 17570})

# Parent (Epic link)
editJiraIssue(cloudId="https://issues.redhat.com", issueIdOrKey="RHOAIENG-1234", fields={"parent": {"key": "RHOAIENG-5678"}})
```

## Known API Quirks

| Field | Issue | Workaround |
|-------|-------|------------|
| Team | Pass string ID directly, NOT `{"id": "..."}` object | `"ec74d716-..."` not `{"id": "ec74d716-..."}` |
| Activity Type | Field not in edit metadata; can't be set via API | Set manually in JIRA UI |
| Parent/Epic | Update reports success but may not link | Verify after update; set manually if needed |
| Multiple fields | Batch updates fail unpredictably | Update fields one at a time |

## Sprint (Always Add to Current)

New issues should always be added to the current sprint. The sprint ID changes each cycle, so look it up dynamically.

**Step 1: Find the active sprint ID**

Search for a recent issue with a sprint, then fetch it to read `customfield_10020`:

```
searchJiraIssuesUsingJql(
  cloudId="https://issues.redhat.com",
  jql="project = RHOAIENG AND component = \"Model Serving\" AND Sprint IS NOT EMPTY ORDER BY updated DESC",
  fields=["customfield_10020"],
  maxResults=1,
  responseContentFormat="markdown"
)
```

The search response may not include `customfield_10020` inline. If so, fetch the returned issue:

```
getJiraIssue(
  cloudId="https://issues.redhat.com",
  issueIdOrKey="RHOAIENG-XXXXX",
  responseContentFormat="markdown"
)
```

Look for `customfield_10020` in the response. Find the entry with `"state": "active"` and note its `id` (e.g., `17570`).

**Step 2: Set the sprint on the new issue**

```
editJiraIssue(
  cloudId="https://issues.redhat.com",
  issueIdOrKey="RHOAIENG-1234",
  fields={"customfield_10020": 17570}
)
```

Note: Sprint ID is an integer, not a string.
