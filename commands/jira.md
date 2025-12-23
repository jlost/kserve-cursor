# JIRA Lookup

Look up a JIRA issue and find related PRs across all KServe forks.

## Instructions

Given a JIRA key (e.g., RHOAIENG-1234), perform the following:

1. **Get JIRA details** using JIRA MCP:
   - Fetch the issue with `fields: *all` and `expand: changelog` to get full context
   - Check the changelog for **RemoteIssueLink** entries - these contain linked GitHub PRs/issues
   - Check for linked JIRA issues (parent epics, sub-tasks, related issues)
   - Note any fix versions or target releases

2. **Follow ALL linked references** (CRITICAL):
   - For each RemoteIssueLink (GitHub PR/issue), fetch and summarize it
   - For each linked JIRA issue, fetch and check for its own linked PRs
   - Build the full context chain before summarizing

3. **Resolve ambiguous GitHub references**:
   - When a PR/issue number is referenced (e.g., "#942"), it may exist in multiple repos
   - Check ALL three forks if a reference seems unrelated:
     - `kserve/kserve`
     - `opendatahub-io/kserve`
     - `red-hat-data-services/kserve`
   - Cherry-pick PRs often reference the original PR number from a different fork

4. **Search for related PRs** using GitHub MCP across all forks:
   - Search `kserve/kserve` for PRs mentioning the JIRA key
   - Search `opendatahub-io/kserve` for PRs mentioning the JIRA key
   - Search `red-hat-data-services/kserve` for PRs mentioning the JIRA key

5. **Search for related commits** if no PRs found:
   - Search code commits that reference the JIRA key

6. **Check Slack** for discussions (optional):
   - Search for messages mentioning the JIRA key

7. **Summarize findings**:
   - JIRA status and summary
   - List of related PRs with their status (open/merged/closed)
   - Which forks have the fix
   - Whether cherry-picks are needed to other forks

## User Input

JIRA Key: {{jira_key}}

## Example Usage

User: `/jira RHOAIENG-1234`

Expected output:
- Issue details from JIRA
- PRs found in each fork
- Recommendation on next steps (e.g., "Fix merged in upstream, needs cherry-pick to ODH")

