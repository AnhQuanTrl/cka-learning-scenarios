# Service Account Authentication

## Scenario Overview
- **Time Limit**: 30 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Master ServiceAccount authentication patterns by implementing both automatic token mounting and manual token generation for a real monitoring application, comparing legacy and modern approaches.

## Context
Your company runs a microservices architecture where different teams need automated monitoring. The platform team has requested you to set up authentication for two monitoring scenarios:

1. **Internal Pod Monitoring**: Deploy a monitoring pod that automatically authenticates using ServiceAccount tokens to collect metrics from the same namespace
2. **External Monitoring Tool**: Create a kubeconfig for an external monitoring script that needs read-only access to multiple namespaces

You need to implement both the modern TokenRequest API approach and the legacy token method, then compare their security characteristics and lifecycle management.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended)
- `kubectl` installed and configured with administrative access
- Basic understanding of Kubernetes authentication concepts

## Tasks

### Task 1: Create Initial Resources and Monitoring Application
*Suggested Time: 8 minutes*

Set up the foundation with namespaces, ServiceAccounts, and a real monitoring workload.

1. **Create two namespaces**: `monitoring` and `app-prod`

2. **Create a ServiceAccount** named `pod-monitor` in the `monitoring` namespace

3. **Create a simple monitoring application** that will use the ServiceAccount. Create a deployment named `pod-monitor` in the `monitoring` namespace with the following specifications:
   - Use image: `busybox:1.35`
   - Command: `sleep 3600`
   - ServiceAccount: `pod-monitor`
   - Include environment variable `MONITORED_NAMESPACE` set to `app-prod`

4. **Create a test application** in the `app-prod` namespace. Deploy a pod named `test-app` using `nginx:1.21` image to provide something for the monitoring to observe.

### Task 2: Configure RBAC for Cross-Namespace Monitoring
*Suggested Time: 7 minutes*

Set up permissions that allow the monitoring ServiceAccount to read resources across namespaces.

1. **Create a ClusterRole** named `cross-namespace-monitor` that grants the following permissions:
   - Read access to pods, services, and deployments in any namespace
   - Read access to pod logs across namespaces
   - Read access to nodes (for cluster-level monitoring)

2. **Create a ClusterRoleBinding** that grants the `pod-monitor` ServiceAccount the `cross-namespace-monitor` ClusterRole

3. **Verify the automatic token mounting** by checking that the monitoring pod has access to the ServiceAccount token through the projected volume

### Task 3: Test Automatic ServiceAccount Authentication
*Suggested Time: 5 minutes*

Validate that the monitoring pod can authenticate and access resources using its automatically mounted token.

1. **Execute into the monitoring pod** and locate the ServiceAccount token files

2. **Test authentication** by using the token to make API calls to list pods in both `monitoring` and `app-prod` namespaces

3. **Verify token characteristics** including the issuer, expiration time, and audience claims

### Task 4: Create Manual Token for External Access
*Suggested Time: 7 minutes*

Generate a longer-lived token for external monitoring tools using the legacy approach.

1. **Create a Secret** of type `kubernetes.io/service-account-token` for the `pod-monitor` ServiceAccount

2. **Extract the token, CA certificate, and server information** needed to build a kubeconfig

3. **Construct a kubeconfig file** named `external-monitor-kubeconfig.yaml` with:
   - Cluster configuration with CA certificate and server URL
   - User configuration with the extracted token
   - Context that defaults to the `app-prod` namespace

### Task 5: Compare Token Approaches and Test Security Boundaries
*Suggested Time: 3 minutes*

Analyze the differences between automatic and manual token approaches, then verify security boundaries.

1. **Compare token characteristics**:
   - Examine expiration times of both token types
   - Check token issuer and audience claims
   - Document which approach provides better security

2. **Test security boundaries** using the external kubeconfig:
   - Verify read access to allowed resources
   - Confirm creation operations are denied
   - Test access to unauthorized namespaces (should fail)

## Verification Commands

### Task 1: Resource Creation Verification
```bash
# Verify namespaces exist
kubectl get namespaces monitoring app-prod

# Check ServiceAccount creation
kubectl get serviceaccount pod-monitor -n monitoring

# Verify monitoring deployment
kubectl get deployment pod-monitor -n monitoring -o jsonpath='{.spec.template.spec.serviceAccountName}'

# Confirm test application is running
kubectl get pod test-app -n app-prod
```

**Expected Output**:
- Both namespaces should be listed as `Active`
- ServiceAccount `pod-monitor` should exist in `monitoring` namespace
- Deployment should show `serviceAccountName: pod-monitor`
- Test app pod should be in `Running` status

### Task 2: RBAC Configuration Verification
```bash
# Check ClusterRole exists and has correct permissions
kubectl get clusterrole cross-namespace-monitor -o yaml

# Verify ClusterRoleBinding
kubectl get clusterrolebinding -o yaml | grep -A 5 -B 5 "pod-monitor"

# Test ServiceAccount permissions
kubectl auth can-i list pods --as=system:serviceaccount:monitoring:pod-monitor -n app-prod
kubectl auth can-i list pods --as=system:serviceaccount:monitoring:pod-monitor -n monitoring
kubectl auth can-i get nodes --as=system:serviceaccount:monitoring:pod-monitor
```

**Expected Output**:
- ClusterRole should contain rules for pods, services, deployments with get/list/watch verbs
- ClusterRoleBinding should show `pod-monitor` ServiceAccount as subject
- All `auth can-i` commands should return `yes`

### Task 3: Automatic Token Verification
```bash
# Check automatic token mounting
kubectl exec -n monitoring deployment/pod-monitor -- ls -la /var/run/secrets/kubernetes.io/serviceaccount/

# Verify token works for API calls
kubectl exec -n monitoring deployment/pod-monitor -- sh -c 'curl -k -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc/api/v1/namespaces/app-prod/pods'

# Check token expiration
kubectl exec -n monitoring deployment/pod-monitor -- sh -c 'cat /var/run/secrets/kubernetes.io/serviceaccount/token' | cut -d. -f2 | base64 -d | jq -r '.exp'
```

**Expected Output**:
- Token directory should contain `token`, `ca.crt`, and `namespace` files
- API call should return JSON with pod information
- Token should have expiration time (Unix timestamp)

### Task 4: Manual Token Verification
```bash
# Verify Secret creation
kubectl get secret -n monitoring -o jsonpath='{.items[?(@.type=="kubernetes.io/service-account-token")].metadata.name}'

# Test external kubeconfig
kubectl --kubeconfig=external-monitor-kubeconfig.yaml get pods -n app-prod
kubectl --kubeconfig=external-monitor-kubeconfig.yaml get pods -n monitoring

# Verify kubeconfig structure
kubectl --kubeconfig=external-monitor-kubeconfig.yaml config view
```

**Expected Output**:
- Secret name should be listed
- Pod listing should work for both namespaces
- Config view should show cluster, context, and user sections

### Task 5: Security and Comparison Verification
```bash
# Compare token expiration times
echo "Automatic token expiration:"
kubectl exec -n monitoring deployment/pod-monitor -- sh -c 'cat /var/run/secrets/kubernetes.io/serviceaccount/token' | cut -d. -f2 | base64 -d | jq -r '.exp | strftime("%Y-%m-%d %H:%M:%S")'

echo "Manual token expiration:"
kubectl get secret -n monitoring -o jsonpath='{.items[?(@.type=="kubernetes.io/service-account-token")].data.token}' | base64 -d | cut -d. -f2 | base64 -d | jq -r 'if .exp then (.exp | strftime("%Y-%m-%d %H:%M:%S")) else "No expiration" end'

# Test security boundaries
kubectl --kubeconfig=external-monitor-kubeconfig.yaml create deployment test --image=nginx -n app-prod
kubectl --kubeconfig=external-monitor-kubeconfig.yaml get secrets -n kube-system
```

**Expected Output**:
- Automatic token should show expiration timestamp (typically 1 hour)
- Manual token should show "No expiration" or much longer expiration
- Creation command should fail with `Forbidden` error
- Secrets access should fail with `Forbidden` error

## Expected Results

After completing all tasks, you should have:

1. **Monitoring Infrastructure**: 
   - `pod-monitor` deployment running with automatic ServiceAccount authentication
   - `test-app` pod providing monitoring target

2. **RBAC Configuration**:
   - ClusterRole with cross-namespace read permissions
   - ClusterRoleBinding connecting ServiceAccount to permissions

3. **Authentication Methods**:
   - Automatic token mounting working inside pod
   - Manual token available for external access via kubeconfig

4. **Security Validation**:
   - Read permissions working across namespaces
   - Write permissions properly denied
   - Unauthorized namespace access blocked

## Key Learning Points

- **Automatic vs Manual Tokens**: Automatic tokens (projected volumes) are short-lived and more secure, while manual tokens (secrets) are longer-lived but less secure
- **Token Lifecycle**: Modern Kubernetes rotates automatic tokens, while manual tokens require manual rotation
- **Cross-Namespace Authentication**: ServiceAccounts can access multiple namespaces when bound to ClusterRoles
- **ServiceAccount Format**: API server recognizes ServiceAccounts as `system:serviceaccount:namespace:name`
- **Security Best Practices**: Use automatic tokens for in-cluster applications, manual tokens only when necessary for external access
- **Token Projection**: Modern Kubernetes mounts tokens as projected volumes with audience and expiration controls

## Exam & Troubleshooting Tips

### Real Exam Tips
- **Fast ServiceAccount Creation**: Use `kubectl create serviceaccount` for speed
- **RBAC Testing**: Always use `kubectl auth can-i` to verify permissions before deploying applications
- **Token Location**: Automatic tokens are always at `/var/run/secrets/kubernetes.io/serviceaccount/token`
- **External Access**: Manual token creation requires Secret of type `kubernetes.io/service-account-token`
- **Cross-Namespace Access**: Requires ClusterRole and ClusterRoleBinding, not Role and RoleBinding

### Common Troubleshooting Issues
- **403 Forbidden Errors**: Check RBAC bindings and verify ServiceAccount has correct permissions
- **Token Not Found**: Ensure ServiceAccount exists and automatic mounting is not disabled
- **Kubeconfig Issues**: Verify CA certificate, server URL, and token are correctly extracted
- **Cross-Namespace Access**: Confirm ClusterRoleBinding exists and references correct ServiceAccount
- **Token Expiration**: Automatic tokens expire, manual tokens from secrets typically don't (unless configured)
- **ServiceAccount Mounting**: Some pods disable automatic mounting via `automountServiceAccountToken: false`