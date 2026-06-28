# End-to-end-NLP-Project-Implementation

## CircleCI Deployment on AWS (Setup & Steps)

This project is configured to build and deploy automatically using CircleCI and AWS services (EC2, ECR, S3). 

### Setup Prerequisites & Configuration

#### 1. AWS IAM User Setup
Create an IAM User in your AWS account with programmatic access. Attach the following policies (or equivalent permissions):
* `AmazonEC2ContainerRegistryFullAccess` (to build and push/pull Docker images to ECR)
* `AmazonS3FullAccess` (to upload/download model files and datasets)

#### 2. AWS ECR Repository
Create a private ECR repository in your preferred region (e.g., `ap-south-1`):
* **Repository Name:** `hate-speech-classification`
* Note your Repository URI (e.g., `844099234694.dkr.ecr.ap-south-1.amazonaws.com/hate-speech-classification`).

#### 3. AWS S3 Bucket
Create an S3 bucket to persist the model artifacts and datasets:
* **Bucket Name:** `hate-speech-classification-844099234694` (must be globally unique, defined in [constants/__init__.py](file:///c:/Users/shikh/Downloads/code/gitHub/MLOpsLearning/nlp-project/hate/constants/__init__.py))
* **Region:** `ap-south-1`

#### 4. AWS EC2 Host Provisioning (Target Instance)
Launch a target EC2 instance with the following specifications to act as the deployment server and host the CircleCI self-hosted runner:
* **Instance Type:** `t2.large` (2 vCPUs, 8 GiB RAM). *Note: TensorFlow/Keras deep learning models require at least 8 GiB RAM to train and execute without triggering Out-Of-Memory (OOM) failures.*
* **Storage (EBS Volume):** `32 GB` (General Purpose SSD - gp3) or more. This provides sufficient disk space for the OS, Docker images, build layers, and pipeline cache.
* **Operating System:** `Ubuntu 22.04 LTS` (64-bit x86).
* **IAM Instance Profile (IAM Role):** Attach an IAM role (e.g., `ec2-ecr-role`) to the EC2 instance. This role must have policies allowing:
  * ECR access (`AmazonEC2ContainerRegistryReadOnly`) to pull the application image.
  * S3 access (`AmazonS3FullAccess` or a custom read/write policy) to read datasets and save models.
  * *Why:* This allows the self-hosted CircleCI runner and Docker on the EC2 machine to securely pull images from ECR and sync with S3 using temporary instance profile credentials, without storing any AWS access keys on the host.
* **Security Group Inbound Rules:**
  * **SSH (Port 22):** Restricted to your IP address (for secure server management).
  * **Custom TCP (Port 8080):** Set to anywhere (`0.0.0.0/0`) or your IP (to access the FastAPI web API and docs).

#### 5. Copying and Executing the EC2 Setup Script
Instead of running setup commands manually, you can use the pre-configured [circleci_setup_template.sh](file:///c:/Users/shikh/Downloads/code/gitHub/MLOpsLearning/nlp-project/awsSupportDocs/circleci_setup_template.sh) script located in the `awsSupportDocs/` directory.

##### Step A. Transfer the script to EC2
From your local workstation terminal, run `scp` to securely copy the setup script to the EC2 instance (replace `<YOUR-EC2-PUBLIC-IP>` with your actual EC2 public IP):
```bash
scp -i awsSupportDocs/rsa-key-skg-mlFlow.pem awsSupportDocs/circleci_setup_template.sh ubuntu@<YOUR-EC2-PUBLIC-IP>:/home/ubuntu/
```

##### Step B. Convert Windows CRLF to Unix LF Line Endings
Because the script was created on a Windows system, it contains carriage returns (`\r`) which cause syntax errors in Linux shells. SSH into the EC2 instance and run `sed` to strip the `\r` endings:
```bash
# SSH into EC2:
ssh -i awsSupportDocs/rsa-key-skg-mlFlow.pem ubuntu@<YOUR-EC2-PUBLIC-IP>

# Convert Windows line endings (CRLF) to Unix line endings (LF):
sed -i 's/\r$//' circleci_setup_template.sh
```

##### Step C. Make the script executable
Change the file permissions to allow execution:
```bash
chmod +x circleci_setup_template.sh
```

##### Step D. Run the setup script
Run the script to automate the installation of Docker, the CircleCI Runner agent, configuration setup, and the AWS CLI:
```bash
./circleci_setup_template.sh
```

---

#### 6. Manual Setup & Installation Commands (Alternative)
If you prefer to configure the server step-by-step manually, run the following commands on the EC2 instance:

##### A. Install Docker
```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
```

##### B. Install CircleCI self-hosted Machine Runner
```bash
curl -s https://packagecloud.io/install/repositories/circleci/runner/script.deb.sh | sudo bash
sudo apt-get install -y circleci-runner
```

##### C. Configure the Runner Token
Open the configuration file:
```bash
sudo nano /etc/circleci-runner/circleci-runner.yml
```
Update the `auth_token` with your CircleCI resource class token:
```yaml
api:
  auth_token: "YOUR_CIRCLECI_RESOURCE_CLASS_TOKEN"
runner:
  name: "hate-speech-ec2-runner"
  working_directory: "/var/opt/circleci-runner/workdir"
  cleanup_working_directory: true
```

##### D. Authorize Runner to use Docker (Non-Root Access)
Add the `circleci-runner` user to the `docker` group so the agent can pull and run containers without `sudo`:
```bash
sudo usermod -aG docker circleci-runner
```

##### E. Start and Enable the Runner Service
```bash
sudo systemctl enable circleci-runner
sudo systemctl start circleci-runner
```

##### F. Verify Runner is Active
```bash
sudo systemctl status circleci-runner
# Or view live runner logs:
journalctl -u circleci-runner -f
```

#### 7. CircleCI Project Settings
Navigate to your CircleCI project settings and configure the following Environment Variables:
* `AWS_ACCESS_KEY_ID`: IAM user access key
* `AWS_SECRET_ACCESS_KEY`: IAM user secret key
* `AWS_REGION`: `ap-south-1`
* `AWS_ECR_REGISTRY_ID`: Your AWS Account ID (e.g., `844099234694`)

---

### Step-by-Step Deployment Architecture

Our deployment pipeline is defined in [.circleci/config.yml](file:///c:/Users/shikh/Downloads/code/gitHub/MLOpsLearning/nlp-project/.circleci/config.yml) and consists of two stages:

```mermaid
graph TD
    A[Git Push to main] --> B[CircleCI Triggered]
    B --> C[Continuous Integration Job]
    C -->|Builds Docker Image| D[Push Image to AWS ECR]
    D --> E[Continuous Delivery Job]
    E -->|Executed on EC2 Runner| F[Pull Image from ECR]
    F --> G[Run Docker Container on Port 8080]
```

#### Step 1: Continuous Integration (Hosted Environment)
1. Triggered automatically on git push.
2. Checks out the code repository.
3. Sets up a remote Docker environment (`setup_remote_docker`).
4. Uses `Dockerfile` (configured with `python:3.8-slim-bullseye` to prevent EOL repository issues) to build the hate speech classifier application image.
5. Authenticates with AWS and pushes the built image tagged as `latest` to your private ECR repository.

#### Step 2: Continuous Delivery (Self-Hosted Runner on EC2)
1. Installs a **CircleCI Machine Runner** on a target EC2 instance (`t2.large` or similar) under the resource class namespace `shikhars22/deployments`.
2. The Runner is added to the `docker` group on the host OS so it can run Docker tasks without `sudo`.
3. Runs the delivery job directly on the EC2 host shell (`machine: true` executor):
   * Authenticates with AWS ECR.
   * Pulls the latest Docker image from ECR.
   * Stops and removes the existing `nlp-app` container if it is running.
   * Runs the new image mapping port `8080:8080` on the EC2 host.
   * Prunes unused images to save disk space.

---

### Run & Verify the Application

Once CircleCI completes the deployment successfully:

#### 1. Train the Model
The containerized application does not ship with a pre-trained model. You must trigger a training run:
* Open your browser and navigate to: `http://<YOUR-EC2-PUBLIC-IP>:8080/train`
* This runs the training pipeline inside the container.
* **S3 Fallback:** If you haven't created the S3 bucket yet, the pipeline automatically falls back to using the local `data/dataset.zip` file, trains the model, saves it inside local artifacts, and gracefully copies it to `artifacts/PredictModel/model.h5`.
* Once training completes, the browser will display **`Training successful !!`**.

#### 2. Execute Predictions
* Open the FastAPI interactive docs: `http://<YOUR-EC2-PUBLIC-IP>:8080/docs`
* Go to the `POST /predict` route, click **Try it out**, enter your text, and click **Execute**.
* The server will load the trained model and output the classification prediction (`hate and abusive` or `no hate`).

