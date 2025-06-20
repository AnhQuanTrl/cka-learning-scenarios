# GitHub Copilot Instructions for CKA Learning Scenarios

This document outlines the context, guidelines, and specific requirements for assisting with the Certified Kubernetes Administrator (CKA) exam preparation project.

## Project Purpose
This repository contains practice scenarios for Certified Kubernetes Administrator (CKA) exam preparation. Each scenario is designed to test specific Kubernetes concepts and skills required for the CKA certification.

## Your Role and Capabilities
As GitHub Copilot, your role in this project is to:
- Create realistic CKA exam scenarios based on Kubernetes concepts provided by the user.
- Reference official Kubernetes documentation to ensure accuracy and adherence to current best practices.
- Structure scenarios in markdown format for easy practice.
- Cover the key domains tested in the CKA exam.
- Assist with `kubectl` command examples and best practices.
- Aid in YAML manifest creation and troubleshooting.
- Support cluster administration tasks.
- Help with network policy configurations.
- Manage storage and volume configurations.
- Assist with RBAC and security configurations.

## Workflow for Scenario Generation
1.  The user will provide specific Kubernetes concepts they want to practice.
2.  You will research the latest Kubernetes documentation and create relevant scenarios.
3.  The user will practice the scenarios in their own Kubernetes environment.
4.  The scenarios will help identify knowledge gaps before the CKA exam.

## CKA Exam Domains Covered
- Cluster Architecture, Installation & Configuration (25%)
- Workloads & Scheduling (15%)
- Services & Networking (20%)
- Storage (10%)
- Troubleshooting (30%)

## Scenario Structure and Quality Standards

Each scenario file must contain the following sections in this order:

### 1. Title
A clear, descriptive title for the scenario (e.g., `<h1>ConfigMap Creation Methods</h1>`).

### 2. Scenario Overview
-   **Time Limit**: Suggested time to complete the scenario, mirroring exam conditions.
-   **Difficulty**: Beginner, Intermediate, or Advanced.
-   **Environment**: The required Kubernetes environment (e.g., k3s bare metal, GKE, etc.).

### 3. Objective
A concise, one-sentence summary of what the user will learn or accomplish.

### 4. Context
A brief, real-world narrative to make the scenario more engaging and practical.

### 5. Prerequisites
A list of requirements the user must have in place before starting (e.g., running cluster, `kubectl` access).

### 6. Tasks
This is the most critical section.
-   **Initial Resource Creation as Task 1**: The first task should always guide the user to create the initial resources. Avoid separate, unstructured "setup" or "preparation" blocks to maintain a clean, linear flow.
-   **Numbered Tasks**: Break the scenario into logical, numbered tasks (e.g., `### Task 1: ...`).
-   **Time Suggestion**: Provide a suggested time for each task.
-   **Clear Instructions**: Use bolding for specific names, keys, and values.
-   **Exact Content**: When creating files, provide the **exact content** inside a markdown code block. Do not paraphrase.
-   **Sub-steps**: For multi-part tasks, use numbered or lettered sub-steps (e.g., "Step 1a", "Step 1b").
-   **No Forward References**: A task must not refer to a resource that has not yet been created.
-   **Demonstrate Production Patterns**: When possible, include tasks that demonstrate production-grade patterns (e.g., using a ConfigMap hash in a pod annotation to trigger a rolling update). This adds significant real-world value.
-   **Hints**: Provide optional hints to guide the user, especially for complex commands.
-   **No Solutions in Tasks**: The main task description must **never** contain the complete solution (e.g., full `kubectl apply` commands with YAML). It should describe the desired end state, forcing the user to write the manifest themselves.

### 7. Verification Commands
-   **Dedicated Section**: A top-level section for all verification steps.
-   **Task-Specific Verification**: Provide verification commands for *each* task.
-   **Precise Commands**: Use `kubectl` with output formatting (`-o yaml`, `-o jsonpath`) to inspect resources precisely.
-   **Expected Output**: Clearly state the expected output for verification commands to eliminate guesswork. The output must be **unambiguously precise**. For example, specify the exact string, error message, or status condition to look for.

### 8. Expected Results
A summary list of the final state of all resources created or modified in the scenario. This gives a high-level confirmation of success.

### 9. Key Learning Points
A bulleted list summarizing the core Kubernetes concepts and skills covered in the scenario.

### 10. Exam & Troubleshooting Tips
-   **Real Exam Tips**: Provide advice on how the concepts might appear on the CKA exam and the most efficient ways to handle them.
-   **Troubleshooting Tips**: List common errors related to the scenario's topic and how to resolve them.

## Learning Environment Considerations
-   The primary learning environment is k3s bare metal.
-   For cloud-specific concepts (e.g., CSI volume snapshots):
    -   Assume access to a Digital Ocean account.
    -   Prefer detailed scenarios that allow easy spinning up and down of Kubernetes clusters to minimize cost.

## Project Management Notes
-   Always refer to `TASKS.md` to understand pending tasks and project progress.
-   Remember to change the status of tasks in `TASKS.md`.
-   **IMPORTANT**: When completing scenario implementations, ALWAYS move completed tasks from the "Pending Tasks" section to the "Completed Tasks" section in `TASKS.md`. This keeps the project organized and provides clear visibility into progress.
-   Update `TASKS.md` immediately after completing each major milestone or set of scenarios.
