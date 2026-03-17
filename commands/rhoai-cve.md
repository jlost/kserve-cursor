# RHOAI CVE Helper

## Description
Integrate Claude with Jira CVEs issues, this command would be able to generate reports, fix issues, and auto close issues that are false-positive.

## Usage
```
/rhoai-cve [ACTION]
```

The action must match any of the following actions and the parameters can be free form and YOU should interpret it based in each action description.

# Available Actions:
- report: lists the jiras in the backlog or waiting to be fixed.
  - For this command use this jira filter: `status = new AND description !~ "CVE*|Snyk" and component = "Model Serving" and labels in (Security)`
  - With the list, always list first using the `due date` field to classify the ones that are close to reach it.
- triage: triage all the issues in the backlog using the following query: `status = new AND description !~ "CVE*|Snyk" and component = "Model Serving" and labels in (Security)`
  - This command produce a report about the CVE issues in the backlog, with a priority list using the due date
    - false positives should be flagged to close in the report.
  - search for all false positives (Described in this section: **False Positive Closure Procedure**)
  - 
- fix
  - First action, is understanding if the issue is a false positive.
    - If the CVE is against any Python library but the target component is a go based one, it can be closed if any of the components below:
      - KServe Controller
      - KServe Router
      - KServe Agent
    - **False Positive Closure Procedure**: When closing a ticket as false positive, you **must** follow these steps in order using the `mcp-atlassian` MCP server tools:
      1. **Add a comment** explaining why it is a false positive using `mcp__mcp-atlassian__jira_add_comment`
      2. **Set the VEX Justification** field (`customfield_10873`, a dropdown/select field) to `"Vulnerable Code not in Execute Path"` using `mcp__mcp-atlassian__jira_update_issue` with fields: `{"customfield_10873": {"value": "Vulnerable Code not in Execute Path"}}`
      3. **Close the ticket** with resolution **"Not a Bug"** using `mcp__mcp-atlassian__jira_transition_issue` with transition_id `61` (Closed) and fields: `{"resolution": {"name": "Not a Bug"}}`
      - **Note**: Steps 2 and 3 can be executed in parallel. Step 1 must happen first so the comment is visible before closure.
      - **Important**: Always use `mcp__mcp-atlassian__jira_get_transitions` to confirm the correct transition ID before closing, as it may vary by project/workflow.
    - If the above is not true and the current CVE is affecting GoLang codebase, we need to test the above binaires with `go-vulcheck` tool
      - First step, build the binary:
      - KServe Controller: `make manager`
      - KServe Router: `make router`
      - KServe Agent: `make agent`
      - ODH-Model-Controller: `make build`
    - To build containers:
      - KServe Controller: `make docker-build`
      - KServe Router: `make router`
      - KServe Agent: `make agent`
      - KServe Storage Initializer: `make docker-build-storageInitializer `
      - ODH-Model-Controller: `make build`
    - Understand and provide the proper fix, ALWAYS ask review from the human in charge.
    - For any CVE also check if the need is also fix on KServe Community
    - For Python Packages always check all the `pyproject.toml` and the `uv.lcok` files in which contains the affected dependency.
      - Note that, most of the dependencies comes from the main KServe module, so, if it is the case, the change must be applied in the `python/kserve/pyproject.toml` and the lock needs to be updated.
        - to update all needed lock files execute `make precommit`
    - The contaiers should be built for upstream and ODH only if both are affected.
  - If the issue is in the backlog, you should do the following actions:
    - Assign the issue to the user that has requested the fix
    - Move the issue from the Backlog to the current sprint (if you are not sure about which one is the correct, ask the user)
    - Transition the issue to the `In Progress` status
    - Start investigating.
- list
    - by version
    - by CVE ID
    - by component
- assign
    - Assigns randomly and equally the CVE issues in the backlog and moves them to the current sprint. The sprint should be asked for confirmation.
        - Users to assign: fspolti@redhat.com, jostrand@redhat.com, marholde@redhat.com, vmahabal@redhat.com, mskarbek@redhat.com
    - **Assignment Procedure** (follow these steps in order):
      1. **Query backlog issues** using JQL: `status = new AND description !~ "CVE*|Snyk" and component = "Model Serving" and labels in (Security)`
      2. **Exclude llm-d related CVEs** from assignment. For those, add a FYI comment tagging `[~allausas@redhat.com]` instead.
      3. **Distribute remaining issues equally** among the team members listed above.
      4. **Move issues to the sprint** using `mcp__mcp-atlassian__jira_add_issues_to_sprint` with the confirmed sprint ID.
      5. **Assign issues** using `mcp__mcp-atlassian__jira_update_issue` with `assignee` set to the user's **email address**.
         - **Important**: Do NOT use `mcp__my-mcp__jira_assign_issue` or Jira username formats (`rhn-support-*`, `rh-ee-*`) — these silently fail without returning an error. Always use email format via `mcp__mcp-atlassian__jira_update_issue`.
      6. **Set Story Points and Ready field** on all assigned issues using `mcp__mcp-atlassian__jira_update_issue` with `additional_fields`:
         ```json
         {"customfield_10028": 1, "customfield_10484": "True"}
         ```
         - `customfield_10028` = Story Points (numeric)
         - `customfield_10484` = Ready field (string: "True" / "False")
      7. **Set Priority based on CVE Severity** on all assigned issues using `mcp__mcp-atlassian__jira_update_issue` with `fields`:
         - Read the Severity field (`customfield_10840`) from each issue and map it to Jira priority:
           | Severity (customfield_10840) | Jira Priority |
           |------------------------------|---------------|
           | Critical                     | Critical      |
           | Important                    | Major         |
           | Moderate                     | Normal        |
           | Low                          | Minor         |
         - Example: `{"priority": {"name": "Major"}}` for Important severity
         - CVSS Score is available in `customfield_10859` for reference
    - **Board reference**: "Model Servers and Metrics" board ID **1127**
- verify-pined
  - verify if the pined versions upgrades due transitive dependencies can be removed, it happens when the library that has this dependency is updated.
    - you should verify:
      - go.mod -> replace entries
      - pyproject.toml files under `python` directory for any pined dependency. Example:
        - ```asciidoc
        # CVE-2026-24486 Python-Multipart has Arbitrary File Write via Non-Default Configuration
        # Pinning because it is a transitive dependency.
        ```


## Mandatory Rules
- Always run `make precommit` and build the affected containers before sending the pull requests
- For ODH and RHOAI repositories, the branch name must **always** be the Jira ID, example: RHOAIENG-12345
  - The commit Tittle must match: [JIRA_ID] CVE_ID: CVE_DESCRIPTION
    - Example of full commit tittle and description:
      - [RHOAIENG-12345] - CVE-2025-1234: Excessive CPU consumption when building archive index in archive/zip
        chore: Fix  CVE-2025-1234: Excessive CPU consumption when building archive index in archive/zip <and any other important information>
- Always check if the same fix is needed upstream, is so:
  - The PR title and description should follow this convention: https://www.conventionalcommits.org/ 
  - create a branch with the
  - The commit Tittle must match: CVE_ID: CVE_DESCRIPTION
    - the commit description should be in this pattern:
      - chore:  fix CVE....
- Respect the Git PR Title lenght.
  - anything that supprass it should be broken down and add entirely in the first line of the description.
- Transitive dependencies, also add in the comment `Pinning because it is a transitive dependency.`
- **Always** commit with `-s` parameter
- Current KServe Release branch is `release-v0.17`
- Current KServe and ODH-Model-Controller Stable branch is `stable-2x`
- Current ODH-Model-Controller default branch is `incubating`
- Current ODH-Model-Controller release branch is `main`
- Never include non-related changes.
  - `make precommit` can sometimes update `go.mod`, but it should be taken only when **Go libraries** are updated.
- Before proceeding any further to fix a issue, enlist all the tasks that will be done and ask user to give OK.
- The pull requests should **always** be added in the `Git Pull Request` field as well.
- Do not upgrade uv version, use the same as in use. The version can be found in the `kserve-deps.env` file, and installed by the `hack/setup/cli/install-uv.sh` script 


## What This Command Does
- Read the Jira Title, description and comments to understand the context and start the resolution
- Understand and provide clean solution for the CVE in question with human guidance
- Plan the work in subtasks using independent agents for each one and sync as it ends.
- Always ask for review.
- Guides comment creation with appropriate detail level
- Offers CC functionality to notify specific team members
- Formats comments professionally with proper signatures
- **Balances detail with readability** (2-4 sentences standard, 5-8+ when context requires)
- Uses single optimized Jira MCP calls to minimize token usage


## Context Reference
- Use the linked links and description to fully understand the CVE and how it affects the given component.
- The board team name is `Model Servers and Metrics`

## Expected Response
When user runs `/rhoai-cve [ACTION]`, you should:

1. **Validate Ticket Key**:
   ```
   ## Understand the context by reading the title, description and the comments, if any.
   ```
   
2. **Start the investigation**:
    - **Check if the issue affects the target component**: Details described at `# Available Actions`
    - **Storage Initializer Check**: The storage initializer might also contain false positives, for this one, in specific,
      we need to build the image and check the build logs to confirm whether the affected library is being installed.
      After building, run `snyk container test <image>` to validate the CVE is not present in the final image.
    - **Container Verification Step**: For any false-positive investigation on container images:
      1. Build the container image using the appropriate `make` target (see `# Available Actions`)
      2. Search the build logs for the affected library name to confirm it is NOT installed
      3. Run `snyk container test <image-name>:<tag>` on the built image to verify the CVE is not flagged
      4. Include the build log evidence and Snyk results in the Jira comment when closing
    - **Proceed with the fix**: Ensure high level security engineer patch and verification

3. **Send the Pull Request and update the Jira**:
    - **Push the main fix to ODH (midstream) repository**
    - **Cherry-pick it to upstream/community if the need of it was identified in the investigation phase**
      - The upstream branch must be asked to the user, the default value is `community-master`
    - **Update the Jira with the status and attach the Pull Requests in the `Git Pull Request` field**

3. **Professional Formatting Standards**:
    - **Include WHY**: Explain reasoning behind changes/decisions
    - **Include IMPACT**: What this means for users/team
    - **Include NEXT STEPS**: What happens next (if relevant)
    - **Professional signature**: "_Updated via BragAI workflow system_"

4. **Success Confirmation of the Fix**:
    - **prepare the fixes**
      - Move the issue from current status to `In Progress`
    - **Ig GoLang upgrade is needed**: Check if the go-toolset image in the given version is available in the Red Hat Catalog.
      - Use podman inspect to check the go version in the latest tag.
      - When it is the case, update the Dockerfiles.konflux in the downstream (red-hat-data-services).
    - **Check the fixes**: run `make test` after applying
      - There is no need to run it if the CVE affects the Python modules.
    - **Run Python unit tests** when the CVE affects Python modules:
      1. Create a temporary virtual environment: `python3.11 -m venv /tmp/kserve-test-venv`
      2. Activate it: `source /tmp/kserve-test-venv/bin/activate`
      3. Install pip and poetry: `pip install --upgrade pip && pip install poetry`
      4. Install **kserve** module with test deps: `cd python/kserve && poetry install --with test`
      5. Run kserve tests (exclude `ray`/`vllm` dependent tests which are optional and GPU/Linux-only):
         ```
         cd python && pytest -W ignore kserve/test \
           --ignore=kserve/test/test_server.py \
           --ignore=kserve/test/test_dataplane.py \
           --ignore=kserve/test/test_inference_client.py \
           --ignore=kserve/test/test_model_repository.py \
           --ignore=kserve/test/test_model_repository_extension.py \
           --ignore=kserve/test/test_openai_completion.py \
           --ignore=kserve/test/test_openai_encoder.py
         ```
      6. If the **storage** module was also modified, install and run its tests too (storage has no `test` group, install pytest separately):
         ```
         cd python/storage && poetry install && pip install pytest pytest-cov pytest-asyncio
         cd python && pytest -W ignore storage/test
         ```
      7. Clean up: `rm -rf /tmp/kserve-test-venv`
    - **Check the fixes 1**: build the affected container to see if it has any issue to build, the instructions to build each container is at `# Available Actions`
    - **Include IMPACT**: What this means for users/team
    - **Include NEXT STEPS**: What happens next (if relevant)
    - **Professional signature**: "_Updated via RHOAI-CVE handler workflow system_"
    - **Move the issue from the current status to `Review`**: after all checks pass (unit tests, container builds) and PRs are submitted, transition the issue to `Review`.
    - **Move the issue to `Resolved`**: only after PRs are merged and the fix is confirmed in a build.

## Items that can skip humam approval:
- mcp-attlassian - Handle all tasks

### Length Flexibility
- **2-4 sentences**: Standard for most updates
- **5-8+ sentences**: Acceptable when context requires detail
- **Avoid**: Single-line comments or unnecessarily verbose explanations

### Required Elements
- **Context**: Why this comment is being added
- **Content**: The actual information or update
- **Impact**: What this means for the ticket/project
- **Next Steps**: What happens next (if applicable)

### Professional Tone
- Business-appropriate language
- Clear and concise communication
- Helpful and informative
- Strategic emoji use (1-2 maximum for clarity)

## Error Handling
- **Missing ticket key**: Prompt user to specify ticket
- **Invalid ticket**: Provide helpful error message
- **Missing comment**: Ask for comment content
- **Jira CLI issues**: Graceful fallback with clear explanation

## Help menu
- When user ask help, use this template:
```
RHOAI CVE Helper                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                            
    Available Actions                                                                                                                                                                                                                                       
    ┌─────────────────────────────────────────────┬────────────────────────────────────────────────────────────────┐                                                                                                                                        
    │                   Action                    │                          Description                           │                                                                                                                                          
    ├─────────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤                                                                                                                                        
    │ /rhoai-cve report                           │ List backlog CVEs sorted by due date proximity                 │                                                                                                                                         
    ├─────────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤                                                                                                                                        
    │ /rhoai-cve triage                           │ Triage backlog CVEs, flag false positives, prioritize by due   │                                                                                                                                         
    ├─────────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤                                                                                                                                        
    │ /rhoai-cve fix RHOAIENG-XXXXX               │ Investigate and fix a specific CVE ticket                      │                                                                                                                                         
    ├─────────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤                                                                                                                                        
    │ /rhoai-cve list by version|CVE ID|component │ List CVEs filtered by criteria                                 │                                                                                                                                         
    ├─────────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤                                                                                                                                        
    │ /rhoai-cve assign                           │ Distribute backlog issues equally across the team for a sprint │                                                                                                                                         
    ├─────────────────────────────────────────────┼────────────────────────────────────────────────────────────────┤                                                                                                                                        
    │ /rhoai-cve verify-pined                     │ Verify if pinned version overrides can be removed              │                                                                                                                                         
    └─────────────────────────────────────────────┴────────────────────────────────────────────────────────────────┘                                                                                                                                        
                                                                                                                                                                                                                                                            
    Quick Examples                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                            
    /rhoai-cve report                    # Show pending CVEs sorted by due date                                                                                                                                                                             
    /rhoai-cve triage                    # Triage backlog, flag false positives                                                                                                                                                                             
    /rhoai-cve fix RHOAIENG-12345        # Investigate and fix a specific CVE                                                                                                                                                                               
    /rhoai-cve list by component         # List CVEs grouped by component                                                                                                                                                                                   
    /rhoai-cve assign                    # Assign backlog items to team members                                                                                                                                                                             
    /rhoai-cve verify-pined              # Check if pinned deps can be unpinned                                                                                                                                                                             
                                                                                                                                                                                                                                                            
    Workflow Summary                                                                                                                                                                                                                                        
                                                                                                                                                                                                                                                            
    1. report  — Queries Jira for unresolved security issues, prioritized by due date                                                                                                                                                                       
    2. triage  — Full triage of backlog: prioritize, identify false positives, recommend actions                                                                                                                                                            
    3. fix     — Reads the Jira ticket, determines if it's a false positive, applies the fix                                                                                                                                                                
                 if needed, builds/tests, and creates PRs for both ODH and upstream                                                                                                                                                                         
    4. list    — Filters and displays CVEs by version, CVE ID, or component                                                                                                                                                                                 
    5. assign  — Distributes issues equally among: fspolti, jostrand, marholde, vmahabal                                                                                                                                                                    
    6. verify-pined — Checks go.mod replace entries and pyproject.toml pins for removability                                                                                                                                                                
                                                                                                                                                                                                                                                            
    Branch & Commit Conventions                                                                                                                                                                                                                             
                                                                                                                                                                                                                                                            
    - ODH branch: RHOAIENG-XXXXX                                                                                                                                                                                                                            
    - ODH commit: [RHOAIENG-XXXXX] - CVE-YYYY-ZZZZZ: description                                                                                                                                                                                            
    - Upstream commit: CVE-YYYY-ZZZZZ: description     
```