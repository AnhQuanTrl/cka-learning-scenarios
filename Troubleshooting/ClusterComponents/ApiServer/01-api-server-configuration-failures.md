# API Server Configuration Failures

## Scenario Overview
- **Time Limit**: 45 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda kubeadm cluster

## Objective
Master API server troubleshooting by intentionally breaking and systematically recovering from common configuration failures that render the cluster completely inaccessible.

## Context
You're a DevOps engineer on-call when the monitoring system alerts that the production Kubernetes cluster is completely down. The previous engineer was performing routine maintenance on the control plane and accidentally corrupted the API server configuration. The cluster is completely inaccessible via kubectl, and you need to restore service immediately. This scenario simulates real production incidents where the API server fails to start due to configuration errors.

## Prerequisites
- Running Killercoda kubeadm cluster with control plane access
- Basic understanding of Kubernetes control plane components
- Familiarity with systemd and journalctl commands
- SSH access to the control plane node

## Tasks

### Task 1: Initial Cluster Setup and Validation (5 minutes)
Create a working baseline environment before introducing failures.

1a. Verify the cluster is healthy and create test workloads:
```bash
kubectl get nodes
kubectl get pods -A
```

1b. Deploy a sample application to validate cluster functionality:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: test-app
  template:
    metadata:
      labels:
        app: test-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: test-app-service
  namespace: default
spec:
  selector:
    app: test-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

1c. Verify the deployment is successful:
```bash
kubectl get deployments,pods,services
kubectl logs -l app=test-app
```

1d. Create a backup of the current API server manifest:
```bash
sudo cp /etc/kubernetes/manifests/kube-api server.yaml /etc/kubernetes/manifests/kube-api server.yaml.backup
```

### Task 2: Break 1 - etcd Connection Parameter Typo (10 minutes)
Simulate a common typo error that breaks etcd connectivity.

2a. Introduce the first configuration error by modifying the API server manifest:
```bash
sudo sed -i 's/--etcd-servers=/--etcd-server=/' /etc/kubernetes/manifests/kube-api server.yaml
```

2b. Wait 30-60 seconds and observe the symptoms. Attempt basic kubectl operations:
```bash
kubectl get nodes
kubectl get pods
```

2c. Investigate the failure by checking the kubelet logs for API server container status:
```bash
sudo journalctl -u kubelet -f --since "2 minutes ago"
```

2d. Examine the API server container logs directly:
```bash
sudo crictl ps -a | grep kube-api server
sudo crictl logs <api-server-container-id>
```

2e. Identify the root cause from the logs and fix the configuration:
```bash
sudo sed -i 's/--etcd-server=/--etcd-servers=/' /etc/kubernetes/manifests/kube-api server.yaml
```

2f. Verify recovery by checking cluster accessibility:
```bash
kubectl get nodes
kubectl get pods -A
```

### Task 3: Break 2 - Invalid etcd Endpoint URLs (8 minutes)
Introduce wrong etcd endpoints to simulate network connectivity issues.

3a. Modify the etcd server endpoints to use invalid addresses:
```bash
sudo sed -i 's/--etcd-servers=https:\/\/[^,]*/--etcd-servers=https:\/\/192.168.1.200:2379/' /etc/kubernetes/manifests/kube-api server.yaml
```

3b. Observe the API server failure symptoms and analyze the error patterns:
```bash
kubectl get nodes
sudo journalctl -u kubelet --since "1 minute ago" | grep -i error
```

3c. Examine API server logs to identify the connectivity failure:
```bash
sudo crictl logs $(sudo crictl ps -a | grep kube-api server | awk '{print $1}' | head -1)
```

3d. Restore the correct etcd endpoint configuration:
```bash
sudo cp /etc/kubernetes/manifests/kube-api server.yaml.backup /etc/kubernetes/manifests/kube-api server.yaml
```

3e. Confirm cluster recovery:
```bash
kubectl get nodes
kubectl get pods -l app=test-app
```

### Task 4: Break 3 - Invalid Service Account Key Path (8 minutes)
Modify service account signing key file path to simulate file system issues.

4a. Identify current service account key file path in the API server manifest:
```bash
sudo grep -i "service-account-key-file" /etc/kubernetes/manifests/kube-api server.yaml
```

4b. Modify the service account key file path to point to a non-existent location:
```bash
sudo sed -i 's|--service-account-key-file=/etc/kubernetes/pki/sa.pub|--service-account-key-file=/etc/kubernetes/pki/missing-sa-key.pub|' /etc/kubernetes/manifests/kube-api server.yaml
```

4c. Monitor the API server startup failure:
```bash
kubectl version --short
sudo journalctl -u kubelet --since "30 seconds ago" | tail -20
```

4d. Analyze the specific error message in API server logs:
```bash
sudo crictl logs --tail=50 $(sudo crictl ps -a | grep kube-api server | awk '{print $1}' | head -1)
```

4e. Correct the service account key file path:
```bash
sudo sed -i 's|--service-account-key-file=/etc/kubernetes/pki/missing-sa-key.pub|--service-account-key-file=/etc/kubernetes/pki/sa.pub|' /etc/kubernetes/manifests/kube-api server.yaml
```

4f. Validate the fix by testing service account functionality:
```bash
kubectl get nodes
kubectl auth can-i get pods --as=system:serviceaccount:default:default
```

### Task 5: Break 4 - Invalid Bind Address Configuration (8 minutes)
Configure API server to bind to an unreachable IP address.

5a. Identify the current bind address configuration:
```bash
sudo grep -i "bind-address" /etc/kubernetes/manifests/kube-api server.yaml
```

5b. Modify the API server bind address to an invalid IP:
```bash
sudo sed -i 's/--bind-address=[0-9.]*/--bind-address=10.255.255.255/' /etc/kubernetes/manifests/kube-api server.yaml
```

5c. Observe the binding failure and network connectivity issues:
```bash
kubectl cluster-info
sudo ss -tlnp | grep 6443
```

5d. Check kubelet logs for API server container restart attempts:
```bash
sudo journalctl -u kubelet --since "1 minute ago" | grep -i "api server"
```

5e. Examine the network binding error in container logs:
```bash
sudo crictl logs --tail=30 $(sudo crictl ps -a | grep kube-api server | awk '{print $1}' | head -1)
```

5f. Restore the original bind address configuration:
```bash
sudo cp /etc/kubernetes/manifests/kube-api server.yaml.backup /etc/kubernetes/manifests/kube-api server.yaml
```

5g. Verify complete cluster recovery:
```bash
kubectl get nodes
kubectl get pods -A --field-selector=status.phase!=Running
```

### Task 6: Comprehensive Recovery Validation (6 minutes)
Perform thorough testing to ensure all cluster functionality is restored.

6a. Validate all cluster components are healthy:
```bash
kubectl get componentstatuses
kubectl get pods -n kube-system | grep -E "(api server|etcd|controller|scheduler)"
```

6b. Test application functionality by scaling the test deployment:
```bash
kubectl scale deployment test-app --replicas=3
kubectl get pods -l app=test-app
```

6c. Verify service discovery and networking:
```bash
kubectl exec -it $(kubectl get pods -l app=test-app -o jsonpath='{.items[0].metadata.name}') -- curl test-app-service
```

6d. Test cluster administration operations:
```bash
kubectl create namespace troubleshooting-test
kubectl delete namespace troubleshooting-test
```

6e. Clean up test resources:
```bash
kubectl delete deployment,service test-app
sudo rm /etc/kubernetes/manifests/kube-api server.yaml.backup
```

## Verification Commands

### Task 1 Verification
```bash
# Verify cluster health
kubectl get nodes -o wide
kubectl get pods -A | grep -v Running | wc -l  # Should be 0 or minimal

# Verify test application
kubectl get deployment test-app -o jsonpath='{.status.readyReplicas}'  # Should equal replicas
kubectl get service test-app-service -o jsonpath='{.spec.clusterIP}'  # Should show valid IP
kubectl logs -l app=test-app --tail=5  # Should show nginx startup logs
```

### Task 2 Verification
```bash
# Verify break symptoms
kubectl get nodes 2>&1 | grep -i "connection refused\|refused\|timeout"  # Should show errors during break

# Verify fix
sudo grep -c "etcd-servers" /etc/kubernetes/manifests/kube-api server.yaml  # Should be 1
kubectl get nodes | grep Ready  # Should show Ready nodes after fix
```

### Task 3 Verification
```bash
# Verify break symptoms
sudo crictl logs $(sudo crictl ps -a | grep kube-api server | awk '{print $1}' | head -1) 2>&1 | grep -i "etcd\|connection"

# Verify fix
kubectl get pods -n kube-system | grep api server | grep Running  # Should show Running status
kubectl version --short  # Should show both client and server versions
```

### Task 4 Verification
```bash
# Verify break symptoms
sudo crictl logs $(sudo crictl ps -a | grep kube-api server | awk '{print $1}' | head -1) 2>&1 | grep -i "service.*account.*key"

# Verify fix
kubectl auth can-i get pods --as=system:serviceaccount:default:default  # Should return "yes"
kubectl get serviceaccounts  # Should list default serviceaccount
```

### Task 5 Verification
```bash
# Verify break symptoms
sudo ss -tlnp | grep 6443  # Should show no listener during break
kubectl cluster-info 2>&1 | grep -i "refused\|timeout"  # Should show connection errors

# Verify fix
sudo ss -tlnp | grep 6443  # Should show kube-api server listening
kubectl cluster-info | grep "Kubernetes control plane"  # Should show successful connection
```

### Task 6 Verification
```bash
# Comprehensive cluster health
kubectl get nodes | grep NotReady | wc -l  # Should be 0
kubectl get pods -A | grep -E "(Error|CrashLoopBackOff|Pending)" | wc -l  # Should be 0
kubectl get componentstatuses | grep Unhealthy | wc -l  # Should be 0

# Application functionality
kubectl get deployment test-app -o jsonpath='{.status.availableReplicas}'  # Should equal desired replicas
kubectl exec -it $(kubectl get pods -l app=test-app -o jsonpath='{.items[0].metadata.name}') -- curl -s test-app-service | grep -i "welcome to nginx"  # Should succeed
```

## Expected Results
- **Initial Setup**: Healthy cluster with 2-replica nginx deployment and working service
- **Break 1**: API server fails to start due to invalid etcd connection parameter
- **Break 2**: API server cannot connect to etcd due to wrong endpoint URLs
- **Break 3**: API server fails to load service account signing key from invalid file path
- **Break 4**: API server cannot bind to unreachable IP address
- **Recovery**: All breaks successfully identified and fixed using systematic troubleshooting approach
- **Final State**: Fully functional cluster with all components healthy and applications running

## Key Learning Points
- **Static Pod Troubleshooting**: Master the workflow of diagnosing static pod failures through kubelet logs and container runtime commands
- **Log Analysis Skills**: Develop proficiency in using journalctl, crictl logs, and kubectl logs for systematic error investigation
- **Configuration Validation**: Learn to identify and correct common API server configuration errors that cause startup failures
- **System Recovery**: Practice methodical approach to restoring cluster functionality from complete API server outages
- **Production Readiness**: Understand the importance of configuration backups and systematic troubleshooting procedures

## Exam & Troubleshooting Tips
- **CKA Exam Strategy**: API server failures are high-impact scenarios frequently tested; focus on quick identification through log analysis
- **Common Error Patterns**: Memorize typical API server error messages for etcd connectivity, certificate issues, and binding failures
- **Troubleshooting Workflow**: Always start with kubelet logs, then container runtime logs, then static pod manifests for systematic diagnosis
- **Recovery Procedures**: Practice restoring from backups quickly; time pressure is critical in both exams and production incidents
- **Verification Steps**: Always test cluster functionality comprehensively after fixes to ensure complete recovery
- **Prevention**: Implement configuration validation and backup procedures to prevent similar failures in production environments