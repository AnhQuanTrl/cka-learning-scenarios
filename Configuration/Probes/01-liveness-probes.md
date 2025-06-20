# Liveness Probes: Ensuring Application Health

## Scenario Overview
-   **Time Limit**: 20 minutes
-   **Difficulty**: Intermediate
-   **Environment**: k3s bare metal

## Objective
This scenario teaches you how to configure HTTP, TCP, and exec liveness probes to automatically detect and restart unhealthy containers, ensuring application reliability.

## Context
You are a platform engineer responsible for a critical web service. Recently, users have reported that the service sometimes becomes unresponsive, even though the pod is still in a `Running` state. Your task is to implement liveness probes to automatically detect these deadlocks and restart the containers to restore service.

## Prerequisites
-   A running Kubernetes cluster (k3s is recommended).
-   `kubectl` installed and configured to connect to your cluster.

## Tasks

### Task 1: Deploy an Application Without a Liveness Probe (5 mins)
First, let's see the problem firsthand. You will deploy a simple Nginx web server that has a custom script. This script will allow us to simulate an application failure.

1.  Create a pod manifest file named `unhealthy-pod.yaml`.
2.  The pod should be named **unhealthy-app** and use the **nginx:1.21.6** image.
3.  The container needs a command that starts the Nginx web server, but then terminates the Nginx process after 30 seconds to simulate a crash. Use the following command:
    ```bash
    ["/bin/sh", "-c", "nginx -g 'daemon off;' & pid=$!; sleep 30; kill $pid; sleep 600"]
    ```
4.  Apply the manifest to create the pod.

### Task 2: Implement an HTTP Liveness Probe (5 mins)
Now, you will add an HTTP liveness probe to the pod. This is the most common type of probe and is perfect for web servers.

1.  Modify the `unhealthy-pod.yaml` manifest.
2.  Add an `httpGet` liveness probe to the container definition.
    -   It should check the default Nginx welcome page on path **/** at port **80**.
    -   Set `initialDelaySeconds` to **5** to give the container time to start.
    -   Set `periodSeconds` to **5** to check every 5 seconds.
    -   Set `failureThreshold` to **1** so it restarts after one failed check.
3.  Apply the updated manifest. After about 30-40 seconds, observe the pod's behavior.

### Task 3: Implement a TCP Liveness Probe (5 mins)
TCP probes are useful for non-HTTP services where you only need to check if a port is accepting connections.

1.  Create a new pod manifest named `tcp-liveness-pod.yaml`.
2.  The pod should be named **tcp-app** and use the **busybox:1.34** image.
3.  The container should run a command that listens on a port for a short time and then stops. Use the following command to listen on port **8080** for 30 seconds:
    ```bash
    ["/bin/sh", "-c", "nc -l -p 8080 -e /bin/true; sleep 30; exit 1"]
    ```
4.  Add a `tcpSocket` liveness probe that checks port **8080**.
    -   Set `initialDelaySeconds` to **5**.
    -   Set `periodSeconds` to **10**.
5.  Create the pod and observe its restarts.

### Task 4: Implement an Exec Liveness Probe (5 mins)
Exec probes are the most flexible. They run a command inside the container, and if the command returns a status code of 0, the container is considered healthy.

1.  Create a pod manifest named `exec-liveness-pod.yaml`.
2.  The pod should be named **exec-app** and use the **busybox:1.34** image.
3.  The container's command should create a file named `/tmp/healthy` and then remove it after 30 seconds to simulate a failure.
    ```bash
    ["/bin/sh", "-c", "touch /tmp/healthy; sleep 30; rm /tmp/healthy; sleep 600"]
    ```
4.  Add an `exec` liveness probe that checks for the existence of the `/tmp/healthy` file using the command `cat /tmp/healthy`.
    -   Set `initialDelaySeconds` to **5**.
    -   Set `periodSeconds` to **5**.
5.  Create the pod and watch for the restart.

## Verification Commands

### Task 1 Verification
-   Check that the pod is running:
    ```bash
    kubectl get pod unhealthy-app
    ```
    **Expected Output**: The pod should be in the `Running` state with `0` restarts.
-   After 35 seconds, exec into the pod and check the running processes:
    ```bash
    kubectl exec unhealthy-app -- ps aux
    ```
    **Expected Output**: You should **not** see any `nginx` processes running. Despite the application being dead, the pod remains in the `Running` state because Kubernetes has no probe to tell it otherwise.

### Task 2 Verification
-   Watch the pod's status change in real-time:
    ```bash
    kubectl get pod unhealthy-app -w
    ```
    **Expected Output**: After about 35-40 seconds, you will see the pod's status change from `Running` to `Terminating` and then back to `Running`. The `RESTARTS` count will increment to `1`.
-   Describe the pod to see the events:
    ```bash
    kubectl describe pod unhealthy-app
    ```
    **Expected Output**: In the `Events` section, you will see `Warning Unhealthy` messages indicating that the liveness probe failed, followed by an event showing the container is being killed and recreated.

### Task 3 Verification
-   Check the pod's restarts:
    ```bash
    kubectl get pod tcp-app
    ```
    **Expected Output**: After about 40 seconds, the `RESTARTS` count should be `1` or higher.
-   Describe the pod to see the probe failures:
    ```bash
    kubectl describe pod tcp-app
    ```
    **Expected Output**: The `Events` section will show `Warning Unhealthy` events from the TCP probe failing.

### Task 4 Verification
-   Check the pod's restarts:
    ```bash
    kubectl get pod exec-app
    ```
    **Expected Output**: After about 40 seconds, the `RESTARTS` count should be `1` or higher.
-   Describe the pod to see the events:
    ```bash
    kubectl describe pod exec-app
    ```
    **Expected Output**: The `Events` section will show `Warning Unhealthy` events from the exec probe failing because the `cat` command returned a non-zero exit code.

## Expected Results
-   A pod named **unhealthy-app** that is periodically restarting due to a failed HTTP liveness probe.
-   A pod named **tcp-app** that is periodically restarting due to a failed TCP liveness probe.
-   A pod named **exec-app** that is periodically restarting due to a failed exec liveness probe.

## Key Learning Points
-   **Liveness Probes**: Automatically detect when an application is unresponsive and restart the container.
-   **Probe Types**:
    -   `httpGet`: Best for web services. Checks for a 2xx or 3xx HTTP response code.
    -   `tcpSocket`: Best for non-HTTP services. Checks if a TCP port is open.
    -   `exec`: Most flexible. Runs a custom command and checks for a `0` exit code.
-   **Probe Configuration**:
    -   `initialDelaySeconds`: Grace period for the application to start before the first probe.
    -   `periodSeconds`: How often the probe is executed.
    -   `failureThreshold`: How many consecutive failures are needed to consider the container unhealthy.

## Exam & Troubleshooting Tips
-   **Exam Tip**: `kubectl describe pod` is your best friend for debugging probe issues. The `Events` section tells you exactly why and when a probe is failing.
-   **Troubleshooting Tip**: A common mistake is setting `initialDelaySeconds` too low for an application that takes a while to start. This can cause a `CrashLoopBackOff` because the probe fails before the app is ready, causing a restart, and the cycle repeats. Always give your app enough time to initialize.
