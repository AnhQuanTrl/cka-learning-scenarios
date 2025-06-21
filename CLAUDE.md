# CKA Learning Scenarios Project

## Project Purpose
This repository contains practice scenarios for Certified Kubernetes Administrator (CKA) exam preparation. Each scenario is designed to test specific Kubernetes concepts and skills required for the CKA certification.

## Claude's Role
Claude assists in this project by:
- Creating realistic CKA exam scenarios based on Kubernetes concepts you provide
- Referencing official Kubernetes documentation to ensure accuracy
- Structuring scenarios in markdown format for easy practice
- Covering the key domains tested in the CKA exam

## How to Use This Repository
1. Provide Claude with specific Kubernetes concepts you want to practice
2. Claude will research the latest K8s documentation and create relevant scenarios
3. Practice the scenarios in your own Kubernetes environment
4. Use the scenarios to identify knowledge gaps before your CKA exam

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

## Additional Quality Standards
- **Clear Task Instructions**: Every task specifies exact names, values, and configurations
- **Practical Applications**: Include workloads (Deployments, StatefulSets) that consume resources, not just resource creation
- **Comprehensive Verification**: Provide specific commands to verify each task is completed correctly
- **Real-world Context**: Scenarios reflect actual CKA exam patterns and requirements

### Critical Structure Requirements
- **No Forward References**: Never reference files, ConfigMaps, or content that hasn't been defined yet in the task descriptions
- **Self-Contained Tasks**: Each task must include ALL information needed to complete it - no hunting through other sections
- **Exact Content Specification**: When tasks require creating files, provide the exact file content within that task, not in verification commands
- **Linear Flow**: Everything needed for a task must appear before or in that task, never after
- **No Vague Content**: Instead of "with application settings" or "configuration files", specify exactly what content goes in each file
- **Step-by-Step Clarity**: Break complex tasks into numbered sub-steps with exact content and commands

## Commands Claude Can Help With
- `kubectl` command examples and best practices
- YAML manifest creation and troubleshooting
- Cluster administration tasks
- Network policy configurations
- Storage and volume management
- RBAC and security configurations

## Getting Started
Tell Claude which Kubernetes concepts you want to practice, and scenarios will be generated based on the official Kubernetes documentation to ensure they reflect current best practices and exam requirements.

## Learning Environment Considerations
- My primary learning environment is k3s bare metal
- For cloud-specific concepts (e.g., CSI volume snapshots):
  - Have access to a Digital Ocean account
  - Prefer detailed scenarios that allow easy spinning up and down of Kubernetes clusters to minimize cost

## CKA Exam Preparation Notes
- Please avoid deprecated features as it will not appear in the exam

## Project Management Notes
- Remember to take a look at TASKS.md to get a good grasp of what needs to be done and the progress of the project.
- Remember to change the status of task in TASKS.md.
- **IMPORTANT**: When completing scenario implementations, ALWAYS move completed tasks from the "Pending Tasks" section to the "Completed Tasks" section in TASKS.md. This keeps the project organized and provides clear visibility into progress.
- Update TASKS.md immediately after completing each major milestone or set of scenarios.
