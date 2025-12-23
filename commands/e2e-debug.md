# E2E Debug

Debug failing E2E tests by analyzing cluster state, logs, and test output.

## Instructions

When E2E tests fail, systematically gather information to diagnose the issue.

1. **Understand the failure context**:
   - Which test marker/suite failed? (predictor, graph, path_based_routing)
   - What was the test attempting to do?
   - Is this a new failure or regression?

2. **Check cluster state** using Kubernetes MCP:
   - List pods in test namespace (`kserve-ci-e2e-test` by default)
   - Check pod status and restart counts
   - Look for pending/failed pods

3. **Gather logs**:
   - InferenceService controller logs
   - Predictor/transformer pod logs
   - Istio/ServiceMesh logs if networking issues
   - Events in the test namespace

4. **Analyze common failure patterns**:

   | Symptom | Likely Cause | Check |
   |---------|--------------|-------|
   | Pod ImagePullBackOff | Missing pull secret | Run "Pull Secret" task |
   | Pod Pending | Resource constraints | Check node resources |
   | Pod CrashLoopBackOff | Container error | Check pod logs |
   | Timeout waiting for Ready | Slow model load | Check model download |
   | 503 Service Unavailable | Routing issue | Check Istio/Gateway |
   | Connection refused | Service not ready | Check endpoints |

5. **Check test environment**:
   - Is DSCI/DSC properly configured?
   - Is the operator running?
   - Are CRDs installed?

## Available VS Code Tasks

Run these from the Command Palette (Ctrl+Shift+P -> "Tasks: Run Task"):

- **Setup E2E**: Initialize test environment with specified marker
- **Teardown E2E**: Clean up test resources
- **Recreate E2E ns**: Reset test namespace (quick cleanup)
- **Apply DSCI + DSC**: Ensure ODH components are configured
- **Create HF Token Secret**: Set up HuggingFace authentication

## Test Scripts Reference

```
test/scripts/openshift-ci/
├── setup-e2e-tests.sh      # Full E2E setup
├── teardown-e2e-setup.sh   # Full E2E teardown
├── setup-ci-namespace.sh   # Namespace setup only
├── run-e2e-tests.sh        # Run tests
└── common.sh               # Shared functions
```

## User Input

Test that failed: {{test_name}} (e.g., "test_sklearn_v2_kserve", "test_transformer")

Error message (if available): {{error_message}}

Test namespace: {{namespace}} (default: kserve-ci-e2e-test)

## Kubernetes MCP Queries

Use these to gather cluster state:

1. **List pods in test namespace**:
   - Check for Failed/Pending/CrashLoopBackOff status

2. **Get events**:
   - Look for warnings and errors

3. **Check InferenceService status**:
   - Ready conditions
   - URL assignment
   - Component status

4. **Get controller logs**:
   - Look for reconciliation errors

## Example Debug Session

```
Debugging: test_sklearn_v2_kserve failed with timeout

1. Cluster State Check:
   - Namespace: kserve-ci-e2e-test
   - Pods found:
     - sklearn-v2-predictor-xyz: Running (0 restarts)
     - sklearn-v2-predictor-abc: Pending (ImagePullBackOff)
   
2. Issue Identified:
   - Second pod stuck in ImagePullBackOff
   - Image: quay.io/opendatahub/kserve-controller:latest
   
3. Root Cause:
   - Pull secret not configured for quay.io

4. Resolution:
   - Run "Pull Secret" VS Code task
   - Delete stuck pod to trigger retry
   - Re-run test

Commands to fix:
  oc delete pod sklearn-v2-predictor-abc -n kserve-ci-e2e-test
  # Run VS Code task: "Pull Secret"
  # Re-run test
```

## Quick Diagnostic Commands

```bash
# Check all pods in test namespace
oc get pods -n kserve-ci-e2e-test

# Get events sorted by time
oc get events -n kserve-ci-e2e-test --sort-by='.lastTimestamp'

# Check InferenceService status
oc get isvc -n kserve-ci-e2e-test -o wide

# Get controller logs
oc logs -n redhat-ods-applications deployment/kserve-controller-manager --tail=100

# Describe failing pod
oc describe pod <pod-name> -n kserve-ci-e2e-test
```

