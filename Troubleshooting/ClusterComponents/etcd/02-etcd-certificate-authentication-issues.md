# etcd Certificate and Authentication Issues

## Scenario Overview
- **Time Limit**: 45 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Master troubleshooting critical etcd certificate and authentication failures that cause cluster-wide TLS communication breakdowns and authentication errors.

## Context
Your monitoring system alerts you at 6 AM: "API server authentication failures - certificate errors detected." The development team reports they can't deploy new applications, and existing workloads are experiencing intermittent issues. Initial investigation reveals TLS handshake failures between the API server and etcd, along with authentication errors suggesting certificate problems. The certificates may have expired overnight or been misconfigured during a recent security update. You need to quickly diagnose and resolve the certificate issues before the morning deployment window opens.

## Prerequisites
- Access to Killercoda Ubuntu Playground with a running kubeadm cluster
- Root access to control plane nodes with certificate file access
- Basic understanding of TLS/PKI concepts and certificate chains
- Familiarity with OpenSSL commands and certificate validation

## Tasks

### Task 1: Create Production Environment and Break etcd Certificate Authentication (10 minutes)
Set up a realistic scenario where certificate issues cascade into cluster-wide authentication failures.

First, create a **production workload** to demonstrate authentication impact:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      containers:
      - name: app
        image: nginx:1.21
        ports:
        - containerPort: 80
        env:
        - name: TLS_VERIFY
          value: "true"
---
apiVersion: v1
kind: Service
metadata:
  name: secure-app-service
  namespace: default
spec:
  selector:
    app: secure-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

Create a **certificate monitoring pod** for testing TLS connectivity:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cert-monitor
  namespace: kube-system
spec:
  containers:
  - name: monitor
    image: alpine/openssl:latest
    command: ['sleep', '3600']
  restartPolicy: Always
```

Now **backup existing certificates** before breaking them:
```bash
# Create backup directory
sudo mkdir -p /tmp/etcd-cert-backup

# Backup etcd certificates
sudo cp /etc/kubernetes/pki/etcd/server.crt /tmp/etcd-cert-backup/
sudo cp /etc/kubernetes/pki/etcd/server.key /tmp/etcd-cert-backup/
sudo cp /etc/kubernetes/pki/etcd/peer.crt /tmp/etcd-cert-backup/
sudo cp /etc/kubernetes/pki/etcd/peer.key /tmp/etcd-cert-backup/
sudo cp /etc/kubernetes/pki/etcd/ca.crt /tmp/etcd-cert-backup/
```

**Break etcd certificate authentication** using one of these methods:

**Method 1: Replace etcd server certificate with expired certificate**:
```bash
# Generate an expired certificate
sudo openssl req -x509 -newkey rsa:2048 -keyout /tmp/expired.key -out /tmp/expired.crt \
  -days -1 -nodes -subj "/CN=etcd-server"

# Replace etcd server certificate with expired one
sudo cp /tmp/expired.crt /etc/kubernetes/pki/etcd/server.crt
sudo cp /tmp/expired.key /etc/kubernetes/pki/etcd/server.key
```

**Method 2: Modify etcd client certificate paths in kube-apiserver**:
```bash
# Edit API server manifest to use wrong etcd client certificate path
sudo sed -i 's|/etc/kubernetes/pki/apiserver-etcd-client.crt|/etc/kubernetes/pki/apiserver-etcd-client-INVALID.crt|g' \
  /etc/kubernetes/manifests/kube-apiserver.yaml
```

**Method 3: Use wrong CA bundle for etcd authentication**:
```bash
# Create invalid CA certificate
sudo openssl req -x509 -newkey rsa:2048 -keyout /tmp/fake-ca.key -out /tmp/fake-ca.crt \
  -days 365 -nodes -subj "/CN=fake-ca"

# Replace etcd CA with fake CA
sudo cp /tmp/fake-ca.crt /etc/kubernetes/pki/etcd/ca.crt
```

### Task 2: Assess Authentication Failures and TLS Handshake Issues (8 minutes)
Document the authentication failures and identify certificate-related error patterns.

**Test API server etcd connectivity**:
- Attempt kubectl commands and observe authentication-related failures
- Check if API server can establish TLS connections to etcd
- Identify specific TLS handshake error messages

**Examine API server logs** for certificate errors:
- Look for TLS handshake failure messages
- Identify certificate validation errors (expired, invalid, wrong CA)
- Find authentication timeout and retry patterns

**Test direct etcd connectivity**:
- Use etcdctl with various certificate combinations
- Test both server and client certificate authentication
- Verify which certificate components are failing

Document the **authentication failure patterns** and **certificate error timeline** to understand the scope of the TLS communication breakdown.

### Task 3: Certificate Validation and TLS Configuration Analysis (10 minutes)
Perform deep analysis of certificate validity and TLS configuration issues.

**Validate etcd server certificates**:
- Check certificate expiration dates using OpenSSL
- Verify certificate subject names and SANs (Subject Alternative Names)
- Validate certificate chain and CA relationships
- Test certificate file permissions and accessibility

**Examine etcd peer certificates**:
- Validate peer certificate configuration for cluster communication
- Check peer certificate paths in etcd manifest
- Verify peer certificate expiration and validity

**Analyze API server etcd client certificates**:
- Validate API server etcd client certificate and key
- Check client certificate paths in kube-apiserver manifest
- Verify client certificate permissions for etcd authentication

**Test certificate trust relationships**:
- Verify CA certificate validity and accessibility
- Test certificate chain validation using OpenSSL
- Check for certificate/key mismatches

### Task 4: Certificate Authentication Troubleshooting (10 minutes)
Diagnose specific authentication issues and certificate configuration problems.

**TLS handshake debugging**:
- Use OpenSSL s_client to test etcd TLS connectivity
- Analyze TLS handshake failure messages
- Identify specific certificate validation errors

**Certificate path validation**:
- Verify all certificate file paths in manifests are correct
- Check file permissions on certificate files
- Ensure certificate files are readable by appropriate users

**etcd client authentication testing**:
- Test etcdctl connectivity with different certificate combinations
- Validate API server can authenticate as etcd client
- Check for certificate format or encoding issues

**Certificate authority validation**:
- Verify CA certificate is trusted by all components
- Check CA certificate distribution and consistency
- Test certificate chain validation end-to-end

### Task 5: Certificate Restoration and Authentication Recovery (10 minutes)
Restore valid certificates and verify complete authentication recovery.

**Restore valid certificates**:
- Restore backup certificates or regenerate valid ones
- Fix certificate file paths in manifests
- Correct CA certificate distribution

**Regenerate expired certificates** (if needed):
- Use kubeadm to regenerate etcd certificates
- Update certificate paths in component manifests
- Ensure consistent certificate distribution

**Restart affected components**:
- Restart etcd if server certificates were changed
- Wait for API server to reconnect with valid certificates
- Monitor component logs for successful authentication

**Validate certificate authentication**:
- Test etcdctl connectivity with restored certificates
- Verify API server can successfully authenticate to etcd
- Confirm TLS handshake completion without errors

### Task 6: Advanced Certificate Management and Monitoring (2 minutes)
Implement certificate monitoring and establish preventive measures.

**Certificate expiration monitoring**:
- Check certificate expiration dates across all etcd certificates
- Set up monitoring for certificate expiration warnings
- Document certificate renewal procedures

**Certificate rotation testing**:
- Test certificate rotation procedures without downtime
- Verify component restart requirements during rotation
- Validate certificate chain updates

## Verification Commands

### Task 1 Verification
```bash
# Verify production workload exists
kubectl get deployment secure-app
kubectl get service secure-app-service
kubectl get pod cert-monitor -n kube-system

# Confirm certificates are backed up
ls -la /tmp/etcd-cert-backup/

# Verify certificates are broken (choose based on method used)
# For expired certificate:
sudo openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -dates

# For wrong paths in API server:
grep "apiserver-etcd-client" /etc/kubernetes/manifests/kube-apiserver.yaml

# For wrong CA:
sudo openssl x509 -in /etc/kubernetes/pki/etcd/ca.crt -noout -subject
```
**Expected Output**: Deployment should exist, backup files present, certificates should show expiration issues, invalid paths, or wrong CA subjects.

### Task 2 Verification
```bash
# Test API server responsiveness
kubectl get nodes --request-timeout=10s
kubectl cluster-info --request-timeout=10s

# Check API server logs for certificate errors
sudo journalctl -u kubelet | grep -i "tls\|certificate\|handshake" | tail -10
sudo crictl logs $(sudo crictl ps -a --name=kube-apiserver -q) 2>&1 | grep -i "etcd\|tls" | tail -10

# Test direct etcd connectivity
sudo ETCDCTL_API=3 etcdctl --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health
```
**Expected Output**: kubectl commands should fail or timeout, logs should show TLS/certificate errors, etcdctl should fail with authentication or TLS errors.

### Task 3 Verification
```bash
# Check certificate expiration
sudo openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -dates -subject
sudo openssl x509 -in /etc/kubernetes/pki/etcd/peer.crt -noout -dates -subject
sudo openssl x509 -in /etc/kubernetes/pki/etcd/ca.crt -noout -dates -subject

# Verify certificate chain
sudo openssl verify -CAfile /etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/server.crt
sudo openssl verify -CAfile /etc/kubernetes/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/peer.crt

# Check certificate file permissions
sudo ls -la /etc/kubernetes/pki/etcd/
sudo ls -la /etc/kubernetes/pki/apiserver-etcd-client.*

# Test certificate/key match
sudo openssl x509 -noout -modulus -in /etc/kubernetes/pki/etcd/server.crt | openssl md5
sudo openssl rsa -noout -modulus -in /etc/kubernetes/pki/etcd/server.key | openssl md5
```
**Expected Output**: Should reveal expired certificates, invalid certificate chains, permission issues, or certificate/key mismatches depending on the breaking method used.

### Task 4 Verification
```bash
# Test TLS handshake
sudo timeout 10 openssl s_client -connect 127.0.0.1:2379 \
  -cert /etc/kubernetes/pki/apiserver-etcd-client.crt \
  -key /etc/kubernetes/pki/apiserver-etcd-client.key \
  -CAfile /etc/kubernetes/pki/etcd/ca.crt

# Validate certificate paths in manifests
grep -A 5 -B 5 "etcd.*crt\|etcd.*key" /etc/kubernetes/manifests/kube-apiserver.yaml
grep -A 5 -B 5 "cert-file\|key-file\|trusted-ca-file" /etc/kubernetes/manifests/etcd.yaml

# Test etcdctl with API server client certificates
sudo ETCDCTL_API=3 etcdctl --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/apiserver-etcd-client.crt \
  --key=/etc/kubernetes/pki/apiserver-etcd-client.key \
  member list
```
**Expected Output**: TLS handshake should fail with specific errors, manifest paths should show incorrect configurations, etcdctl should fail with authentication errors.

### Task 5 Verification
```bash
# Restore certificates (example for backup method)
sudo cp /tmp/etcd-cert-backup/* /etc/kubernetes/pki/etcd/

# OR regenerate certificates using kubeadm
sudo kubeadm certs renew etcd-server
sudo kubeadm certs renew etcd-peer
sudo kubeadm certs renew etcd-healthcheck-client
sudo kubeadm certs renew apiserver-etcd-client

# Verify certificate restoration
sudo openssl x509 -in /etc/kubernetes/pki/etcd/server.crt -noout -dates -subject

# Test etcd connectivity after restoration
sudo ETCDCTL_API=3 etcdctl --endpoints=127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  endpoint health

# Verify API server reconnection
kubectl get nodes
kubectl cluster-info
```
**Expected Output**: Certificates should show valid dates and correct subjects, etcdctl should return "healthy", kubectl commands should work normally.

### Task 6 Verification
```bash
# Check all certificate expiration dates
sudo kubeadm certs check-expiration

# Verify certificate monitoring setup
for cert in /etc/kubernetes/pki/etcd/*.crt; do
  echo "Certificate: $cert"
  sudo openssl x509 -in "$cert" -noout -dates -subject
  echo "---"
done

# Test certificate rotation simulation
sudo kubeadm certs renew --dry-run etcd-server

# Verify cluster health after restoration
kubectl get componentstatuses
kubectl get pods --all-namespaces | grep -E "(etcd|kube-apiserver)"
```
**Expected Output**: All certificates should show valid future expiration dates, cluster components should be healthy, dry-run should show successful rotation capability.

## Expected Results
- All etcd certificates restored to valid, non-expired state with correct configurations
- TLS handshake between API server and etcd working without authentication errors
- Complete cluster functionality restored with all kubectl operations working normally
- Certificate chain validation successful across all etcd components
- API server successfully authenticating to etcd with proper client certificates
- Production workloads (secure-app deployment) healthy and accessible
- Certificate monitoring established with expiration tracking

## Key Learning Points
- **Certificate criticality**: etcd certificate issues cause immediate cluster-wide authentication failures affecting all operations
- **TLS handshake troubleshooting**: Using OpenSSL tools to diagnose certificate validation and TLS connection issues
- **Certificate chain validation**: Understanding CA relationships and certificate trust chains in Kubernetes
- **Component interdependencies**: API server, etcd server, and peer certificates must all be valid for cluster functionality
- **Certificate paths**: Correct file paths in component manifests are critical for certificate loading
- **kubeadm certificate management**: Using kubeadm for certificate renewal and regeneration in production clusters
- **Authentication vs authorization**: Certificate issues cause authentication failures before RBAC authorization even applies

## Exam & Troubleshooting Tips
- **CKA Exam Approach**: Certificate errors often present as "TLS handshake failed" or "x509: certificate has expired" - check certificate dates first
- **Quick Certificate Validation**: `openssl x509 -in cert.crt -noout -dates` shows expiration immediately
- **Common Certificate Issues**:
  - Expired certificates (check with `kubeadm certs check-expiration`)
  - Wrong file paths in component manifests
  - Certificate/key mismatches
  - Invalid CA trust relationships
  - File permission issues (certificates not readable)
- **Emergency Recovery**: 
  - `kubeadm certs renew all` regenerates all cluster certificates
  - Always backup certificates before making changes
  - Static pod restarts automatically when manifest files change
- **Production Considerations**:
  - Set up certificate expiration monitoring (90 days before expiry)
  - Automate certificate renewal processes
  - Test certificate rotation procedures regularly
  - Document certificate dependencies and renewal procedures
- **Troubleshooting Tools**: 
  - `openssl s_client` for TLS handshake testing
  - `openssl verify` for certificate chain validation
  - `openssl x509 -noout -modulus` for certificate/key matching
- **File Locations**: Standard etcd certificates in `/etc/kubernetes/pki/etcd/` and API server client certificates in `/etc/kubernetes/pki/`
- **Certificate Types**: Understand differences between server certificates (etcd), client certificates (API server), and peer certificates (etcd cluster communication)