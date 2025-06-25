# Controller Manager Configuration Issues

## Scenario Overview
- **Time Limit**: 40 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Master troubleshooting critical kube-controller-manager configuration failures that prevent controller reconciliation, certificate signing, and service account functionality.

## Context
Your production cluster is experiencing a cascade of mysterious issues: new deployments aren't scaling, service accounts aren't getting tokens, certificate signing requests are stuck pending, and endpoints aren't being updated. The development team is blocked from deploying new features, and existing workloads are showing signs of drift from their desired state. Initial investigation points to the kube-controller-manager - the brain that orchestrates cluster state reconciliation. You need to quickly diagnose and fix controller manager configuration issues before the system becomes completely unmanageable.

## Prerequisites
- Access to Killercoda Ubuntu Playground with a running kubeadm cluster
- Root access to control plane nodes with static pod manifest access
- Understanding of Kubernetes controller patterns and reconciliation loops
- Familiarity with kube-controller-manager responsibilities

## Tasks

### Task 1: Create Production Environment and Controller Dependencies (8 minutes)
Set up a realistic environment with workloads that depend on controller manager functionality.

Create **production workloads** that require active controller management:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-application
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-application
  template:
    metadata:
      labels:
        app: web-application
    spec:
      containers:
      - name: web
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: default
spec:
  selector:
    app: web-application
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Create **ServiceAccount** that requires token management:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account
  namespace: default
automountServiceAccountToken: true
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-account-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: service-account-app
  template:
    metadata:
      labels:
        app: service-account-app
    spec:
      serviceAccountName: app-service-account
      containers:
      - name: app
        image: alpine:latest
        command: ['sleep', '3600']
```

Create **Certificate Signing Request** that needs controller manager processing:
```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: test-csr
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ1ZqQ0NBVDRDQVFBd0VURVBNQTBHQTFVRUF3d0dZVzVuYVc1NE1JSUJJakFOQmdrcWhraUc5dzBCQVFFRgpBQU9DQVE4QU1JSUJDZ0tDQVFFQTByczhJTHRHdTYxakx2dHhWTTJSVlRWMDNHWlJTWWw0dWluVWo4RElaWjBOCnR2MUZtRVFSd3VoaUZsOFEzcWl0Qm0wMUFSMkNJVXBGd2ZzSjZ4MXF3ckJzVkhZbGlBNVhwRVpZM3ExcGswSDQKM3Z3aGJlK1o2MVNiVE04L2UzbVB0NTF1Ly9MWXQ2VWJOVGdSOVl6OHBYS3BvUDhGWGtoZmJwcXFhZUs4VTFXMVB6WgpMTERkTnJvYzlyb3krcTVhWlpTK01KQWJvNzgzRXNXOEIyY0hNSEVPd2JEUVRySzdlREl0SHNsOTZEQXBOcXRRCmZGZitqemJyUVNQZUQ2UU4xL0I1cWZ6NXR0RUZMSHROLzBuNjI5azUyaU1xSG5Mc0ZOOVFGTnYyM2I1NUhBODMKVzFxemE3RHlZWHU3K05yTnltWHZrQWVROGVGYjZaRmJPRVp3VENRSURBUUFCb0FBd0RRWUpLb1pJaHZjTkFRRUwKQlFBRGdnRUJBVGJsODZITlBVS1ZEZkVzTGVvaDJsMTRQTEVHM0Y5R253SGNyWmU3TjdNeHNDenA3b3hIMkZvL0owSQpJOFpjRUVxOE13Y25BUnJWSThiQlBndkpaZ0QzS0lCQllhRG1heE95VllMRnR3YnRmSWt5RVNRaDdlQTVHYnMzQQpvMUdBSUhZMGZJaXVhWm12R1VEaXhMZzJlLzJlSG0zMm5DSWI5L0w5Nnp5cVFJVUtHU2QzRVNaU0syWlBYWkI5CjhNRXFUUlhNc1BSK1kyUTRmd1BMZ1dEd1FGS3drQ3BkRUNhV3ZoMUs3SWJMNFdXRW9SRUxaZCtWRGZ3cnNiVUkKd0RQMlh1eFQ3T2xoRGd0VDR5QmllSjhIRzM3YnJLRU5HSCtKMGV6bzE4VWNsVXFTTTRsU0ZpMGNheHhlRjJ3Kwo4ekJ3TUhvUEp3bGY1YWJOa3ZOcjhVND0KLS0tLS1FTkQgQ0VSVElGSUNBVEUgUkVRVUVTVC0tLS0tCg==
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
  - client auth
```

Now **break the controller manager configuration** using one of these methods:

**Method 1: Invalid kubeconfig path**:
```bash
# Backup original manifest
sudo cp /etc/kubernetes/manifests/kube-controller-manager.yaml /tmp/kube-controller-manager-backup.yaml

# Modify kubeconfig path to non-existent file
sudo sed -i 's|--kubeconfig=/etc/kubernetes/controller-manager.conf|--kubeconfig=/etc/kubernetes/controller-manager-INVALID.conf|g' \
  /etc/kubernetes/manifests/kube-controller-manager.yaml
```

**Method 2: Invalid service account private key path**:
```bash
# Modify service account key file path
sudo sed -i 's|--service-account-private-key-file=/etc/kubernetes/pki/sa.key|--service-account-private-key-file=/etc/kubernetes/pki/sa-INVALID.key|g' \
  /etc/kubernetes/manifests/kube-controller-manager.yaml
```

**Method 3: Invalid cluster signing certificate paths**:
```bash
# Modify cluster signing certificate paths
sudo sed -i 's|--cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt|--cluster-signing-cert-file=/etc/kubernetes/pki/ca-INVALID.crt|g' \
  /etc/kubernetes/manifests/kube-controller-manager.yaml
```

### Task 2: Assess Controller Manager Impact and Identify Configuration Issues (8 minutes)
Document the cascading failures caused by controller manager dysfunction.

**Test controller-dependent functionality**:
- Attempt to scale the web-application deployment up and down
- Create new service accounts and check for automatic token creation
- Submit certificate signing requests and check processing status
- Verify endpoint creation and updates for services

**Examine controller manager logs** for configuration errors:
- Look for file not found errors for kubeconfig and certificate files
- Identify authentication failures to the API server
- Find controller startup and initialization errors

**Check controller manager pod status**:
- Verify if the controller manager pod is running or crash-looping
- Examine pod restart count and failure reasons
- Check if the controller manager is leader-elected and active

**Document controller reconciliation failures**:
- Identify which controllers are not functioning (deployment, endpoint, service account)
- Test specific controller functionality (scaling, token creation, CSR processing)
- Assess the scope of controller manager dysfunction

### Task 3: Controller Manager Configuration Analysis and Validation (8 minutes)
Perform deep analysis of controller manager configuration and certificate dependencies.

**Validate controller manager manifest configuration**:
- Examine command-line arguments in the static pod manifest
- Check file paths for kubeconfig, certificates, and keys
- Verify volume mounts and host path configurations

**Test file accessibility and permissions**:
- Verify all referenced certificate and key files exist
- Check file permissions for controller manager to read configuration files
- Test kubeconfig file validity and API server connectivity

**Analyze certificate dependencies**:
- Validate cluster signing certificates for CSR processing
- Check service account signing key for token generation
- Verify root CA certificates for cluster trust relationships

**Test controller manager authentication**:
- Validate controller manager can authenticate to API server
- Check if controller manager has proper RBAC permissions
- Test certificate-based authentication workflows

### Task 4: Controller Manager Configuration Repair and Service Restoration (10 minutes)
Restore controller manager functionality and verify complete service recovery.

**Restore valid configuration**:
- Fix file paths in the controller manager manifest
- Restore correct kubeconfig, certificate, and key file references
- Validate all configuration parameters are syntactically correct

**Restart controller manager**:
- Apply the corrected manifest configuration
- Monitor controller manager pod restart and startup logs
- Verify controller manager achieves ready state

**Validate authentication and authorization**:
- Confirm controller manager can authenticate to API server
- Test RBAC permissions for controller operations
- Verify leader election completes successfully

**Test controller functionality recovery**:
- Scale deployments and verify controller responds
- Create service accounts and check automatic token generation
- Submit CSRs and verify controller manager processes them
- Test endpoint controller updates service endpoints

### Task 5: Comprehensive Controller Validation and Monitoring Setup (4 minutes)
Verify complete controller manager recovery and establish monitoring.

**Test all controller functions**:
- Deployment controller: scaling, rolling updates, pod management
- Service account controller: token creation, secret management
- Certificate controller: CSR approval, certificate generation
- Endpoint controller: service endpoint management

**Validate workload health**:
- Ensure web-application deployment scales properly
- Verify service-account-app has valid tokens
- Test service endpoint connectivity and load balancing

**Establish controller monitoring**:
- Monitor controller manager metrics and health endpoints
- Set up alerting for controller manager failures
- Document recovery procedures for future incidents

**Performance validation**:
- Check controller reconciliation timing and performance
- Verify no controller lag or backlog accumulation
- Test controller responsiveness under load

### Task 6: Advanced Controller Manager Configuration (2 minutes)
Test advanced controller configurations and troubleshooting scenarios.

**Controller-specific configuration**:
- Test individual controller enable/disable flags
- Validate controller-specific timing and batch settings
- Check resource quota and limit configurations for controllers

**High availability considerations**:
- Test leader election behavior with multiple controller managers
- Verify controller failover and recovery scenarios

## Verification Commands

### Task 1 Verification
```bash
# Verify production workloads are created
kubectl get deployment web-application service-account-app
kubectl get service web-service
kubectl get serviceaccount app-service-account
kubectl get csr test-csr

# Verify controller manager configuration is broken
sudo grep -E "(kubeconfig|service-account-private-key-file|cluster-signing-cert-file)" \
  /etc/kubernetes/manifests/kube-controller-manager.yaml

# Check controller manager pod status
kubectl get pods -n kube-system -l component=kube-controller-manager
```
**Expected Output**: Deployments should exist but may not scale properly, CSR should be pending, controller manager pod may be crash-looping or failing.

### Task 2 Verification
```bash
# Test deployment scaling
kubectl scale deployment web-application --replicas=5
kubectl get deployment web-application -w --timeout=30s

# Check service account token creation
kubectl describe serviceaccount app-service-account
kubectl get secrets | grep app-service-account

# Check CSR processing
kubectl get csr test-csr -o yaml

# Check controller manager logs
sudo crictl logs $(sudo crictl ps -a --name=kube-controller-manager -q) | tail -20
```
**Expected Output**: Scaling should not work or be delayed, service account should lack tokens, CSR should remain pending, logs should show configuration file errors.

### Task 3 Verification
```bash
# Validate file paths in manifest
sudo cat /etc/kubernetes/manifests/kube-controller-manager.yaml | grep -E "(kubeconfig|private-key-file|cert-file)"

# Check file existence
sudo ls -la /etc/kubernetes/controller-manager.conf
sudo ls -la /etc/kubernetes/pki/sa.key
sudo ls -la /etc/kubernetes/pki/ca.crt

# Test kubeconfig validity
sudo kubectl --kubeconfig=/etc/kubernetes/controller-manager.conf get nodes

# Check controller manager RBAC
kubectl auth can-i "*" "*" --as=system:kube-controller-manager
```
**Expected Output**: Manifest should show invalid paths, referenced files should not exist or be accessible, kubeconfig test should fail, RBAC should be configured properly.

### Task 4 Verification
```bash
# Restore configuration from backup
sudo cp /tmp/kube-controller-manager-backup.yaml /etc/kubernetes/manifests/kube-controller-manager.yaml

# Monitor controller manager restart
kubectl get pods -n kube-system -l component=kube-controller-manager -w

# Check controller manager logs for successful startup
sudo crictl logs $(sudo crictl ps --name=kube-controller-manager -q) | tail -20

# Test controller functionality
kubectl scale deployment web-application --replicas=3
kubectl get csr test-csr
```
**Expected Output**: Controller manager pod should restart successfully, logs should show successful initialization, deployment scaling should work, CSR should be processed.

### Task 5 Verification
```bash
# Verify deployment controller works
kubectl scale deployment web-application --replicas=4
kubectl rollout status deployment web-application

# Check service account token generation
kubectl get secrets | grep app-service-account-token
kubectl describe serviceaccount app-service-account

# Verify CSR processing
kubectl certificate approve test-csr 2>/dev/null || echo "CSR already processed"
kubectl get csr test-csr

# Check endpoint controller
kubectl get endpoints web-service
kubectl describe service web-service
```
**Expected Output**: Deployment should scale successfully, service account should have token secret, CSR should be approved/issued, endpoints should match pod IPs.

### Task 6 Verification
```bash
# Check controller manager metrics
kubectl get --raw /metrics | grep controller_manager || echo "Metrics endpoint not available"

# Verify leader election
kubectl get lease -n kube-system kube-controller-manager -o yaml

# Test controller performance
time kubectl scale deployment web-application --replicas=6
kubectl get deployment web-application -o yaml | grep -A 5 status

# Check all controllers are healthy
kubectl get componentstatuses
```
**Expected Output**: Metrics should be available, leader election should show current controller manager as leader, scaling should be fast, component status should be healthy.

## Expected Results
- kube-controller-manager service restored with proper configuration and functionality
- All Kubernetes controllers operational (deployment, service account, certificate, endpoint)
- Production workloads (web-application, service-account-app) scaling and functioning normally
- Service account token creation and management working correctly
- Certificate signing request processing operational
- Service endpoint management and updates functioning
- Complete controller reconciliation and cluster state management restored

## Key Learning Points
- **Controller manager criticality**: kube-controller-manager is essential for cluster state reconciliation - without it, desired state is not maintained
- **Configuration dependencies**: controller manager requires valid kubeconfig, service account keys, and cluster signing certificates
- **Controller interdependencies**: deployment scaling, service account tokens, and CSR processing all depend on controller manager
- **Static pod troubleshooting**: controller manager runs as static pod, requiring manifest file corrections for fixes
- **Authentication requirements**: controller manager must authenticate to API server with proper certificates and RBAC
- **Leader election**: only one controller manager instance is active at a time through leader election mechanisms
- **Reconciliation loops**: understanding how controllers maintain desired state through continuous reconciliation

## Exam & Troubleshooting Tips
- **CKA Exam Focus**: Controller manager issues often present as "deployments not scaling" or "service accounts without tokens"
- **Quick Diagnosis**: Check `/etc/kubernetes/manifests/kube-controller-manager.yaml` for configuration errors first
- **Common Issues**:
  - Invalid file paths in controller manager manifest
  - Missing or corrupted certificate files
  - Incorrect RBAC permissions for system:kube-controller-manager
  - Leader election failures in multi-master setups
- **File Locations**: 
  - Manifest: `/etc/kubernetes/manifests/kube-controller-manager.yaml`
  - Kubeconfig: `/etc/kubernetes/controller-manager.conf`
  - Service account key: `/etc/kubernetes/pki/sa.key`
  - Cluster signing certificates: `/etc/kubernetes/pki/ca.crt` and `/etc/kubernetes/pki/ca.key`
- **Recovery Steps**:
  1. Check controller manager pod status and logs
  2. Validate manifest file paths and configuration
  3. Verify certificate file existence and permissions
  4. Test kubeconfig authentication
  5. Restart by updating static pod manifest
- **Production Considerations**:
  - Monitor controller manager health and metrics
  - Set up alerting for controller failures
  - Regular certificate rotation and validation
  - Backup controller manager configuration
- **Testing Controller Functions**: Use `kubectl scale`, service account creation, and CSR submission to test controller functionality
- **Leader Election**: In HA setups, only one controller manager is active - check leader election status in multi-master environments