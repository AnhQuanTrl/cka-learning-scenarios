# Scheduler Authentication and Performance Issues

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Diagnose and resolve scheduler authentication failures, RBAC permission issues, resource constraints, and performance problems affecting pod scheduling in a Kubernetes cluster.

## Context
You're the platform engineer for a growing e-commerce company. The development team is reporting that new application deployments are failing - pods are stuck in Pending state for extended periods, and some are never getting scheduled. The monitoring team has also noticed scheduler performance degradation and intermittent authentication errors in the logs. You need to investigate and fix these scheduler-related issues to restore normal cluster operations.

## Prerequisites
- Killercoda Ubuntu Playground environment (or similar kubeadm cluster)
- Root access to control plane node
- Understanding of Kubernetes scheduler components
- Familiarity with systemd service management
- Knowledge of RBAC and certificate troubleshooting

## Tasks

### Task 1: Create Initial Test Workloads and Break Scheduler Authentication (8 minutes)
Create test applications to demonstrate scheduler functionality, then simulate authentication failures by using invalid certificates in the scheduler configuration.

Step 1a: Create test deployment workloads to verify scheduling behavior:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-frontend
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-backend
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api-backend
  template:
    metadata:
      labels:
        app: api-backend
    spec:
      containers:
      - name: api
        image: httpd:2.4
        resources:
          requests:
            cpu: 150m
            memory: 256Mi
          limits:
            cpu: 300m
            memory: 512Mi
```

Step 1b: Create a namespace with specific workloads to test scheduler behavior:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database-replica
  namespace: production
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database-replica
  template:
    metadata:
      labels:
        app: database-replica
    spec:
      containers:
      - name: postgres
        image: postgres:13
        env:
        - name: POSTGRES_DB
          value: replica_db
        - name: POSTGRES_USER
          value: replica_user
        - name: POSTGRES_PASSWORD
          value: replica_pass
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 1000m
            memory: 2Gi
```

Step 1c: Break scheduler authentication by creating an invalid certificate in the scheduler kubeconfig. First, backup the original kubeconfig, then replace the client certificate with an expired one:
```bash
# Backup original scheduler kubeconfig
cp /etc/kubernetes/scheduler.conf /etc/kubernetes/scheduler.conf.backup

# Create an expired certificate (expires immediately)
openssl req -new -key /etc/kubernetes/pki/scheduler.key -out /tmp/scheduler-expired.csr -subj "/CN=system:kube-scheduler"
openssl x509 -req -in /tmp/scheduler-expired.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -out /tmp/scheduler-expired.crt -days -1 -CAcreateserial

# Replace the certificate in scheduler kubeconfig
base64 -w 0 /tmp/scheduler-expired.crt > /tmp/scheduler-expired-b64.txt
```

Step 1d: Modify the scheduler kubeconfig to use the expired certificate by editing the `client-certificate-data` field. Update `/etc/kubernetes/scheduler.conf` and replace the existing certificate data with the expired one from `/tmp/scheduler-expired-b64.txt`.

### Task 2: Configure Scheduler RBAC Permission Issues (5 minutes)
Create RBAC permission problems by modifying the scheduler's service account permissions and cluster role bindings.

Step 2a: Modify the system:kube-scheduler ClusterRoleBinding to remove critical permissions. Remove the scheduler's ability to update pod status and create events:
```bash
# Get current ClusterRole permissions
kubectl get clusterrole system:kube-scheduler -o yaml > /tmp/scheduler-role-backup.yaml

# Create a restricted version
kubectl get clusterrole system:kube-scheduler -o yaml | sed '/- pods\/status/d' | sed '/- events/d' | kubectl apply -f -
```

Step 2b: Create additional RBAC restrictions by removing the scheduler's access to node information:
```bash
# Remove nodes permissions from scheduler ClusterRole
kubectl get clusterrole system:kube-scheduler -o yaml | sed '/- nodes/d' | kubectl apply -f -
```

### Task 3: Simulate Scheduler Resource Constraints and Performance Issues (4 minutes)
Configure the scheduler with insufficient resources causing memory pressure and performance degradation.

Step 3a: Modify the scheduler static pod manifest to use minimal memory limits that will cause OOM conditions. Edit `/etc/kubernetes/manifests/kube-scheduler.yaml` and add resource constraints:
```yaml
resources:
  limits:
    memory: "32Mi"
    cpu: "50m"
  requests:
    memory: "16Mi"
    cpu: "25m"
```

Step 3b: Configure invalid metrics bind address that conflicts with existing services. In the same manifest file, add conflicting command arguments:
```yaml
- --bind-address=127.0.0.1
- --secure-port=10259
- --metrics-bind-address=0.0.0.0:10250  # This conflicts with kubelet
```

Step 3c: Add an invalid scheduler configuration file reference to cause configuration parsing errors:
```yaml
- --config=/etc/kubernetes/invalid-scheduler-config.yaml
```

### Task 4: Diagnose Authentication and Permission Failures (4 minutes)
Identify the authentication and RBAC issues affecting scheduler functionality through log analysis and permission testing.

Step 4a: Analyze scheduler pod logs to identify authentication failures. Look for certificate validation errors and API server connection issues.

Step 4b: Test scheduler service account permissions using `kubectl auth can-i` commands to verify RBAC access:
- Test pod status update permissions
- Test node read permissions  
- Test event creation permissions

Step 4c: Verify scheduler certificate validity using OpenSSL commands to check expiration dates and certificate chain validation.

### Task 5: Resolve Performance and Resource Issues (4 minutes) 
Fix the resource constraints and performance configuration problems affecting scheduler operation.

Step 5a: Restore appropriate resource limits for the scheduler pod by modifying the static pod manifest with production-ready values.

Step 5b: Fix the metrics bind address conflict by configuring a unique port that doesn't conflict with other cluster components.

Step 5c: Remove the invalid scheduler configuration file reference or create a valid configuration file at the specified path.

## Verification Commands

### Task 1 Verification:
```bash
# Verify test workloads are created but pods may be pending
kubectl get deployments -A
kubectl get pods -A --field-selector=status.phase=Pending

# Check scheduler pod status and logs for authentication errors
kubectl get pods -n kube-system -l component=kube-scheduler
kubectl logs -n kube-system -l component=kube-scheduler --tail=50

# Verify certificate expiration
openssl x509 -in /tmp/scheduler-expired.crt -text -noout | grep -A 2 "Validity"
```
**Expected Output**: Test deployments created, pods stuck in Pending state, scheduler logs showing certificate validation errors like "certificate has expired".

### Task 2 Verification:
```bash
# Verify RBAC permissions are restricted
kubectl auth can-i update pods/status --as=system:kube-scheduler
kubectl auth can-i create events --as=system:kube-scheduler  
kubectl auth can-i get nodes --as=system:kube-scheduler

# Check scheduler logs for permission denied errors
kubectl logs -n kube-system -l component=kube-scheduler --tail=30 | grep -i "forbidden\|denied"
```
**Expected Output**: All `kubectl auth can-i` commands should return "no", scheduler logs showing RBAC permission denied errors.

### Task 3 Verification:
```bash
# Check scheduler pod resource usage and OOM conditions
kubectl top pods -n kube-system -l component=kube-scheduler
kubectl describe pod -n kube-system -l component=kube-scheduler | grep -A 10 "Resource Limits"

# Verify scheduler pod restart count due to OOM
kubectl get pods -n kube-system -l component=kube-scheduler -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}'

# Check for port conflict errors in logs
kubectl logs -n kube-system -l component=kube-scheduler | grep -i "bind\|port\|address"
```
**Expected Output**: High resource usage, non-zero restart count indicating OOM kills, port binding conflict errors in logs.

### Task 4 Verification:
```bash
# Verify authentication failure diagnosis
kubectl logs -n kube-system -l component=kube-scheduler | grep -i "certificate\|auth\|tls"

# Confirm RBAC permission test results
kubectl auth can-i --list --as=system:kube-scheduler | head -20

# Validate certificate issues with OpenSSL
openssl verify -CAfile /etc/kubernetes/pki/ca.crt /tmp/scheduler-expired.crt
```
**Expected Output**: Clear authentication errors in logs, limited permissions in auth listing, certificate verification failure.

### Task 5 Verification:
```bash
# Verify scheduler is running normally with proper resources
kubectl get pods -n kube-system -l component=kube-scheduler
kubectl logs -n kube-system -l component=kube-scheduler --tail=20

# Confirm pods are being scheduled successfully
kubectl get pods -A --field-selector=status.phase=Running | wc -l
kubectl get pods -A --field-selector=status.phase=Pending | wc -l

# Verify scheduler authentication is working
kubectl logs -n kube-system -l component=kube-scheduler | grep -i "successfully\|started"
```
**Expected Output**: Scheduler pod running without restarts, increasing number of Running pods, decreasing Pending pods, successful authentication messages in logs.

## Expected Results
- All test deployments (web-frontend, api-backend, database-replica) have pods in Running state
- Scheduler pod shows 0 restarts and healthy status
- Scheduler logs show successful authentication and normal scheduling operations
- RBAC permissions restored for system:kube-scheduler service account
- No port conflicts or resource constraint errors in scheduler configuration
- Scheduler performance metrics accessible without conflicts

## Key Learning Points
- **Scheduler Authentication**: Understanding certificate-based authentication for scheduler component
- **RBAC Troubleshooting**: Diagnosing and fixing scheduler service account permissions
- **Resource Management**: Configuring appropriate resource limits for control plane components
- **Performance Optimization**: Identifying and resolving scheduler performance bottlenecks
- **Log Analysis**: Using logs to diagnose authentication, authorization, and configuration issues
- **Static Pod Troubleshooting**: Managing scheduler configuration through static pod manifests

## Exam & Troubleshooting Tips
- **Real Exam Tips**: 
  - Always check pod status first when scheduling issues occur
  - Use `kubectl auth can-i` to quickly test RBAC permissions
  - Scheduler issues often cause cascading failures across the cluster
  - Static pod manifests require kubelet restart to pick up changes
- **Troubleshooting Tips**:
  - **Certificate Issues**: Use `openssl x509 -text -noout -in <cert>` to inspect certificate details
  - **RBAC Problems**: Check both ClusterRole and ClusterRoleBinding for scheduler permissions
  - **Resource Constraints**: Monitor control plane component resource usage with `kubectl top`
  - **Performance Issues**: Look for OOMKilled status and high restart counts
  - **Configuration Errors**: Validate scheduler static pod manifest syntax before applying changes
  - **Recovery Strategy**: Always backup original configurations before making changes