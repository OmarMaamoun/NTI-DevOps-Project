# 🚀 NTI DevOps Final Project

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Terraform](https://img.shields.io/badge/Terraform-v1.5.0-blue)
![Docker](https://img.shields.io/badge/Docker-v24.0-blue)
![License](https://img.shields.io/badge/license-MIT-blue)

> Full DevOps pipeline implementation using Terraform, Ansible, Docker, Kubernetes, Jenkins, and monitoring tools as part of the NTI DevOps program.

---

## 📑 Table of Contents

* [Project Overview](#-project-overview)
* [Tech Stack](#-tech-stack)
* [Project Structure](#-project-structure)
* [Getting Started](#-getting-started)
* [Terraform](#-terraform)
* [Ansible](#-ansible)
* [Docker](#-docker)
* [Kubernetes](#-kubernetes)
* [Jenkins CI/CD Pipeline](#-jenkins-cicd-pipeline)
* [Monitoring & Alerting](#-monitoring--alerting)
* [Author](#-author)

---

## 📌 Project Overview

This project demonstrates a full DevOps pipeline for a 3 web-tier application, including:

1. Infrastructure provisioning with Terraform
2. Configuration management with Ansible
3. Containerization with Docker
4. Orchestration with Kubernetes
5. Continuous integration and delivery with Jenkins
6. Monitoring and alerting using Prometheus and Grafana

---

## 🛠️ Tech Stack

| Layer                    | Technology                                                            |
| ------------------------ | --------------------------------------------------------------------- |
| Infrastructure           | Terraform, AWS (VPC, EKS, EC2, RDS, S3, ECR, Secrets Manager, Backup) |
| Configuration Management | Ansible                                                               |
| Containerization         | Docker, Docker Compose                                                |
| Orchestration            | Kubernetes (EKS), Helm                                                |
| CI/CD                    | Jenkins, GitHub                                                       |
| Security                 | Network Policies, Trivy, AWS IAM                                      |
| Monitoring               | Prometheus, Grafana, AWS CloudWatch                                   |
| Code Quality             | SonarQube                                                             |

---

## 📁 Project Structure

```
NTI-DevOps-Project/
├── Ansible/
├── api/
├── k8s/
├── terraform/
├── web/
├── .gitignore
├── Jenkinsfile
├── README.md
└── docker-compose.yml
```

---

## 🚀 Getting Started

### Terraform

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### Ansible

```bash
cd Ansible/
ansible-playbook jenkins-ec2.yml
ansible-playbook CWplaybook.yml
```

### Docker Compose

```bash
docker compose up --build
```

### Kubernetes Deployment

```bash
kubectl apply -f k8s/
```

---

## 🔧 Terraform

* Create **EKS cluster** with 2 nodes, auto-scaling group, and ELB
* Create **RDS instance** and store credentials in **AWS Secrets Manager**
* Launch **EC2 instance** for Jenkins
* Enable **daily snapshot** of Jenkins using **AWS Backup service**
* Save **ELB access logs** to **AWS S3 bucket**
* Create **AWS ECR** for Docker images

---

## 🔧 Ansible

* Install **Jenkins**, including configuration and plugins
* Install **CloudWatch agent** on all EC2 instances

---

## 🔧 Docker

* Build **Docker images** for the application
* Create **docker-compose** to run the app locally

---

## 🔧 Kubernetes

* Create **Kubernetes manifests** to deploy the app on EKS
* Implement **Network Policies** for pod-to-pod security

---

## 🔁 Jenkins CI/CD Pipeline

* Multi-branch pipeline triggered on **GitHub push**
* Pipeline stages:

  1. Run **SonarQube quality checks**; stop pipeline if quality gate fails
  2. Build **Docker image** from repo and scan with **Trivy**
  3. Push Docker image to **ECR**
  4. Deploy updated image to **Kubernetes pods** using **Helm charts**

---

## 📊 Monitoring & Alerting (Prometheus & Grafana)

* Deploy **Prometheus** to monitor all pods and nodes using service discovery
* Create **alerts** if CPU or RAM usage exceeds **80%** on any pod
* Setup **Grafana dashboards** to visualize application metrics

---


 👤 Author

**Omar Maamoun**

---
