# Secret Types and Creation Methods

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Master the creation of fundamental Kubernetes Secret types, including `Opaque` and `kubernetes.io/tls`, using both imperative and declarative methods, while understanding the constraints and validation for each type.

## Context
As part of deploying a secure application, you need to handle different kinds of sensitive data: simple credentials, API keys from files, and TLS certificates for securing ingress traffic. This scenario challenges you to use the correct secret type and creation method for each use case, based on official Kubernetes concepts.

## Prerequisites
- A running k3s cluster.
- `kubectl` access with admin privileges.
- The `openssl` command-line tool available for generating a self-signed certificate.

## Tasks

### Task 1: Create an Opaque Secret from Literals
*(Time Suggestion: 3 minutes)*

Create a generic `Opaque` secret imperatively. This is the most common type for unstructured key-value data.

- **Secret Name**: `db-app-credentials`
- **Key 1**: `DB_USER` with value `app_user`
- **Key 2**: `DB_PASS` with value `S!p3rS3cr3t`

---

### Task 2: Create an Opaque Secret from a File
*(Time Suggestion: 4 minutes)*

Create a secret from a file containing sensitive data. This is a common pattern for injecting configuration files or tokens.

**Step 2a**: Create the source file.

Create a file named `api-token.txt`:
```
aK1s9d8F3gH5jL2k-b7v3n9m2p
```

**Step 2b**: Create the secret from the file.
- **Secret Name**: `api-token-secret`
- **Source File**: `api-token.txt`

---

### Task 3: Create a TLS Secret Declaratively
*(Time Suggestion: 8 minutes)*

Create a `kubernetes.io/tls` secret to store a TLS certificate and private key. This secret type has specific data key requirements (`tls.crt` and `tls.key`) that Kubernetes can validate.

**Step 3a**: Generate a self-signed TLS certificate and private key.
Use `openssl` to create `tls.key` and `tls.crt` files.
```bash
openssl req -x509 -newkey rsa:4096 -keyout tls.key -out tls.crt -days 365 -nodes -subj "/CN=myapp.example.com"
```

**Step 3b**: Create the secret from the generated files.
- **Secret Type**: `kubernetes.io/tls`
- **Secret Name**: `myapp-tls-cert`
- **Source Files**: `tls.crt` and `tls.key`

**Hint**: Use an imperative command with the correct `--type` flag for this. This is a common exam shortcut.

---

### Task 4: Inspect a ServiceAccount Token Secret
*(Time Suggestion: 4 minutes)*

Kubernetes automatically creates secrets of type `kubernetes.io/service-account-token`. Inspect one of these to understand its structure and how the system manages pod identities.

**Step 4a**: Create a new ServiceAccount.
- **ServiceAccount Name**: `automation-agent`

**Step 4b**: Identify and inspect the token secret created for this ServiceAccount.

---

### Task 5: Validate Secret Data via Decoding
*(Time Suggestion: 3 minutes)*

Verify the contents of the secrets you created by retrieving and decoding their Base64 encoded values. This task reinforces that secrets are not encrypted, merely encoded.

**Your Goal**: Retrieve and decode the `DB_PASS` value from the `db-app-credentials` secret created in Task 1.

---

## Verification Commands

### Task 1: Verification
**Command**:
```bash
kubectl describe secret db-app-credentials
```
**Expected Result**: The output should show the secret name, namespace, type `Opaque`, and two data keys: `DB_PASS` and `DB_USER`.

**Command**:
```bash
kubectl get secret db-app-credentials -o jsonpath='{.data.DB_PASS}' | base64 --decode
```
**Expected Result**: The command should output the exact string `S!p3rS3cr3t`.

---

### Task 2: Verification
**Command**:
```bash
kubectl get secret api-token-secret -o jsonpath='{.data.api-token\.txt}' | base64 --decode
```
**Expected Result**: The command should output the exact string `aK1s9d8F3gH5jL2k-b7v3n9m2p`.

---

### Task 3: Verification
**Command**:
```bash
kubectl describe secret myapp-tls-cert
```
**Expected Result**: The output should show the secret name and the type `kubernetes.io/tls`. It must contain two data keys: `tls.crt` and `tls.key`.

**Command**:
```bash
# Verify the secret contains the required keys
kubectl get secret myapp-tls-cert -o jsonpath='{.data}' | grep "tls.crt" | grep "tls.key"
```
**Expected Result**: The command should successfully find both keys and produce output.

---

### Task 4: Verification
**Command**:
```bash
# The secret name is auto-generated, so we find it programmatically
SECRET_NAME=$(kubectl get sa automation-agent -o jsonpath='{.secrets[0].name}')
kubectl describe secret $SECRET_NAME
```
**Expected Result**: The output should describe a secret of type `kubernetes.io/service-account-token` containing `token`, `ca.crt`, and `namespace` data.

---

### Task 5: Verification
**Command**:
```bash
kubectl get secret db-app-credentials -o jsonpath='{.data.DB_PASS}' | base64 --decode
```
**Expected Result**: The command should output the original plain text password: `S!p3rS3cr3t`.

---

## Expected Results
- An `Opaque` Secret named `db-app-credentials` exists.
- An `Opaque` Secret named `api-token-secret` exists.
- A `kubernetes.io/tls` Secret named `myapp-tls-cert` exists with `tls.crt` and `tls.key` data keys.
- A ServiceAccount named `automation-agent` and its associated token secret exist.
- You have successfully decoded a secret value back to plain text.

## Key Learning Points
- **Built-in Secret Types**: You created secrets of type `Opaque` (the default for generic data) and `kubernetes.io/tls` (for certificates). Kubernetes uses specific types to validate data and for consumption by certain components like Ingress controllers.
- **Creation Methods**: You used both imperative (`--from-literal`, `--from-file`) and declarative-style (`--type`) commands to create secrets suitable for different use cases.
- **Type-Specific Validation**: The `tls` secret type requires specific data keys (`tls.crt`, `tls.key`). Creating a `tls` secret without these keys would fail, demonstrating built-in validation.
- **Base64 Encoding**: You confirmed that all secret data, regardless of type, is stored as Base64 encoded strings, which is not a form of encryption.

## Exam & Troubleshooting Tips
- **Exam Tip**: Know the shortcuts for creating typed secrets. `kubectl create secret tls <name> --cert=path/to/cert --key=path/to/key` is much faster than writing YAML.
- **TLS Secret Keys**: A common mistake is misnaming the keys in a `tls` secret. They *must* be `tls.crt` and `tls.key`.
- **Troubleshooting**: If an Ingress controller isn't picking up a TLS secret, use `kubectl describe secret <secret-name>` to verify its type is `kubernetes.io/tls` and that it contains the correct keys.
- **OpenSSL**: Be familiar with basic `openssl` commands to generate certificates and keys for testing purposes. The `-nodes` flag (no DES) is useful to avoid being prompted for a passphrase.