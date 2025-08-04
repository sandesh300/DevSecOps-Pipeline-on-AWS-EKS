# DevSecOps Mega Project-Springboot Bankapp

## End-to-End Bank Application Deployment using DevSecOps on AWS EKS
- This is a multi-tier bank an application written in Java (Springboot).

  
## Step 1: Create an IAM User with Administrator Permissions

1. **Login to AWS Console:** Open the [AWS Management Console](https://aws.amazon.com/console/).
    
2. **Navigate to IAM:** Go to the Identity and Access Management (IAM) service.
    
3. **Create User:**
    
    * Click on **Users** &gt; **Add Users**.
        
    * Enter a username, e.g., `mega-project-user`.
        
    * Select **Programmatic access** to generate an access key.
        
4. **Attach Permissions:** Attach the policy `AdministratorAccess`.
    
5. **Generate Access Key:**
    
    * In the Security tab, create an access key.
        
    * Save the **Access Key ID** and **Secret Access Key** securely.
        

---

## Step 2: Setting Up Visual Studio Code (VSCode)

### Adding Linux Terminal in VSCode (Windows Users)

If you are on Windows, refer to this [guide](https://amitabhdevops.hashnode.dev/a-step-by-step-guide-to-adding-ubuntu-wsl-in-vs-code-terminal) to integrate an Ubuntu terminal in VSCode for seamless project execution.

---

## Step 3: Fork and Clone the Project Repository

1. **Fork the Repository:**
    
    * Open the repository [DevOps Mega Project](https://github.com/sandesh300/DevSecOps-Pipeline-on-AWS-EKS.git) on GitHub.
        
    * Click **Fork** to create a copy in your GitHub account.
        
2. **Clone the Repository:**
    
    * Open the terminal in VSCode.
        
    * Clone the repository:
        
        ```bash
        git clone https://github.com/<your-username>/DevOps-mega-project.git
        ```
        
    * Switch to the project branch:
        
        ```bash
        git checkout project
        ```
        

---

## Step 4: Install AWS CLI and Configure It

1. **Install AWS CLI:**
    
    ```bash
    sudo apt update
    sudo apt install awscli -y
    ```
    
2. **Configure AWS CLI:**
    
    ```bash
    aws configure
    ```
    
    * Enter the Access Key ID and Secret Access Key.
        
    * Specify your preferred AWS region (e.g., `eu-west-1`).
        

---

## Step 5: Build and Push Docker Image

1. **Build the Docker Image:**
    
    ```bash
    docker build -t <dockerhub-username>/bankapp:latest .
    ```
    
2. **Login to DockerHub:**
    
    ```bash
    docker login
    ```
    
3. **Push the Image to DockerHub:**
    
    ```bash
    docker push <dockerhub-username>/bankapp:latest
    ```
    
4. **Update Deployment File:**
    
    * Update the `bankapp-deployment.yml` file to use your Docker image.
        

---

## Step 6: Set Up Infrastructure with Terraform

1. **Generate SSH Key:**
    
    ```bash
    ssh-keygen
    ```
    
    * Enter a name as `mega-project-key`.
        
    * Update the `variable.tf` file with the key name, if you have entered another key name.
        
2. **Initialize Terraform**: Run the initialization command to download provider plugins and prepare your working directory:
    
    ```bash
    terraform init
    ```
    
3. **Plan Terraform Execution**: Preview the resources Terraform will create:
    
    ```bash
    terraform plan
    ```
    
4. **Apply Terraform Configuration**: Deploy the infrastructure using:
    
    ```bash
    terraform apply --auto-approve
    ```
    
5. **Connect to EC2 Instance**: Once the infrastructure is created, connect to your EC2 instance:
    
    ```bash
    ssh -i mega-project-key.pem ubuntu@<instance-public-ip>
    ```
    

---

## Step 7: Install Essential DevOps Tools on created Instance.

Follow this [guide](https://amitabhdevops.hashnode.dev/how-to-install-essential-devops-tools-on-ubuntulinux) to install:

* AWS CLI
    
* kubectl
    
* eksctl
    

### Install eksctl:

```bash
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo mv /tmp/eksctl /usr/local/bin
```

---

## Step 8: Create Kubernetes Cluster

1. **Create EKS Cluster:**
    
    ```bash
    eksctl create cluster --name bankapp-cluster --region eu-west-1 --without-nodegroup
    ```
    
2. **Verify Cluster Creation:**
    
    ```bash
    eksctl get clusters
    ```
    
3. **Associate IAM OIDC Provider:**
    
    ```bash
    eksctl utils associate-iam-oidc-provider --region=eu-west-1 --cluster=bankapp-cluster --approve
    ```
    
4. **Create Node Group:**
    
    ```bash
    eksctl create nodegroup \
      --cluster=bankapp-cluster \
      --region=eu-west-1 \
      --name=bankapp-ng \
      --node-type=t2.medium \
      --nodes=2 \
      --nodes-min=2 \
      --nodes-max=2 \
      --node-volume-size=15 \
      --ssh-access \
      --ssh-public-key=mega-project-key
    ```
    

---

## Step 9: Set Up ArgoCD

#### Step 1: Create a Namespace for ArgoCD

To ensure ArgoCD has its own isolated environment within your Kubernetes cluster, create a dedicated namespace.

```bash
kubectl create ns argocd
```

---

#### Step 2: Install ArgoCD

Use the official installation manifest from ArgoCD’s GitHub repository to deploy it to your cluster.

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

This command installs all required ArgoCD components in the `argocd` namespace.

---

#### Step 3: Install ArgoCD CLI

To interact with the ArgoCD server from your local machine or a terminal, install the ArgoCD command-line interface (CLI).

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

Once installed, verify the installation using:

```bash
argocd version
```

---

#### Step 4: Check ArgoCD Services

To confirm that ArgoCD services are running:

```bash
kubectl get svc -n argocd
```

This lists all services in the `argocd` namespace. Take note of the `argocd-server` service, as it will be exposed in the next step.

---

#### Step 5: Expose ArgoCD Server Using NodePort

By default, the `argocd-server` service is of type `ClusterIP`, which makes it accessible only within the cluster. Change it to `NodePort` to expose it externally.

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type": "NodePort"}}'
```

Retrieve the updated service information to identify the assigned NodePort:

```bash
kubectl get svc -n argocd
```

Note the port in the `PORT(S)` column (e.g., `30529`).

---

#### Step 6: Configure AWS Inbound Rule for NodePort

If your Kubernetes cluster is hosted on AWS, ensure that the assigned NodePort is accessible by adding an inbound rule to your security group. Allow traffic on this port from the internet to the worker node(s).

---

#### Step 7: Access ArgoCD Web UI

With the NodePort and the worker node’s public IP, access the ArgoCD web UI:

```bash
http://<worker-node-public-ip>:<node-port>
```

![image](https://github.com/user-attachments/assets/32222a1f-3aea-450b-a7e5-0f44b34702ed)


For the initial login:

* **Username:** `admin`
    
* **Password:** Retrieve using the following command:
    

```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

Change the password after logging in by navigating to the user info section in the ArgoCD UI.

---

#### Step 8: Log In to ArgoCD via CLI

To log in from the CLI, use the public IP and NodePort:

```bash
argocd login <worker-node-public-ip>:<node-port> --username admin
```

For example:

```bash
argocd login 54.154.41.147:30529 --username admin
```

---

#### Step 9: Check ArgoCD Cluster Configuration

To view the cluster configurations managed by ArgoCD:

```bash
argocd cluster list
```

---

#### Step 10: Add a Cluster to ArgoCD

If your cluster is not already added, first identify its context:

```bash
kubectl config get-contexts
```

Then, add the desired cluster to ArgoCD. Replace the placeholders with your actual cluster context and name:

```bash
argocd cluster add <kube-context> --name <friendly-name>
```

For example:

```bash
argocd cluster add mega-project-user@bankapp-cluster.eu-west-1.eksctl.io --name bankapp-cluster
```

#### Step 11: Add Project Repository in ArgoCD UI

To integrate your Git repository with ArgoCD:

1. Navigate to **Settings** &gt; **Repositories** in the ArgoCD UI.
    
2. Click on **Connect Repo** and provide the appropriate repository URL.
    
3. Select the connection method as HTTPS. If the repository is private:
    
    * Enter your username and password to authenticate.
        
    * Otherwise, skip the authentication step for public repositories.
        
4. Choose the default project (or any specific project, if configured) and complete the setup.
    

Once connected, your repository will be ready for deploying applications via ArgoCD.

---

source community and contribute to this project. Let’s work together to make this project even better!

We look forward to your innovative contributions, and remember, great work deserves great rewards!


