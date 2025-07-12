# Introduction

Solution description for DevOps assessment.

I prioritized completing each task solution with maximum quality and coverage within the assigned time. The simpler solutions have been tested and validated. The more complex ones, which required AWS setup for validation, primarily focus on design and architecture rather than testing and validation.

## 1 - AWS and Cloud Architecture

### 1.1 RDS DB backup terraform code

Solution [rds_postgres_backup](https://github.com/7sergaza7/ntr/blob/main/1.1/rds_postgres_backup.tf)

### 1.2 ALB issue

According to the description potential issue:

1. 8080 Port might be wrong in configuration. According to log we see port 80 on 10.0.1.5:80
1. Health check path /health might be wrong at the endpoint.
1. application itself might be unhealthy
1. Check firewall and security groups rules on ec2.

AWS Console UI and aws cli might help here to query with different parameters like --region etc:

Need to check all parameters related to connectivity and health.
Reference [elbv2](https://docs.aws.amazon.com/cli/latest/reference/elbv2/)

```bash
aws elbv2 describe-target-groups 

aws elbv2 describe-target-health --target-group-arn

aws elbv2 describe-load-balancers

aws ec2 describe-security-groups --group-ids

aws ec2 describe-instances --instance-ids
```

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

Assuming this is a simple Node.js application workflow without handling credentials, secrets, or package manager sources. Building the Docker image and publishing to an artifactory are out of scope.

The provided example workflow compiles and tests the Node.js application, then uploads the `dist` folder to an unspecified location using two jobs: build and test. A third job downloads the `dist` folder and deploys it to a Kubernetes cluster using manifest files, which is unnecessary.

The optimization is to run jobs (on pull requests only) - build and upload, test, and lint in parallel, without dependencies between them. The deployment job should be triggered on pushes to the main branch. An additional path filter can be applied to trigger this workflow only for changes to the specific application.

See the fixed simple node.js app workflow [`_cicd_nodeapp`](https://github.com/7sergaza7/ntr/blob/main/3.1/_cicd_nodeapp.yaml)

The things worth to implement:

- versioning
- SCA tools
- tagging

### 3.2 Deployment strategy

Argo CD with Canary and Blue/Green

```bash
serg@DESKTOP-ICPB06S:~$ kubectl-argo-rollout list rollouts -n nodejs-api
NAME               STRATEGY   STATUS        STEP  SET-WEIGHT  READY  DESIRED  UP-TO-DATE  AVAILABLE
nodeapi-bluegreen  BlueGreen  Healthy       -     -           3/3    3        3           3        
nodeapi-canary     Canary     Healthy       6/6   100         3/3    3        3           3 
```

To undo the latest rollout run the following command:

```bash
kubectl argo rollouts undo <rollout-name>
```

List all rollouts and their history:

```bash
kubectl argo rollouts list 

kubectl argo rollouts history <rollout-name>
```

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

Let's assume we design AWS solution and not multi-cloud architecture.

Using AWS native services need the following:

- AWS Secrets Manager: A secure and scalable service for storing and managing secrets such as API keys, database credentials, and other sensitive information.
- Access Management (IAM):
- EKS installed with the following components:
  - AWS Identity - EKS Pod Identity (better and easier then IRSA), which provides a secure way to grant Kubernetes pods access to AWS resources without needing to manage credentials manually.
  - Kubernetes Secrets Store CSI Driver (helm chart): This driver allows you to mount secrets from external stores, like AWS Secrets Manager, as volumes inside your pods. This avoids exposing secrets as environment variables.
  - AWS Secrets & Configuration Provider (ASCP): A plugin for the Secrets Store CSI Driver that enables it to communicate with AWS Secrets Manager.
  - Kubernetes RBAC (Role-Based Access Control): To enforce fine-grained access control to Kubernetes resources, including the secrets synchronized into the cluster.
  - Reloader (helm chart): A Kubernetes controller that watches for changes in ConfigMaps and Secrets and triggers rolling upgrades on associated Deployments, StatefulSets, and DaemonSets. This is crucial for automated secret rotation.
- Kubernetes Audit Logs & AWS CloudTrail: For comprehensive auditing of secret access and management activities.

See [deployment](https://github.com/7sergaza7/ntr/blob/main/4.2/deployment.yaml) example with annotation to reloader from [secret-provider-class](https://github.com/7sergaza7/ntr/blob/main/4.2/secret-provider-class.yaml).

See [rbac](https://github.com/7sergaza7/ntr/blob/main/4.2/rbac.yaml) example configuration for `my-app-sa` assigned to role `secret-reader`

---

### Bonus Task

It is feasible, but my priority was to complete all four assignment sections first.
