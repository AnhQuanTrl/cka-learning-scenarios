# Service Account Authentication

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Learn how to create and use a Service Account for external application authentication by manually generating a token and constructing a Kubeconfig file.

## Context
You are a Kubernetes administrator for a company that runs a critical application in the `app-prod` namespace. The monitoring team needs to deploy an external script that can list pods and view logs within that namespace to check application health. To follow the principle of least privilege, you must provide them with a Kubeconfig file that grants only the necessary read-only permissions and is tied to a specific Service Account, not a user.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended).
- `kubectl` installed and configured with administrative access.

## Tasks

### Task 1: Create the Namespace and a Service Account
*Suggested Time: 5 minutes*

First, set up the environment by creating the namespace and the Service Account for the monitoring tool.

1.  **Create a new namespace** called `app-prod`.
    ```bash
    kubectl create namespace app-prod
    ```

2.  **Create a new Service Account** named `monitoring-sa` in the `app-prod` namespace.
    ```bash
    kubectl create serviceaccount monitoring-sa -n app-prod
    ```

### Task 2: Define a Read-Only Role
*Suggested Time: 5 minutes*

Create a `Role` that grants the specific, minimal permissions required by the monitoring tool.

1.  **Create a YAML file** named `monitoring-role.yaml` with a `Role` that allows `get`, `list`, and `watch` access to `pods` and `pods/log`.
    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: pod-reader-role
      namespace: app-prod
    rules:
    - apiGroups: [""] # "" indicates the core API group
      resources: ["pods", "pods/log"]
      verbs: ["get", "list", "watch"]
    ```

2.  **Apply the manifest** to create the Role.
    ```bash
    kubectl apply -f monitoring-role.yaml
    ```

### Task 3: Bind the Role to the Service Account
*Suggested Time: 5 minutes*

Create a `RoleBinding` to connect the `monitoring-sa` Service Account to the `pod-reader-role`.

1.  **Create the RoleBinding** using an imperative `kubectl` command.
    ```bash
    kubectl create rolebinding monitoring-rb --role=pod-reader-role --serviceaccount=app-prod:monitoring-sa -n app-prod
    ```

2.  **Verify the RoleBinding** was created successfully.
    ```bash
    kubectl get rolebinding monitoring-rb -n app-prod -o yaml
    ```

### Task 4: Manually Generate a Token and Construct a Kubeconfig
*Suggested Time: 10 minutes*

This is the core task. Manually create a long-lived token for the Service Account and use it to build a new Kubeconfig file from scratch.

1.  **Create a new Secret** to hold the Service Account token.
    - Create a file named `monitoring-sa-secret.yaml` with the following content:
      ```yaml
      apiVersion: v1
      kind: Secret
      metadata:
        name: monitoring-sa-token
        namespace: app-prod
        annotations:
          kubernetes.io/service-account.name: monitoring-sa
      type: kubernetes.io/service-account-token
      ```
    - Apply the manifest:
      ```bash
      kubectl apply -f monitoring-sa-secret.yaml
      ```

2.  **Extract the token and CA certificate** from the cluster and store them in environment variables.
    ```bash
    # Extract the token
    TOKEN=$(kubectl get secret monitoring-sa-token -n app-prod -o jsonpath='{.data.token}' | base64 --decode)

    # Extract the CA certificate from your current kubeconfig
    CA_CERT_DATA=$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name=="default")].cluster.certificate-authority-data}')
    ```
    **Note**: Replace `default` with your actual cluster name if it's different.

3.  **Get the server URL**.
    ```bash
    SERVER_URL=$(kubectl config view --raw -o jsonpath='{.clusters[?(@.name=="default")].cluster.server}')
    ```

4.  **Construct the new Kubeconfig file** named `monitoring-kubeconfig.yaml`.
    ```bash
    cat <<EOF > monitoring-kubeconfig.yaml
    apiVersion: v1
    kind: Config
    clusters:
    - name: default
      cluster:
        certificate-authority-data: $CA_CERT_DATA
        server: $SERVER_URL
    contexts:
    - name: monitoring-context
      context:
        cluster: default
        namespace: app-prod
        user: monitoring-sa
    current-context: monitoring-context
    users:
    - name: monitoring-sa
      user:
        token: $TOKEN
    EOF
    ```

### Task 5: Test the New Kubeconfig
*Suggested Time: 5 minutes*

Verify that the `monitoring-kubeconfig.yaml` file works as expected and only grants the intended permissions.

1.  **Use the new Kubeconfig** to list pods in the `app-prod` namespace. This should succeed (even if it returns no pods).
    ```bash
    kubectl --kubeconfig=monitoring-kubeconfig.yaml get pods
    ```

2.  **Attempt to list pods** in the `kube-system` namespace. This command must **fail**.
    ```bash
    kubectl --kubeconfig=monitoring-kubeconfig.yaml get pods -n kube-system
    ```

3.  **Attempt to create a resource**. This command must also **fail**.
    ```bash
    kubectl --kubeconfig=monitoring-kubeconfig.yaml run nginx --image=nginx
    ```

## Verification Commands

### Task 1: Service Account Creation
- **Check for the Service Account**:
  ```bash
  kubectl get sa monitoring-sa -n app-prod
  ```
  - **Expected Output**: The `monitoring-sa` Service Account should be listed.

### Task 2: Role Creation
- **Check for the Role**:
  ```bash
  kubectl get role pod-reader-role -n app-prod
  ```
  - **Expected Output**: The `pod-reader-role` should be listed.

### Task 3: RoleBinding
- **Describe the RoleBinding**:
  ```bash
  kubectl describe rolebinding monitoring-rb -n app-prod
  ```
  - **Expected Output**: The output should show the `pod-reader-role` bound to the `monitoring-sa` Service Account.

### Task 4: Kubeconfig Construction
- **View the generated Kubeconfig**:
  ```bash
  cat monitoring-kubeconfig.yaml
  ```
  - **Expected Output**: The file should contain the cluster, context, and user sections, with the token embedded.

### Task 5: Verification
- **Successful command**:
  ```bash
  kubectl --kubeconfig=monitoring-kubeconfig.yaml get pods -n app-prod
  ```
  - **Expected Output**: `No resources found in app-prod namespace.` (or a list of pods if you have any).
- **Failed command (wrong namespace)**:
  ```bash
  kubectl --kubeconfig=monitoring-kubeconfig.yaml get pods -n kube-system
  ```
  - **Expected Output**: An error message like: `Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-prod:monitoring-sa" cannot list resource "pods" in API group "" in the namespace "kube-system"`.
- **Failed command (wrong verb)**:
  ```bash
  kubectl --kubeconfig=monitoring-kubeconfig.yaml run nginx --image=nginx
  ```
  - **Expected Output**: An error message like: `Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-prod:monitoring-sa" cannot create resource "pods" in API group "" in the namespace "app-prod"`.

## Expected Results
- A `ServiceAccount` named `monitoring-sa` exists in the `app-prod` namespace.
- A `Role` named `pod-reader-role` exists, granting read-only access to pods and logs.
- A `RoleBinding` connects the Service Account to the Role.
- A new `monitoring-kubeconfig.yaml` file is created that allows authentication as the Service Account.
- The new Kubeconfig successfully grants read-only access to the `app-prod` namespace but denies all other requests.

## Key Learning Points
- **Service Accounts for Applications**: Service Accounts are the standard, most secure way to grant in-cluster or external applications access to the Kubernetes API.
- **Principle of Least Privilege**: Always create roles with the absolute minimum permissions required. Avoid using cluster-wide roles (`ClusterRole`) when a namespaced `Role` will suffice.
- **Manual Token Generation**: While tokens are mounted automatically into pods, you often need to generate them manually for external tools. Creating a dedicated `Secret` of type `kubernetes.io/service-account-token` is the standard way to do this.
- **Kubeconfig from Scratch**: Understanding the structure of a Kubeconfig file (`clusters`, `contexts`, `users`) is a critical skill that allows you to construct access credentials for any scenario.

## Exam & Troubleshooting Tips
- **Exam Tip**: Be fast with `kubectl create serviceaccount`, `kubectl create role`, and `kubectl create rolebinding`. Imperative commands are much quicker than writing YAML from scratch.
- **Troubleshooting**: If you get a `Forbidden` error, use `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:<namespace>:<sa-name> -n <namespace>` to test permissions directly on the server, which helps isolate whether the issue is with RBAC rules or the Kubeconfig file itself.
- **Token Expiration**: Be aware that tokens can have expiration dates. For long-lived access, ensure your token generation process accounts for this. The manual secret creation method used here typically creates a non-expiring token, but this behavior can be configured by cluster administrators.
- **Common Mistake**: Forgetting the `system:serviceaccount:` prefix when specifying a Service Account in a `can-i` check or other manual validation steps.
