# Scheduler Configuration and Policy Issues

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Diagnose and resolve various kube-scheduler configuration failures that prevent proper pod scheduling in a Kubernetes cluster.

## Context
You're a Kubernetes administrator troubleshooting a production cluster where pods are stuck in Pending state. The development team reports that new deployments aren't being scheduled, and some existing workloads show inconsistent scheduling behavior. Your investigation reveals that the kube-scheduler component has various configuration issues that need immediate resolution.

## Prerequisites
- Access to a kubeadm-based Kubernetes cluster with sudo privileges
- Basic understanding of Kubernetes control plane components
- Familiarity with static pod manifests and systemd services
- kubectl configured with cluster-admin permissions

## Tasks

### Task 1: Create Test Workloads and Break Scheduler Configuration (5 minutes)

First, create test deployments to observe scheduling behavior, then introduce scheduler configuration problems.

Create a test deployment:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-scheduling
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: test-scheduling
  template:
    metadata:
      labels:
        app: test-scheduling
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

Now break the scheduler configuration by modifying the kubeconfig path:
1. Navigate to `/etc/kubernetes/manifests/`
2. Edit the `kube-scheduler.yaml` static pod manifest
3. Change the `--kubeconfig` parameter from `/etc/kubernetes/scheduler.conf` to `/etc/kubernetes/invalid-scheduler.conf`
4. Save the file and observe the scheduler behavior

### Task 2: Introduce Scheduler Policy Configuration Issues (5 minutes)

Create an invalid scheduler policy configuration:

1. Create a scheduler policy file with invalid JSON syntax:
```json
{
  "kind": "Policy",
  "apiVersion": "v1",
  "predicates": [
    {
      "name": "PodFitsHostPorts"
    },
    {
      "name": "PodFitsResources"
    }
    // Invalid comment in JSON
  ],
  "priorities": [
    {
      "name": "LeastRequestedPriority",
      "weight": 1
    }
  ]
}
```

2. Save this as `/etc/kubernetes/scheduler-policy.json`
3. Modify the scheduler manifest to use this policy by adding:
   - `--policy-config-file=/etc/kubernetes/scheduler-policy.json`
4. Restart the scheduler and observe the behavior

### Task 3: Configure Invalid Bind Address and Leader Election (5 minutes)

Introduce network and leader election configuration issues:

1. In the kube-scheduler manifest, modify the bind address:
   - Change `--bind-address=127.0.0.1` to `--bind-address=192.168.999.1` (invalid IP)

2. Break leader election configuration:
   - Add `--leader-elect=true`
   - Add `--leader-elect-lease-duration=0s` (invalid duration)
   - Add `--leader-elect-renew-deadline=0s` (invalid deadline)

3. Save the changes and monitor the scheduler's behavior

### Task 4: Create Resource Constraints and Multiple Scheduler Conflicts (5 minutes)

Simulate resource exhaustion and scheduler conflicts:

1. Create a second scheduler deployment with conflicting configuration:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: duplicate-scheduler
  namespace: kube-system
spec:
  replicas: 2
  selector:
    matchLabels:
      app: duplicate-scheduler
  template:
    metadata:
      labels:
        app: duplicate-scheduler
    spec:
      containers:
      - name: kube-scheduler
        image: k8s.gcr.io/kube-scheduler:v1.28.0
        command:
        - kube-scheduler
        - --kubeconfig=/etc/kubernetes/scheduler.conf
        - --leader-elect=true
        - --bind-address=0.0.0.0
        resources:
          requests:
            memory: "1Gi"
            cpu: "2000m"
          limits:
            memory: "1Gi"
            cpu: "2000m"
        volumeMounts:
        - name: kubeconfig
          mountPath: /etc/kubernetes/scheduler.conf
          readOnly: true
      volumes:
      - name: kubeconfig
        hostPath:
          path: /etc/kubernetes/scheduler.conf
          type: File
```

2. Apply this deployment and observe the scheduling conflicts

### Task 5: Diagnose and Resolve All Scheduler Issues (5 minutes)

Systematically troubleshoot and fix all introduced problems:

1. **Identify scheduling symptoms**:
   - Check pod status for the test deployment
   - Examine scheduler pod logs and status
   - Verify scheduler metrics and health endpoints

2. **Fix configuration issues**:
   - Restore correct kubeconfig path
   - Remove or fix invalid scheduler policy file
   - Correct bind address configuration
   - Fix leader election parameters

3. **Resolve resource and conflict issues**:
   - Remove duplicate scheduler deployment
   - Ensure proper resource allocation
   - Verify single scheduler instance with leader election

4. **Validate scheduler recovery**:
   - Ensure test pods are scheduled successfully
   - Verify scheduler health and metrics
   - Test new pod creation and scheduling

## Verification Commands

### Task 1 Verification:
```bash
# Check test deployment status
kubectl get deployment test-scheduling -o wide

# Check pod scheduling status
kubectl get pods -l app=test-scheduling -o wide

# Check scheduler pod status
kubectl get pods -n kube-system -l component=kube-scheduler

# Check scheduler logs for kubeconfig errors
kubectl logs -n kube-system -l component=kube-scheduler --tail=50
```

**Expected Output**: Pods should be in Pending state, scheduler logs should show kubeconfig file not found errors.

### Task 2 Verification:
```bash
# Verify scheduler policy file exists
ls -la /etc/kubernetes/scheduler-policy.json

# Check scheduler logs for policy parsing errors
kubectl logs -n kube-system -l component=kube-scheduler --tail=20 | grep -i policy

# Check scheduler pod restart count
kubectl get pods -n kube-system -l component=kube-scheduler -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}'
```

**Expected Output**: Scheduler logs should show JSON parsing errors, restart count should be increasing.

### Task 3 Verification:
```bash
# Check scheduler bind address configuration
kubectl get pods -n kube-system -l component=kube-scheduler -o yaml | grep -A5 -B5 bind-address

# Check scheduler logs for bind and leader election errors
kubectl logs -n kube-system -l component=kube-scheduler --tail=30 | grep -E "(bind|leader|election)"

# Check scheduler pod events
kubectl describe pods -n kube-system -l component=kube-scheduler | grep Events -A10
```

**Expected Output**: Scheduler should show bind address errors and leader election configuration failures.

### Task 4 Verification:
```bash
# Check for multiple scheduler instances
kubectl get deployments -n kube-system | grep scheduler

# Check scheduler leader election conflicts
kubectl logs -n kube-system -l app=duplicate-scheduler --tail=20

# Check cluster resource usage
kubectl top nodes
kubectl top pods -n kube-system
```

**Expected Output**: Multiple scheduler pods should be running, logs should show leader election conflicts and resource exhaustion.

### Task 5 Verification:
```bash
# Verify all pods are scheduled successfully
kubectl get pods -l app=test-scheduling -o wide

# Check final scheduler status
kubectl get pods -n kube-system -l component=kube-scheduler -o wide

# Verify scheduler health endpoint
kubectl get pods -n kube-system -l component=kube-scheduler -o jsonpath='{.items[0].status.containerStatuses[0].ready}'

# Test new pod scheduling
kubectl run test-pod --image=nginx:1.21 --rm -it --restart=Never -- echo "Scheduling test"

# Check scheduler metrics (if available)
kubectl proxy --port=8080 &
curl http://localhost:8080/api/v1/namespaces/kube-system/pods/kube-scheduler-<node-name>:10259/proxy/metrics | grep scheduler
```

**Expected Output**: All pods should be in Running state, scheduler should be healthy (ready=true), new pods should schedule successfully.

## Expected Results
- Test deployment with 3 pods successfully scheduled across available nodes
- Single healthy kube-scheduler instance running in kube-system namespace
- Scheduler configuration restored to valid state with correct kubeconfig path
- No duplicate or conflicting scheduler instances
- Leader election working properly with single elected leader
- Scheduler metrics and health endpoints accessible and reporting healthy status
- New pod creation and scheduling working normally

## Key Learning Points
- Kube-scheduler relies on valid kubeconfig for API server communication
- Invalid JSON syntax in scheduler policies causes parsing failures and restarts
- Network bind address configuration must use valid IP addresses accessible by the scheduler
- Leader election prevents multiple scheduler instances from making conflicting decisions
- Resource constraints on scheduler pods can impact scheduling performance and reliability
- Static pod manifests automatically restart components when configuration files change
- Scheduler troubleshooting requires examining pod status, logs, and cluster events systematically

## Exam & Troubleshooting Tips

### Real Exam Tips:
- **Pod Pending State**: When pods are stuck in Pending, always check scheduler status first
- **Configuration Files**: Remember that kube-scheduler configuration is in `/etc/kubernetes/manifests/kube-scheduler.yaml`
- **Leader Election**: Multi-master clusters require proper leader election to prevent scheduling conflicts
- **Quick Validation**: Use `kubectl get events --sort-by=.metadata.creationTimestamp` to see recent scheduling events
- **Log Analysis**: Scheduler logs contain detailed information about why pods cannot be scheduled

### Troubleshooting Tips:
- **Invalid kubeconfig**: Results in authentication failures and "connection refused" errors
- **JSON Policy Errors**: Cause scheduler restart loops with parsing error messages in logs
- **Bind Address Issues**: Lead to "cannot bind to address" errors and scheduler startup failures
- **Leader Election Problems**: Create multiple active schedulers and conflicting scheduling decisions
- **Resource Exhaustion**: Causes scheduler OOM kills and degraded scheduling performance
- **Certificate Expiration**: Results in authentication failures similar to invalid kubeconfig issues
- **Network Policies**: Can block scheduler communication with API server on some CNI implementations