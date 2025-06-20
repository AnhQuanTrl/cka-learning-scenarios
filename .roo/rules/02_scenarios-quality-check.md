# CKA Scenario Quality Standards

This document outlines the "golden standard" for creating high-quality Certified Kubernetes Administrator (CKA) practice scenarios. All new scenarios must adhere to these guidelines to ensure they are clear, accurate, and effective for exam preparation. The reference for this standard is [`Configuration/ConfigMaps/01-configmap-creation-methods.md`](Configuration/ConfigMaps/01-configmap-creation-methods.md:1).

## Core Principles

1.  **Clarity and Precision**: Every instruction must be unambiguous. Avoid vague descriptions. Use exact names, values, and configurations.
2.  **Self-Contained Tasks**: Each task must provide all the information required to complete it. The user should not have to hunt for information in other sections or files.
3.  **Linear Flow**: The scenario must progress logically. Content, files, or resources required for a task must be defined before or within that task, never after.
4.  **Verifiability**: Every task must have a corresponding, precise verification command that proves it was completed correctly.

## Scenario Structure

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

By following this structure, we ensure every CKA learning scenario is a valuable, high-quality asset for exam preparation.