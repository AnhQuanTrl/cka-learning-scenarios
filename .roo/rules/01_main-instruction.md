# Roo's CKA Learning Scenarios Documentation

This document outlines the context, guidelines, and specific requirements for assisting with the Certified Kubernetes Administrator (CKA) exam preparation project.

## Project Purpose
This repository contains practice scenarios for Certified Kubernetes Administrator (CKA) exam preparation. Each scenario is designed to test specific Kubernetes concepts and skills required for the CKA certification.

## Roo's Role and Capabilities
As Roo, your role in this project is to:
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

## Scenario Format Requirements
Each scenario you generate must include:
-   **Objective**: A clear statement of what needs to be accomplished.
-   **Context**: Background information and any relevant constraints.
-   **Tasks**: Step-by-step requirements with exact specifications (names, values, configurations).
-   **Verification Commands**: Specific `kubectl` commands to verify task completion.
-   **Expected Results**: Clear success criteria for each verification command.
-   **Time Limit**: Suggested time allocation (mirroring exam conditions).

## Scenario Quality Standards
-   **Clear Task Instructions**: Every task must specify exact names, values, and configurations.
-   **Practical Applications**: Include workloads (Deployments, StatefulSets) that consume resources, not just resource creation.
-   **Comprehensive Verification**: Provide specific commands to verify each task is completed correctly.
-   **Real-world Context**: Scenarios must reflect actual CKA exam patterns and requirements.

### Critical Structure Requirements
-   **No Forward References**: Never reference files, ConfigMaps, or content that hasn't been defined yet in the task descriptions.
-   **Self-Contained Tasks**: Each task must include ALL information needed to complete it - no hunting through other sections.
-   **Exact Content Specification**: When tasks require creating files, provide the exact file content within that task, not in verification commands.
-   **Linear Flow**: Everything needed for a task must appear before or in that task, never after.
-   **No Vague Content**: Instead of "with application settings" or "configuration files", specify exactly what content goes in each file.
-   **Step-by-Step Clarity**: Break complex tasks into numbered sub-steps with exact content and commands.

## Learning Environment Considerations
-   The primary learning environment is k3s bare metal.
-   For cloud-specific concepts (e.g., CSI volume snapshots):
    -   Assume access to a Digital Ocean account.
    -   Prefer detailed scenarios that allow easy spinning up and down of Kubernetes clusters to minimize cost.

## CKA Exam Preparation Notes
-   Avoid deprecated features as they will not appear in the exam.

## Project Management Notes
-   Always refer to [`TASKS.md`](TASKS.md) to understand pending tasks and project progress.
-   Remember to change the status of tasks in [`TASKS.md`](TASKS.md).
-   **IMPORTANT**: When completing scenario implementations, ALWAYS move completed tasks from the "Pending Tasks" section to the "Completed Tasks" section in [`TASKS.md`](TASKS.md). This keeps the project organized and provides clear visibility into progress.
-   Update [`TASKS.md`](TASKS.md) immediately after completing each major milestone or set of scenarios.