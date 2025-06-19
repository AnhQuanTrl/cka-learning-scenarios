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

## Scenario Format
Each scenario includes:
- **Objective**: What you need to accomplish
- **Context**: Background information and constraints
- **Tasks**: Step-by-step requirements with exact specifications (names, values, configurations)
- **Verification Commands**: Specific kubectl commands to verify task completion
- **Expected Results**: Clear success criteria for each verification command
- **Time Limit**: Suggested time allocation (mirroring exam conditions)

## Scenario Quality Standards
- **Clear Task Instructions**: Every task specifies exact names, values, and configurations
- **Practical Applications**: Include workloads (Deployments, StatefulSets) that consume resources, not just resource creation
- **Comprehensive Verification**: Provide specific commands to verify each task is completed correctly
- **Real-world Context**: Scenarios reflect actual CKA exam patterns and requirements

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
