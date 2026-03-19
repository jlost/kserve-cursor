---
name: dev-environments
description: Set up development environments for kserve or odh-model-controller. Use when setting up Kind or CRC clusters, running E2E tests, starting devspace, or deploying local code changes.
---
# Development Environments

## Fork to Environment Mapping

| Fork | Environment | Cluster Type |
|------|-------------|--------------|
| Upstream (kserve/kserve) | Kind | Kubernetes |
| ODH (opendatahub-io/kserve or omc) | CRC | OpenShift |
| Downstream (red-hat-data-services/*) | CRC | OpenShift |

**Kind and CRC cannot run simultaneously.** Stop one before starting the other.

## Quick Reference

**Detect target fork first** using branch/tracking signals from the fork-structure rules:
- Branch `RHOAIENG-*` or tracking `odh/*` -> CRC
- Branch `master` or tracking `upstream/*` -> Kind

Run git commands from within the target repo directory (e.g., `kserve/` or `odh-model-controller/`).

### Upstream -> Kind

```bash
hack/setup/dev/manage.kind-with-registry.sh   # 1. Create/refresh Kind cluster
test/scripts/gh-actions/setup-deps.sh          # 2. Install kserve + network deps
make deploy-dev                                # 3. Deploy kserve with dev images
```

Then: `devspace dev` for local code
E2E tests: `test/scripts/gh-actions/run-e2e-tests.sh`

### ODH/Downstream -> CRC

```bash
crc start                                      # 1. Start/refresh CRC
# 2. Configure pull secret (via CRC setup or manual oc commands)
```

Then choose path:
- **Operator Path** (production parity): `test/scripts/openshift-ci/deploy.odh.sh`
- **E2E Path** (CI parity): `test/scripts/openshift-ci/setup-e2e-tests.sh` -> `test/scripts/openshift-ci/setup-ci-namespace.sh`

Then: `devspace dev` for local code
E2E tests: `test/scripts/openshift-ci/run-e2e-tests.sh`

## Switching Environments

Kind -> CRC: `kind delete cluster`, then follow CRC steps
CRC -> Kind: `crc stop`, then follow Kind steps
