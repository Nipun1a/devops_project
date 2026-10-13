#!/bin/bash
# For Ubuntu 22.04
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Give package installation and services additional memory headroom.
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# Install prerequisites before using curl, unzip, or gpg.
sudo apt-get update
sudo apt-get install -y ca-certificates curl wget unzip gnupg lsb-release fontconfig

# Installing Java for current Jenkins LTS.
sudo apt-get install -y openjdk-21-jdk
java --version

# Installing Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y

sudo mkdir -p /etc/systemd/system/jenkins.service.d
printf '[Service]\nEnvironment="JAVA_OPTS=-Djava.awt.headless=true -Xms128m -Xmx512m"\n' | sudo tee /etc/systemd/system/jenkins.service.d/memory.conf > /dev/null
sudo systemctl daemon-reload

# Installing Docker 
sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker jenkins
# Restart Jenkins so it picks up membership in the docker group.
sudo systemctl restart jenkins

# If you don't want to install Jenkins, you can create a container of Jenkins
# docker run -d -p 8080:8080 -p 50000:50000 --name jenkins-container jenkins/jenkins:lts

# Run Docker Container of Sonarqube
if [ "${install_sonarqube}" = "true" ]; then
${sonar_install_script}
fi


# Installing AWS CLI
install_dir=$(mktemp -d)
cd "$install_dir"
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install --update

# Installing Kubectl
sudo apt update
sudo apt install curl -y
# Pin this to a version within one minor version of your EKS cluster.
kubectl_version=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fsSLO "https://dl.k8s.io/release/$kubectl_version/bin/linux/amd64/kubectl"
curl -fsSLO "https://dl.k8s.io/release/$kubectl_version/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client


# Installing eksctl
curl --fail --silent --show-error --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C "$install_dir"
sudo install -m 0755 "$install_dir/eksctl" /usr/local/bin/eksctl
eksctl version

# Installing Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install terraform -y

# Installing Trivy
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
sudo apt update
sudo apt install trivy -y


# Intalling Helm
sudo snap install helm --classic

touch /var/lib/jenkins-bootstrap-complete
