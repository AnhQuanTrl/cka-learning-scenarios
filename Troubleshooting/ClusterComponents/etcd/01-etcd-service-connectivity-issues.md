# etcd Service and Connectivity Issues

## Scenario Overview
- **Time Limit**: 40 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Master troubleshooting critical etcd service and connectivity failures that cause complete cluster outages in production environments.

## Context
It's 3 AM and you receive an urgent page from your monitoring system: "Kubernetes API server unreachable - all applications down." Users can't access any services, deployments aren't updating, and kubectl commands are timing out. Initial investigation reveals that the API server can't connect to etcd, the heart of your Kubernetes cluster's data store. You have 40 minutes to diagnose and restore etcd connectivity before the business impact becomes catastrophic.

## Prerequisites
- Access to Killercoda Ubuntu Playground with a running kubeadm cluster
- Root access to control plane and worker nodes
- Basic understanding of etcd architecture and Kubernetes control plane components
- Familiarity with systemd service management

## Tasks

### Task 1: Create Production-Like Environment and Break etcd Service (8 minutes)
Set up a realistic scenario where etcd service failures cascade into cluster-wide outages.

First, create a **production workload** to demonstrate the impact:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: critical-app-service
  namespace: default
spec:
  selector:
    app: critical-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Create a **monitoring pod** to test cluster responsiveness:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cluster-monitor
  namespace: kube-system
spec:
  containers:
  - name: monitor
    image: curlimages/curl:latest
    command: ['sleep', '3600']
  restartPolicy: Always
```

Now **break the etcd service** to simulate the production incident. On the control plane node, execute:
```bash
# Stop the etcd service
sudo systemctl stop etcd

# Verify etcd is stopped
sudo systemctl status etcd
```

**Alternative breaking methods** (choose one):
- **Data directory modification**: Change etcd data directory to non-existent path in `/etc/kubernetes/manifests/etcd.yaml`
- **Listen address corruption**: Modify etcd listen addresses to invalid IPs in the etcd manifest
- **Member URL misconfiguration**: Corrupt etcd cluster member URLs in etcd configuration

### Task 2: Assess Cluster Impact and Identify etcd Connectivity Issues (7 minutes)
Document the cascading failures caused by etcd service disruption and confirm etcd as the root cause.

**Test API server accessibility**:
- Attempt basic kubectl commands (get nodes, get pods, get services)
- Try to create new resources or modify existing ones
- Check if the Kubernetes API server responds to health checks

**Examine API server logs** for etcd connectivity errors:
- Look for connection refused errors to etcd endpoints
- Identify timeout messages and retry attempts
- Find specific error patterns related to etcd communication failures

**Check control plane component status**:
- Verify which static pods are running vs failing
- Examine kube-controller-manager and kube-scheduler behavior
- Identify which components depend on etcd and are affected

Document the **failure timeline** and **impact scope** to understand the full extent of the etcd connectivity issue.

### Task 3: etcd Service Status and Configuration Analysis (8 minutes)
Perform deep diagnosis of etcd service health and configuration issues.

**Analyze etcd service status**:
- Check systemd service status and recent failures
- Examine etcd service logs for startup errors
- Identify why etcd failed to start or maintain connectivity

**Validate etcd configuration files**:
- Inspect `/etc/kubernetes/manifests/etcd.yaml` for configuration errors
- Check etcd data directory permissions and existence
- Verify etcd listen addresses and client URLs are valid and reachable

**Test etcd network connectivity**:
- Verify etcd ports (2379, 2380) are accessible
- Check firewall rules affecting etcd communication
- Test network connectivity between API server and etcd endpoints

**Examine etcd cluster membership**:
- Use etcdctl to check cluster member status (if etcd is partially functional)
- Identify any cluster configuration mismatches
- Verify peer URLs and client URLs are correctly configured

### Task 4: etcd Service Recovery and Connectivity Restoration (10 minutes)
Restore etcd service functionality and verify full cluster connectivity.

**Restore etcd service**:
- Start the etcd service using systemctl
- Monitor etcd startup logs for successful initialization
- Verify etcd is listening on correct ports and addresses

**Fix configuration issues** (if broken configurations were used):
- Correct data directory paths in etcd manifest
- Restore valid listen addresses and client URLs
- Fix any cluster member URL misconfigurations

**Validate etcd cluster health**:
- Use etcdctl to check cluster health and member status
- Verify etcd can accept read and write operations
- Test etcd cluster consensus and leader election

**Restart dependent services** if necessary:
- Restart kube-apiserver if it's in a failed state
- Monitor API server reconnection to etcd
- Verify control plane components are functioning normally

### Task 5: Cluster Functionality Verification and Post-Incident Analysis (5 minutes)
Confirm complete cluster recovery and implement preventive measures.

**Test full cluster functionality**:
- Verify kubectl commands work normally across all resource types
- Check that the critical-app deployment is healthy and responsive
- Test resource creation, modification, and deletion operations

**Validate workload health**:
- Ensure all pods are running and ready
- Test service connectivity and load balancing
- Verify that any disrupted workloads have recovered

**Implement monitoring and alerting**:
- Set up etcd health monitoring
- Configure alerts for etcd service failures
- Document the incident timeline and recovery procedures

**Review preventive measures**:
- Discuss etcd backup strategies
- Identify single points of failure in the etcd setup
- Plan for etcd cluster redundancy and high availability

### Task 6: Advanced etcd Troubleshooting Scenarios (2 minutes)
Handle complex etcd connectivity issues that require advanced diagnosis.

**Network partition simulation**:
- Test etcd behavior during network connectivity issues
- Understand etcd cluster behavior during split-brain scenarios

**Performance troubleshooting**:
- Identify etcd performance bottlenecks affecting cluster responsiveness
- Monitor etcd disk I/O and network latency impact

## Verification Commands

### Task 1 Verification
```bash
# Verify production workload exists
kubectl get deployment critical-app
kubectl get service critical-app-service
kubectl get pod cluster-monitor -n kube-system

# Confirm etcd service is stopped
sudo systemctl status etcd
sudo systemctl is-active etcd

# Test that API server is affected
kubectl get nodes --request-timeout=5s
```
**Expected Output**: Deployment and service should exist, etcd status should be "inactive (dead)", kubectl commands should timeout or fail with connection errors.

### Task 2 Verification
```bash
# Test API server responsiveness
kubectl version --request-timeout=5s
kubectl get componentstatuses --request-timeout=5s

# Check API server logs for etcd errors
sudo journalctl -u kubelet -f | grep -i etcd
sudo crictl logs $(sudo crictl ps -a --name=kube-apiserver -q) | tail -20

# Verify control plane pod status
kubectl get pods -n kube-system --request-timeout=5s
```
**Expected Output**: API server commands should fail or timeout, logs should show "connection refused" or "context deadline exceeded" errors related to etcd endpoints, control plane pods may show connectivity issues.

### Task 3 Verification
```bash
# Check etcd service detailed status
sudo systemctl status etcd -l
sudo journalctl -u etcd --no-pager -l

# Verify etcd configuration
sudo cat /etc/kubernetes/manifests/etcd.yaml | grep -A 5 -B 5 "etcd-servers\|listen\|data-dir"

# Test etcd port accessibility
sudo netstat -tlnp | grep :2379
sudo ss -tlnp | grep :2380

# Check etcd data directory
sudo ls -la /var/lib/etcd/
sudo df -h /var/lib/etcd/
```
**Expected Output**: etcd service should show failure details, configuration should reveal misconfigurations if present, ports 2379/2380 should not be listening if etcd is stopped, data directory should exist with proper permissions.

### Task 4 Verification
```bash
# Start etcd and verify status
sudo systemctl start etcd
sudo systemctl status etcd
sudo systemctl is-active etcd

# Test etcd connectivity
sudo ETCDCTL_API=3 etcdctl --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Verify API server reconnects
kubectl get nodes
kubectl cluster-info
```
**Expected Output**: etcd status should be "active (running)", endpoint health should return "healthy", kubectl commands should work normally without timeouts.

### Task 5 Verification
```bash
# Test complete cluster functionality
kubectl get all --all-namespaces
kubectl create configmap test-recovery --from-literal=status=recovered
kubectl get configmap test-recovery -o yaml

# Verify workload health
kubectl get deployment critical-app -o wide
kubectl get pods -l app=critical-app
curl -s critical-app-service:80 # from within cluster

# Check etcd cluster health
sudo ETCDCTL_API=3 etcdctl --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status --write-out=table
```
**Expected Output**: All kubectl operations should work normally, critical-app should show 3/3 ready replicas, HTTP requests should succeed, etcd status should show healthy cluster with leader elected.

### Task 6 Verification
```bash
# Test etcd performance metrics
sudo ETCDCTL_API=3 etcdctl --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint status --write-out=json | jq '.[] | {endpoint, status}'

# Monitor etcd resource usage
sudo systemctl show etcd --property=MemoryCurrent,CPUUsageNSec
sudo iotop -ao -d 1 -p $(pgrep etcd)

# Test cluster consensus
sudo ETCDCTL_API=3 etcdctl --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list --write-out=table
```
**Expected Output**: etcd status should show JSON with healthy status, resource usage should be reasonable, member list should show all cluster members with consistent configuration.

## Expected Results
- etcd service restored to active/running state with proper connectivity
- Kubernetes API server successfully reconnected to etcd with normal response times
- All control plane components (API server, controller manager, scheduler) functioning normally
- Production workloads (critical-app deployment) healthy and accessible
- Complete cluster functionality restored with all kubectl operations working
- etcd cluster health validated with proper consensus and leadership
- Monitoring and alerting configured to prevent future incidents

## Key Learning Points
- **etcd criticality**: etcd is the single point of failure for the entire Kubernetes cluster - when etcd fails, everything stops
- **Cascading failure patterns**: etcd connectivity issues cause API server failures, which cascade to all cluster operations
- **Service management**: Using systemctl for etcd service control and diagnosis in kubeadm clusters
- **Configuration validation**: etcd manifest files, data directories, and network configuration are critical failure points
- **Recovery procedures**: Systematic approach to etcd service restoration and cluster health validation
- **etcdctl usage**: Essential tool for etcd cluster health checking, member management, and operational verification
- **Monitoring importance**: etcd service monitoring is critical for preventing production outages

## Exam & Troubleshooting Tips
- **CKA Exam Approach**: etcd issues often present as "API server not responding" - always check etcd service status first
- **Quick Diagnosis**: `systemctl status etcd` and `journalctl -u etcd` are your first troubleshooting commands
- **Common Failure Modes**: 
  - etcd service stopped (systemctl restart etcd)
  - Data directory permissions or disk space issues
  - Network connectivity problems (firewall, port conflicts)
  - Configuration errors in etcd manifest files
- **Emergency Recovery**: Always have etcd backup and restore procedures documented and tested
- **Production Considerations**: 
  - etcd should run on dedicated nodes with SSD storage
  - Regular etcd backups are mandatory for disaster recovery
  - Monitor etcd performance metrics (latency, throughput, disk I/O)
  - Implement etcd cluster redundancy (odd number of members, typically 3 or 5)
- **Network Issues**: Check ports 2379 (client) and 2380 (peer) accessibility
- **Performance Problems**: Monitor etcd disk I/O - slow disks cause cluster-wide performance issues
- **Split-brain Prevention**: Ensure proper network connectivity between etcd cluster members
- **Certificate Issues**: etcd TLS certificate problems cause authentication failures with API server