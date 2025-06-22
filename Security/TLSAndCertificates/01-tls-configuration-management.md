# TLS Configuration and Management

## Scenario Overview
- **Time Limit**: 45 minutes
- **Difficulty**: Advanced
- **Environment**: Killercoda Ubuntu Playground with kubeadm cluster

## Objective
Master Kubernetes TLS certificate lifecycle management including examination, validation, rotation, and troubleshooting in a production-like environment.

## Context
You're a platform engineer at SecureCloud Corp, responsible for maintaining the security posture of multiple Kubernetes clusters. The security team has requested a comprehensive audit of TLS certificate management practices, including certificate validation, rotation procedures, and troubleshooting workflows. Your task is to demonstrate proper certificate lifecycle management and establish monitoring procedures for certificate expiration.

## Prerequisites
- Killercoda Ubuntu Playground environment
- Basic understanding of X.509 certificates and TLS concepts
- Familiarity with kubectl and kubeadm commands
- Access to cluster admin credentials

## Tasks

### Task 1: Environment Setup and Cluster Initialization
**Time: 8 minutes**

Initialize a kubeadm Kubernetes cluster in the Killercoda environment to provide a realistic certificate management scenario.

1. **Install kubeadm, kubelet, and kubectl**:
   - Update package repository and install Docker
   - Add Kubernetes apt repository and install kubeadm components
   - Initialize the cluster with kubeadm

2. **Configure kubectl access**:
   - Copy admin kubeconfig to user's home directory
   - Verify cluster connectivity with kubectl

3. **Install a CNI plugin**:
   - Deploy Flannel or Calico for pod networking
   - Ensure cluster nodes are in Ready state

**Hint**: Use `kubeadm init --pod-network-cidr=10.244.0.0/16` for Flannel compatibility.

### Task 2: TLS Certificate Examination and Validation
**Time: 10 minutes**

Examine the cluster's TLS certificate infrastructure and validate certificate properties.

1. **Locate and examine API server certificates**:
   - Find the API server certificate files in `/etc/kubernetes/pki/`
   - Use `openssl x509` command to inspect certificate details including:
     - Subject and issuer information
     - Validity period (not before/not after dates)
     - Subject Alternative Names (SANs)
     - Key usage extensions

2. **Validate certificate chain**:
   - Examine the relationship between CA certificate and server certificates
   - Verify certificate signatures using OpenSSL
   - Check certificate file permissions and ownership

3. **Inspect kubelet certificates**:
   - Locate kubelet client certificate in `/var/lib/kubelet/pki/`
   - Examine certificate details and compare with API server certificates
   - Verify kubelet certificate is signed by cluster CA

**Hint**: Use `openssl x509 -in <cert-file> -text -noout` to display certificate details.

### Task 3: Certificate Expiration Monitoring and Checking
**Time: 8 minutes**

Implement certificate expiration monitoring and establish alerting procedures.

1. **Check certificate expiration status**:
   - Use `kubeadm certs check-expiration` to review all cluster certificates
   - Identify certificates approaching expiration (within 30 days)
   - Document certificate renewal timeline

2. **Create certificate monitoring script**:
   - Write a bash script that checks certificate expiration dates
   - Script should output certificates expiring within specified days
   - Include both cluster certificates and kubelet certificates

3. **Verify certificate rotation capability**:
   - Test certificate rotation with `kubeadm certs renew --dry-run`
   - Examine which certificates would be renewed
   - Verify rotation process doesn't affect cluster operations

**Hint**: Use `kubeadm certs renew --help` to see available certificate renewal options.

### Task 4: Manual Certificate Rotation Procedure
**Time: 12 minutes**

Perform manual certificate rotation to simulate production certificate lifecycle management.

1. **Backup existing certificates**:
   - Create backup directory for current certificates
   - Copy all certificates from `/etc/kubernetes/pki/` to backup location
   - Verify backup integrity by comparing file checksums

2. **Rotate API server certificates**:
   - Use `kubeadm certs renew apiserver` to renew API server certificate
   - Compare certificate details before and after rotation
   - Verify new certificate has updated validity period

3. **Rotate admin client certificates**:
   - Renew admin client certificate with `kubeadm certs renew admin.conf`
   - Update kubeconfig with new certificate
   - Test kubectl connectivity with renewed certificates

4. **Restart control plane components**:
   - Restart API server to load new certificates
   - Verify cluster remains operational after certificate rotation
   - Check component logs for certificate-related errors

**Hint**: Control plane components may need restart after certificate renewal: `systemctl restart kubelet`

### Task 5: TLS Troubleshooting and Debugging
**Time: 7 minutes**

Simulate and resolve common TLS certificate issues to build troubleshooting skills.

1. **Simulate certificate validation failure**:
   - Temporarily modify a certificate file to create validation error
   - Attempt cluster operations and observe error messages
   - Use kubectl with increased verbosity (`-v=8`) to see TLS handshake details

2. **Diagnose kubelet certificate issues**:
   - Check kubelet logs for certificate-related errors
   - Verify kubelet can communicate with API server
   - Test certificate validation with curl against API server

3. **Resolve certificate trust issues**:
   - Restore original certificate from backup
   - Verify certificate chain validation
   - Confirm cluster operations return to normal

**Hint**: Use `journalctl -u kubelet -f` to monitor kubelet logs in real-time during troubleshooting.

## Verification Commands

### Task 1 Verification
```bash
# Verify cluster initialization
kubectl cluster-info
kubectl get nodes -o wide

# Check control plane pods
kubectl get pods -n kube-system

# Verify CNI plugin deployment
kubectl get pods -n kube-system | grep -E "(flannel|calico)"
```

**Expected Output**: Cluster should show Ready nodes and all control plane pods Running.

### Task 2 Verification
```bash
# Examine API server certificate
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A 10 "Subject:"

# Verify certificate chain
openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt

# Check certificate file permissions
ls -la /etc/kubernetes/pki/apiserver.crt
```

**Expected Output**: Certificate should show proper subject with kubernetes hostname, valid signature verification, and correct file permissions (644).

### Task 3 Verification
```bash
# Check certificate expiration
kubeadm certs check-expiration

# Verify monitoring script functionality
bash cert-monitor.sh 365

# Test dry-run certificate renewal
kubeadm certs renew --dry-run
```

**Expected Output**: Certificate expiration check should show validity periods, monitoring script should list certificates with days until expiration.

### Task 4 Verification
```bash
# Compare certificate serial numbers before/after rotation
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -serial -noout

# Verify kubectl connectivity with new certificates
kubectl get pods --v=2

# Check kubelet certificate rotation
openssl x509 -in /var/lib/kubelet/pki/kubelet-client-current.pem -dates -noout
```

**Expected Output**: Certificate serial numbers should be different after rotation, kubectl should work without errors.

### Task 5 Verification
```bash
# Check kubelet certificate validation
curl -k https://$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):6443/api/v1/namespaces

# Verify certificate chain after restoration
openssl verify -CAfile /etc/kubernetes/pki/ca.crt /etc/kubernetes/pki/apiserver.crt

# Confirm cluster operations
kubectl get pods --all-namespaces
```

**Expected Output**: Certificate verification should succeed, kubectl operations should complete without TLS errors.

## Expected Results

After completing this scenario, you should have:

1. **Functional kubeadm cluster** with proper TLS certificate infrastructure
2. **Certificate examination skills** including OpenSSL commands for certificate inspection
3. **Certificate monitoring system** with automated expiration checking
4. **Certificate rotation experience** with manual renewal procedures
5. **TLS troubleshooting capabilities** for common certificate issues
6. **Backup and recovery procedures** for certificate lifecycle management

## Key Learning Points

- **Certificate Lifecycle Management**: Understanding how Kubernetes certificates are generated, validated, and renewed
- **kubeadm Certificate Commands**: Using `kubeadm certs` subcommands for certificate management
- **OpenSSL Certificate Inspection**: Reading certificate details, validating chains, and checking expiration
- **Certificate Rotation Procedures**: Manual certificate renewal and component restart requirements
- **TLS Troubleshooting**: Diagnosing certificate validation failures and kubelet communication issues
- **Security Best Practices**: Certificate backup, monitoring, and proactive renewal strategies

## Exam & Troubleshooting Tips

**Real Exam Tips:**
- **Certificate Locations**: Memorize standard certificate paths (`/etc/kubernetes/pki/`, `/var/lib/kubelet/pki/`)
- **kubeadm Commands**: Practice `kubeadm certs check-expiration` and `kubeadm certs renew` commands
- **Certificate Validation**: Know how to use OpenSSL to inspect certificate details and verify chains
- **Component Restart**: Understand which components need restart after certificate rotation
- **Time Management**: Certificate tasks often appear in troubleshooting scenarios - practice efficient workflows

**Troubleshooting Tips:**
- **Certificate Expiration**: Always check certificate validity dates when troubleshooting TLS errors
- **File Permissions**: Verify certificate file ownership and permissions (typically root:root 644)
- **Certificate Chain**: Ensure proper CA certificate validation and intermediate certificate presence
- **SAN Validation**: Check Subject Alternative Names match cluster hostnames and IP addresses
- **Kubelet Certificates**: Kubelet certificate issues often cause node communication failures
- **Log Analysis**: Use `journalctl -u kubelet` and `kubectl logs` to identify certificate-related errors
- **Backup Strategy**: Always backup certificates before rotation to enable quick recovery
- **Dry Run Testing**: Use `--dry-run` options to verify certificate operations before execution

## Common Certificate Issues and Solutions

**Issue: Certificate Validation Failed**
- Solution: Check certificate expiration dates, verify CA certificate, validate SAN entries

**Issue: Kubelet Cannot Connect to API Server**
- Solution: Verify kubelet client certificate, check certificate rotation, restart kubelet service

**Issue: Certificate Rotation Fails**
- Solution: Ensure sufficient disk space, verify file permissions, check kubeadm version compatibility

**Issue: Control Plane Components Not Starting**
- Solution: Verify certificate file paths in component configurations, check certificate validity periods