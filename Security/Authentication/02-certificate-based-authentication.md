# Certificate-based Authentication

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Advanced
- **Environment**: k3s bare metal

## Objective
Learn how to create a new user, generate a client certificate, have it signed by the Kubernetes CA, and configure RBAC rules to grant the user specific permissions.

## Context
A new developer, "dev-user," has joined the team. As the Kubernetes administrator, you need to grant them access to the `dev-namespace`. For security, your company policy requires using individual, short-lived client certificates for all human users. Your task is to create the user credentials, get the certificate signed, and set up the correct permissions for them to work in their designated namespace.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended).
- `kubectl` installed and configured with administrative access.
- `openssl` installed for certificate generation.

## Tasks

### Task 1: Create a Namespace and a New User's Credentials
*Suggested Time: 5 minutes*

First, create the developer's namespace and generate their private key and Certificate Signing Request (CSR).

1.  **Create a new namespace** called `dev-namespace`.
    ```bash
    kubectl create namespace dev-namespace
    ```

2.  **Generate a private key** for `dev-user`.
    ```bash
    openssl genrsa -out dev-user.key 2048
    ```

3.  **Create a CSR**. The Common Name (`CN`) will be the username (`dev-user`), and the Organization (`O`) will be the group (`developers`).
    ```bash
    openssl req -new -key dev-user.key -out dev-user.csr -subj "/CN=dev-user/O=developers"
    ```

### Task 2: Get the Certificate Signed by the Kubernetes CA
*Suggested Time: 10 minutes*

Submit the CSR to the Kubernetes API to have it signed by the cluster's built-in Certificate Authority.

1.  **Create a `CertificateSigningRequest` manifest** named `dev-user-csr.yaml`.
    - **Hint**: The request data must be base64-encoded.
    ```yaml
    apiVersion: certificates.k8s.io/v1
    kind: CertificateSigningRequest
    metadata:
      name: dev-user-csr
    spec:
      request: $(cat dev-user.csr | base64 | tr -d '\n')
      signerName: kubernetes.io/kube-apiserver-client
      expirationSeconds: 86400 # 24 hours
      usages:
      - client auth
    ```

2.  **Apply the manifest** to create the CSR object.
    ```bash
    kubectl apply -f dev-user-csr.yaml
    ```

3.  **Approve the CSR**.
    ```bash
    kubectl certificate approve dev-user-csr
    ```

4.  **Retrieve the signed certificate** and save it to a file.
    ```bash
    kubectl get csr dev-user-csr -o jsonpath='{.status.certificate}' | base64 --decode > dev-user.crt
    ```

### Task 3: Create a Kubeconfig File for the New User
*Suggested Time: 5 minutes*

With the signed certificate, create a dedicated Kubeconfig file for `dev-user`.

1.  **Use `kubectl config`** to create a new Kubeconfig file named `dev-user-kubeconfig.yaml`.
    - **Hint**: You'll need the server URL and CA data from your admin Kubeconfig.
    ```bash
    # Get cluster info from your current config
    SERVER_URL=$(kubectl config view -o jsonpath='{.clusters[?(@.name=="default")].cluster.server}')
    CA_CERT_DATA=$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name=="default")].cluster.certificate-authority-data}')

    # Create the Kubeconfig
    kubectl config --kubeconfig=dev-user-kubeconfig.yaml set-cluster default --server="$SERVER_URL" --certificate-authority-data="$CA_CERT_DATA" --embed-certs=true
    kubectl config --kubeconfig=dev-user-kubeconfig.yaml set-credentials dev-user --client-certificate=dev-user.crt --client-key=dev-user.key --embed-certs=true
    kubectl config --kubeconfig=dev-user-kubeconfig.yaml set-context dev-context --cluster=default --user=dev-user --namespace=dev-namespace
    kubectl config --kubeconfig=dev-user-kubeconfig.yaml use-context dev-context
    ```

### Task 4: Grant Permissions with RBAC
*Suggested Time: 5 minutes*

Currently, `dev-user` can authenticate but has no permissions. Create a `Role` and `RoleBinding` to grant them the ability to manage deployments and services in `dev-namespace`.

1.  **Create a `Role`** named `dev-role` in `dev-namespace` that allows full access to `deployments`, `services`, and `pods`.
    - Create a file named `dev-role.yaml`:
      ```yaml
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: dev-role
        namespace: dev-namespace
      rules:
      - apiGroups: ["", "apps"]
        resources: ["deployments", "services", "pods"]
        verbs: ["*"]
      ```
    - Apply the manifest:
      ```bash
      kubectl apply -f dev-role.yaml
      ```

2.  **Create a `RoleBinding`** to grant the `dev-role` to the `developers` group.
    ```bash
    kubectl create rolebinding dev-rb --role=dev-role --group=developers -n dev-namespace
    ```

### Task 5: Verify Access
*Suggested Time: 5 minutes*

Test that `dev-user` has the correct permissions.

1.  **As `dev-user`**, try to create a deployment in `dev-namespace`. This should **succeed**.
    ```bash
    kubectl --kubeconfig=dev-user-kubeconfig.yaml create deployment nginx --image=nginx
    ```

2.  **As `dev-user`**, try to list pods in the `default` namespace. This should **fail**.
    ```bash
    kubectl --kubeconfig=dev-user-kubeconfig.yaml get pods -n default
    ```

## Verification Commands

### Task 2: Certificate Signing
- **Check CSR status**:
  ```bash
  kubectl get csr dev-user-csr
  ```
  - **Expected Output**: The status should show `Approved,Issued`.

### Task 4: RBAC
- **Check the RoleBinding**:
  ```bash
  kubectl get rolebinding dev-rb -n dev-namespace -o yaml
  ```
  - **Expected Output**: The `subjects` section should show the `developers` group.

### Task 5: Access Verification
- **Successful command**:
  ```bash
  kubectl --kubeconfig=dev-user-kubeconfig.yaml get deployments -n dev-namespace
  ```
  - **Expected Output**: The `nginx` deployment should be listed.
- **Failed command**:
  ```bash
  kubectl --kubeconfig=dev-user-kubeconfig.yaml get pods -n default
  ```
  - **Expected Output**: An error message: `Error from server (Forbidden): pods is forbidden: User "dev-user" cannot list resource "pods" in API group "" in the namespace "default"`.

## Expected Results
- A new user `dev-user` is created, belonging to the `developers` group.
- A signed client certificate (`dev-user.crt`) is generated for the user.
- A dedicated Kubeconfig file (`dev-user-kubeconfig.yaml`) is created for the user.
- The `dev-user` has full permissions on `deployments`, `services`, and `pods` within the `dev-namespace` only.
- The user cannot access any resources outside of their designated namespace.

## Key Learning Points
- **User vs. Service Account**: Kubernetes does not have a "user" object. A user is simply an identity defined by a private key and a signed certificate. The username (`CN`) and group (`O`) are embedded in the certificate's subject.
- **CSR API**: The `certificates.k8s.io` API provides a standardized way to request and receive signed certificates from the cluster's CA, enabling a secure certificate lifecycle.
- **`expirationSeconds`**: Setting an expiration on certificates is a critical security best practice. It forces periodic credential rotation, reducing the risk of a compromised key.
- **Group-based RBAC**: Binding roles to groups (`O` field in the certificate) instead of individual users (`CN` field) is a more scalable and manageable approach to RBAC.

## Exam & Troubleshooting Tips
- **Exam Tip**: Be very quick with `openssl` commands for generating keys and CSRs. The exam is time-pressured, and fumbling with `openssl` syntax can cost you valuable minutes.
- **Troubleshooting**: If a user with a valid certificate gets a `Forbidden` error, the problem is almost always with RBAC. Use `kubectl describe rolebinding <name>` and `kubectl describe role <name>` to carefully check that the user/group, resources, and verbs are all correct.
- **CSR Not Found**: If `kubectl get csr` doesn't show your CSR, make sure you applied the YAML manifest correctly and are in the correct context.
- **Certificate Not Issued**: If a CSR is `Approved` but not `Issued`, check the logs of the `kube-controller-manager` pod, as it is responsible for signing certificates.
