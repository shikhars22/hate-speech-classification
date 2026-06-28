# CircleCI Configuration Explanation - CICD Pipeline

This document provides a line-by-line breakdown and structural explanation of the project's CircleCI pipeline configuration file: [.circleci/config.yml](file:///c:/Users/shikh/Downloads/code/gitHub/MLOpsLearning/nlp-project/.circleci/config.yml).

---

## 1. Pipeline Overview

The pipeline implements a **Continuous Integration and Continuous Delivery (CI/CD)** workflow divided into two main jobs:
1. **Continuous Integration (CI):** Builds the Docker image of the application and pushes it to AWS ECR. It runs in a hosted environment managed by CircleCI.
2. **Continuous Delivery (CD):** Deploys the built image on the target EC2 instance. It runs on your self-hosted CircleCI Machine Runner.

---

## 2. Configuration Breakdown

### Orbs Configuration (Lines 1-4)
```yaml
version: 2.1
orbs:
  aws-ecr: circleci/aws-ecr@8.2.1
  aws-cli: circleci/aws-cli@3.1.4
```
* **Orbs** are pre-packaged chunks of configuration provided by CircleCI or partners.
* `aws-ecr`: Simplifies authenticating, building, and pushing Docker images to Amazon Elastic Container Registry (ECR).
* `aws-cli`: Configures the AWS Command Line Interface on build executors.

---

### Job 1: Continuous Integration (Lines 6-24)
```yaml
  continuous-integration:
    docker:
      - image: cimg/base:stable
    resource_class: medium
    steps:
      - setup_remote_docker:
          version: docker24
          docker_layer_caching: false
```
* **Executor (`docker`):** The job runs inside a clean, CircleCI-hosted Docker container (`cimg/base:stable`).
* **Resource Class (`medium`):** Provisions a standard hosted build agent (2 vCPUs, 4GB RAM).
* **`setup_remote_docker`:** 
  * Provisions a secure, isolated remote VM running Docker (version `docker24`) to handle the image builds.
  * `docker_layer_caching: false`: Disabled because Docker Layer Caching (DLC) is a paid CircleCI feature. Setting this to `true` on a free tier causes the build job to crash instantly.

```yaml
      - aws-ecr/build-and-push-image:
          create-repo: true
          dockerfile: Dockerfile
          path: .
          platform: linux/amd64
          push-image: true
          repo: hate-speech-classification
          registry-id: AWS_ECR_REGISTRY_ID
          repo-scan-on-push: true
          tag: latest
```
* **`aws-ecr/build-and-push-image`:** An automated command from the ECR orb.
* `create-repo: true`: Automatically creates the private ECR repo if it doesn't already exist.
* `platform: linux/amd64`: Ensures the image compiles for x86_64 target platforms (compatibility matching the EC2 deployment host).
* `registry-id: AWS_ECR_REGISTRY_ID`: Reads the registry ID (AWS Account ID) from the CircleCI project's environment variables.
* `tag: latest`: Tags the output container image as `latest` and pushes it to ECR.

---

### Job 2: Continuous Delivery (Lines 26-48)
```yaml
  continuous-delivery:
    machine: true
    resource_class: shikhars22/deployments
```
* **Executor (`machine: true`):** Runs the execution environment directly on the host machine operating system, rather than nesting it inside a clean Docker container.
* **Resource Class (`shikhars22/deployments`):** Directs CircleCI to run the job on your **self-hosted Machine Runner** installed on the EC2 instance. This is key: instead of SSH-ing from a CircleCI cloud agent into your server, the server pulls the deployment tasks securely using an outbound polling connection.

```yaml
    steps:
      - run:
          name: auth to aws ecr
          command: aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 844099234694.dkr.ecr.ap-south-1.amazonaws.com
```
* **Authentication:** Generates an ECR login token and logs the host's Docker daemon into your private ECR repository.
* **IAM Role Security:** Because we removed `- aws-cli/setup`, the runner does not use static credentials. Instead, it utilizes the EC2 instance's attached IAM Instance Profile (IAM Role) automatically via the AWS Instance Metadata Service (IMDS).

```yaml
      - run:
          name: pull image from private repository
          command: docker pull 844099234694.dkr.ecr.ap-south-1.amazonaws.com/hate-speech-classification:latest
```
* Pulls the new docker image built in the CI job from your private ECR repository onto the EC2 host.

```yaml
      - run:
          name: stop existing container
          command: docker rm -f nlp-app || true
```
* Stops and deletes any container currently running under the name `nlp-app`. The `|| true` operator prevents the pipeline from failing if the container isn't running (e.g., during the first deployment).

```yaml
      - run:
          name: run image
          command: docker run -d -p 8080:8080 --name nlp-app 844099234694.dkr.ecr.ap-south-1.amazonaws.com/hate-speech-classification:latest
```
* Launches the new image in detached background mode (`-d`), exposing port `8080` on the EC2 host, and names the running container `nlp-app`.

```yaml
      - run:
          name: clean unused docker images
          command: docker image prune -f
```
* Deletes old dangling images and build layers to prevent ECR image pulls from slowly consuming all disk space on your EBS volume.

---

### Workflows Configuration (Lines 49-56)
```yaml
workflows:
  CICD:
    jobs:
      - continuous-integration
      - continuous-delivery:
          requires:
            - continuous-integration
```
* Organizes the sequence of job execution.
* The workflow is named `CICD`.
* It runs the `continuous-integration` job first.
* The `continuous-delivery` job starts only after the `continuous-integration` job completes successfully (`requires` parameter).
