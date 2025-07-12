# Introduction

Solution description for each section

## 1 - AWS and Cloud Architecture

### 1.1 RDS DB backup terraform code

Solution [rds_postgres_backup](https://github.com/7sergaza7/ntr/blob/main/1.1/rds_postgres_backup.tf)

### 1.2 ALB issue

### 1.3 S3 Bucked config

Solution [s3_static_site](https://github.com/7sergaza7/ntr/blob/main/1.1/rds_postgres_backup.tf)

---

## 2 - Kubernetes and Container Management

### 2.1 Deployment fixed

Please check [`2.1_fixed`](https://github.com/7sergaza7/ntr/blob/main/2.1/2.1_fixed.yaml)

### 2.2 REsource Management

Please check [`2.2 folder`](https://github.com/7sergaza7/ntr/blob/main/2.2) with the manifests created for simple node api found on docker hub.

---

## 3 - CI/CD & Automation

### 3.1 Node app workflow optimization

Let's assume this is a simple Node application workflow and we don't deal with credentials, secrets and package manager source. The building docker image, publishing to artifactory is out of this scope.

Following the assignment example workflow just compiling, testing node.js application and uploading the dist folder to unknown place with 2 jobs build and test.
The 3rd job is download dist folder and deployment to kubernetes cluster k8s folders manifests which is unnecessary.

The optimization is to run jobs on pull request only - build (and upload), test, lint in parallel without any dependency in between.
The deployment job triggered on push to main branch. Extra path trigger might be applied to trigger this specific application workflow.

See the fixed simple node.js app workflow [`_cicd_nodeapp`](https://github.com/7sergaza7/ntr/blob/main/3.1/_cicd_nodeapp.yaml)

The things worth to implement:

- versioning
- SCA tools
- tagging

### 3.2 Deployment strategy

Argo CD with Canary and Blue/Green

---

## 4 - Security and Compliance

### 4.1 Security Audit

- ClusterRoleBinding issue:
Developers have the same access level as cluster admin role which is bad. Need to define restricted cluster role for developers group
Example with developers defined ClusterRole and ClusterRoleBinding for developers group [`pod`](https://github.com/7sergaza7/ntr/blob/main/4.1/developers_clusterrole.yaml)

- Pod security issue:
Running application with root privilege which is not secured. Need to define access for application users.

See the secured nginx configuration example that using nginx user [`pod`](https://github.com/7sergaza7/ntr/blob/main/4.1/pod.yaml)

### 4.2 Secret Management

---

### Bonus Task
