# Controller Manager Authentication and Authorization Issues

## Scenario Overview
- **Time Limit**: 45 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Master troubleshooting kube-controller-manager authentication failures and RBAC permission issues that prevent controller operations and cluster state management.

## Context
Your security team just completed a "hardening sprint" where they updated certificates and tightened RBAC permissions across the production cluster. However, since the changes went live, the cluster has been behaving erratically: deployments aren't scaling, service accounts aren't getting tokens, and certificate signing requests are accumulating in pending state. The on-call engineer reports that the controller manager seems to be running but not functioning properly. You suspect the security changes may have inadvertently broken controller manager authentication or authorization. You need to quickly diagnose and fix the authentication issues before the business impact escalates.

## Prerequisites
- Access to Killercoda Ubuntu Playground with a running kubeadm cluster
- Understanding of Kubernetes RBAC concepts and certificate-based authentication
- Familiarity with kube-controller-manager authentication and authorization requirements
- Basic knowledge of certificate expiration and renewal procedures

## Tasks

### Task 1: Create Production Environment and Authentication Dependencies (8 minutes)
Set up a realistic environment with workloads that depend on controller manager authentication and authorization.

Create **production workloads** requiring controller manager functionality:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: banking-api
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: banking-api
  template:
    metadata:
      labels:
        app: banking-api
    spec:
      containers:
      - name: api
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: ENVIRONMENT
          value: "production"
---
apiVersion: v1
kind: Service
metadata:
  name: banking-api-service
  namespace: default
spec:
  selector:
    app: banking-api
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Create **ServiceAccount** requiring token management:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: payment-processor
  namespace: default
automountServiceAccountToken: true
---
apiVersion: v1
kind: Secret
metadata:
  name: payment-processor-secret
  namespace: default
  annotations:
    kubernetes.io/service-account.name: payment-processor
type: kubernetes.io/service-account-token
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-processor
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-processor
  template:
    metadata:
      labels:
        app: payment-processor
    spec:
      serviceAccountName: payment-processor
      containers:
      - name: processor
        image: alpine:latest
        command: ['sleep', '3600']
```

Create **Certificate Signing Request** requiring controller manager approval:
```yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: payment-service-csr
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ1ZqQ0NBVDRDQVFBd0VURVBNQTBHQTFVRUF3d0dZVzVuYVc1NE1JSUJJakFOQmdrcWhraUc5dzBCQVFFRgpBQU9DQVE4QU1JSUJDZ0tDQVFFQTByczhJTHRHdTYxakx2dHhWTTJSVlRWMDNHWlJTWWw0dWluVWo4RElaWjBOCnR2MUZtRVFSd3VoaUZsOFEzcWl0Qm0wMUFSMkNJVXBGd2ZzSjZ4MXF3ckJzVkhZbGlBNVhwRVpZM3ExcGswSDQKM3Z3aGJlK1o2MVNiVE04L2UzbVB0NTF1Ly9MWXQ2VWJOVGdSOVl6OHBYS3BvUDhGWGtoZmJwcXFhZUs4VTFXMVB6WgpMTERkTnJvYzlyb3krcTVhWlpTK01KQWJvNzgzRXNXOEIyY0hNSEVPd2JEUVRySzdlREl0SHNsOTZEQXBOcXRRCmZGZitqemJyUVNQZUQ2UU4xL0I1cWZ6NXR0RUZMSHROLzBuNjI5azUyaU1xSG5Mc0ZOOVFGTnYyM2I1NUhBODMKVzFxemE3RHlZWHU3K05yTnltWHZrQWVROGVGYjZaRmJPRVp3VENRSURBUUFCb0FBd0RRWUpLb1pJaHZjTkFRRUwKQlFBRGdnRUJBVGJsODZITlBVS1ZEZkVzTGVvaDJsMTRQTEVHM0Y5R253SGNyWmU3TjdNeHNDenA3b3hIMkZvL0owSQpJOFpjRUVxOE13Y25BUnJWSThiQlBndkpaZ0QzS0lCQllhRG1heE95VllMRnR3YnRmSWt5RVNRaDdlQTVHYnMzQQpvMUdBSUhZMGZJaXVhWm12R1VEaXhMZzJlLzJlSG0zMm5DSWI5L0w5Nnp5cVFJVUtHU2QzRVNaU0syWlBYWkI5CjhNRXFUUlhNc1BSK1kyUTRmd1BMZ1dEd1FGS3drQ3BkRUNhV3ZoMUs3SWJMNFdXRW9SRUxaZCtWRGZ3cnNiVUkKd0RQMlh1eFQ3T2xoRGd0VDR5QmllSjhIRzM3YnJLRU5HSCtKMGV6bzE4VWNsVXFTTTRsU0ZpMGNheHhlRjJ3Kwo4ekJ3TUhvUEp3bGY1YWJOa3ZOcjhVND0KLS0tLS1FTkQgQ0VSVElGSUNBVEUgUkVRVUVTVC0tLS0tCg==
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
  - client auth
```

Now **break controller manager authentication/authorization** using one of these methods:

**Method 1: Expire controller manager certificate**:
```bash
# Backup current kubeconfig
sudo cp /etc/kubernetes/controller-manager.conf /tmp/controller-manager-backup.conf

# Generate expired certificate for controller manager
sudo openssl req -x509 -newkey rsa:2048 -keyout /tmp/expired-controller.key -out /tmp/expired-controller.crt \
  -days -1 -nodes -subj "/CN=system:kube-controller-manager"

# Create kubeconfig with expired certificate
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/pki/ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=/tmp/expired-controller-config.conf

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=/tmp/expired-controller.crt \
  --client-key=/tmp/expired-controller.key \
  --embed-certs=true \
  --kubeconfig=/tmp/expired-controller-config.conf

kubectl config set-context default \
  --cluster=kubernetes \
  --user=system:kube-controller-manager \
  --kubeconfig=/tmp/expired-controller-config.conf

kubectl config use-context default --kubeconfig=/tmp/expired-controller-config.conf

# Replace controller manager kubeconfig
sudo cp /tmp/expired-controller-config.conf /etc/kubernetes/controller-manager.conf
```

**Method 2: Modify controller manager RBAC permissions**:
```bash
# Remove critical permissions from system:kube-controller-manager
kubectl patch clusterrolebinding system:kube-controller-manager --type='json' \
  -p='[{"op": "replace", "path": "/subjects/0/name", "value": "system:kube-controller-manager-INVALID"}]'
```

**Method 3: Delete controller manager cluster role binding**:
```bash
# Backup RBAC configuration
kubectl get clusterrolebinding system:kube-controller-manager -o yaml > /tmp/controller-manager-rbac-backup.yaml

# Delete controller manager cluster role binding
kubectl delete clusterrolebinding system:kube-controller-manager
```

### Task 2: Assess Authentication Failures and Permission Denied Errors (8 minutes)
Document authentication and authorization failures affecting controller manager functionality.

**Test controller authentication**:
- Use kubectl with controller manager credentials to test API server access
- Verify controller manager can authenticate vs authorization failures
- Check for certificate validation errors vs RBAC permission errors

**Examine controller manager logs** for authentication/authorization errors:
- Look for "Unauthorized" or "Forbidden" error messages
- Identify certificate validation failures vs RBAC denials
- Find specific API operations being denied

**Test controller-specific operations**:
- Attempt deployment scaling to test deployment controller authorization
- Create service accounts to test service account controller permissions
- Submit CSRs to test certificate controller authorization

**Analyze RBAC configuration**:
- Check controller manager cluster role bindings
- Verify system:kube-controller-manager permissions
- Identify missing or modified RBAC rules

### Task 3: Authentication and Certificate Validation (10 minutes)
Perform detailed analysis of controller manager authentication mechanisms and certificate validity.

**Validate controller manager certificate**:
- Check certificate expiration dates and validity periods
- Verify certificate subject names match expected principals
- Test certificate chain validation and CA trust
- Examine certificate usage and key usage extensions

**Test authentication mechanisms**:
- Use controller manager kubeconfig to authenticate manually
- Verify API server certificate trust and validation
- Test TLS handshake and client certificate authentication

**Analyze authentication logs**:
- Examine API server audit logs for authentication events
- Look for certificate validation failures
- Identify authentication success vs authorization failures

**Validate kubeconfig configuration**:
- Check kubeconfig file structure and contents
- Verify cluster, user, and context configurations
- Test kubeconfig certificate embedding and file references

### Task 4: RBAC Permission Analysis and Debugging (10 minutes)
Diagnose RBAC authorization issues and identify missing or incorrect permissions.

**Analyze controller manager RBAC requirements**:
- Review system:kube-controller-manager cluster role
- Identify required permissions for each controller function
- Check cluster role bindings and subject mappings

**Test specific RBAC permissions**:
- Use kubectl auth can-i to test controller manager permissions
- Check permissions for deployments, services, endpoints, secrets
- Verify CSR signing and service account token creation permissions

**Debug authorization failures**:
- Identify which API operations are being denied
- Check for missing verbs (create, update, patch, delete)
- Verify resource and API group permissions

**Validate RBAC binding integrity**:
- Check cluster role binding subjects and role references
- Verify system:kube-controller-manager user binding
- Test role aggregation and permission inheritance

### Task 5: Authentication and Authorization Recovery (7 minutes)
Restore controller manager authentication and authorization functionality.

**Restore valid authentication**:
- Replace expired certificates with valid ones
- Restore proper kubeconfig configuration
- Validate certificate chain and API server trust

**Fix RBAC permissions**:
- Restore system:kube-controller-manager cluster role binding
- Verify all required permissions are present
- Test RBAC configuration with kubectl auth can-i

**Restart controller manager**:
- Force controller manager pod restart to pick up new credentials
- Monitor authentication success in controller manager logs
- Verify leader election and controller initialization

**Validate controller functionality**:
- Test deployment scaling and controller reconciliation
- Verify service account token creation
- Check CSR processing and approval

### Task 6: Advanced Authentication and Authorization Monitoring (2 minutes)
Implement monitoring and establish security best practices for controller manager authentication.

**Set up authentication monitoring**:
- Monitor controller manager authentication events
- Set up alerting for authentication failures
- Track certificate expiration and renewal

**Validate security configuration**:
- Verify least-privilege RBAC principles
- Check certificate rotation procedures
- Document authentication troubleshooting procedures

## Verification Commands

### Task 1 Verification
```bash
# Verify production workloads are created
kubectl get deployment banking-api payment-processor
kubectl get service banking-api-service
kubectl get serviceaccount payment-processor
kubectl get csr payment-service-csr

# Check controller manager authentication is broken
kubectl --kubeconfig=/etc/kubernetes/controller-manager.conf get nodes

# Verify RBAC or certificate issues
kubectl get clusterrolebinding system:kube-controller-manager
sudo openssl x509 -in /etc/kubernetes/pki/apiserver.crt -noout -dates
```
**Expected Output**: Deployments should exist but may not scale, kubeconfig test should fail with authentication/authorization errors, RBAC binding may be missing or incorrect.

### Task 2 Verification
```bash
# Test controller manager authentication
kubectl --kubeconfig=/etc/kubernetes/controller-manager.conf auth can-i get nodes

# Check controller manager logs for auth errors
sudo crictl logs $(sudo crictl ps --name=kube-controller-manager -q) | grep -i "unauthorized\|forbidden\|authentication\|authorization" | tail -10

# Test deployment scaling (should fail)
kubectl scale deployment banking-api --replicas=5
kubectl get deployment banking-api -w --timeout=30s

# Check service account token creation
kubectl describe serviceaccount payment-processor
kubectl get secrets | grep payment-processor

# Check CSR processing
kubectl get csr payment-service-csr -o yaml
```
**Expected Output**: Authentication should fail, logs should show auth errors, scaling should not work, service account should lack tokens, CSR should remain pending.

### Task 3 Verification
```bash
# Check certificate validity
sudo openssl x509 -in /etc/kubernetes/controller-manager.conf -noout -dates 2>/dev/null || echo "Certificate embedded in kubeconfig"

# Extract and check certificate from kubeconfig
kubectl config view --kubeconfig=/etc/kubernetes/controller-manager.conf --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d | openssl x509 -noout -dates -subject

# Test kubeconfig authentication
kubectl --kubeconfig=/etc/kubernetes/controller-manager.conf cluster-info

# Check API server audit logs for controller manager
sudo journalctl -u kubelet | grep "controller-manager" | tail -5

# Verify certificate chain
sudo openssl verify -CAfile /etc/kubernetes/pki/ca.crt /tmp/expired-controller.crt 2>/dev/null || echo "Certificate verification failed"
```
**Expected Output**: Certificate should show expired dates or invalid subject, kubeconfig test should fail, audit logs should show authentication failures.

### Task 4 Verification
```bash
# Check controller manager RBAC permissions
kubectl auth can-i "*" "*" --as=system:kube-controller-manager
kubectl auth can-i create deployments --as=system:kube-controller-manager
kubectl auth can-i create secrets --as=system:kube-controller-manager
kubectl auth can-i approve certificatesigningrequests --as=system:kube-controller-manager

# Verify cluster role binding exists
kubectl get clusterrolebinding system:kube-controller-manager -o yaml

# Check system controller manager cluster role
kubectl describe clusterrole system:kube-controller-manager

# Test specific controller permissions
kubectl auth can-i patch endpoints --as=system:kube-controller-manager
kubectl auth can-i create serviceaccounts --as=system:kube-controller-manager
```
**Expected Output**: Permission tests should fail or show unauthorized, cluster role binding may be missing or incorrect, specific controller permissions should be denied.

### Task 5 Verification
```bash
# Restore authentication (choose based on breaking method used)
# For expired certificate:
sudo cp /tmp/controller-manager-backup.conf /etc/kubernetes/controller-manager.conf

# For RBAC issues:
kubectl apply -f /tmp/controller-manager-rbac-backup.yaml

# OR recreate RBAC binding:
kubectl create clusterrolebinding system:kube-controller-manager \
  --clusterrole=system:kube-controller-manager \
  --user=system:kube-controller-manager

# Test authentication restoration
kubectl --kubeconfig=/etc/kubernetes/controller-manager.conf get nodes

# Verify RBAC permissions
kubectl auth can-i "*" "*" --as=system:kube-controller-manager

# Monitor controller manager restart
kubectl get pods -n kube-system -l component=kube-controller-manager -w

# Test controller functionality
kubectl scale deployment banking-api --replicas=3
kubectl get csr payment-service-csr
```
**Expected Output**: Authentication should succeed, RBAC permissions should be granted, controller manager should restart successfully, scaling should work, CSR should be processed.

### Task 6 Verification
```bash
# Verify complete authentication and authorization
kubectl auth can-i create deployments --as=system:kube-controller-manager
kubectl auth can-i approve certificatesigningrequests --as=system:kube-controller-manager

# Check controller manager health
kubectl get componentstatuses
sudo crictl logs $(sudo crictl ps --name=kube-controller-manager -q) | tail -10

# Verify all controllers are working
kubectl rollout status deployment banking-api
kubectl get secrets | grep payment-processor-token
kubectl certificate approve payment-service-csr 2>/dev/null || echo "CSR already processed"

# Check authentication monitoring
kubectl get events -n kube-system | grep controller-manager | tail -5
```
**Expected Output**: All permission tests should succeed, component status should be healthy, controllers should be functioning normally, all workloads should be operational.

## Expected Results
- kube-controller-manager authentication restored with valid certificates or credentials
- RBAC permissions properly configured for system:kube-controller-manager
- All controller functions operational (deployment, service account, certificate management)
- Production workloads (banking-api, payment-processor) scaling and functioning normally
- Service account token creation and management working correctly
- Certificate signing request processing operational
- Authentication and authorization monitoring established

## Key Learning Points
- **Authentication vs authorization**: Understanding the difference between certificate/credential issues and RBAC permission problems
- **Controller manager authentication**: kube-controller-manager authenticates as system:kube-controller-manager user with specific RBAC requirements
- **Certificate validation**: Certificate expiration and invalid subjects cause authentication failures before RBAC evaluation
- **RBAC dependencies**: Controller manager requires extensive cluster-wide permissions to manage cluster state
- **Troubleshooting methodology**: Systematic approach to distinguish authentication failures from authorization denials
- **Security implications**: Security hardening must preserve essential system component authentication and permissions
- **Monitoring importance**: Proactive monitoring of authentication events and certificate expiration prevents outages

## Exam & Troubleshooting Tips
- **CKA Exam Focus**: Authentication/authorization issues often present as "controllers not working" or "permission denied" errors
- **Quick Diagnosis**: Use `kubectl auth can-i` commands to test controller manager permissions immediately
- **Common Issues**:
  - Expired certificates in controller manager kubeconfig
  - Modified or deleted system:kube-controller-manager cluster role binding
  - Invalid certificate subjects or CA trust issues
  - RBAC changes that remove essential controller permissions
- **Authentication vs Authorization**:
  - Authentication failures: "Unauthorized" (401) - certificate/credential issues
  - Authorization failures: "Forbidden" (403) - RBAC permission issues
- **Critical RBAC Requirements**: Controller manager needs permissions for deployments, services, endpoints, secrets, serviceaccounts, and certificatesigningrequests
- **Recovery Steps**:
  1. Test authentication with controller manager kubeconfig
  2. Check certificate validity and expiration
  3. Verify RBAC cluster role binding exists
  4. Test specific permissions with kubectl auth can-i
  5. Restore certificates or RBAC as needed
- **Production Considerations**:
  - Regular certificate rotation and monitoring
  - RBAC change management and testing
  - Authentication event logging and alerting
  - Backup of critical RBAC configurations
- **Testing Tools**: `kubectl auth can-i`, certificate inspection with openssl, kubeconfig testing
- **File Locations**: Controller manager kubeconfig at `/etc/kubernetes/controller-manager.conf`, cluster role binding `system:kube-controller-manager`