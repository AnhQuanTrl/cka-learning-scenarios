# Kubeconfig Management

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Learn to manage cluster access by creating and manipulating Kubeconfig files, defining users, and switching between contexts.

## Context
As a cluster administrator, you are responsible for managing access for different users and services across multiple environments (development, staging, and production). You need to create separate Kubeconfig files for each user, merge them into a central file, and efficiently switch between access contexts without compromising security.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended).
- `kubectl` installed and configured to access the cluster.
- `openssl` and `cfssl` tools installed for certificate generation.

## Tasks

### Task 1: Create a New User with Certificate-Based Authentication
*Suggested Time: 10 minutes*

First, you'll create a new user named **jane** who will authenticate using a client certificate.

1.  **Generate a private key for Jane**:
    ```bash
    openssl genrsa -out jane.key 2048
    ```

2.  **Create a Certificate Signing Request (CSR)** for Jane. The subject should identify her as part of the **developers** group:
    ```bash
    openssl req -new -key jane.key -out jane.csr -subj "/CN=jane/O=developers"
    ```

3.  **Create a `CertificateSigningRequest` object in Kubernetes**.
    - Create a file named `jane-csr.yaml` with the following content:
      ```yaml
      apiVersion: certificates.k8s.io/v1
      kind: CertificateSigningRequest
      metadata:
        name: jane-csr
      spec:
        request: $(cat jane.csr | base64 | tr -d '\n')
        signerName: kubernetes.io/kube-apiserver-client
        usages:
        - client auth
      ```
    - Apply the manifest:
      ```bash
      kubectl apply -f jane-csr.yaml
      ```

4.  **Approve the CSR**:
    ```bash
    kubectl certificate approve jane-csr
    ```

5.  **Retrieve the signed certificate**:
    ```bash
    kubectl get csr jane-csr -o jsonpath='{.status.certificate}' | base64 --decode > jane.crt
    ```

### Task 2: Create a Dedicated Kubeconfig for Jane
*Suggested Time: 5 minutes*

Now, create a new Kubeconfig file specifically for Jane.

1.  **Get the cluster CA certificate and server URL**.
    - **Hint**: You can find these in your default Kubeconfig file (`~/.kube/config`). For k3s, the CA data is typically embedded.

2.  **Create a new Kubeconfig file named `jane-kubeconfig.yaml`**. Use the `kubectl config` command to add the cluster, user, and context.
    - **Cluster Name**: `k3s-dev`
    - **User Name**: `jane`
    - **Context Name**: `jane-dev`
    - **Hint**: Use the `--embed-certs=true` flag to embed the certificate data directly.

    ```bash
    # Replace with your actual server URL and CA data path
    KUBE_SERVER="<YOUR_K3S_SERVER_URL>"
    KUBE_CA_CERT="<PATH_TO_YOUR_CA_CERT>" # Or extract from default kubeconfig

    kubectl config --kubeconfig=jane-kubeconfig.yaml set-cluster k3s-dev --server="$KUBE_SERVER" --certificate-authority="$KUBE_CA_CERT" --embed-certs=true
    kubectl config --kubeconfig=jane-kubeconfig.yaml set-credentials jane --client-certificate=jane.crt --client-key=jane.key --embed-certs=true
    kubectl config --kubeconfig=jane-kubeconfig.yaml set-context jane-dev --cluster=k3s-dev --user=jane
    ```

### Task 3: Merge Kubeconfig Files
*Suggested Time: 5 minutes*

Merge Jane's Kubeconfig with your default Kubeconfig file.

1.  **Set the `KUBECONFIG` environment variable** to include both your default config and Jane's new config.
    ```bash
    export KUBECONFIG=~/.kube/config:jane-kubeconfig.yaml
    ```

2.  **View the merged configuration** and save it to a new file named `merged-kubeconfig.yaml`.
    ```bash
    kubectl config view --flatten > merged-kubeconfig.yaml
    ```

3.  **Inspect the `merged-kubeconfig.yaml` file**. Verify that it contains both your original context and the new `jane-dev` context.

### Task 4: Switch Contexts and Verify Access
*Suggested Time: 5 minutes*

Use the merged Kubeconfig to switch between contexts and test Jane's permissions.

1.  **Use the merged Kubeconfig** to view the current context.
    ```bash
    kubectl config --kubeconfig=merged-kubeconfig.yaml get-contexts
    ```

2.  **Switch to the `jane-dev` context**.
    ```bash
    kubectl config --kubeconfig=merged-kubeconfig.yaml use-context jane-dev
    ```

3.  **Verify Jane's access**. As Jane, try to list pods in the `kube-system` namespace. This command should **fail** because Jane is not authorized.
    ```bash
    kubectl --kubeconfig=merged-kubeconfig.yaml get pods -n kube-system
    ```

## Verification Commands

### Task 1: Create a New User
- **Check CSR status**:
  ```bash
  kubectl get csr jane-csr -o yaml
  ```
  - **Expected Output**: The `status` field should contain a `certificate` and the `conditions` should show `Approved`.

### Task 2: Create a Dedicated Kubeconfig
- **View Jane's Kubeconfig**:
  ```bash
  kubectl config --kubeconfig=jane-kubeconfig.yaml view
  ```
  - **Expected Output**: The output should show the `k3s-dev` cluster, `jane` user, and `jane-dev` context, with all certificate data embedded.

### Task 3: Merge Kubeconfig Files
- **List contexts in the merged file**:
  ```bash
  kubectl config --kubeconfig=merged-kubeconfig.yaml get-contexts
  ```
  - **Expected Output**: The output should list both your original context (e.g., `default`) and the new `jane-dev` context.

### Task 4: Switch Contexts and Verify Access
- **Check the current context**:
  ```bash
  kubectl config --kubeconfig=merged-kubeconfig.yaml current-context
  ```
  - **Expected Output**: `jane-dev`

- **Verify failed access**:
  ```bash
  kubectl --kubeconfig=merged-kubeconfig.yaml get pods -n kube-system
  ```
  - **Expected Output**: An error message indicating that `user "jane"` is forbidden:
    ```
    Error from server (Forbidden): pods is forbidden: User "jane" cannot list resource "pods" in API group "" in the namespace "kube-system"
    ```

## Expected Results
- A new user `jane` is created with certificate-based authentication.
- A standalone Kubeconfig file `jane-kubeconfig.yaml` is created for Jane.
- A `merged-kubeconfig.yaml` file is created containing both the admin and Jane's contexts.
- You can successfully switch to the `jane-dev` context, but attempts to access unauthorized resources fail as expected.

## Key Learning Points
- **Kubeconfig File Structure**: Understand the three main sections: `clusters`, `users`, and `contexts`.
- **Certificate-Based Authentication**: Learn how to create users and grant access using client certificates, a common and secure method.
- **Authentication Methods**: While this scenario focuses on certificates, Kubeconfig also supports other methods like bearer tokens (used by ServiceAccounts). Understanding the different user credential types is crucial.
- **`kubectl config` Command**: Master the use of `kubectl config` to create, view, and manage Kubeconfig files imperatively.
- **`KUBECONFIG` Environment Variable**: Understand how to use the `KUBECONFIG` variable to manage multiple configuration files simultaneously.
- **Context Switching**: Learn how to switch between different clusters, users, and namespaces efficiently.

## Exam & Troubleshooting Tips
- **Exam Tip**: The CKA exam requires you to be fast. Knowing `kubectl config` commands by heart is much faster than editing YAML manually. Practice `set-cluster`, `set-credentials`, and `set-context`.
- **Troubleshooting**: If a user cannot access the cluster, always check the `~/.kube/config` file first. Use `kubectl config view` to ensure the server URL, user credentials, and context are correct.
- **Common Error**: `error: you must be logged in to the server (Unauthorized)`. This usually means the client certificate or token is invalid or not correctly referenced in the Kubeconfig.
- **Token vs. Certificate**: Be ready to work with token-based credentials. A user in a Kubeconfig might have a `token` field instead of `client-certificate-data` and `client-key-data`. This is common for ServiceAccounts.
- **Merging Precedence**: When merging files with `KUBECONFIG`, the first file in the list takes precedence for any conflicting entries.
