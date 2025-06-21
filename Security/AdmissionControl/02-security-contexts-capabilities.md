# Security Contexts and Capabilities

## Scenario Overview
- **Time Limit**: 55 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Configure container and pod security contexts with Linux capabilities management to implement defense-in-depth security for a multi-tier financial application.

## Context
Your financial services company is migrating a critical payment processing application to Kubernetes. The security team requires strict access controls, principle of least privilege, and container hardening to meet compliance requirements. You need to implement proper security contexts and capabilities management across the application tiers.

## Prerequisites
- Running k3s cluster with admin access
- `kubectl` configured and working
- Understanding of Linux user/group permissions and capabilities

## Tasks

### Task 1: User and Group Security Context Configuration
**Time**: 12 minutes

Configure different security contexts for a multi-tier application:
1. Create a pod named **frontend-secure** that runs as **user ID 1001**, **group ID 2001**, with **fsGroup 3001**
2. Create a pod named **api-nonroot** that runs with **runAsNonRoot: true** and **user ID 1000**
3. Create a pod named **database-restricted** with **user ID 999**, **group ID 999**, and **allowPrivilegeEscalation: false**

Each pod should use the **nginx:alpine** image and mount a volume to demonstrate filesystem ownership behavior.

Use this volume configuration for all pods:

```yaml
volumes:
- name: data-volume
  emptyDir: {}
```

Mount the volume at **/app/data** in each container and verify the ownership and permissions.

### Task 2: Linux Capabilities Management
**Time**: 15 minutes

Implement capability-based security for different application requirements:
1. Create a pod named **network-service** that drops **ALL capabilities** and adds only **NET_BIND_SERVICE**
2. Create a pod named **time-sync** that drops **ALL capabilities** and adds only **SYS_TIME** 
3. Create a pod named **file-operations** that drops **ALL capabilities** and adds **CHOWN** and **FOWNER**
4. Create a pod named **minimal-caps** that demonstrates running with **no additional capabilities**

Use the **alpine:latest** image for these pods and include a command to keep the container running:

```yaml
command: ["sleep", "3600"]
```

Test the capability restrictions by attempting operations that require specific capabilities.

### Task 3: Filesystem Security Controls
**Time**: 10 minutes

Implement strict filesystem security controls:
1. Create a pod named **readonly-filesystem** with **readOnlyRootFilesystem: true**
2. Add a writable **emptyDir** volume mounted at **/tmp** for temporary files
3. Add another writable **emptyDir** volume mounted at **/var/log** for logging
4. Configure **allowPrivilegeEscalation: false** and **runAsNonRoot: true**

The pod should use **nginx:alpine** image and demonstrate that the root filesystem is read-only while specific directories remain writable.

### Task 4: Volume Permissions and fsGroup
**Time**: 8 minutes

Demonstrate volume ownership management with fsGroup:
1. Create a **PersistentVolumeClaim** named **shared-storage** requesting **1Gi** of storage
2. Create a pod named **volume-owner** with **fsGroup: 2000** that mounts the PVC at **/shared**
3. Create a second pod named **volume-consumer** with **fsGroup: 2000** and **runAsUser: 1500** that also mounts the same PVC

Both pods should use **busybox:latest** with command **["sleep", "3600"]**.

Verify that both pods can read and write to the shared volume due to the fsGroup configuration.

### Task 5: Production Security Hardening Template
**Time**: 10 minutes

Create a comprehensive security template for production workloads:
1. Create a **Deployment** named **secure-app** with **2 replicas**
2. Configure the deployment with the most restrictive security context combining all security best practices
3. Add **resource requests and limits** (CPU: 100m-200m, Memory: 128Mi-256Mi)
4. Include **liveness and readiness probes** for the application

The security context must include:
- **runAsNonRoot: true**
- **runAsUser: 1000**
- **runAsGroup: 3000**
- **fsGroup: 2000**
- **allowPrivilegeEscalation: false**
- **readOnlyRootFilesystem: true**
- **Drop ALL capabilities**
- **seccompProfile: RuntimeDefault**

Use **nginx:alpine** image and mount appropriate writable volumes for nginx operation.

## Verification Commands

### Task 1 Verification
```bash
# Check pod creation and security contexts
kubectl get pods frontend-secure api-nonroot database-restricted
kubectl describe pod frontend-secure
kubectl describe pod api-nonroot  
kubectl describe pod database-restricted

# Verify user and group IDs
kubectl exec frontend-secure -- id
kubectl exec api-nonroot -- id
kubectl exec database-restricted -- id

# Check filesystem ownership
kubectl exec frontend-secure -- ls -la /app/data
kubectl exec api-nonroot -- ls -la /app/data
kubectl exec database-restricted -- ls -la /app/data
```
**Expected Output**: frontend-secure should run as UID 1001/GID 2001, api-nonroot as UID 1000, database-restricted as UID 999. Volume directories should show appropriate group ownership based on fsGroup settings.

### Task 2 Verification
```bash
# Check pods are running
kubectl get pods network-service time-sync file-operations minimal-caps

# Verify capabilities configuration
kubectl describe pod network-service | grep -A 10 -B 5 capabilities
kubectl describe pod time-sync | grep -A 10 -B 5 capabilities
kubectl describe pod file-operations | grep -A 10 -B 5 capabilities

# Test capability restrictions
kubectl exec network-service -- apk add --no-cache bind-tools 2>/dev/null || echo "Expected: network operations work"
kubectl exec time-sync -- date -s "2024-01-01 12:00:00" 2>/dev/null || echo "Expected: time change blocked"
kubectl exec file-operations -- chown root:root /tmp 2>/dev/null || echo "Expected: chown operations work"
kubectl exec minimal-caps -- ping -c 1 google.com 2>/dev/null || echo "Expected: network operations blocked"
```
**Expected Output**: Each pod should show the appropriate capabilities configuration. Operations requiring missing capabilities should fail with permission errors.

### Task 3 Verification
```bash
# Check readonly-filesystem pod
kubectl get pod readonly-filesystem
kubectl describe pod readonly-filesystem

# Test filesystem restrictions
kubectl exec readonly-filesystem -- touch /test-file 2>/dev/null || echo "Expected: root filesystem read-only"
kubectl exec readonly-filesystem -- touch /tmp/test-file && echo "Writable /tmp works"
kubectl exec readonly-filesystem -- touch /var/log/test.log && echo "Writable /var/log works"

# Verify security settings
kubectl get pod readonly-filesystem -o jsonpath='{.spec.containers[0].securityContext}'
```
**Expected Output**: Pod should be running. Creating files in root filesystem should fail. Creating files in /tmp and /var/log should succeed. Security context should show readOnlyRootFilesystem: true.

### Task 4 Verification
```bash
# Check PVC and pods
kubectl get pvc shared-storage
kubectl get pods volume-owner volume-consumer

# Test volume permissions
kubectl exec volume-owner -- id
kubectl exec volume-consumer -- id
kubectl exec volume-owner -- touch /shared/owner-file
kubectl exec volume-consumer -- touch /shared/consumer-file
kubectl exec volume-owner -- ls -la /shared/
kubectl exec volume-consumer -- ls -la /shared/

# Verify both pods can access each other's files
kubectl exec volume-owner -- cat /shared/consumer-file 2>/dev/null && echo "Cross-access works"
kubectl exec volume-consumer -- cat /shared/owner-file 2>/dev/null && echo "Cross-access works"
```
**Expected Output**: Both pods should be running with different user IDs but same fsGroup (2000). Both should be able to create and access files in the shared volume due to group ownership.

### Task 5 Verification
```bash
# Check deployment and pods
kubectl get deployment secure-app
kubectl get pods -l app=secure-app

# Verify security context configuration
kubectl get deployment secure-app -o yaml | grep -A 20 securityContext

# Check resource constraints
kubectl describe deployment secure-app | grep -A 10 -B 5 "Limits\|Requests"

# Test application functionality
kubectl exec deployment/secure-app -- nginx -t
kubectl exec deployment/secure-app -- ls -la /var/cache/nginx/
kubectl exec deployment/secure-app -- ls -la /var/run/

# Verify probes are configured
kubectl describe deployment secure-app | grep -A 5 -B 5 "Liveness\|Readiness"
```
**Expected Output**: Deployment should have 2 running replicas. Security context should show all restrictive settings. nginx should start successfully with read-only root filesystem and writable cache/run directories. Probes should be configured and passing.

## Expected Results
- 3 pods with different user/group security contexts demonstrating filesystem ownership
- 4 pods with various Linux capability configurations showing privilege restrictions
- 1 pod with read-only root filesystem and selective writable volumes
- 2 pods sharing a PVC with fsGroup-based access control
- 1 deployment with production-grade security hardening and 2 running replicas

## Key Learning Points
- Security contexts control process user/group IDs and filesystem permissions
- fsGroup enables shared volume access across multiple containers
- Linux capabilities provide fine-grained privilege control beyond root/non-root
- readOnlyRootFilesystem prevents container filesystem modifications
- allowPrivilegeEscalation blocks privilege escalation attempts
- Combining multiple security controls creates defense-in-depth protection
- Production workloads should use minimal privileges and maximum security restrictions

## Exam & Troubleshooting Tips
- **CKA Exam**: Know the difference between runAsUser (process UID) and fsGroup (volume ownership)
- **Capability Format**: Use capability names without CAP_ prefix (e.g., NET_ADMIN, not CAP_NET_ADMIN)
- **Volume Permissions**: fsGroup only affects volume ownership, not container processes
- **ReadOnly Root**: Always provide writable volumes for application requirements (logs, cache, tmp)
- **Troubleshooting**: Use `kubectl exec pod -- id` to verify user/group settings
- **Security Testing**: Use `kubectl exec pod -- ls -la /path` to check filesystem permissions
- **Common Error**: Forgetting to add writable volumes when using readOnlyRootFilesystem
- **Best Practice**: Always combine multiple security controls rather than relying on single mechanisms
- **Debugging**: Check container logs for permission denied errors when security contexts are too restrictive