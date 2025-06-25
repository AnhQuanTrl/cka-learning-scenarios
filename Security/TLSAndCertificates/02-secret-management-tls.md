# Secret Management for TLS

## Scenario Overview
- **Time Limit**: 40 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Master TLS secret creation, management, rotation, and integration with Kubernetes workloads using practical applications and ingress controllers.

## Context
You're a DevOps engineer at SecureWeb Solutions, tasked with implementing secure TLS certificate management for multiple web applications. The platform team requires standardized procedures for TLS secret creation, automated certificate rotation, and secure ingress configuration. Your mission is to establish best practices for TLS secret lifecycle management while ensuring zero-downtime certificate updates.

## Prerequisites
- Running k3s cluster with Traefik ingress controller
- kubectl access with cluster-admin privileges
- Basic understanding of TLS certificates and Kubernetes secrets
- OpenSSL installed for certificate generation

## Tasks

### Task 1: TLS Certificate Generation using Kubernetes CSR API
**Time: 15 minutes**

Create TLS certificates using the Kubernetes Certificate Signing Request (CSR) API workflow and convert them into TLS secrets for different applications.

1. **Create private keys and certificate signing requests**:
   - Generate private keys for three applications:
     - **app1.securelab.svc.cluster.local** (web application)
     - **api.securelab.svc.cluster.local** (REST API service) 
     - **admin.securelab.svc.cluster.local** (admin dashboard)
   - Create CSR files for each domain with proper Subject Alternative Names
   - Set Organization to **SecureWeb Solutions**

2. **Create and approve Kubernetes CSR objects**:
   - Create CertificateSigningRequest objects: **app1-csr**, **api-csr**, **admin-csr**
   - Configure proper key usages for **digital signature**, **key encipherment**, and **server auth**
   - Set signer name to **securewebsolutions.com/serving** for custom CA signing
   - Approve all CSRs using kubectl certificate approve commands

3. **Sign certificates using custom self-signed CA**:
   - Create a self-signed CA certificate and private key for **SecureWeb Solutions**
   - Extract CSR data from the Kubernetes CSR objects
   - Sign each certificate using the custom CA with 1-year validity
   - Upload signed certificates back to CSR objects using raw Kubernetes API:
     `/apis/certificates.k8s.io/v1/certificatesigningrequests/{csr-name}/status`

4. **Create TLS secrets using different methods**:
   - Create **app1-tls** secret using `kubectl create secret tls` command with downloaded certificate
   - Create **api-tls** secret from certificate files using `--from-file` method
   - Create **admin-tls** secret using YAML manifest with base64-encoded certificate data
   - Create **ca-bundle** ConfigMap containing the self-signed CA certificate for client verification

5. **Verify secret creation and certificate validity**:
   - Examine secret data structure and certificate storage format
   - Validate certificate content within secrets using openssl
   - Check certificate chain against the custom CA
   - Verify Subject Alternative Names and expiration dates

**Hint**: Use `kubectl get csr <name> -o jsonpath='{.status.certificate}'` to retrieve signed certificates from CSR objects.

### Task 2: TLS Secret Consumption Patterns
**Time: 12 minutes**

Deploy applications that consume TLS secrets through different patterns including volume mounts and ingress integration.

1. **Deploy web application with volume-mounted certificates**:
   - Create **frontend-app** deployment using nginx image
   - Mount **app1-tls** secret as volume at `/etc/ssl/certs/`
   - Configure nginx to use mounted certificates for HTTPS
   - Create custom nginx configuration through ConfigMap

2. **Deploy API service with environment variable certificate paths**:
   - Create **api-service** deployment using **hashicorp/http-echo:latest** image
   - Mount **api-tls** secret as volume at `/etc/certs/`
   - Set environment variables for certificate paths:
     - **TLS_CERT_PATH**: `/etc/certs/tls.crt`
     - **TLS_KEY_PATH**: `/etc/certs/tls.key`
   - Expose service on port 8443 with HTTPS configuration
   - Verify TLS certificate is loaded correctly

3. **Deploy admin dashboard and configure ingress with TLS termination**:
   - Create **admin-dashboard** deployment using **nginx:1.21** image
   - Create service to expose the admin dashboard on port 80
   - Create ingress resource for the **admin-dashboard** service
   - Configure TLS termination using **admin-tls** secret
   - Set up hostname routing for **admin.securelab.svc.cluster.local**
   - Verify Traefik picks up TLS configuration

**Hint**: Use `kubectl port-forward` to test HTTPS endpoints locally before ingress configuration.

### Task 3: TLS Secret Rotation and Rolling Updates
**Time: 10 minutes**

Implement TLS certificate rotation procedures with zero-downtime deployment updates.

1. **Generate new certificates with extended validity**:
   - Create renewed certificates for **app1.securelab.svc.cluster.local** with 2-year validity
   - Generate certificates with additional Subject Alternative Names
   - Include both old and new certificates for transition period

2. **Perform secret rotation with rolling deployment**:
   - Update **app1-tls** secret with new certificate data
   - Trigger rolling deployment of **frontend-app** to pick up new certificates
   - Monitor deployment progress and verify zero downtime
   - Validate new certificate is active in the application

3. **Implement secret versioning strategy**:
   - Create **app1-tls-v2** secret with new certificate
   - Update deployment to reference new secret version
   - Maintain old secret for rollback capability
   - Test rollback procedure by switching back to original secret

**Hint**: Use deployment annotations like `kubectl.kubernetes.io/restartedAt` to force pod restarts after secret updates.

### Task 4: Certificate Lifecycle Automation
**Time: 8 minutes**

Create automated procedures for TLS certificate monitoring and rotation using Kubernetes jobs and scripts.

1. **Create certificate expiration monitoring job**:
   - Write bash script to check certificate expiration from TLS secrets
   - Create Kubernetes job that runs the monitoring script
   - Configure job to output certificates expiring within 30 days
   - Store monitoring results in ConfigMap for external consumption

2. **Implement certificate renewal automation**:
   - Create CronJob that generates new certificates monthly
   - Script should update existing TLS secrets with new certificates
   - Include logic to backup old certificates before replacement
   - Trigger deployment restarts after certificate updates

3. **Setup certificate validation pipeline**:
   - Create init container that validates certificate integrity
   - Check certificate chain, expiration, and SAN entries
   - Prevent application startup if certificate validation fails
   - Log certificate validation results for monitoring

**Hint**: Use `kubectl create job --from=cronjob/cert-renewal` to test CronJob logic manually.

## Verification Commands

### Task 1 Verification
```bash
# Check TLS secret creation
kubectl get secrets --field-selector type=kubernetes.io/tls

# Examine secret structure
kubectl describe secret app1-tls
kubectl get secret app1-tls -o yaml

# Validate certificate content
kubectl get secret app1-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

**Expected Output**: Three TLS secrets (app1-tls, api-tls, admin-tls) should exist with valid certificate data and proper kubernetes.io/tls type.

### Task 2 Verification
```bash
# Check application deployments
kubectl get deployments -o wide
kubectl get pods -l app=frontend-app

# Verify certificate mounting
kubectl exec deployment/frontend-app -- ls -la /etc/ssl/certs/
kubectl exec deployment/frontend-app -- openssl x509 -in /etc/ssl/certs/tls.crt -subject -noout

# Test HTTPS endpoints
kubectl port-forward service/frontend-app 8443:443 &
curl -k https://localhost:8443 -v

# Check ingress configuration
kubectl get ingress admin-dashboard -o yaml
kubectl describe ingress admin-dashboard
```

**Expected Output**: Applications should be running with properly mounted certificates, HTTPS endpoints should respond with valid TLS handshakes.

### Task 3 Verification
```bash
# Compare certificate serial numbers before/after rotation
kubectl get secret app1-tls -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -serial -noout

# Check deployment rollout status
kubectl rollout status deployment/frontend-app
kubectl rollout history deployment/frontend-app

# Verify new certificate validity period
kubectl get secret app1-tls-v2 -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -dates -noout

# Test rollback functionality
kubectl rollout undo deployment/frontend-app
kubectl rollout status deployment/frontend-app
```

**Expected Output**: Certificate serial numbers should change after rotation, deployments should complete rollout successfully with new certificates.

### Task 4 Verification
```bash
# Check certificate monitoring job
kubectl get jobs -l app=cert-monitor
kubectl logs job/cert-expiration-check

# Verify CronJob configuration
kubectl get cronjobs cert-renewal
kubectl describe cronjob cert-renewal

# Test certificate validation logic
kubectl logs -l app=frontend-app -c cert-validator --previous
kubectl get configmap cert-monitoring-results -o yaml
```

**Expected Output**: Monitoring job should complete successfully and identify certificate expiration dates, CronJob should be properly scheduled.

## Expected Results

After completing this scenario, you should have:

1. **Three TLS secrets** (app1-tls, api-tls, admin-tls) created using different methods
2. **Multiple applications** consuming TLS certificates via volume mounts and environment variables
3. **Ingress configuration** with TLS termination using Traefik
4. **Certificate rotation procedures** with zero-downtime deployment updates
5. **Automated monitoring system** for certificate expiration tracking
6. **CronJob automation** for certificate lifecycle management

## Key Learning Points

- **TLS Secret Creation Methods**: Command-line, file-based, and YAML manifest approaches
- **Certificate Integration Patterns**: Volume mounting vs environment variable configuration
- **Ingress TLS Configuration**: Traefik integration with TLS secrets for HTTPS termination
- **Secret Rotation Strategies**: Zero-downtime certificate updates and rollback procedures
- **Certificate Lifecycle Management**: Automated monitoring, renewal, and validation processes
- **Security Best Practices**: Certificate storage, access control, and validation patterns

## Exam & Troubleshooting Tips

**Real Exam Tips:**
- **TLS Secret Type**: Always use `kubernetes.io/tls` type for TLS certificates in secrets
- **Certificate Data Keys**: Standard keys are `tls.crt` and `tls.key` in TLS secrets
- **Base64 Encoding**: Remember that secret data is base64-encoded, decode for inspection
- **Ingress TLS**: TLS configuration in ingress requires matching secret names and hostnames
- **Rolling Updates**: Certificate rotation requires deployment restart to pick up new certificates

**Troubleshooting Tips:**
- **Certificate Validation**: Use `openssl x509 -text -noout` to inspect certificate details
- **Secret Mounting Issues**: Check volume mount paths and file permissions inside containers
- **Ingress TLS Problems**: Verify secret exists in same namespace as ingress resource
- **Certificate Expiration**: Monitor certificate validity periods and set up automated alerts
- **Application Startup**: Use init containers to validate certificates before main application starts
- **TLS Handshake Failures**: Check certificate chain, SAN entries, and hostname matching
- **Secret Updates**: Deployment restarts may be needed after secret modifications
- **Rollback Procedures**: Maintain versioned secrets for easy certificate rollback capability

## Common TLS Secret Issues and Solutions

**Issue: TLS Secret Not Found**
- Solution: Verify secret exists in correct namespace, check secret name spelling in ingress/deployment

**Issue: Certificate Format Errors**
- Solution: Ensure PEM format, check for proper BEGIN/END certificate markers, validate base64 encoding

**Issue: Certificate Chain Validation Fails**
- Solution: Include intermediate certificates, verify CA certificate installation, check certificate order

**Issue: Applications Not Picking Up New Certificates**
- Solution: Restart deployments, check volume mount refresh intervals, verify secret update propagation

**Issue: Ingress TLS Not Working**
- Solution: Check hostname matching, verify secret reference, confirm ingress controller supports TLS

**Issue: Certificate Expiration Not Detected**
- Solution: Implement automated monitoring, check certificate validity dates, set up proactive alerts