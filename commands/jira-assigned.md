# My Assigned JIRAs

List and briefly summarize all JIRA issues assigned to me.

## Instructions

1. **Get current user** using JIRA MCP:
   - Identify the authenticated user's account

2. **Search for assigned issues** using JIRA MCP:
   - Use JQL: `assignee = currentUser() AND status NOT IN (Done, Closed) ORDER BY updated DESC`
   - Fetch key fields: summary, status, priority, updated, due date

3. **Summarize each issue briefly**:
   - Format: `KEY: Summary (Status, Priority)`
   - Group by status if there are many issues

4. **Highlight actionable items**:
   - Issues that are In Progress
   - Issues with approaching due dates
   - Issues blocked or waiting on others

## Output Format

```
## In Progress
- RHOAIENG-1234: Fix TLS certificate validation (In Progress, High)
- RHOAIENG-5678: Add retry logic to storage init (In Progress, Medium)

## To Do
- RHOAIENG-9012: Update documentation for v0.15 (To Do, Low)

## Blocked / Waiting
- RHOAIENG-3456: Waiting on upstream fix (Blocked, High)
```

## Example Usage

User: `/jira-assigned`

Expected output:
- Grouped list of assigned issues by status
- Brief one-line summary for each
- Total count of assigned issues

