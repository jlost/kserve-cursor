---
name: dev-environments
description: Set up development environments for KServe. Use when setting up Kind or CRC clusters, running E2E tests, starting devspace, or deploying local code changes.
---
# Development Environments

## Fork to Environment Mapping

| Fork | Environment | Cluster Type |
|------|-------------|--------------|
| Upstream (kserve/kserve) | Kind | Kubernetes |
| ODH (opendatahub-io/kserve) | CRC | OpenShift |
| Downstream (red-hat-data-services/kserve) | CRC | OpenShift |

**Kind and CRC cannot run simultaneously.** Stop one before starting the other.

## Quick Reference

**Detect target fork first** using branch/tracking signals from `fork-structure.mdc`:
- Branch `RHOAIENG-*` or tracking `odh/*` -> CRC
- Branch `master` or tracking `upstream/*` -> Kind

### Upstream -> Kind

```
1. mcp_ignition-mcp_task_kind_refresh
2. mcp_ignition-mcp_task_install_kserve_dependencies
3. mcp_ignition-mcp_task_install_network_dependencies
4. mcp_ignition-mcp_task_clean_deploy_kserve
5. mcp_ignition-mcp_task_patch_deployment_mode
```

Then: `mcp_ignition-mcp_launch_devspace` for local code
E2E tests: `mcp_ignition-mcp_launch_e2e_test_kind`

### ODH/Downstream -> CRC

```
1. mcp_ignition-mcp_task_crc_refresh
2. mcp_ignition-mcp_task_pull_secret
```

Then choose path:
- **Operator Path** (production parity): `mcp_ignition-mcp_task_install_odh_rhoai_operator` -> `mcp_ignition-mcp_task_apply_dsci_dsc`
- **E2E Path** (CI parity): `mcp_ignition-mcp_task_setup_e2e` -> `mcp_ignition-mcp_task_recreate_e2e_ns`

Then: `mcp_ignition-mcp_launch_devspace` for local code
E2E tests: `mcp_ignition-mcp_launch_e2e_test_odh_rhoai`

## Switching Environments

Kind -> CRC: `kind delete cluster`, then follow CRC steps
CRC -> Kind: `crc stop`, then follow Kind steps
