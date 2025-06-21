# Certificate-based Authentication

## Scenario Overview
- **Time Limit**: 35 minutes
- **Difficulty**: Advanced
- **Environment**: k3s bare metal

## Objective
Implement secure certificate-based authentication for a developer user, including certificate lifecycle management and proper RBAC configuration.

## Context
Your organization has implemented a zero-trust security model requiring individual client certificates for all human users accessing Kubernetes. A new developer, "dev-user," needs access to work on applications in a dedicated namespace. You must create their authentication credentials, implement proper certificate lifecycle management, and configure least-privilege access using RBAC. Additionally, you need to demonstrate certificate rotation procedures to ensure ongoing security compliance.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended)
- `kubectl` installed and configured with administrative access
- `openssl` installed for certificate generation
- Basic understanding of X.509 certificates and PKI concepts

## Tasks

### Task 1: Create Initial Environment and Generate User Credentials
*Suggested Time: 8 minutes*

Set up the development environment and generate the cryptographic materials needed for certificate-based authentication.

1. **Create a namespace** called **dev-namespace** for the developer's work.

2. **Generate a private key** for **dev-user** using RSA with **2048-bit** key length. Save this as **dev-user.key**.

3. **Create a Certificate Signing Request (CSR)** with the following specifications:
   - Common Name (CN): **dev-user** (this becomes the username)
   - Organization (O): **developers** (this becomes the group membership)
   - Save the CSR as **dev-user.csr**

**Hint**: Use `openssl` commands for key generation and CSR creation. The CSR should be non-interactive using the `-subj` parameter.

### Task 2: Submit Certificate Signing Request to Kubernetes
*Suggested Time: 10 minutes*

Use the Kubernetes Certificate API to get the user's certificate signed by the cluster's Certificate Authority.

1. **Create a Kubernetes manifest** file named **dev-user-csr.yaml** containing a `CertificateSigningRequest` resource with these specifications:
   - Name: **dev-user-csr**
   - Request data: Base64-encoded content of the CSR file (with no newlines)
   - Signer: **kubernetes.io/kube-apiserver-client**
   - Expiration: **86400 seconds** (24 hours)
   - Usage: **client auth**

2. **Apply the manifest** to create the CSR object in the cluster.

3. **Approve the certificate signing request** using kubectl.

4. **Extract the signed certificate** from the CSR status and save it as **dev-user.crt**.

**Hint**: Use `cat dev-user.csr | base64 | tr -d '\n'` to properly encode the CSR data for the manifest.

### Task 3: Create User Kubeconfig
*Suggested Time: 7 minutes*

Create a dedicated kubeconfig file that the developer can use to authenticate with their certificate.

1. **Create a kubeconfig file** named **dev-user-kubeconfig.yaml** with the following configuration:
   - Cluster name: Use the current cluster name from your admin kubeconfig
   - Server URL: Extract from your current kubeconfig
   - Certificate Authority data: Extract from your current kubeconfig
   - User credentials: Use the generated private key and signed certificate
   - Default namespace: **dev-namespace**
   - Context name: **dev-context**

2. **Set the default context** to **dev-context** in the new kubeconfig file.

**Hint**: Use `kubectl config view` commands to extract cluster information, then use `kubectl config --kubeconfig=` commands to build the new config file.

### Task 4: Configure RBAC Permissions
*Suggested Time: 7 minutes*

Grant the developer appropriate permissions to work within their namespace using Kubernetes RBAC.

1. **Create a Role** named **dev-role** in the **dev-namespace** with permissions for:
   - API groups: **""** (core) and **"apps"**
   - Resources: **deployments**, **services**, **pods**, **configmaps**, **secrets**
   - Verbs: **get**, **list**, **create**, **update**, **patch**, **delete**

2. **Create a RoleBinding** named **dev-binding** that grants the **dev-role** to the **developers** group in the **dev-namespace**.

**Hint**: Create the Role as a YAML manifest, then use kubectl commands for the RoleBinding.

### Task 5: Test Authentication and Authorization
*Suggested Time: 8 minutes*

Verify that the certificate-based authentication works correctly and that RBAC permissions are properly configured.

1. **Test successful operations** using the dev-user kubeconfig:
   - List pods in **dev-namespace**
   - Create a deployment named **test-app** using image **nginx:alpine** in **dev-namespace**
   - Create a ConfigMap named **app-config** with key **env** and value **development**

2. **Test authorization boundaries** by attempting operations that should fail:
   - List pods in the **default** namespace
   - Create resources in the **kube-system** namespace
   - List nodes (cluster-wide resource)

3. **Verify certificate expiration** by checking the certificate's validity period.

**Hint**: Use `--kubeconfig=dev-user-kubeconfig.yaml` flag with kubectl commands to test as the dev-user.

### Task 6: Implement Certificate Rotation
*Suggested Time: 5 minutes*

Demonstrate certificate lifecycle management by rotating the user's certificate.

1. **Generate a new private key** and CSR for **dev-user** with a **12-hour expiration**.

2. **Create and approve a new CSR** following the same process as Task 2, but name it **dev-user-csr-rotated**.

3. **Update the kubeconfig file** to use the new certificate while keeping the same private key.

4. **Verify the rotation** by confirming the user can still access resources with the updated certificate.

**Hint**: You can update credentials in an existing kubeconfig using `kubectl config set-credentials`.

## Verification Commands

### Task 1: Environment and Credentials
- **Verify namespace creation**:
  ```bash
  kubectl get namespace dev-namespace
  ```
  - **Expected Output**: `dev-namespace   Active   <age>`

- **Verify private key generation**:
  ```bash
  ls -la dev-user.key
  ```
  - **Expected Output**: File should exist with permissions `-rw-------` (600)

- **Verify CSR content**:
  ```bash
  openssl req -in dev-user.csr -text -noout | grep -E "Subject:|Signature Algorithm"
  ```
  - **Expected Output**: Subject should contain `CN = dev-user, O = developers`

### Task 2: Certificate Signing Request
- **Check CSR object creation**:
  ```bash
  kubectl get csr dev-user-csr -o wide
  ```
  - **Expected Output**: CSR should show `Approved,Issued` status

- **Verify certificate extraction**:
  ```bash
  openssl x509 -in dev-user.crt -text -noout | grep -E "Subject:|Issuer:|Not After"
  ```
  - **Expected Output**: Subject should be `CN = dev-user, O = developers`, Issuer should contain `kubernetes`

- **Check certificate validity period**:
  ```bash
  openssl x509 -in dev-user.crt -noout -dates
  ```
  - **Expected Output**: Certificate should be valid for 24 hours from creation time

### Task 3: Kubeconfig Creation
- **Verify kubeconfig file structure**:
  ```bash
  kubectl config --kubeconfig=dev-user-kubeconfig.yaml view
  ```
  - **Expected Output**: Should show cluster, user `dev-user`, and context `dev-context`

- **Check current context**:
  ```bash
  kubectl config --kubeconfig=dev-user-kubeconfig.yaml current-context
  ```
  - **Expected Output**: `dev-context`

- **Verify default namespace**:
  ```bash
  kubectl config --kubeconfig=dev-user-kubeconfig.yaml view -o jsonpath='{.contexts[?(@.name=="dev-context")].context.namespace}'
  ```
  - **Expected Output**: `dev-namespace`

### Task 4: RBAC Configuration
- **Check Role creation**:
  ```bash
  kubectl get role dev-role -n dev-namespace -o yaml
  ```
  - **Expected Output**: Should show rules for deployments, services, pods, configmaps, secrets with specified verbs

- **Verify RoleBinding**:
  ```bash
  kubectl get rolebinding dev-binding -n dev-namespace -o jsonpath='{.subjects[0].name}'
  ```
  - **Expected Output**: `developers`

- **Check effective permissions**:
  ```bash
  kubectl auth can-i --as=dev-user --as-group=developers create deployments -n dev-namespace
  ```
  - **Expected Output**: `yes`

### Task 5: Authentication and Authorization Testing
- **Verify successful pod listing**:
  ```bash
  kubectl --kubeconfig=dev-user-kubeconfig.yaml get pods -n dev-namespace
  ```
  - **Expected Output**: Should list pods without permission errors

- **Check deployment creation**:
  ```bash
  kubectl --kubeconfig=dev-user-kubeconfig.yaml get deployment test-app -n dev-namespace
  ```
  - **Expected Output**: Should show the `test-app` deployment with `nginx:alpine` image

- **Verify ConfigMap creation**:
  ```bash
  kubectl --kubeconfig=dev-user-kubeconfig.yaml get configmap app-config -n dev-namespace -o jsonpath='{.data.env}'
  ```
  - **Expected Output**: `development`

- **Test authorization boundary - default namespace**:
  ```bash
  kubectl --kubeconfig=dev-user-kubeconfig.yaml get pods -n default
  ```
  - **Expected Output**: `Error from server (Forbidden): pods is forbidden: User "dev-user" cannot list resource "pods" in API group "" in the namespace "default"`

- **Test authorization boundary - cluster resources**:
  ```bash
  kubectl --kubeconfig=dev-user-kubeconfig.yaml get nodes
  ```
  - **Expected Output**: `Error from server (Forbidden): nodes is forbidden: User "dev-user" cannot list resource "nodes" in API group "" at the cluster scope`

### Task 6: Certificate Rotation
- **Verify new CSR creation**:
  ```bash
  kubectl get csr dev-user-csr-rotated -o wide
  ```
  - **Expected Output**: Should show `Approved,Issued` status

- **Check certificate expiration difference**:
  ```bash
  openssl x509 -in dev-user.crt -noout -dates | grep "Not After" && openssl x509 -in dev-user-rotated.crt -noout -dates | grep "Not After"
  ```
  - **Expected Output**: New certificate should have a 12-hour validity period

- **Verify kubeconfig update**:
  ```bash
  kubectl --kubeconfig=dev-user-kubeconfig.yaml get pods -n dev-namespace
  ```
  - **Expected Output**: Should work with rotated certificate without errors

## Expected Results
- **Namespace**: `dev-namespace` created and ready for development work
- **User Identity**: `dev-user` with group membership in `developers` established through X.509 certificate
- **Certificates**: 
  - Initial certificate with 24-hour expiration (`dev-user.crt`)
  - Rotated certificate with 12-hour expiration (`dev-user-rotated.crt`)
- **Authentication**: Dedicated kubeconfig file (`dev-user-kubeconfig.yaml`) with embedded certificates
- **Authorization**: RBAC Role (`dev-role`) and RoleBinding (`dev-binding`) providing namespace-scoped permissions
- **Security Boundaries**: User access restricted to `dev-namespace` only, with verified denial of access to other namespaces and cluster resources
- **Workload Testing**: Successful deployment of test applications and configuration resources using user credentials

## Key Learning Points
- **X.509 Certificate Identity**: Kubernetes users are defined by X.509 certificates where the Common Name (CN) becomes the username and Organization (O) field defines group membership
- **Certificate Signing Request API**: The `certificates.k8s.io/v1` API provides a secure, auditable way to request certificates from the cluster's Certificate Authority
- **Certificate Lifecycle Management**: Short-lived certificates with automatic rotation improve security posture by limiting exposure from compromised credentials
- **Group-based RBAC**: Assigning roles to groups rather than individual users enables scalable permission management and easier onboarding/offboarding
- **Least Privilege Principle**: Namespace-scoped roles limit blast radius and enforce proper resource isolation
- **kubeconfig Security**: Embedding certificates in kubeconfig files provides portable authentication while maintaining security through proper file permissions
- **Authentication vs Authorization**: Certificate-based authentication establishes identity, while RBAC controls what authenticated users can do
- **Certificate Expiration**: Short certificate lifespans (24 hours or less) are production security best practices that force regular credential rotation

## Production Security Considerations
- **Private Key Storage**: In production, private keys should be stored in secure key management systems (e.g., HashiCorp Vault, AWS KMS)
- **Certificate Distribution**: Use secure channels for distributing certificates and kubeconfig files to users
- **Audit Logging**: Monitor certificate issuance and authentication events through Kubernetes audit logs
- **Automated Rotation**: Implement automated certificate rotation using tools like cert-manager or custom controllers
- **Emergency Revocation**: Plan for certificate revocation procedures in case of compromise

## Exam & Troubleshooting Tips

### CKA Exam Tips
- **Time Management**: Practice `openssl` commands until they're muscle memory - the exam is time-pressured
- **Common Commands**: Memorize the CSR base64 encoding pattern: `cat file.csr | base64 | tr -d '\n'`
- **kubeconfig Shortcuts**: Use `kubectl config --kubeconfig=` pattern for testing user access quickly
- **RBAC Testing**: Use `kubectl auth can-i` to verify permissions before testing with actual user credentials

### Troubleshooting Common Issues

#### Authentication Problems
- **Certificate Validation Errors**: 
  - Check certificate validity dates with `openssl x509 -in cert.crt -noout -dates`
  - Verify certificate subject matches expected username/groups
  - Ensure certificate is properly signed by cluster CA
- **kubeconfig Issues**: 
  - Verify cluster server URL and CA data match admin kubeconfig
  - Check that certificate and key are properly embedded or referenced
  - Confirm context and namespace settings

#### Authorization Problems
- **Forbidden Errors**: 
  - Use `kubectl describe role` and `kubectl describe rolebinding` to verify RBAC configuration
  - Check that group names in certificate match RoleBinding subjects
  - Verify API groups, resources, and verbs are correctly specified
- **Permission Debugging**: 
  - Use `kubectl auth can-i --as=username --as-group=groupname` to test permissions
  - Check effective permissions with `kubectl auth can-i --list --as=username`

#### Certificate Signing Request Issues
- **CSR Not Found**: Verify the YAML manifest was applied correctly and CSR object exists
- **CSR Not Approved**: Check if automatic approval is enabled or manually approve with `kubectl certificate approve`
- **Certificate Not Issued**: 
  - Check `kube-controller-manager` logs for signing errors
  - Verify the signer name matches cluster capabilities
  - Ensure CSR has proper usage specifications

#### k3s Specific Issues
- **Cluster Name**: k3s typically uses `default` as cluster name, not `kubernetes`
- **CA Certificate**: k3s CA certificate location is `/var/lib/rancher/k3s/server/tls/server-ca.crt`
- **Server URL**: Default k3s server URL is `https://127.0.0.1:6443` for local clusters

### Security Best Practices Checklist
- [ ] Use strong private keys (minimum 2048-bit RSA)
- [ ] Set appropriate certificate expiration times (24 hours or less)
- [ ] Implement proper file permissions (600) for private keys
- [ ] Use group-based RBAC for scalability
- [ ] Apply least privilege principle to role definitions
- [ ] Monitor certificate expiration and automate rotation
- [ ] Audit authentication and authorization events
- [ ] Secure distribution of kubeconfig files
