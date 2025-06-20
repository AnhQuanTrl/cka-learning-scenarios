# Docker Registry Secrets and Private Image Pulls

## Scenario Overview
**Time Limit**: 20 minutes
**Difficulty**: Intermediate
**Environment**: k3s bare metal with access to a private Docker registry

## Objective
Master the creation and application of `docker-registry` Secrets to enable Kubernetes to securely pull container images from your private registry, applying credentials to individual Pods and automating access with ServiceAccounts.

## Context
Your development team needs to deploy a new microservice that relies on a proprietary base image stored in your organization's private container registry. Your task is to configure the Kubernetes cluster with the necessary authentication credentials to allow seamless and secure image pulls.

## Prerequisites
- A running k3s cluster
- `kubectl` configured with administrative access
- Access to a private Docker registry with a pushed container image
- The following details for your private registry:
    - **Your Registry URL**: e.g., `your-registry.example.com`
    - **Your Username**
    - **Your Password**
    - **Your Email**
    - **A Private Image Path**: e.g., `your-registry.example.com/your-app:1.0`

## Tasks

### Task 1: Create a `docker-registry` Secret Imperatively (5 minutes)
Create a Secret using an imperative `kubectl` command. This method is fast and useful for direct, on-the-fly operations.

**Instructions**:
- Replace the placeholder values with your actual registry credentials.
- **Secret Name**: `my-private-reg-cred`
- **Secret Type**: `docker-registry`

```bash
# Replace placeholders and run this command
kubectl create secret docker-registry my-private-reg-cred \
  --docker-server="<YOUR_REGISTRY_URL>" \
  --docker-username="<YOUR_USERNAME>" \
  --docker-password="<YOUR_PASSWORD>" \
  --docker-email="<YOUR_EMAIL>"
```

### Task 2: Create a Pod Referencing the Secret via `imagePullSecrets` (5 minutes)
Demonstrate how a Pod uses the `imagePullSecrets` field to authenticate with your private registry and pull an image.

**Step 2a**: Create a Pod manifest named `pod-with-secret.yaml`.
- Replace `<YOUR_PRIVATE_IMAGE_PATH>` with the full path to an image in your private registry.
- **Pod Name**: `private-app-pod`
- **Container Name**: `main-app`
- **`imagePullSecrets`**: Reference the `my-private-reg-cred` secret created in Task 1.

```yaml
# pod-with-secret.yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-app-pod
spec:
  containers:
  - name: main-app
    image: <YOUR_PRIVATE_IMAGE_PATH>
  imagePullSecrets:
  - name: my-private-reg-cred
```

**Step 2b**: Apply the manifest.

### Task 3: Create a `docker-registry` Secret Declaratively (5 minutes)
Create a Secret using a YAML manifest. This is the recommended approach for version-controlled, GitOps-driven environments as it allows you to store your secret configuration as code.

**Step 3a**: Create a local Docker `config.json` file.
- First, log in to your private registry using the Docker CLI on your local machine:
  ```bash
  docker login <YOUR_REGISTRY_URL>
  ```
- This command will create or update a `config.json` file in your `~/.docker/` directory with the necessary auth token.

**Step 3b**: Create the declarative Secret manifest.
- **Secret Name**: `my-private-reg-cred-declarative`
- **Secret Type**: `kubernetes.io/dockerconfigjson`
- **Data Key**: `.dockerconfigjson`
- **Data Value**: The base64-encoded content of your `~/.docker/config.json` file.

**Instructions**:
1.  Copy the `~/.docker/config.json` file to your current working directory.
2.  Base64-encode its content. The output must be a single, unbroken line.
    ```bash
    cat config.json | base64
    ```
3.  Create a manifest named `secret-declarative.yaml` and paste the encoded string into the `.data[".dockerconfigjson"]` field.

```yaml
# secret-declarative.yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-private-reg-cred-declarative
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <YOUR_BASE64_ENCODED_CONFIG_JSON>
```

**Step 3c**: Apply the manifest.

### Task 4: Automate Secret Usage with a ServiceAccount (5 minutes)
Configure a ServiceAccount to automatically provide `imagePullSecrets` to any Pod that uses it. This is a more scalable and secure pattern.

**Step 4a**: Create a new ServiceAccount.
- **ServiceAccount Name**: `app-service-account`
  ```bash
  kubectl create sa app-service-account
  ```

**Step 4b**: Patch the ServiceAccount to include the declarative secret.
  ```bash
  kubectl patch sa app-service-account -p '{"imagePullSecrets": [{"name": "my-private-reg-cred-declarative"}]}'
  ```

**Step 4c**: Create a new Pod that uses the ServiceAccount.
- Replace `<YOUR_PRIVATE_IMAGE_PATH>` with your image path.
- **Pod Name**: `automated-app-pod`
- **`serviceAccountName`**: `app-service-account`
- **Note**: Do *not* specify `imagePullSecrets` directly in this Pod's manifest.

```yaml
# pod-with-sa.yaml
apiVersion: v1
kind: Pod
metadata:
  name: automated-app-pod
spec:
  serviceAccountName: app-service-account
  containers:
  - name: main-app
    image: <YOUR_PRIVATE_IMAGE_PATH>
```
**Step 4d**: Apply the manifest.

## Verification Commands

### Verify Task 1 & 2: Imperative Secret and Pod
```bash
# Check that the secret was created
kubectl get secret my-private-reg-cred

# Verify the Pod successfully pulled the image and is running
kubectl get pod private-app-pod
# Expected STATUS: Running
```

### Verify Task 3: Declarative Secret
```bash
# Check the declarative secret's data
kubectl get secret my-private-reg-cred-declarative -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode
# Expected: The output should be the JSON content from your config.json file.
```

### Verify Task 4: ServiceAccount and Automated Pod
```bash
# Verify the secret is attached to the ServiceAccount
kubectl get sa app-service-account -o yaml
# Expected: The imagePullSecrets section should contain 'my-private-reg-cred-declarative'.

# Verify the new pod successfully pulled the image and is running
kubectl get pod automated-app-pod
# Expected STATUS: Running
```

## Key Learning Points
- **Secret Type**: The correct type for registry credentials is `kubernetes.io/dockerconfigjson`.
- **Imperative vs. Declarative**: `kubectl create secret` is fast for temporary needs, while YAML manifests are essential for production-grade, version-controlled infrastructure.
- **Pod-Level Specificity**: `spec.imagePullSecrets` in a Pod manifest grants access only to that specific Pod.
- **ServiceAccount Automation**: Attaching `imagePullSecrets` to a ServiceAccount grants access to all Pods using it, simplifying management and improving security posture.

## Exam & Troubleshooting Tips
- **Efficiency**: For the CKA exam, `kubectl create secret docker-registry` is the fastest way to create the secret.
- **Troubleshooting `ImagePullBackOff`**: If you see this error, use `kubectl describe pod <pod-name>` to check events. Common causes include missing or incorrect `imagePullSecrets`, invalid credentials, or the secret being in a different namespace from the Pod.
- **Base64 Encoding**: Remember that for declarative secrets, the `.dockerconfigjson` value must be a base64-encoded string of the *entire* JSON configuration file.