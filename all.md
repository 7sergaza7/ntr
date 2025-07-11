# Introduction

Provide a brief overview of the project, its objectives, and expected outcomes.

---

<!-- # Task Assignment

| Task                | Owner        | Deadline    | Status     |
|---------------------|--------------|-------------|------------|
| Requirement Gathering | [Name]     | [Date]      | [Status]   |
| UI/UX Design        | [Name]       | [Date]      | [Status]   |
| Development         | [Name]       | [Date]      | [Status]   |
| Testing             | [Name]       | [Date]      | [Status]   |

--- -->

## 1 - AWS and Cloud Architecture

### 1.1 RDS DB terraform code

### 1.2 ALB issue

### 1.3 S3 Bucked config

---

## 2 - Kubernetes and Container Management

### 2.1 Deployment fix

### 2.2 REsource Management

---

## 3 - CI/CD & Automation

### 3.1 Node app workflow optimization

Let's assume this is a simple Node application workflow and we don't deal with credentials, secrets and package manager source. The building docker image, publishing to artifactory is out of this scope.

Following the assignment example workflow just compiling, testing node.js application and uploading the dist folder to unknown place with 2 jobs build and test.
The 3rd job is download dist folder and deployment to kubernetes cluster k8s folders manifests which is unnecessary.

The optimization is to run jobs on pull request only - build (and upload), test, lint in parallel without any dependency in between.
The deployment job triggered on push to main branch. Extra path trigger might be applied to trigger this specific application workflow.

See the fixed simple node.js app workflow [`_cicd_nodeapp`](https://github.com/7sergaza7/ntr/tree/3.1/_cicd_nodeapp.yaml)

The things worth to implement:

- versioning
- SCA tools
- tagging

### 3.2 Deployment strategy

Argo CD with Canary and Blue/Green

---

## 4 - Security and Compliance

### 4.1 Security Audit

- RBAC:
Developers has a full privilege as admins

- Pod:
Running as root which is bad and highly unsecured

### 4.2 Secret Management

---

### Bonus Task
