# RBAC Fundamentals

## Scenario Overview
- **Time Limit**: 25 minutes
- **Difficulty**: Intermediate
- **Environment**: k3s bare metal

## Objective
Learn the fundamentals of Role-Based Access Control (RBAC) by creating namespaced and cluster-wide roles and binding them to different subjects (Service Accounts and Users).

## Context
As a cluster administrator, you need to enforce the principle of least privilege. You have two main requirements:
1.  An application, running as a Service Account in the `app-namespace`, needs to be able to list secrets within that same namespace to read its configuration.
2.  A junior administrator, `junior-admin`, needs read-only access to view nodes across the entire cluster for monitoring purposes.

This scenario requires you to create both a namespaced `Role` and a cluster-wide `ClusterRole` and bind them correctly.

## Prerequisites
- A running Kubernetes cluster (k3s is recommended).
- `kubectl` installed and configured with administrative access.
- A user certificate for `junior-admin` (or you can simulate this user).

## Tasks

### Task 1: Set Up the Application Namespace and Service Account
*Suggested Time: 5 minutes*

1.  **Create a namespace** for the application.
    ```bash
    kubectl create namespace app-namespace
    ```

2.  **Create a Service Account** for the application.
    ```bash
    kubectl create serviceaccount app-sa -n app-namespace
    ```

### Task 2: Create a Namespaced Role for the Application
*Suggested Time: 5 minutes*

The application only needs to read secrets in its own namespace. Create a `Role` with these minimal permissions.

1.  **Create a YAML file** named `secret-reader-role.yaml`.
    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: secret-reader
      namespace: app-namespace
    rules:
    - apiGroups: [""]
      resources: ["secrets"]
      verbs: ["get", "list"]
    ```

2.  **Apply the manifest**.
    ```bash
    kubectl apply -f secret-reader-role.yaml
    ```

3.  **Bind the `Role` to the `ServiceAccount`** using a `RoleBinding`.
    ```bash
    kubectl create rolebinding app-sa-secret-reader-binding --role=secret-reader --serviceaccount=app-namespace:app-sa -n app-namespace
    ```

### Task 3: Create a Cluster-Wide Role for the Junior Admin
*Suggested Time: 5 minutes*

The junior admin needs to view nodes cluster-wide. This requires a `ClusterRole`.

1.  **Create a `ClusterRole`** named `node-reader` that grants read-only access to `nodes`.
    - Create a file named `node-reader-clusterrole.yaml`:
      ```yaml
      apiVersion: rbac.authorization.k8s.io/v1
      kind: ClusterRole
      metadata:
        name: node-reader
      rules:
      - apiGroups: [""]
        resources: ["nodes"]
        verbs: ["get", "list", "watch"]
      ```
    - Apply the manifest:
      ```bash
      kubectl apply -f node-reader-clusterrole.yaml
      ```

2.  **Bind the `ClusterRole` to the user `junior-admin`** using a `ClusterRoleBinding`.
    ```bash
    kubectl create clusterrolebinding junior-admin-node-reader-binding --clusterrole=node-reader --user=junior-admin
    ```

### Task 4: Verify Permissions
*Suggested Time: 10 minutes*

Use `kubectl auth can-i` to test the permissions for both the Service Account and the user. This command is a powerful tool for debugging RBAC without needing to generate Kubeconfig files.

1.  **Test the Service Account's permissions**.
    - Can it list secrets in `app-namespace`? (Should be **yes**)
      ```bash
      kubectl auth can-i list secrets --as=system:serviceaccount:app-namespace:app-sa -n app-namespace
      ```
    - Can it list pods in `app-namespace`? (Should be **no**)
      ```bash
      kubectl auth can-i list pods --as=system:serviceaccount:app-namespace:app-sa -n app-namespace
      ```
    - Can it list secrets in the `default` namespace? (Should be **no**)
      ```bash
      kubectl auth can-i list secrets --as=system:serviceaccount:app-namespace:app-sa -n default
      ```

2.  **Test the junior admin's permissions**.
    - Can `junior-admin` list nodes? (Should be **yes**)
      ```bash
      kubectl auth can-i list nodes --as=junior-admin
      ```
    - Can `junior-admin` list pods in `app-namespace`? (Should be **no**)
      ```bash
      kubectl auth can-i list pods --as=junior-admin -n app-namespace
      ```
    - Can `junior-admin` delete nodes? (Should be **no**)
      ```bash
      kubectl auth can-i delete nodes --as=junior-admin
      ```

## Verification Commands

### Task 2: Namespaced Role
- **Describe the RoleBinding**:
  ```bash
  kubectl describe rolebinding app-sa-secret-reader-binding -n app-namespace
  ```
  - **Expected Output**: Shows `app-sa` ServiceAccount bound to the `secret-reader` Role.

### Task 3: Cluster-Wide Role
- **Describe the ClusterRoleBinding**:
  ```bash
  kubectl describe clusterrolebinding junior-admin-node-reader-binding
  ```
  - **Expected Output**: Shows `junior-admin` user bound to the `node-reader` ClusterRole.

### Task 4: Permissions Check
- **Service Account (Success)**:
  ```bash
  kubectl auth can-i list secrets --as=system:serviceaccount:app-namespace:app-sa -n app-namespace
  ```
  - **Expected Output**: `yes`
- **Service Account (Failure)**:
  ```bash
  kubectl auth can-i list pods --as=system:serviceaccount:app-namespace:app-sa -n app-namespace
  ```
  - **Expected Output**: `no`
- **Junior Admin (Success)**:
  ```bash
  kubectl auth can-i list nodes --as=junior-admin
  ```
  - **Expected Output**: `yes`
- **Junior Admin (Failure)**:
  ```bash
  kubectl auth can-i delete nodes --as=junior-admin
  ```
  - **Expected Output**: `no`

## Expected Results
- A `Role` named `secret-reader` and a `RoleBinding` exist in `app-namespace`, granting the `app-sa` Service Account permission to read secrets only within that namespace.
- A `ClusterRole` named `node-reader` and a `ClusterRoleBinding` exist globally, granting the user `junior-admin` permission to view nodes across the entire cluster.
- All permission checks using `kubectl auth can-i` produce the expected `yes` or `no` answers.

## Key Learning Points
- **Role vs. ClusterRole**: A `Role` is always namespaced, granting permissions to resources *within* that namespace. A `ClusterRole` is a non-namespaced resource that can grant access to cluster-wide resources (like `nodes`) or to namespaced resources across all namespaces.
- **RoleBinding vs. ClusterRoleBinding**: A `RoleBinding` grants the permissions in a `Role` to a subject. A `ClusterRoleBinding` grants the permissions in a `ClusterRole` to a subject. You can also use a `RoleBinding` to grant a `ClusterRole`'s permissions within a single namespace, which is a common pattern.
- **Subjects**: The `subjects` section of a binding can include a `ServiceAccount`, a `User`, or a `Group`. Remember the specific prefixes required, especially `system:serviceaccount:` for Service Accounts.
- **`kubectl auth can-i`**: This is your best friend for debugging RBAC. It directly queries the API server's authorization layer to tell you if a specific action is allowed, saving you from guesswork.

## Exam & Troubleshooting Tips
- **Exam Tip**: Be fast with imperative commands like `kubectl create role`, `kubectl create clusterrole`, `kubectl create rolebinding`, and `kubectl create clusterrolebinding`. They are much faster than writing YAML.
- **Troubleshooting**: When a user or service account is forbidden from an action, the first step is to use `kubectl auth can-i` to confirm the expected permissions. If the result is `no`, check the bindings (`describe rolebinding/clusterrolebinding`) and the roles (`describe role/clusterrole`) step-by-step.
- **Common Mistake**: Trying to bind a `Role` with a `ClusterRoleBinding`. A `ClusterRoleBinding` can only be used with a `ClusterRole`.
- **Another Common Mistake**: Forgetting the namespace. `Roles` and `RoleBindings` are namespaced resources. If you forget `-n <namespace>`, they will be created in the `default` namespace, which is usually not what you want.
