# Pod Security Standards

## Scenario Overview
- **Time Limit**: 50 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Configure and enforce Pod Security Standards across different namespaces to control pod security policies using Kubernetes' built-in admission controller.

## Context
Your organization is implementing security governance across multiple environments. The development team needs flexible security policies for testing, while production workloads require strict security controls. You need to configure Pod Security Standards to automatically enforce these policies without manual intervention.

## Prerequisites
- Running k3s cluster with admin access
- `kubectl` configured and working
- Understanding of Kubernetes security contexts

## Tasks

### Task 1: Create Namespaces with Different Security Profiles
**Time**: 8 minutes

Create three namespaces representing different environments:
1. Create namespace **dev-unrestricted** with **privileged** Pod Security Standard
2. Create namespace **staging-baseline** with **baseline** Pod Security Standard  
3. Create namespace **prod-restricted** with **restricted** Pod Security Standard

Configure each namespace with appropriate labels:
- `pod-security.kubernetes.io/enforce`: The policy level to enforce
- `pod-security.kubernetes.io/audit`: The policy level for audit logging
- `pod-security.kubernetes.io/warn`: The policy level for warnings

**Hint**: Use `kubectl create namespace` followed by `kubectl label namespace` to configure the security standards.

### Task 2: Test Privileged Workloads
**Time**: 10 minutes

Deploy workloads to test the **privileged** security profile in the **dev-unrestricted** namespace:
1. Create a pod named **privileged-pod** that runs with **privileged: true** security context
2. Create a pod named **root-pod** that runs as **root user (UID 0)**
3. Create a pod named **hostpath-pod** that mounts a **hostPath volume** at **/host-data**

Each pod should use the **nginx:alpine** image and include the following volume configuration for the hostPath pod:

```yaml
volumes:
- name: host-data
  hostPath:
    path: /tmp
    type: Directory
```

### Task 3: Test Baseline Security Restrictions
**Time**: 12 minutes

Deploy workloads to test the **baseline** security profile in the **staging-baseline** namespace:
1. Create a pod named **baseline-allowed** that runs with a **non-root user (UID 1000)** and **read-only root filesystem**
2. Attempt to create a pod named **baseline-blocked** that tries to run with **privileged: true** (this should be blocked)
3. Create a pod named **baseline-caps** that drops **ALL capabilities** and adds only **NET_BIND_SERVICE**

The baseline-allowed pod should use this security context:

```yaml
securityContext:
  runAsUser: 1000
  runAsNonRoot: true
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
```

### Task 4: Test Restricted Security Enforcement
**Time**: 10 minutes

Deploy workloads to test the **restricted** security profile in the **prod-restricted** namespace:
1. Create a pod named **restricted-compliant** with the most restrictive security context
2. Attempt to create a pod named **restricted-blocked** that violates restricted policies
3. Create a deployment named **secure-app** with **2 replicas** that meets all restricted requirements

The restricted-compliant pod must include:
- **runAsNonRoot: true**
- **runAsUser: 1000**
- **runAsGroup: 3000**
- **fsGroup: 2000**
- **readOnlyRootFilesystem: true**
- **allowPrivilegeEscalation: false**
- **Drop ALL capabilities**
- **seccompProfile: RuntimeDefault**

### Task 5: Configure Audit and Warning Modes
**Time**: 5 minutes

Update the **staging-baseline** namespace to demonstrate audit and warning modes:
1. Set the **audit** level to **restricted** while keeping **enforce** at **baseline**
2. Set the **warn** level to **restricted** while keeping **enforce** at **baseline**
3. Deploy a pod that violates restricted policies but passes baseline to observe warnings

### Task 6: Migration from PodSecurityPolicy (Conceptual)
**Time**: 5 minutes

Understand the migration path from deprecated PodSecurityPolicy to Pod Security Standards:
1. Create a namespace **legacy-psp** and label it to simulate a PodSecurityPolicy equivalent
2. Compare a conceptual PodSecurityPolicy YAML with equivalent Pod Security Standard labels
3. Document the key differences and migration considerations for existing clusters

Review this conceptual PodSecurityPolicy that would be equivalent to **baseline** Pod Security Standard:

```yaml
# This is for reference only - PodSecurityPolicy is deprecated
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: baseline-equivalent
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

Create the **legacy-psp** namespace with labels that provide equivalent security to the above PodSecurityPolicy.

## Verification Commands

### Task 1 Verification
```bash
# Verify namespace creation and labels
kubectl get namespaces dev-unrestricted staging-baseline prod-restricted -o yaml

# Check Pod Security Standard labels
kubectl get namespace dev-unrestricted -o jsonpath='{.metadata.labels}'
kubectl get namespace staging-baseline -o jsonpath='{.metadata.labels}'
kubectl get namespace prod-restricted -o jsonpath='{.metadata.labels}'
```
**Expected Output**: Each namespace should show the appropriate `pod-security.kubernetes.io/*` labels with correct security levels.

### Task 2 Verification
```bash
# Verify privileged pods are running
kubectl get pods -n dev-unrestricted
kubectl describe pod privileged-pod -n dev-unrestricted
kubectl describe pod root-pod -n dev-unrestricted
kubectl describe pod hostpath-pod -n dev-unrestricted

# Check security contexts
kubectl get pod privileged-pod -n dev-unrestricted -o jsonpath='{.spec.containers[0].securityContext}'
kubectl get pod root-pod -n dev-unrestricted -o jsonpath='{.spec.containers[0].securityContext}'
```
**Expected Output**: All pods should be in **Running** status. The privileged-pod should show `"privileged":true`, root-pod should show `"runAsUser":0`, and hostpath-pod should have the hostPath volume mounted.

### Task 3 Verification
```bash
# Check baseline-allowed pod
kubectl get pod baseline-allowed -n staging-baseline
kubectl get pod baseline-allowed -n staging-baseline -o jsonpath='{.spec.containers[0].securityContext}'

# Verify baseline-blocked was rejected
kubectl get pod baseline-blocked -n staging-baseline 2>/dev/null || echo "Pod correctly blocked by baseline policy"

# Check baseline-caps pod capabilities
kubectl get pod baseline-caps -n staging-baseline -o jsonpath='{.spec.containers[0].securityContext.capabilities}'
```
**Expected Output**: baseline-allowed should be **Running** with correct security context. baseline-blocked should not exist or show creation errors. baseline-caps should show dropped capabilities and NET_BIND_SERVICE added.

### Task 4 Verification
```bash
# Check restricted-compliant pod
kubectl get pod restricted-compliant -n prod-restricted
kubectl get pod restricted-compliant -n prod-restricted -o yaml | grep -A 20 securityContext

# Verify restricted-blocked was rejected
kubectl get pod restricted-blocked -n prod-restricted 2>/dev/null || echo "Pod correctly blocked by restricted policy"

# Check deployment
kubectl get deployment secure-app -n prod-restricted
kubectl get pods -l app=secure-app -n prod-restricted
```
**Expected Output**: restricted-compliant should be **Running** with full restrictive security context. restricted-blocked should not exist. secure-app deployment should have 2 running replicas.

### Task 5 Verification
```bash
# Check updated namespace labels
kubectl get namespace staging-baseline -o jsonpath='{.metadata.labels}' | grep pod-security

# Deploy a test pod to see warnings
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: audit-test
  namespace: staging-baseline
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      runAsUser: 0
EOF

# Check for warnings in kubectl output
kubectl get events -n staging-baseline --field-selector reason=FailedCreate
```
**Expected Output**: Namespace should show audit and warn levels set to **restricted**. Pod creation should succeed but generate warnings about restricted policy violations.

### Task 6 Verification
```bash
# Verify legacy-psp namespace creation and labels
kubectl get namespace legacy-psp -o jsonpath='{.metadata.labels}'

# Test pod creation in legacy-psp namespace
kubectl run test-pod --image=nginx:alpine --namespace=legacy-psp --dry-run=client -o yaml

# Compare policy enforcement
kubectl get pods -n legacy-psp
```
**Expected Output**: legacy-psp namespace should have baseline Pod Security Standard labels. Pod creation should follow baseline policy restrictions, demonstrating equivalent security to the conceptual PodSecurityPolicy.

## Expected Results
- 4 namespaces created with appropriate Pod Security Standard labels
- dev-unrestricted: 3 running pods with privileged configurations
- staging-baseline: 2 running pods, 1 blocked pod demonstrating baseline enforcement
- prod-restricted: 1 running pod, 1 deployment with 2 replicas, 1 blocked pod
- staging-baseline configured with audit/warn modes generating appropriate warnings
- legacy-psp: namespace demonstrating PodSecurityPolicy migration concepts

## Key Learning Points
- Pod Security Standards provide three built-in security profiles: privileged, baseline, and restricted
- Security policies are enforced at the namespace level using standard Kubernetes labels
- Policies can be configured in enforce, audit, and warn modes independently
- The restricted profile enforces the most secure configuration for production workloads
- Baseline profile blocks known privileged escalations while allowing common container patterns
- Privileged profile allows unrestricted pod creation for development and testing
- Pod Security Standards replace deprecated PodSecurityPolicy with simpler label-based configuration
- Migration from PodSecurityPolicy involves mapping existing policies to equivalent Pod Security Standard profiles

## Exam & Troubleshooting Tips
- **CKA Exam**: Pod Security Standards replaced PodSecurityPolicy; know the three profiles and their differences
- **Migration Strategy**: Use audit mode to assess impact before migrating from PodSecurityPolicy to Pod Security Standards
- **Label Syntax**: Use `pod-security.kubernetes.io/enforce`, `pod-security.kubernetes.io/audit`, and `pod-security.kubernetes.io/warn`
- **Security Context**: Understand which security context settings are required for each profile
- **Troubleshooting**: Check admission controller logs if pods are unexpectedly blocked
- **Best Practice**: Use audit mode first to understand policy impact before enforcing
- **Common Error**: Forgetting `runAsNonRoot: true` in restricted profile - this is mandatory
- **PodSecurityPolicy Removal**: Ensure Pod Security Standards are configured before removing PodSecurityPolicy from clusters
- **Debugging**: Use `kubectl auth can-i create pods --as=system:serviceaccount:namespace:default` to test service account permissions