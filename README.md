# 🤖 KServe Agentic Prompts

AI agent rules and commands for developing KServe on OpenShift. This is a companion to the [kserve-workspace](https://github.com/jlost/kserve-workspace) VS Code configuration.

## ✨ Features

* **Cursor/Claude Code Rules** - Context-aware rules that help the AI understand the multi-fork structure and workflows
* **Slash Commands** - Pre-built prompts for common development tasks like JIRA lookup, cherry-pick checking, and PR targeting
* **MCP Integration** - Configured for JIRA, GitHub, and Slack

## 📋 Prereqs

This repository depends on the [kserve-workspace](https://github.com/jlost/kserve-workspace) being cloned as `.vscode` in the same KServe repository.

## 🚀 Setup

1. Ensure `.vscode` is already set up (see [kserve-workspace README](https://github.com/jlost/kserve-workspace)):
    ```sh
    cd kserve
    git clone git@github.com:jlost/kserve-workspace.git .vscode
    ```

2. Clone this repository into your kserve repository at the root, named as `.cursor`:
    ```sh
    cd kserve
    git clone git@github.com:jlost/kserve-prompts.git .cursor
    ```
    You should now have both `.vscode` and `.cursor` directories at the root of the kserve repository.

3. Symlink global rules (one-time, applies across all ODH repos):
    ```sh
    mkdir -p ~/.cursor/rules
    ln -sf "$(pwd)/.cursor/global-rules/odh-fork-structure.mdc" ~/.cursor/rules/
    ```

4. Configure MCP servers (one-time):

    First, set the required environment variables in your shell config (`~/.zshenv` or `~/.bashrc`):
    ```sh
    # GitHub MCP
    export GITHUB_MCP_TOKEN="ghp_xxxx"

    # JIRA integration
    export JIRA_URL="https://issues.redhat.com"
    export JIRA_PERSONAL_TOKEN="your-token"

    # Slack integration (extract from browser cookies)
    # See: https://github.com/maorfr/slack-token-extractor
    export SLACK_XOXC_TOKEN="xoxc-xxxx"
    export SLACK_XOXD_TOKEN="xoxd-xxxx"
    ```

    Then run the setup script to generate `~/.cursor/mcp.json`:
    ```sh
    .cursor/scripts/setup-mcp.sh
    ```

5. Start Cursor:
    ```sh
    cursor .
    ```

## 📦 Contents

### 📜 Rules (`rules/`)

Cursor rules that provide context to the AI agent:

| Rule | Description |
|------|-------------|
| `fork-structure.mdc` | Repo-specific fork details (upstream/odh/downstream paths) |
| `git-workflow.mdc` | Git worktrees, commit signing, PR creation |
| `jira-github.mdc` | JIRA/GitHub integration and cross-reference handling |
| `mcp-tools.mdc` | Available MCP tools for cross-repository workflows |
| `e2e-testing.mdc` | E2E testing scripts, markers, and VS Code tasks |

### 🌍 Global Rules (`global-rules/`)

Rules meant to be symlinked to `~/.cursor/rules/` for cross-repo consistency:

| Rule | Description |
|------|-------------|
| `odh-fork-structure.mdc` | Generic ODH fork patterns, branch targeting, cherry-pick flow |

**Why symlink?**
- Rules stay version-controlled in this repo
- Updates propagate automatically via git pull
- Single source of truth for the team
- Works across all ODH repos without copying files

### ⚡ Commands (`commands/`)

Slash commands for common workflows:

#### 🎫 JIRA Workflow Commands

| Command | Description |
|---------|-------------|
| `/jira-work TICKET` | **Full workflow:** research -> determine target -> create worktree |
| `/jira-research TICKET` | Deep search for existing work, document findings in JIRA |
| `/jira TICKET` | Quick context fetch (no deep search, no JIRA comment) |
| `/jira-assigned` | List assigned JIRA issues |

**Workflow composition:** `/jira-research` -> `/jira-work` -> `/jira` (in new worktree)

**Usage examples:**

```bash
# Full workflow: research issue, create worktree, start coding
/jira-work RHOAIENG-1234

# Research only (no worktree creation)
/jira-research RHOAIENG-1234

# Quick lookup of JIRA context
/jira RHOAIENG-1234

# Skip research if already done, specify target directly
/jira-work RHOAIENG-1234 skip_research:true target:odh/release-v0.15
```

#### 🔍 Code Investigation Commands

| Command | Description |
|---------|-------------|
| `/pr-target` | Determine correct PR target for changes |
| `/cherrypick-check` | Check if a commit needs cherry-picking |
| `/branch-compare` | Compare branches across forks |
| `/find-fix ISSUE` | Find the fix for an issue across forks |

#### 🧪 Testing Commands

| Command | Description |
|---------|-------------|
| `/e2e-debug` | Debug E2E test failures |

#### 📦 Release Commands

| Command | Description |
|---------|-------------|
| `/odh-release` | Guide through ODH release process |

## 🔄 Applying to Other ODH Repos

To set up Cursor rules for another ODH-pattern repository:

1. **Copy `.cursor/rules/fork-structure.mdc`** and update with repo-specific details:
   - Repository name
   - Upstream org/repo path (usually `kserve/<repo>`)
   - Any repo-specific documentation paths

2. **Symlink global rules** (if not already done):
   ```sh
   ln -sf /path/to/kserve/.cursor/global-rules/odh-fork-structure.mdc ~/.cursor/rules/
   ```

The global rules symlink only needs to be created once per user - it applies to all workspaces.

## 🤝 Contributions

Contributions welcome! Fork and submit a pull request.

### 💡 Best Practices for Shared Prompt Repositories

**Live with changes before proposing them.** Prompt engineering is empirical - what seems like an improvement in theory may not work well in practice. Before submitting a PR:

1. **Use the change for at least a week** across varied real tasks
2. **Note specific outcomes** - did the agent follow the rule? Did it help or create friction?
3. **Watch for edge cases** - rules that help in one scenario may hurt in another
4. **Check for conflicts** - new rules may contradict or interfere with existing ones

**Keep rules focused and actionable.** Vague guidance like "be thorough" doesn't help. Specific instructions like "always fetch JIRA comments separately since fields:*all excludes them" do.

**Iterate on wording.** Small phrasing changes can significantly affect agent behavior. If a rule isn't being followed, try:
- Making it more prominent (move earlier, add emphasis)
- Making it more specific (add examples)
- Simplifying the language

**Document the "why".** When adding rules, include context about what problem they solve. This helps others understand whether the rule applies to their situation and makes future cleanup easier.

**Test across models.** Different AI models interpret prompts differently. A rule that works well with one model may need adjustment for another.
