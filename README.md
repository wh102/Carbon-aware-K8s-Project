# Carbon-Aware Kubernetes Autoscaling

A cloud-native Kubernetes platform that combines application demand, real-time UK grid carbon intensity and workload energy consumption to make autoscaling decisions.

The project demonstrates how Kubernetes workloads can be deployed, monitored and automatically scaled using a carbon-aware metric derived from **Prometheus**, **Kepler**, **KEDA** and live UK carbon-intensity data.

---

## Table of Contents

- [About the Project](#about-the-project)
- [Architecture](#architecture)
- [Built With](#built-with)
- [Key Features](#key-features)
- [Carbon-Aware Autoscaling](#carbon-aware-autoscaling)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Monitoring and Observability](#monitoring-and-observability)
- [Testing the Autoscaler](#testing-the-autoscaler)
- [CI/CD and GitOps](#cicd-and-gitops)
- [Repository Structure](#repository-structure)
- [Results](#results)
- [Destroying the Infrastructure](#destroying-the-infrastructure)
- [Limitations and Future Improvements](#limitations-and-future-improvements)
- [Acknowledgments](#acknowledgments)

---

## About the Project

Traditional Kubernetes autoscaling normally reacts to infrastructure metrics such as CPU or memory utilisation.

While this helps applications respond to changing demand, it does not consider the environmental impact of the infrastructure running the workload.

This project explores a different approach by implementing a **carbon-aware Kubernetes autoscaling system**.

The autoscaling signal combines three factors:

1. **Application demand** – measured using HTTP request metrics exported by the Flask application.
2. **Grid carbon intensity** – obtained from UK electricity carbon-intensity data and exposed to Prometheus.
3. **Workload energy consumption** – measured using Kepler at Kubernetes container level.

These metrics are collected by Prometheus and combined using PromQL. KEDA then exposes the calculated metric to the Kubernetes Horizontal Pod Autoscaler (HPA), allowing the Flask application to scale according to both workload demand and environmental conditions.

The complete platform is provisioned using **Terraform** on **Amazon Web Services (AWS)** and deployed using a GitOps-based workflow with **Argo CD**.

---

## Architecture

The project uses the following architecture:

```text
                         GitHub Repository
                               |
                               |
                        GitHub Actions
                               |
                               v
                           Terraform
                               |
                               v
                    Amazon Web Services
                               |
                        Amazon EKS Cluster
                               |
        +----------------------+----------------------+
        |                      |                      |
        v                      v                      v
     Argo CD                Prometheus              KEDA
        |                      |                      |
        |                      |                      |
        v                      |                      |
 Kubernetes Manifests         |                      |
        |                      |                      |
        v                      |                      |
   Flask Application <--------+----------------------+
        |
        v
      MySQL

        Kubernetes Nodes
              |
              v
            Kepler
              |
              v
          Prometheus
              |
              v
            Grafana
```

### Metric Flow

```text
User Requests
     |
     v
Flask Application
     |
     +---- flask_http_requests_total
     |
     v
Prometheus <---- carbon_intensity
     ^
     |
     +---- Kepler energy metrics
               |
               v
      kepler_container_joules_total

               |
               v

       Carbon-Aware PromQL
               |
               v
             KEDA
               |
               v
              HPA
               |
               v
       Flask Replica Count
```

This creates a closed monitoring and autoscaling loop where application behaviour and energy information influence Kubernetes scaling.

---

## Built With

The project combines cloud infrastructure, Kubernetes, application development, monitoring and GitOps technologies.

### Cloud and Infrastructure

- Amazon Web Services (AWS)
- Amazon Elastic Kubernetes Service (EKS)
- Amazon Elastic Container Registry (ECR)
- Application Load Balancer (ALB)
- Amazon S3 Terraform backend
- Terraform

### Kubernetes

- Kubernetes
- KEDA
- Horizontal Pod Autoscaler
- AWS Load Balancer Controller
- Kubernetes Secrets
- Deployments
- Services
- Ingress
- StatefulSets

### Application

- Python
- Flask
- MySQL
- Docker
- Gunicorn / Python web application runtime

### Observability

- Prometheus
- Grafana
- Kepler
- Prometheus ServiceMonitor
- PromQL

### DevOps and GitOps

- GitHub
- GitHub Actions
- Argo CD
- Terraform
- Docker
- Amazon ECR

---

## Key Features

### Infrastructure as Code

AWS infrastructure is defined using Terraform, allowing the Kubernetes environment to be created and destroyed reproducibly.

### Managed Kubernetes

The application runs on Amazon EKS rather than a manually configured Kubernetes cluster.

### Containerised Application

The Flask application is packaged as a Docker image and stored in Amazon ECR.

### Persistent Database

The application communicates with a MySQL database deployed inside Kubernetes.

### GitOps Deployment

Argo CD synchronises Kubernetes manifests stored in GitHub with the EKS cluster.

### Health Monitoring

The Flask application exposes:

```text
/health
/ready
/metrics
```

These endpoints provide Kubernetes health checks and Prometheus monitoring.

### Application Metrics

The application exports a custom Prometheus counter:

```text
flask_http_requests_total
```

Health checks and Prometheus scraping are excluded so the metric represents application demand rather than monitoring traffic.

### Carbon Intensity Metrics

The application retrieves UK electricity carbon-intensity information and exports:

```text
carbon_intensity
```

The metric represents grid carbon intensity in:

```text
gCO2/kWh
```

### Energy Monitoring

Kepler monitors Kubernetes workload energy consumption and exposes metrics including:

```text
kepler_container_joules_total
```

This allows the energy usage of the Flask workload to be incorporated into the scaling model.

### Carbon-Aware Autoscaling

KEDA queries Prometheus and provides the resulting external metric to Kubernetes HPA.

The HPA can therefore scale the Flask deployment according to a metric that considers:

- traffic,
- grid carbon intensity,
- workload energy consumption.

---

## Carbon-Aware Autoscaling

The main carbon-aware scaling query used by KEDA is:

```promql
sum(rate(flask_http_requests_total[2m]))
*
clamp(
  (300 - max(carbon_intensity)) / 150,
  0.25,
  1.25
)
*
clamp(
  1 /
  clamp_min(
    sum(
      rate(
        kepler_container_joules_total{
          container_namespace="flask-app",
          container_name="flask-app",
          mode="dynamic"
        }[2m]
      )
    ),
    0.25
  ),
  0.5,
  2
)
```

The metric consists of three components.

### 1. Application Demand

```promql
sum(rate(flask_http_requests_total[2m]))
```

This calculates the recent application request rate.

More traffic increases the scaling signal.

---

### 2. Carbon Intensity Factor

```promql
clamp(
  (300 - max(carbon_intensity)) / 150,
  0.25,
  1.25
)
```

The current carbon intensity modifies the scaling signal.

The `clamp()` function ensures that the carbon factor remains within controlled limits so that carbon intensity influences scaling without completely overriding application demand.

---

### 3. Energy Efficiency Factor

```promql
clamp(
  1 /
  clamp_min(
    sum(
      rate(
        kepler_container_joules_total{
          container_namespace="flask-app",
          container_name="flask-app",
          mode="dynamic"
        }[2m]
      )
    ),
    0.25
  ),
  0.5,
  2
)
```

Kepler provides workload-level energy measurements.

The energy factor modifies the final metric according to the measured energy consumption of the Flask containers.

The lower and upper bounds prevent extreme values from destabilising autoscaling.

---

### Final Scaling Signal

Conceptually, the metric can be represented as:

```text
Carbon-Aware Scaling Metric
        =
Application Demand
        ×
Carbon Intensity Factor
        ×
Energy Efficiency Factor
```

KEDA evaluates this query against Prometheus.

The project uses:

```yaml
metricType: AverageValue
```

This is important because the metric is interpreted relative to the number of replicas rather than as a single global target value.

The KEDA configuration allows the Flask deployment to scale between:

```text
Minimum replicas: 1
Maximum replicas: 5
```

Scaling behaviour also includes stabilisation windows to prevent rapid replica oscillation.

---

## Getting Started

### Prerequisites

The following tools are required to deploy and manage the project:

- AWS account
- AWS CLI
- Terraform
- Docker
- kubectl
- Helm
- Git
- GitHub account

The AWS CLI must be authenticated with an AWS account that has permission to create the required infrastructure.

Example:

```powershell
aws configure
```

Verify authentication:

```powershell
aws sts get-caller-identity
```

---

## Deployment

### 1. Clone the Repository

```powershell
git clone https://github.com/wh102/Carbon-aware-K8s-Project.git
cd Carbon-aware-K8s-Project
```

---

### 2. Configure Required Secrets

Sensitive credentials must not be committed to the repository.

The GitHub Actions workflow requires the appropriate repository secrets for AWS authentication and any Terraform variables marked as sensitive.

Typical examples include:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
GH_PAT
```

Additional secrets should be configured according to the Terraform variables used by the deployment.

---

### 3. Initialise Terraform

Move into the Terraform directory:

```powershell
cd terraform
```

Initialise Terraform:

```powershell
terraform init
```

---

### 4. Validate the Configuration

```powershell
terraform fmt -check
terraform validate
```

---

### 5. Review the Deployment Plan

```powershell
terraform plan
```

Review all infrastructure changes before applying them.

---

### 6. Deploy the Infrastructure

```powershell
terraform apply
```

Confirm the deployment when prompted.

Terraform provisions the AWS infrastructure required by the project, including the EKS environment and supporting components.

---

### 7. Configure kubectl

After the EKS cluster has been created, configure local Kubernetes access.

For example:

```powershell
aws eks update-kubeconfig --region eu-west-2 --name <cluster-name>
```

Verify the connection:

```powershell
kubectl get nodes
```

---

### 8. Verify the Application

Check the application namespace:

```powershell
kubectl get pods -n flask-app
```

Check the service:

```powershell
kubectl get svc -n flask-app
```

Check the ingress:

```powershell
kubectl get ingress -n flask-app
```

Once the AWS Application Load Balancer is available, its address can be used to access the Flask application.

---

## Monitoring and Observability

### Prometheus

Prometheus collects application, Kubernetes and energy metrics.

The Flask application exposes Prometheus metrics at:

```text
/metrics
```

A Kubernetes `ServiceMonitor` allows the Prometheus Operator to discover the Flask service.

The ServiceMonitor selects:

```yaml
selector:
  matchLabels:
    app: flask-app
```

and scrapes:

```yaml
path: /metrics
port: http
```

---

### Carbon Intensity

Verify the metric in Prometheus:

```promql
carbon_intensity
```

To obtain a single cluster-wide value:

```promql
max(carbon_intensity)
```

---

### Application Request Rate

Raw counter:

```promql
flask_http_requests_total
```

Application request rate:

```promql
sum(rate(flask_http_requests_total[2m]))
```

---

### Kepler Energy Monitoring

Kepler provides energy-consumption metrics for Kubernetes workloads.

The Flask workload can be queried using:

```promql
sum(
  rate(
    kepler_container_joules_total{
      container_namespace="flask-app",
      container_name="flask-app",
      mode="dynamic"
    }[5m]
  )
)
```

---

### Estimated Carbon Emissions

Energy consumption can be combined with carbon intensity.

For example:

```promql
(
  sum(
    rate(
      kepler_container_joules_total{
        container_namespace="flask-app",
        container_name="flask-app",
        mode="dynamic"
      }[2m]
    )
  )
  *
  max(carbon_intensity)
)
/ 3600000
```

This demonstrates how energy measurements and grid carbon intensity can be combined to estimate the carbon impact of the running workload.

---

## Grafana Dashboard

Grafana is used to visualise the project's observability data.

The completed dashboard contains panels covering the main carbon-aware metrics, including:

- UK carbon intensity
- Flask workload energy consumption
- application request rate
- carbon-aware scaling metric
- Kubernetes replica/scaling behaviour

Together, these panels provide visibility across the complete chain:

```text
Traffic
   ↓
Application
   ↓
Energy Consumption
   ↓
Carbon Intensity
   ↓
Carbon-Aware Metric
   ↓
Kubernetes Scaling
```

Screenshots of the completed monitoring environment and project validation can be retained as supporting project evidence.

---

## Testing the Autoscaler

The application can be load tested by repeatedly sending HTTP requests to the application load balancer.

For example, in PowerShell:

```powershell
$url = "http://<application-load-balancer>/"

1..300 | ForEach-Object {
    curl.exe -s -o NUL $url
}
```

The application request rate can then be checked in Prometheus:

```promql
sum(rate(flask_http_requests_total[2m]))
```

The HPA can be monitored with:

```powershell
kubectl get hpa -n flask-app -w
```

Replica changes can be observed with:

```powershell
kubectl get pods -n flask-app -w
```

During project testing, increased application demand caused KEDA and HPA to increase the number of Flask replicas.

After traffic reduced and the configured stabilisation period elapsed, the deployment scaled back down.

This demonstrated the complete autoscaling path:

```text
HTTP Traffic
     ↓
Flask Prometheus Counter
     ↓
Prometheus
     ↓
Carbon + Energy Adjustments
     ↓
KEDA
     ↓
External Metric
     ↓
Kubernetes HPA
     ↓
Replica Scaling
```

---

## CI/CD and GitOps

The project separates infrastructure provisioning from Kubernetes application deployment.

### GitHub Actions

The repository contains multiple GitHub Actions workflows with different responsibilities:

- `terraform.yml` — provisions the AWS/EKS platform in dependency-aware stages.
- `deploy-app.yaml` — builds and deploys the Flask application image.
- `ecr-image-sync.yaml` — synchronises required container images with Amazon ECR.

This separates infrastructure provisioning, application delivery and image-management concerns rather than combining everything into one pipeline.

The Terraform workflow can perform tasks such as:

```text
Checkout repository
        ↓
Configure AWS credentials
        ↓
Install Terraform
        ↓
Terraform Init
        ↓
Terraform Format / Validate
        ↓
Terraform Plan
        ↓
Terraform Apply
```

Sensitive values are supplied through GitHub repository secrets rather than being committed to source control.

---

### Argo CD

Argo CD provides GitOps deployment for Kubernetes resources.

The desired Kubernetes state is stored in the GitHub repository.

Argo CD compares this desired state with the live EKS cluster and synchronises changes.

The deployment flow is therefore:

```text
Developer
    ↓
Git Commit
    ↓
GitHub
    ↓
Argo CD
    ↓
Amazon EKS
```

This provides declarative and reproducible Kubernetes deployment.

---

## Repository Structure

The repository is organised around application code, Kubernetes manifests, infrastructure and automation.

A simplified structure is shown below:

```text
Carbon-aware-K8s-Project/
│
├── .github/
│   └── workflows/
│       ├── terraform.yml
│       ├── deploy-app.yaml
│       └── ecr-image-sync.yaml
│
├── k8s-manifest/
│   ├── flask-app.yaml
│   ├── mysql.yaml
│   └── keda-scaling.yaml
│
├── terraform/
│   ├── ecr.tf
|   ├── eks.tf
|   ├── helm.tf
|   ├── kubernetes.tf
|   ├── vpc.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
|   ├── app-namespace.tf
|   ├── .terraform.lock.hcl
|   ├── kepler-config.yaml
│   └── kepler-values.yaml
│
├── app/
|   ├── Dockerfile
|   ├── app.py
|   ├── requirements.txt
│   └── templates/
│       └── index.html
├── .dockerignore
├── .gitignore
├── argocd-app.yaml
├── argocd-install.yaml
├── iam_policy.json
├── kepler-app.yaml
└── README.md
```

> The exact Terraform file layout may vary as the infrastructure configuration evolves.

---

## Kubernetes Application Components

### Flask Deployment

The Flask application runs as a Kubernetes Deployment.

Resource requests and limits are configured so Kubernetes can schedule the workload predictably.

The deployment also implements:

- startup probe
- liveness probe
- readiness probe
- graceful SIGTERM handling
- MySQL connectivity checks

---

### Flask Service

The Flask workload is exposed internally through a Kubernetes Service.

The service also provides the named `http` port used by the Prometheus ServiceMonitor.

---

### Application Load Balancer

An AWS ALB Ingress exposes the Flask application externally.

The ingress uses the AWS Load Balancer Controller and routes external HTTP requests to the Flask service.

---

### MySQL

MySQL provides persistent application data storage.

The Flask application connects using environment variables and Kubernetes secrets rather than embedding credentials directly in the application source.

---

## Results

The completed implementation successfully demonstrated the main project objectives.

### Infrastructure

Terraform successfully provisioned the AWS and Kubernetes infrastructure.

### Application

The Flask application successfully ran on Amazon EKS and communicated with MySQL.

### External Access

The application was accessible through an AWS Application Load Balancer.

### GitOps

Argo CD successfully synchronised Kubernetes manifests from GitHub.

### Monitoring

Prometheus successfully scraped the Flask application's custom metrics.

### Carbon Data

The `carbon_intensity` metric was successfully exposed to Prometheus.

### Application Demand

The custom:

```text
flask_http_requests_total
```

counter successfully measured application requests.

### Energy Monitoring

Kepler successfully produced container-level energy measurements for the Flask workload.

### Carbon-Aware Metric

Prometheus successfully combined application demand, carbon intensity and Kepler energy data into a single scaling signal.

### Autoscaling

KEDA successfully exposed the Prometheus query as an external Kubernetes metric.

The HPA responded to the metric and scaled the Flask deployment.

The final scaler used:

```yaml
metricType: AverageValue
```

which allowed the scaling signal to be interpreted appropriately across multiple application replicas.

### Visualisation

Grafana successfully visualised the application's carbon, energy, traffic and autoscaling behaviour.

---

## Destroying the Infrastructure

Cloud resources should be destroyed when they are no longer required to prevent unnecessary AWS charges.

From the Terraform directory:

```powershell
terraform destroy
```

Review the destruction plan and confirm when prompted.

After completion, verify that major billable resources such as EKS infrastructure and load balancers have been removed.

Terraform state is stored remotely using the configured S3 backend.

---

## Security Considerations

Sensitive credentials should never be committed directly to Git.

The project uses mechanisms such as:

- GitHub Actions secrets
- Kubernetes Secrets
- Terraform sensitive variables
- AWS IAM permissions

Credentials should be rotated if they are accidentally exposed.

Production deployments should additionally use stronger secret-management mechanisms and least-privilege IAM policies.

---

## Limitations and Future Improvements

This project is primarily a proof of concept demonstrating carbon-aware autoscaling.

Several areas could be extended in future work.

### Carbon Forecasting

The current implementation uses current grid carbon intensity.

A future implementation could use forecast carbon intensity and proactively schedule workloads during lower-carbon periods.

### Geographic Carbon Awareness

Workloads could potentially be shifted between cloud regions based on regional carbon intensity.

### Improved Energy Modelling

Kepler provides estimated workload energy information. Future work could compare these estimates with hardware-level or cloud-provider energy measurements.

### Advanced Load Testing

A dedicated load-testing framework such as Locust or k6 could provide repeatable workload profiles and more detailed performance testing.

### Long-Term Carbon Reporting

Prometheus data could be retained for longer periods and used to calculate cumulative energy use and estimated emissions.

### Multi-Cloud Deployment

The architecture could be extended to deploy workloads across multiple cloud providers and select infrastructure based on carbon intensity, cost and availability.

### HTTPS

TLS certificates and HTTPS could be added to the public ALB endpoint for a production deployment.

### Production Database

A production implementation could replace the Kubernetes-hosted MySQL instance with a managed database service such as Amazon RDS.

---

## Project Objectives

The project demonstrates how modern cloud-native technologies can be combined to make sustainability information part of infrastructure decision-making.

Rather than treating observability, energy consumption and autoscaling as separate systems, the project integrates them into a single control loop.

The resulting implementation demonstrates:

```text
Infrastructure as Code
        +
Containerisation
        +
Managed Kubernetes
        +
GitOps
        +
Observability
        +
Energy Monitoring
        +
Carbon Intensity
        +
Autoscaling
```

The project therefore provides a practical proof of concept for **carbon-aware cloud-native computing**.

---

## Acknowledgments

This project makes use of several open-source and cloud-native technologies, including:

- Kubernetes
- Terraform
- Prometheus
- Grafana
- KEDA
- Kepler
- Argo CD
- Flask
- MySQL

The project also uses UK electricity carbon-intensity data to demonstrate how environmental information can be incorporated into Kubernetes workload management.

---

## Author

**W.H**

GitHub: `wh102`

Project repository:

```text
https://github.com/wh102/Carbon-aware-K8s-Project
```

---

## Project Status

**Completed**

The final implementation demonstrates:

- AWS infrastructure provisioned using Terraform
- Amazon EKS Kubernetes deployment
- Dockerised Flask application
- MySQL persistence
- AWS ALB ingress
- Argo CD GitOps
- Prometheus monitoring
- custom Flask metrics
- UK carbon-intensity metrics
- Kepler energy monitoring
- Grafana visualisation
- KEDA carbon-aware autoscaling
- Kubernetes HPA scaling
- GitHub Actions infrastructure automation
