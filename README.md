# Go Web App — DevOpsified

A simple Go web application, taken from `go run main.go` all the way to a **cloud-native, GitOps-driven deployment on AWS EKS**. This repo is a hands-on demonstration of a full DevOps toolchain app[...]

> Built as a practical exercise in taking an application from "runs on my machine" to "runs on a Kubernetes cluster, deployed via GitOps."

---

## Overview

The application itself is intentionally simple — a Go `net/http` server that renders a course-listing web page from static HTML/CSS. That simplicity is the point: it keeps the focus on the **Dev[...]

Starting from that base, this project layers on:

- **Containerization** with a multi-stage, distroless Docker build
- **Kubernetes manifests** for direct `kubectl` deployment
- **A Helm chart** to templatize and version the Kubernetes resources
- **An NGINX Ingress Controller** to route external traffic into the cluster
- **An AWS EKS cluster** as the target production environment
- **A GitHub Actions CI/CD pipeline** that builds, tests, lints, containerizes, and pushes the app — then automatically bumps the image tag in the Helm chart
- **ArgoCD** for GitOps-style continuous delivery — the cluster state is kept in sync with what's declared in Git

---

## Architecture

```
 Developer
     │
     │ git push (app code)
     ▼
 GitHub Actions CI  ──────────────────────────────────────────┐
     │ build → test → lint → docker build → push to Docker Hub │
     │ bump image tag in helm/go-web-app-chart/values.yaml     │
     │ commit + push back to "main"                            │
     ▼                                                          │
 GitHub Repository (this repo) ◄───────────────────────────────┘
     │
     │  Helm chart declares the new desired state
     ▼
 ArgoCD  ───────────────►  syncs desired state to cluster
     │
     ▼
 AWS EKS Cluster
     ├── Deployment (Go app pods, built from the Dockerfile)
     ├── Service (ClusterIP, exposes the pods internally)
     └── Ingress ──► NGINX Ingress Controller ──► External traffic
```

**Flow in short:** a push to `main` triggers CI, which builds, tests, and lints the app, builds a Docker image and pushes it to Docker Hub tagged with the CI run ID, then writes that same tag into[...]

---

## Tech Stack

| Layer                        | Tool / Technology                                     |
|-------------------------------|--------------------------------------------------------|
| Application                    | Go (`net/http`, standard library)                      |
| Containerization                 | Docker (multi-stage build, distroless runtime image)   |
| Orchestration                     | Kubernetes                                             |
| Package Management                 | Helm                                                    |
| Traffic Routing                     | NGINX Ingress Controller                                |
| Cloud Infrastructure                  | AWS EKS (Elastic Kubernetes Service)                    |
| Continuous Integration                   | GitHub Actions (build, test, lint, image build/push)    |
| Continuous Delivery / GitOps              | ArgoCD                                                  |
| Code Quality                              | golangci-lint                                           |
| Container Registry                        | Docker Hub                                              |
| Version Control                          | Git / GitHub                                            |

---

## Repository Structure

```
go-web-app-devopsified/
├── .github/
│   └── workflows/
│       └── ci.yml               # CI pipeline: build, test, lint, image push, Helm tag bump
├── main.go                    # Go application entrypoint (HTTP server)
├── main_test.go                # Unit tests for the application
├── go.mod                      # Go module definition
├── Dockerfile                  # Multi-stage build → distroless production image
├── static/                     # Static assets (HTML templates, images, CSS)
├── k8s/                        # Raw Kubernetes manifests (Deployment, Service, Ingress)
├── helm/
│   └── go-web-app-chart/       # Helm chart packaging the Kubernetes resources
├── ingress-controller/         # NGINX Ingress Controller setup
├── eks/                        # AWS EKS cluster provisioning configuration
└── gitops/
    └── argocd/                 # ArgoCD Application manifest for GitOps-based deployment
```

---

## Key Features

- **Multi-stage, distroless Docker image** — the build stage compiles the Go binary with the full `golang` image, then the final image copies only the compiled binary and static assets onto a `g[...]
- **Kubernetes-native deployment** — the app runs as a `Deployment`, exposed internally through a `Service`, and externally through an `Ingress` resource.
- **Helm packaging** — the same Kubernetes resources are templated as a Helm chart, making the release configurable and versioned rather than a set of static YAML files.
- **Ingress-based routing** — an NGINX Ingress Controller handles external access instead of relying on a `NodePort` or a manually provisioned `LoadBalancer` per service.
- **GitOps delivery with ArgoCD** — rather than deploying with `kubectl apply` by hand, the desired cluster state lives in this Git repository and ArgoCD continuously reconciles the live EKS cl[...]
- **Cloud-ready** — designed to run on a real AWS EKS cluster, not just a local cluster like kind/minikube.

---

## CI/CD Pipeline (GitHub Actions)

The workflow at `.github/workflows/ci.yml` runs on every push to `main` (excluding changes under `helm/**` and `README.md`, to avoid the pipeline re-triggering itself) and is split into four jobs:

| Job | What it does |
|---|---|
| **build** | Checks out the code, sets up Go, compiles the binary (`go build`), and runs the unit tests (`go test`) |
| **code-quality** | Runs `golangci-lint` against the codebase to catch style and correctness issues early |
| **push** | Logs into Docker Hub, builds the image with Docker Buildx using the repo's `Dockerfile`, and pushes it tagged with the GitHub Actions run ID (`go-web-app:${{ github.run_id }}`) |
| **update-newtag-in-helm-chart** | Checks the repo back out, updates `helm/go-web-app-chart/values.yaml` so the chart's image tag matches the image just pushed, then commits and pushes that chan[...]

That last job is what closes the loop between CI and CD: instead of someone manually editing the Helm chart after a new image is built, the pipeline does it automatically — and because that com[...]

---

## Getting Started

### Prerequisites

- Go 1.23+
- Docker
- `kubectl`
- Helm 3+
- An AWS account + `eksctl` (for the EKS cluster)
- ArgoCD (running on the target cluster)

### 1. Run locally

```bash
git clone https://github.com/Alaa-Atwa/go-web-app-devopsified.git
cd go-web-app-devopsified
go run main.go
```

The server starts on port `8080`. Visit `http://localhost:8080/courses` in your browser.

### 2. Build and run with Docker

```bash
docker build -t go-web-app:latest .
docker run -p 8080:8080 go-web-app:latest
```

### 3. Deploy with raw Kubernetes manifests

```bash
kubectl apply -f k8s/
```

### 4. Deploy with Helm

```bash
helm install go-web-app ./helm/go-web-app-chart
```

### 5. Provision the EKS cluster

Cluster provisioning configuration lives under `eks/`. Once your AWS credentials are configured, provision the cluster and point `kubectl` at it before deploying the Ingress Controller and the applica[...]

### 6. Set up the Ingress Controller

Manifests/configuration for the NGINX Ingress Controller live under `ingress-controller/`. Apply them to the cluster so the `Ingress` resource defined in `k8s/` (or the Helm chart) has a controll[...]

### 7. Deploy via ArgoCD (GitOps)

```bash
kubectl apply -f gitops/argocd/
```

Once the ArgoCD `Application` resource is created, ArgoCD picks up the Helm chart from this repository and keeps the cluster in sync with it automatically — no manual `kubectl apply` needed for[...]

---

## Preview

The application serves a simple course-listing page — see `static/images/golang-website.png` in the repo for a preview of the running app.

---

## What This Project Demonstrates

- Writing a production-style, multi-stage `Dockerfile` with a minimal distroless runtime image
- Structuring Kubernetes resources both as raw manifests and as a reusable Helm chart
- Configuring Ingress-based traffic routing with a real Ingress Controller
- Provisioning and targeting a managed Kubernetes service (AWS EKS)
- Implementing GitOps delivery with ArgoCD instead of manual, imperative deployments
- Building a CI pipeline in GitHub Actions that ties directly into the CD side — automating the "update the image tag" step that's manual in a lot of tutorial-level projects
- Organizing a repository so that application code, container config, and infrastructure/deployment config are clearly separated and independently understandable

---

## Possible Next Steps

- [ ] Add resource requests/limits and health probes (liveness/readiness) to the Deployment
- [ ] Add TLS termination at the Ingress (cert-manager + Let's Encrypt)
- [ ] Add Horizontal Pod Autoscaling
- [ ] Add monitoring/observability (Prometheus + Grafana)
- [ ] Cache Go modules in CI to speed up the `build` job
- [ ] Add a `needs: [build, code-quality]` gate on the `push` job so a lint failure blocks the image push

---

## Author

**Alaa Atwa**
DevOps / System Administration | Cloud & Infrastructure
GitHub: [@Alaa-Atwa](https://github.com/Alaa-Atwa)

---

## License

This project is open source and available for learning purposes.
