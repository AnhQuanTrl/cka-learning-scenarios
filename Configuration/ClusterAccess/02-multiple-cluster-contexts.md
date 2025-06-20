# Managing Multiple Cluster Contexts

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s and minikube

## Objective
Learn to manage access to multiple Kubernetes clusters by creating, switching, renaming, and deleting contexts within a single Kubeconfig file.

## Context
As a DevOps engineer, you manage several Kubernetes clusters, including a local `k3s-dev` cluster and a `minikube` cluster for testing. To work efficiently, you need to configure your Kubeconfig file to switch between these environments seamlessly and safely, ensuring you always run commands against the correct cluster.

## Prerequisites
- A running k3s cluster.
- A running minikube cluster (`minikube start`).
- `kubectl` installed and configured. Your Kubeconfig should be located at `~/.kube/config` and contain contexts for both clusters.

## Tasks

### Task 1: Clean Up and Rename Existing Contexts
*Suggested Time: 10 minutes*

Your default Kubeconfig file contains contexts for both k3s and minikube, but the names are not standardized. Let's rename them for clarity.

1.  **Backup your existing Kubeconfig file**:
    ```bash
    cp ~/.kube/config ~/.kube/config.backup
    ```

2.  **Identify your current contexts, users, and clusters**.
    ```bash
    kubectl config get-contexts
    kubectl config get-users
    kubectl config get-clusters
    ```
    You should see entries for both `k3s` (often named `default`) and `minikube`.

3.  **Rename the k3s context** to `dev-admin@k3s-dev`.
    - **Hint**: The default k3s context is often named `default`.
    ```bash
    # Replace 'default' with your actual k3s context name if different
    kubectl config rename-context default dev-admin@k3s-dev
    ```

4.  **Rename the minikube context** to `test-admin@minikube`.
    ```bash
    kubectl config rename-context minikube test-admin@minikube
    ```

5.  **Standardize the cluster and user names** for better readability.
    ```bash
    # Rename k3s cluster and user
    kubectl config set-cluster k3s-dev --name=k3s-dev
    kubectl config set-user k3s-admin --name=k3s-admin
    kubectl config set-context dev-admin@k3s-dev --cluster=k3s-dev --user=k3s-admin

    # Rename minikube user
    kubectl config set-user minikube-user --name=minikube-user
    kubectl config set-context test-admin@minikube --cluster=minikube --user=minikube-user
    ```

### Task 2: Switch Between Cluster Contexts
*Suggested Time: 5 minutes*

With the contexts properly named, practice switching between your `k3s` and `minikube` clusters.

1.  **View the standardized contexts**.
    ```bash
    kubectl config get-contexts
    ```
    You should see `dev-admin@k3s-dev` and `test-admin@minikube`.

2.  **Switch to the `test-admin@minikube` context**.
    ```bash
    kubectl config use-context test-admin@minikube
    ```

3.  **Verify you are on the minikube cluster**.
    ```bash
    kubectl get nodes
    ```
    The output should show the `minikube` node.

4.  **Switch back to the `dev-admin@k3s-dev` context**.
    ```bash
    kubectl config use-context dev-admin@k3s-dev
    ```

5.  **Verify you are on the k3s cluster**.
    ```bash
    kubectl get nodes
    ```
    The output should show your k3s node(s).

### Task 3: Associate a Default Namespace with a Context
*Suggested Time: 5 minutes*

To avoid errors and improve efficiency, set a default namespace for your development work on the k3s cluster.

1.  **Ensure you are in the `dev-admin@k3s-dev` context**.
    ```bash
    kubectl config current-context
    ```

2.  **Create a new namespace** called `dev-apps`.
    ```bash
    kubectl create namespace dev-apps
    ```

3.  **Modify the `dev-admin@k3s-dev` context** to default to the `dev-apps` namespace.
    ```bash
    kubectl config set-context --current --namespace=dev-apps
    ```

4.  **Verify the change**. Create a resource without specifying a namespace.
    ```bash
    kubectl run nginx --image=nginx
    ```
    The pod should be created in the `dev-apps` namespace automatically.

### Task 4: Clean Up a Context
*Suggested Time: 5 minutes*

Imagine the `minikube` testing environment is no longer needed. Clean it up by removing its context, user, and cluster definitions from the Kubeconfig.

1.  **Unset the `test-admin@minikube` context**.
    ```bash
    kubectl config unset contexts.test-admin@minikube
    ```
    **Note**: The command is `unset contexts.<name>`, not `delete-context`.

2.  **Delete the `minikube-user` and `minikube` cluster**.
    ```bash
    kubectl config delete-user minikube-user
    kubectl config delete-cluster minikube
    ```

3.  **Verify the cleanup**.
    ```bash
    kubectl config view
    ```
    The `minikube` entries should be gone.

## Verification Commands

### Task 1: Rename Contexts
- **Check renamed contexts**:
  ```bash
  kubectl config get-contexts
  ```
  - **Expected Output**: The list should include `dev-admin@k3s-dev` and `test-admin@minikube`.

### Task 2: Switch Contexts
- **Check current context after switching**:
  ```bash
  kubectl config current-context
  ```
  - **Expected Output**: `test-admin@minikube` after the first switch, and `dev-admin@k3s-dev` after switching back.

### Task 3: Associate a Namespace
- **Verify the context's namespace**:
  ```bash
  kubectl config view -o jsonpath='{.contexts[?(@.name=="dev-admin@k3s-dev")].context.namespace}'
  ```
  - **Expected Output**: `dev-apps`
- **Check for the Nginx pod**:
  ```bash
  kubectl get pod nginx -n dev-apps
  ```
  - **Expected Output**: The pod `nginx` should be listed with a `Running` status.

### Task 4: Clean Up
- **Verify Kubeconfig after cleanup**:
  ```bash
  kubectl config get-contexts
  ```
  - **Expected Output**: Only the `dev-admin@k3s-dev` context should remain.

## Expected Results
- Your Kubeconfig file is organized with clear, descriptive names for contexts, users, and clusters.
- You can confidently switch between different Kubernetes environments.
- The `dev-admin@k3s-dev` context is configured to default to the `dev-apps` namespace for streamlined workflow.
- You can cleanly remove cluster configurations that are no longer needed.

## Key Learning Points
- **`kubectl config rename-context`**: The easiest way to rename a context without manually editing the Kubeconfig file.
- **`kubectl config set-context --current`**: A powerful flag to modify the currently active context, useful for setting a default namespace.
- **`kubectl config unset`**: The correct command for removing a context or other top-level sections from the Kubeconfig.
- **Kubeconfig Hygiene**: Maintaining a clean and well-organized Kubeconfig is essential for preventing costly mistakes, like running a command in production that was intended for development.

## Exam & Troubleshooting Tips
- **Exam Tip**: The CKA exam will provide you with the Kubeconfig files you need, but you must be fast at switching between them. `kubectl config use-context` is a command you must know by heart.
- **Troubleshooting**: If `kubectl` commands are failing or giving strange results, your first two checks should always be `kubectl config current-context` and `kubectl config view` to confirm you are targeting the right cluster, user, and namespace.
- **Restoring Backup**: To revert all changes made in this scenario, run:
  ```bash
  mv ~/.kube/config.backup ~/.kube/config
  ```
