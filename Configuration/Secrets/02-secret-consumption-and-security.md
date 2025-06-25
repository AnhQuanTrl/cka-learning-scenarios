# Secret Consumption and Security

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Master secure methods for consuming Kubernetes Secrets in Pods, including environment variables and volume mounts, and understand the security risks and mitigation strategies associated with each approach.

## Context
Your team is deploying a new microservice that requires access to sensitive database credentials and an API key. You must configure the application to consume this data securely, following production best practices to minimize exposure risk. This involves choosing the right consumption method and implementing RBAC controls to restrict access to the secrets.

## Prerequisites
- A running k3s cluster.
- `kubectl` access with admin privileges.

## Tasks

### Task 1: Create the Necessary Secrets
*(Time Suggestion: 4 minutes)*

First, create the secrets that will be consumed by the application pods in later tasks.

**Step 1a**: Create a secret for database credentials.
- **Secret Name**: `db-credentials`
- **Key 1**: `username` with value `postgres_user`
- **Key 2**: `password` with value `P@ssw0rd123!`

**Step 1b**: Create a secret for API keys.
- **Secret Name**: `api-keys`
- **Key 1**: `api-key` with value `abc-123-def-456`
- **Key 2**: `api-secret` with value `shhh-its-a-secret-dont-tell-anyone`

---

### Task 2: Create TLS Secret using Kubernetes CSR API
*(Time Suggestion: 12 minutes)*

Create a TLS certificate using the Kubernetes Certificate Signing Request (CSR) API workflow, then create a TLS secret for secure communication.

**Step 2a**: Create private key and certificate signing request.
- Generate a private key for **web-service.default.svc.cluster.local**
- Create a CSR file requesting a serving certificate with the following details:
  - Common Name: **web-service.default.svc.cluster.local**
  - Organization: **MyCompany**
  - Subject Alternative Names: **web-service.default.svc.cluster.local**, **web-service**, **localhost**

**Step 2b**: Create Kubernetes CSR object and approve it.
- Create a Kubernetes CertificateSigningRequest object named **web-service-csr**
- Set the signer to **kubernetes.io/kube-apiserver-client**
- Configure key usages for **digital signature** and **key encipherment**
- Approve the CSR using kubectl

**Step 2c**: Sign the certificate using a custom self-signed CA.
- Create a self-signed CA certificate and private key for **MyCompany Root CA**
- Extract the CSR from the Kubernetes CSR object
- Sign the certificate using the custom CA with 1-year validity
- Upload the signed certificate to the CSR object using the raw Kubernetes API:
  ```
  /apis/certificates.k8s.io/v1/certificatesigningrequests/web-service-csr/status
  ```

**Step 2d**: Create TLS secret and CA ConfigMap.
- Download the signed certificate from the CSR object
- Create a TLS secret named **web-service-tls** with the signed certificate and private key
- Create a ConfigMap named **ca-bundle** containing the self-signed CA certificate for client verification

### Task 3: Consume a Secret as Environment Variables
*(Time Suggestion: 5 minutes)*

Create a Pod that consumes the `db-credentials` secret by injecting its keys as environment variables. This method is convenient but carries risks, as environment variables can be easily inspected.

- **Pod Name**: `app-pod-env`
- **Container Image**: `busybox`
- **Command**: `sleep 3600`
- **Secret to Consume**: `db-credentials`
- **Consumption Method**:
  - Inject the `username` key from the secret as an environment variable named `DB_USER`.
  - Inject the `password` key from the secret as an environment variable named `DB_PASS`.

---

### Task 3: Consume a Secret as a Volume Mount
*(Time Suggestion: 6 minutes)*

Create a Pod that mounts the `api-keys` secret as a volume. This is generally a more secure pattern, as the secret data is only accessible from within the Pod's filesystem.

- **Pod Name**: `app-pod-volume`
- **Container Image**: `busybox`
- **Command**: `sleep 3600`
- **Secret to Consume**: `api-keys`
- **Consumption Method**:
  - Mount the secret as a volume at the path `/etc/secrets/api`.
  - The files inside the directory should be named after the secret keys (`api-key` and `api-secret`).

---

### Task 4: Selectively Expose Secret Keys in a Volume
*(Time Suggestion: 5 minutes)*

Create a Pod that mounts only a *single key* from the `api-keys` secret. This demonstrates the principle of least privilege by exposing only the necessary data to the application.

- **Pod Name**: `app-pod-selective`
- **Container Image**: `busybox`
- **Command**: `sleep 3600`
- **Secret to Consume**: `api-keys`
- **Consumption Method**:
  - Mount only the `api-key` from the secret.
  - The projected file should be located at the path `/etc/secrets/selective/api-key-file`.

---

### Task 5: Implement RBAC to Restrict Secret Access
*(Time Suggestion: 5 minutes)*

Create a ServiceAccount with restricted permissions to demonstrate how RBAC can be used to limit exposure of secrets.

**Step 5a**: Create a new ServiceAccount.
- **ServiceAccount Name**: `readonly-user`

**Step 5b**: Create a Role that grants read-only access to secrets.
- **Role Name**: `secret-reader`
- **Permissions**: Grant `get` and `list` verbs on the `secrets` resource.

**Step 5c**: Bind the Role to the ServiceAccount.
- **RoleBinding Name**: `read-secrets-binding`
- **Binding**: Connect the `secret-reader` Role to the `readonly-user` ServiceAccount.

## Verification Commands

### Task 1: Verification
**Command**:
```bash
kubectl get secrets db-credentials api-keys
```
**Expected Result**: Both secrets `db-credentials` and `api-keys` should be listed.

**Command**:
```bash
kubectl describe secret db-credentials
```
**Expected Result**: The output should show two data keys: `username` and `password`.

---

### Task 2: Verification
**Command**:
```bash
# Wait for the pod to be running
kubectl wait --for=condition=Ready pod/app-pod-env --timeout=60s
# Inspect the environment variables
kubectl exec -it app-pod-env -- printenv | grep DB_
```
**Expected Result**: The output must show the `DB_USER` and `DB_PASS` environment variables with their corresponding values from the secret.
```
DB_USER=postgres_user
DB_PASS=P@ssw0rd123!
```

---

### Task 3: Verification
**Command**:
```bash
# Wait for the pod to be running
kubectl wait --for=condition=Ready pod/app-pod-volume --timeout=60s
# List the files in the mounted volume
kubectl exec -it app-pod-volume -- ls /etc/secrets/api
```
**Expected Result**: The output should list two files named after the secret keys: `api-key` and `api-secret`.

**Command**:
```bash
# View the content of the mounted secret key
kubectl exec -it app-pod-volume -- cat /etc/secrets/api/api-key
```
**Expected Result**: The output should be the value of the `api-key`: `abc-123-def-456`.

---

### Task 4: Verification
**Command**:
```bash
# Wait for the pod to be running
kubectl wait --for=condition=Ready pod/app-pod-selective --timeout=60s
# List the files in the mounted volume
kubectl exec -it app-pod-selective -- ls /etc/secrets/selective
```
**Expected Result**: The output should list only one file: `api-key-file`.

**Command**:
```bash
# View the content of the projected file
kubectl exec -it app-pod-selective -- cat /etc/secrets/selective/api-key-file
```
**Expected Result**: The output should be the value of the `api-key`: `abc-123-def-456`.

---

### Task 5: Verification
**Command**:
```bash
# Verify the ServiceAccount can read secrets
kubectl auth can-i get secrets --as=system:serviceaccount:default:readonly-user
```
**Expected Result**: The command should output `yes`.

**Command**:
```bash
# Verify the ServiceAccount CANNOT create secrets
kubectl auth can-i create secrets --as=system:serviceaccount:default:readonly-user
```
**Expected Result**: The command should output `no`.

## Expected Results
- A secret named `db-credentials` with two data keys exists.
- A secret named `api-keys` with two data keys exists.
- A Pod named `app-pod-env` is running and has `DB_USER` and `DB_PASS` environment variables.
- A Pod named `app-pod-volume` is running and has the `api-keys` secret mounted at `/etc/secrets/api`.
- A Pod named `app-pod-selective` is running and has only the `api-key` from the `api-keys` secret mounted.
- A ServiceAccount `readonly-user` exists with a RoleBinding that grants it read-only access to secrets.

## Key Learning Points
- **Environment Variable vs. Volume Mount**: You learned the two primary methods for consuming secrets. Volume mounts are generally more secure as they are not as easily exposed as environment variables.
- **Principle of Least Privilege**: Selectively mounting only the required secret keys into a Pod reduces the potential attack surface if the Pod is compromised.
- **RBAC for Secrets**: Using Roles and RoleBindings is the standard way to enforce access control, ensuring that only authorized entities (users or ServiceAccounts) can read or manage secrets.
- **Security Risk**: Secrets injected as environment variables can be exposed via application logs, `kubectl describe pod`, or shell access to the container, posing a higher security risk.

## Exam & Troubleshooting Tips
- **Exam Tip**: Be fast with both consumption patterns. For volume mounts, remember the `secretName` and `mountPath` fields. For environment variables, remember `valueFrom` and `secretKeyRef`.
- **Troubleshooting**: If a Pod fails to start with `CreateContainerConfigError`, check `kubectl describe pod <pod-name>`. The error often indicates that the secret or a specific key it's trying to reference does not exist.
- **RBAC Verification**: The `kubectl auth can-i` command is your best friend for quickly verifying permissions during the exam. Use the `--as` flag to impersonate a user or ServiceAccount.
- **Default Mounts**: Remember that secrets mounted as volumes are read-only by default.