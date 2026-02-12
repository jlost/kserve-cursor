---
name: model-serving-release-workflow
description: RHOAI Model Serving release and process workflows. Use when the user asks how to get a change into RHOAI, code freezes, CVE process, or which repo/branch to use for a new feature (upstream vs ODH vs odh-model-controller).
---

# Model Serving Release Workflow

Use this skill when the user asks about getting changes into RHOAI, code freezes, CVE handling, or whether to work upstream vs ODH first.

## Two Workflows

### 1. KServe / ModelMesh (this repo: opendatahub-io/kserve)

**Entry: Is this a new feature?**
- **Yes** -> Can you contribute to upstream (kserve/kserve)?
  - **Yes:** Work on **Upstream/kserve master**. After upstream PR merges: either wait for Monday sync to ODH, or (if it must be in this RHOAI release) follow the RHOAI release path below.
  - **No:** Work on **ODH/kserve master**; then "Need to be in this RHOAI release?" drives the same release path.
- **No (not a new feature)** -> Is it a CVE?
  - **Yes:** Follow **CVE process** (red.ht/modelserving-cve-process).
  - **No:** Same "Can contribute to upstream?" branch as above.

**RHOAI release path:** "Need to be in this RHOAI release?" -> "Does it pass Internal Code Freeze?" -> "Does it pass Official Code Freeze?". If it fails a freeze: report to team, get approval **with Jira ticket**, then either cherry-pick to odh/release and sync odh/master -> odh/release, or wait for the regular sync process.

### 2. odh-model-controller (opendatahub-io/odh-model-controller)

**Entry: Is this a new feature?**
- **Yes** -> Work with **ODH/odh-model-controller incubating branch**.
- **No** -> Is it a CVE?
  - **Yes:** Follow **CVE process** (red.ht/modelserving-cve-process).
  - **No:** Work with **ODH/odh-model-controller incubating branch**.

**RHOAI release:** "Need to be in this RHOAI release?" -> Internal Code Freeze -> Official Code Freeze. If it fails: report to team and get **verbal** approval, then either wait for regular sync or manual path: **Sync from odh/incubating to RHOAI/release** (Cherry-pick to odh/main from incubating -> Sync odh/main -> RHOAI/main -> Sync RHOAI/main -> RHOAI/release). All manual.

## Regular Sync (ODH Release Process Owner)

- **Every Monday:** Sync upstream -> odh master.
- **Sprint timing:** First / second / last week of sprint: Start ODH Release Process (red.ht/odh-model-process).
- **Process:** Release odh-model-controller, KServe, ModelMesh (GitHub actions), update image tags on quay.io.
- **Post process:** Sync odh/release -> rhoai/main (odh-model-controller) or rhoai/master (KServe, ModelMesh).

## References

- CVE process: red.ht/modelserving-cve-process
- ODH release process: red.ht/odh-model-process

## Full diagrams

Full Mermaid flowcharts live in `modelServing-dev-workflow-mermaid.md` (e.g. in the user's Documents folder). This skill summarizes the decision flow; use the doc for detailed diagrams when needed.
